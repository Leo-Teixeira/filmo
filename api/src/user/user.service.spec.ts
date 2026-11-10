import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma } from '../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UserService } from './user.service';

const recordNotFound = () =>
  new Prisma.PrismaClientKnownRequestError('Record not found', {
    code: 'P2025',
    clientVersion: 'test',
  });

describe('UserService', () => {
  let service: UserService;
  const prisma = {
    user: { findUnique: jest.fn(), update: jest.fn(), delete: jest.fn() },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const moduleRef = await Test.createTestingModule({
      providers: [UserService, { provide: PrismaService, useValue: prisma }],
    }).compile();
    service = moduleRef.get(UserService);
  });

  it('never selects the password hash', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });

    await service.findMe('user-1');

    const [[{ select }]] = prisma.user.findUnique.mock.calls as [
      [{ select: Record<string, boolean> }],
    ];
    expect(select).not.toHaveProperty('passwordHash');
  });

  it('returns 404 when the token belongs to a deleted account', async () => {
    prisma.user.findUnique.mockResolvedValue(null);

    await expect(service.findMe('ghost')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('maps P2025 on update to 404', async () => {
    prisma.user.update.mockRejectedValue(recordNotFound());

    await expect(
      service.updateMe('ghost', { displayName: 'x' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('maps P2025 on delete to 404', async () => {
    prisma.user.delete.mockRejectedValue(recordNotFound());

    await expect(service.removeMe('ghost')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('rethrows other errors untouched', async () => {
    const dbDown = new Error('connection refused');
    prisma.user.delete.mockRejectedValue(dbDown);

    await expect(service.removeMe('user-1')).rejects.toBe(dbDown);
  });
});
