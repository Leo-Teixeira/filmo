import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { PrismaService } from './../src/prisma/prisma.service';

// Runs against the local docker Postgres configured in api/.env.
describe('Auth & /me (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  const createdEmails: string[] = [];

  const uniqueEmail = () => {
    const email = `e2e-${randomUUID()}@filmo.local`;
    createdEmails.push(email);
    return email;
  };

  const register = (email: string) =>
    request(app.getHttpServer())
      .post('/auth/register')
      .send({ email, password: 'password1234', displayName: '  E2E  ' });

  const bearer = (res: request.Response) =>
    `Bearer ${(res.body as { accessToken: string }).accessToken}`;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    await app.init();
    prisma = app.get(PrismaService);
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { email: { in: createdEmails } } });
    await prisma.household.deleteMany({ where: { name: 'e2e-household' } });
    await prisma.title.deleteMany({ where: { provider: 'e2e' } });
    await app.close();
  });

  it('GET / is public', () => {
    return request(app.getHttpServer()).get('/').expect(200);
  });

  it('GET /me without token returns 401', () => {
    return request(app.getHttpServer()).get('/me').expect(401);
  });

  it('normalizes the email and trims the display name', async () => {
    const email = uniqueEmail();
    const registered = await register(email.toUpperCase()).expect(201);

    const me = await request(app.getHttpServer())
      .get('/me')
      .set('Authorization', bearer(registered))
      .expect(200);
    expect(me.body).toMatchObject({ email, displayName: 'E2E' });
    expect(me.body).not.toHaveProperty('passwordHash');

    await register(email).expect(409);
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: ` ${email.toUpperCase()} `, password: 'password1234' })
      .expect(200);
  });

  it('deletes an account that added items, keeping the household items', async () => {
    const email = uniqueEmail();
    const auth = bearer(await register(email).expect(201));
    const me = await request(app.getHttpServer())
      .get('/me')
      .set('Authorization', auth);
    const userId = (me.body as { id: string }).id;

    const title = await prisma.title.create({
      data: {
        provider: 'e2e',
        externalId: randomUUID(),
        type: 'MOVIE',
        title: 'E2E',
      },
    });
    const household = await prisma.household.create({
      data: {
        name: 'e2e-household',
        inviteCode: randomUUID(),
        collections: { create: { name: 'Watchlist' } },
      },
      include: { collections: true },
    });
    const collectionId = household.collections[0].id;
    await prisma.collectionItem.create({
      data: { collectionId, titleId: title.id, addedById: userId },
    });

    await request(app.getHttpServer())
      .delete('/me')
      .set('Authorization', auth)
      .expect(204);

    const item = await prisma.collectionItem.findUnique({
      where: { collectionId_titleId: { collectionId, titleId: title.id } },
    });
    expect(item?.addedById).toBeNull();

    // Token still valid for up to 1h: the API must answer 404, not 500.
    await request(app.getHttpServer())
      .patch('/me')
      .set('Authorization', auth)
      .send({ displayName: 'ghost' })
      .expect(404);
    await request(app.getHttpServer())
      .delete('/me')
      .set('Authorization', auth)
      .expect(404);
  });
});
