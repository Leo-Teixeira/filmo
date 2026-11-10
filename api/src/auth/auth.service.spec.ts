import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as argon from 'argon2';
import { Prisma } from '../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  let service: AuthService;
  const prisma = {
    user: { create: jest.fn(), findUnique: jest.fn() },
  };
  const jwt = { signAsync: jest.fn().mockResolvedValue('signed-token') };

  beforeEach(async () => {
    jest.clearAllMocks();
    const moduleRef = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prisma },
        { provide: JwtService, useValue: jwt },
      ],
    }).compile();
    service = moduleRef.get(AuthService);
  });

  describe('register', () => {
    const dto = {
      email: 'leo@filmo.local',
      password: 'password123',
      displayName: 'Léo',
    };

    it('stores an argon2 hash, never the plain password', async () => {
      prisma.user.create.mockResolvedValue({ id: 'user-1' });

      const result = await service.register(dto);

      const [[{ data }]] = prisma.user.create.mock.calls as [
        [{ data: { passwordHash: string } }],
      ];
      expect(data.passwordHash).not.toBe(dto.password);
      await expect(argon.verify(data.passwordHash, dto.password)).resolves.toBe(
        true,
      );
      expect(jwt.signAsync).toHaveBeenCalledWith({ sub: 'user-1' });
      expect(result).toEqual({ accessToken: 'signed-token' });
    });

    it('maps a unique constraint violation to 409', async () => {
      prisma.user.create.mockRejectedValue(
        new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
          code: 'P2002',
          clientVersion: 'test',
        }),
      );

      await expect(service.register(dto)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('rethrows unexpected errors instead of hiding them', async () => {
      const dbDown = new Error('connection refused');
      prisma.user.create.mockRejectedValue(dbDown);

      await expect(service.register(dto)).rejects.toBe(dbDown);
    });
  });

  describe('login', () => {
    it('returns a token for valid credentials', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        passwordHash: await argon.hash('password123'),
      });

      await expect(
        service.login({ email: 'leo@filmo.local', password: 'password123' }),
      ).resolves.toEqual({ accessToken: 'signed-token' });
    });

    it('rejects a wrong password with the generic message', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        passwordHash: await argon.hash('password123'),
      });

      await expect(
        service.login({ email: 'leo@filmo.local', password: 'wrong-password' }),
      ).rejects.toThrow(new UnauthorizedException('Invalid credentials'));
    });

    it('rejects an unknown email with the same message', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.login({ email: 'nobody@filmo.local', password: 'password123' }),
      ).rejects.toThrow(new UnauthorizedException('Invalid credentials'));
    });
  });
});
