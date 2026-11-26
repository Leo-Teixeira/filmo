import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { PrismaService } from './../src/prisma/prisma.service';

interface Summary {
  id: string;
  role: string;
  inviteCode?: string;
}

// Runs against the local docker Postgres configured in api/.env.
describe('Collections (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  const createdEmails: string[] = [];
  const createdCollectionIds: string[] = [];
  let owner: string;
  let member: string;
  let outsider: string;
  let titleId: string;

  const http = () => request(app.getHttpServer());

  const signUp = async () => {
    const email = `e2e-${randomUUID()}@filmo.local`;
    createdEmails.push(email);
    const res = await http()
      .post('/auth/register')
      .send({ email, password: 'password1234', displayName: 'E2E' })
      .expect(201);
    return `Bearer ${(res.body as { accessToken: string }).accessToken}`;
  };

  const createCollection = async (auth: string) => {
    const res = await http()
      .post('/collections')
      .set('Authorization', auth)
      .send({ name: '  Soirées  ' })
      .expect(201);
    const created = res.body as Summary;
    createdCollectionIds.push(created.id);
    return created;
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    await app.init();
    prisma = app.get(PrismaService);

    [owner, member, outsider] = await Promise.all([
      signUp(),
      signUp(),
      signUp(),
    ]);
    const title = await prisma.title.create({
      data: {
        provider: 'e2e-collections',
        externalId: randomUUID(),
        type: 'MOVIE',
        title: 'E2E',
      },
    });
    titleId = title.id;
  });

  afterAll(async () => {
    await prisma.collection.deleteMany({
      where: { id: { in: createdCollectionIds } },
    });
    await prisma.user.deleteMany({ where: { email: { in: createdEmails } } });
    await prisma.title.deleteMany({ where: { provider: 'e2e-collections' } });
    await app.close();
  });

  it('creates a collection owned by the caller with an invite code', async () => {
    const created = await createCollection(owner);
    expect(created).toMatchObject({ name: 'Soirées', role: 'OWNER' });
    expect(created.inviteCode).toMatch(/^[A-Z2-9]{10}$/);

    const mine = await http()
      .get('/collections')
      .set('Authorization', owner)
      .expect(200);
    expect((mine.body as Summary[]).map((c) => c.id)).toContain(created.id);
  });

  it('rejects an empty name', () =>
    http()
      .post('/collections')
      .set('Authorization', owner)
      .send({ name: '   ' })
      .expect(400));

  it('returns 404 to a non-member on every collection route (anti-IDOR)', async () => {
    const { id } = await createCollection(owner);
    const as = (req: request.Test) => req.set('Authorization', outsider);

    await as(http().get(`/collections/${id}`)).expect(404);
    await as(http().patch(`/collections/${id}`).send({ name: 'x' })).expect(
      404,
    );
    await as(http().delete(`/collections/${id}`)).expect(404);
    await as(http().get(`/collections/${id}/members`)).expect(404);
    await as(http().post(`/collections/${id}/leave`)).expect(404);
    await as(http().post(`/collections/${id}/items`).send({ titleId })).expect(
      404,
    );
    await as(http().delete(`/collections/${id}/items/${titleId}`)).expect(404);

    const mine = await as(http().get('/collections')).expect(200);
    expect((mine.body as Summary[]).map((c) => c.id)).not.toContain(id);
    // Same answer for an id that does not exist at all.
    await as(http().get(`/collections/${randomUUID()}`)).expect(404);
    await as(http().get('/collections/not-a-uuid')).expect(404);
  });

  it('joins with a valid code, 404 on a wrong one, 409 when already a member', async () => {
    const { id, inviteCode } = await createCollection(owner);

    await http()
      .post('/collections/join')
      .set('Authorization', member)
      .send({ inviteCode: 'ZZZZZZZZZZ' })
      .expect(404);
    await http()
      .post('/collections/join')
      .set('Authorization', member)
      .send({ inviteCode: 'short' })
      .expect(400);

    const joined = await http()
      .post('/collections/join')
      .set('Authorization', member)
      .send({ inviteCode: ` ${inviteCode!.toLowerCase()} ` })
      .expect(201);
    expect(joined.body).toMatchObject({ id, role: 'MEMBER' });
    expect(joined.body).not.toHaveProperty('inviteCode');

    await http()
      .post('/collections/join')
      .set('Authorization', member)
      .send({ inviteCode })
      .expect(409);
    await http()
      .post('/collections/join')
      .set('Authorization', owner)
      .send({ inviteCode })
      .expect(409);

    const members = await http()
      .get(`/collections/${id}/members`)
      .set('Authorization', member)
      .expect(200);
    expect(members.body).toHaveLength(2);
    expect(JSON.stringify(members.body)).not.toContain('email');
  });

  it('enforces owner-only rules and shares items between members', async () => {
    const { id, inviteCode } = await createCollection(owner);
    await http()
      .post('/collections/join')
      .set('Authorization', member)
      .send({ inviteCode })
      .expect(201);

    await http()
      .patch(`/collections/${id}`)
      .set('Authorization', member)
      .send({ name: 'Mine now' })
      .expect(403);
    await http()
      .delete(`/collections/${id}`)
      .set('Authorization', member)
      .expect(403);
    await http()
      .patch(`/collections/${id}`)
      .set('Authorization', owner)
      .send({ name: 'Renamed' })
      .expect(200);

    await http()
      .post(`/collections/${id}/items`)
      .set('Authorization', member)
      .send({ titleId })
      .expect(201);
    await http()
      .post(`/collections/${id}/items`)
      .set('Authorization', owner)
      .send({ titleId })
      .expect(409);
    await http()
      .post(`/collections/${id}/items`)
      .set('Authorization', owner)
      .send({ titleId: randomUUID() })
      .expect(404);

    const detail = await http()
      .get(`/collections/${id}`)
      .set('Authorization', owner)
      .expect(200);
    expect(detail.body).toMatchObject({ name: 'Renamed', itemCount: 1 });

    await http()
      .delete(`/collections/${id}/items/${titleId}`)
      .set('Authorization', owner)
      .expect(204);
    await http()
      .delete(`/collections/${id}/items/${titleId}`)
      .set('Authorization', owner)
      .expect(404);

    await http()
      .post(`/collections/${id}/leave`)
      .set('Authorization', owner)
      .expect(409);
    await http()
      .post(`/collections/${id}/leave`)
      .set('Authorization', member)
      .expect(204);
    await http()
      .get(`/collections/${id}`)
      .set('Authorization', member)
      .expect(404);

    await http()
      .delete(`/collections/${id}`)
      .set('Authorization', owner)
      .expect(204);
    await http()
      .get(`/collections/${id}`)
      .set('Authorization', owner)
      .expect(404);
  });
});
