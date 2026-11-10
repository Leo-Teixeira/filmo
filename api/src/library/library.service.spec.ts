import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma } from '../generated/prisma/client';
import { WatchStatus } from '../generated/prisma/enums';
import { PrismaService } from '../prisma/prisma.service';
import { TitleNotFoundException } from '../titles/titles.service';
import { LibraryService } from './library.service';

const prismaError = (code: string) =>
  new Prisma.PrismaClientKnownRequestError('boom', {
    code,
    clientVersion: 'test',
  });

const key = { userId_titleId: { userId: 'user-1', titleId: 'title-1' } };

describe('LibraryService', () => {
  let service: LibraryService;

  const userTitle = {
    findMany: jest.fn(),
    findUnique: jest.fn(),
    findUniqueOrThrow: jest.fn(),
    upsert: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  };
  // Interactive transaction: the callback receives "tx", here the same userTitle mock.
  const tx = { userTitle };
  const prisma = {
    userTitle,
    $transaction: jest.fn((run: (client: typeof tx) => unknown) => run(tx)),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const moduleRef = await Test.createTestingModule({
      providers: [LibraryService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    service = moduleRef.get(LibraryService);
  });

  it('always scopes the list to the caller', async () => {
    userTitle.findMany.mockResolvedValue([]);

    await service.list('user-1', WatchStatus.WATCHING);

    expect(userTitle.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'user-1', status: WatchStatus.WATCHING },
      }),
    );
  });

  it('returns 404 when the title is not in the caller library', async () => {
    userTitle.findUnique.mockResolvedValue(null);

    await expect(service.findOne('user-1', 'title-1')).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(userTitle.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: key }),
    );
  });

  describe('upsert', () => {
    it('writes on the (userId, titleId) key and clears an omitted rating', async () => {
      userTitle.upsert.mockResolvedValue({ watchedAt: null });
      userTitle.findUniqueOrThrow.mockResolvedValue({ status: 'WATCHING' });

      await service.upsert('user-1', 'title-1', {
        status: WatchStatus.WATCHING,
      });

      expect(userTitle.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: key,
          update: {
            status: WatchStatus.WATCHING,
            rating: null,
            watchedAt: null,
          },
        }),
      );
      expect(userTitle.update).not.toHaveBeenCalled();
    });

    it('keeps the upsert free of include/select so Prisma uses a native ON CONFLICT upsert', async () => {
      userTitle.upsert.mockResolvedValue({ watchedAt: null });

      await service.upsert('user-1', 'title-1', {
        status: WatchStatus.WATCHING,
      });

      const [[args]] = userTitle.upsert.mock.calls as [[object]];
      expect(args).not.toHaveProperty('include');
      expect(args).not.toHaveProperty('select');
      expect(userTitle.findUniqueOrThrow).toHaveBeenCalledWith(
        expect.objectContaining({ where: key, omit: { userId: true } }),
      );
    });

    it('stamps watchedAt when an entry switches to COMPLETED', async () => {
      userTitle.upsert.mockResolvedValue({ watchedAt: null });
      userTitle.update.mockResolvedValue({});

      await service.upsert('user-1', 'title-1', {
        status: WatchStatus.COMPLETED,
        rating: 9,
      });

      expect(userTitle.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: key,
          data: { watchedAt: expect.any(Date) as unknown },
        }),
      );
    });

    it('keeps the original watchedAt when re-saving a COMPLETED entry', async () => {
      const watchedAt = new Date('2026-01-01');
      userTitle.upsert.mockResolvedValue({ watchedAt });
      userTitle.findUniqueOrThrow.mockResolvedValue({ watchedAt });

      const entry = await service.upsert('user-1', 'title-1', {
        status: WatchStatus.COMPLETED,
        rating: 7,
      });

      expect(userTitle.update).not.toHaveBeenCalled();
      expect(entry.watchedAt).toBe(watchedAt);
    });

    it('maps an unknown titleId (P2003) to 404', async () => {
      userTitle.upsert.mockRejectedValue(prismaError('P2003'));

      await expect(
        service.upsert('user-1', 'ghost', { status: WatchStatus.WATCHING }),
      ).rejects.toBeInstanceOf(TitleNotFoundException);
    });
  });

  describe('remove', () => {
    it('deletes on the (userId, titleId) key', async () => {
      userTitle.delete.mockResolvedValue({});

      await service.remove('user-1', 'title-1');

      expect(userTitle.delete).toHaveBeenCalledWith({ where: key });
    });

    it('maps P2025 to 404', async () => {
      userTitle.delete.mockRejectedValue(prismaError('P2025'));

      await expect(service.remove('user-1', 'title-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('rethrows other errors untouched', async () => {
      const dbDown = new Error('connection refused');
      userTitle.delete.mockRejectedValue(dbDown);

      await expect(service.remove('user-1', 'title-1')).rejects.toBe(dbDown);
    });
  });
});
