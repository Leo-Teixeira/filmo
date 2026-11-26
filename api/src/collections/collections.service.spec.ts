import { ConflictException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma } from '../generated/prisma/client';
import { CollectionRole } from '../generated/prisma/enums';
import { PrismaErrorCode } from '../prisma/prisma-errors';
import { PrismaService } from '../prisma/prisma.service';
import { TitleNotFoundException } from '../titles/titles.service';
import {
  CollectionItemNotFoundException,
  CollectionNotFoundException,
  CollectionsService,
  InviteCodeNotFoundException,
} from './collections.service';
import { INVITE_CODE_PATTERN } from './invite-code';

const prismaError = (code: string) =>
  new Prisma.PrismaClientKnownRequestError('boom', {
    code,
    clientVersion: 'test',
  });

const row = (role: CollectionRole) => ({
  id: 'col-1',
  name: 'Films',
  inviteCode: 'ABCDEFGHJK',
  createdAt: new Date(),
  members: [{ role }],
  _count: { items: 2, members: 3 },
});

describe('CollectionsService', () => {
  let service: CollectionsService;

  const collection = {
    findMany: jest.fn(),
    findFirst: jest.fn(),
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  };
  const collectionMember = {
    findMany: jest.fn(),
    findUnique: jest.fn(),
    create: jest.fn(),
    count: jest.fn(),
    delete: jest.fn(),
  };
  const collectionItem = { create: jest.fn(), delete: jest.fn() };
  const tx = { collectionMember };
  const prisma = {
    collection,
    collectionMember,
    collectionItem,
    $transaction: jest.fn((run: (client: typeof tx) => unknown) => run(tx)),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const moduleRef = await Test.createTestingModule({
      providers: [
        CollectionsService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    service = moduleRef.get(CollectionsService);
  });

  describe('create', () => {
    it('makes the caller OWNER with a well-formed invite code', async () => {
      collection.create.mockResolvedValue(row(CollectionRole.OWNER));

      const result = await service.create('user-1', 'Films');

      const [{ data }] = collection.create.mock.calls[0] as [
        { data: { inviteCode: string; members: unknown } },
      ];
      expect(data.inviteCode).toMatch(INVITE_CODE_PATTERN);
      expect(data.members).toEqual({
        create: { userId: 'user-1', role: CollectionRole.OWNER },
      });
      expect(result).toMatchObject({ role: 'OWNER', inviteCode: 'ABCDEFGHJK' });
    });

    it('retries on an invite code collision', async () => {
      collection.create
        .mockRejectedValueOnce(
          prismaError(PrismaErrorCode.UniqueConstraintViolation),
        )
        .mockResolvedValueOnce(row(CollectionRole.OWNER));

      await service.create('user-1', 'Films');

      expect(collection.create).toHaveBeenCalledTimes(2);
    });

    it('gives up after repeated collisions', async () => {
      collection.create.mockRejectedValue(
        prismaError(PrismaErrorCode.UniqueConstraintViolation),
      );

      await expect(service.create('user-1', 'Films')).rejects.toBeInstanceOf(
        Prisma.PrismaClientKnownRequestError,
      );
      expect(collection.create).toHaveBeenCalledTimes(3);
    });

    it('returns 404 when the account no longer exists', async () => {
      collection.create.mockRejectedValue(
        prismaError(PrismaErrorCode.ForeignKeyViolation),
      );

      await expect(service.create('user-1', 'Films')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  it('hides the invite code from a plain member', async () => {
    collection.findMany.mockResolvedValue([row(CollectionRole.MEMBER)]);

    const [summary] = await service.listMine('user-1');

    expect(summary).not.toHaveProperty('inviteCode');
    expect(summary).toMatchObject({ itemCount: 2, memberCount: 3 });
  });

  it('scopes findOne to the caller membership', async () => {
    collection.findFirst.mockResolvedValue(null);

    await expect(service.findOne('col-1', 'user-1')).rejects.toBeInstanceOf(
      CollectionNotFoundException,
    );
    expect(collection.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'col-1', members: { some: { userId: 'user-1' } } },
      }),
    );
  });

  it('only lets an owner rename, else 404', async () => {
    collection.update.mockRejectedValue(
      prismaError(PrismaErrorCode.RecordNotFound),
    );

    await expect(
      service.rename('col-1', 'user-1', 'New'),
    ).rejects.toBeInstanceOf(CollectionNotFoundException);
    expect(collection.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          id: 'col-1',
          members: { some: { userId: 'user-1', role: CollectionRole.OWNER } },
        },
      }),
    );
  });

  it('rethrows unexpected errors on delete', async () => {
    collection.delete.mockRejectedValue(new Error('db down'));

    await expect(service.remove('col-1', 'user-1')).rejects.toThrow('db down');
  });

  describe('join', () => {
    it('returns 404 for an unknown code', async () => {
      collection.findUnique.mockResolvedValue(null);

      await expect(service.join('user-1', 'ABCDEFGHJK')).rejects.toBeInstanceOf(
        InviteCodeNotFoundException,
      );
      expect(collectionMember.create).not.toHaveBeenCalled();
    });

    it('returns 409 when already a member', async () => {
      collection.findUnique.mockResolvedValue({ id: 'col-1' });
      collectionMember.create.mockRejectedValue(
        prismaError(PrismaErrorCode.UniqueConstraintViolation),
      );

      await expect(service.join('user-1', 'ABCDEFGHJK')).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('joins as MEMBER and returns the summary', async () => {
      collection.findUnique.mockResolvedValue({ id: 'col-1' });
      collectionMember.create.mockResolvedValue({});
      collection.findFirst.mockResolvedValue(row(CollectionRole.MEMBER));

      const result = await service.join('user-1', 'ABCDEFGHJK');

      expect(collectionMember.create).toHaveBeenCalledWith({
        data: { collectionId: 'col-1', userId: 'user-1' },
      });
      expect(result).toMatchObject({ id: 'col-1', role: 'MEMBER' });
    });
  });

  describe('leave', () => {
    it('blocks the last owner', async () => {
      collectionMember.findUnique.mockResolvedValue({
        role: CollectionRole.OWNER,
      });
      collectionMember.count.mockResolvedValue(1);

      await expect(service.leave('col-1', 'user-1')).rejects.toBeInstanceOf(
        ConflictException,
      );
      expect(collectionMember.delete).not.toHaveBeenCalled();
    });

    it('lets a member leave', async () => {
      collectionMember.findUnique.mockResolvedValue({
        role: CollectionRole.MEMBER,
      });

      await service.leave('col-1', 'user-1');

      expect(collectionMember.delete).toHaveBeenCalledWith({
        where: {
          collectionId_userId: { collectionId: 'col-1', userId: 'user-1' },
        },
      });
    });

    it('returns 404 when not a member', async () => {
      collectionMember.findUnique.mockResolvedValue(null);

      await expect(service.leave('col-1', 'user-1')).rejects.toBeInstanceOf(
        CollectionNotFoundException,
      );
    });
  });

  describe('items', () => {
    it('records who added the title', async () => {
      collectionItem.create.mockResolvedValue({});

      await service.addItem('col-1', 'user-1', 'title-1');

      expect(collectionItem.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            collectionId: 'col-1',
            titleId: 'title-1',
            addedById: 'user-1',
          },
        }),
      );
    });

    it('maps a duplicate to 409 and an unknown title to 404', async () => {
      collectionItem.create.mockRejectedValueOnce(
        prismaError(PrismaErrorCode.UniqueConstraintViolation),
      );
      await expect(
        service.addItem('col-1', 'user-1', 'title-1'),
      ).rejects.toBeInstanceOf(ConflictException);

      collectionItem.create.mockRejectedValueOnce(
        prismaError(PrismaErrorCode.ForeignKeyViolation),
      );
      await expect(
        service.addItem('col-1', 'user-1', 'title-1'),
      ).rejects.toBeInstanceOf(TitleNotFoundException);
    });

    it('returns 404 when removing a title that is not there', async () => {
      collectionItem.delete.mockRejectedValue(
        prismaError(PrismaErrorCode.RecordNotFound),
      );

      await expect(
        service.removeItem('col-1', 'title-1'),
      ).rejects.toBeInstanceOf(CollectionItemNotFoundException);
    });
  });
});
