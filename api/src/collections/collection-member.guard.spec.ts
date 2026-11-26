import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { CollectionRole } from '../generated/prisma/enums';
import { PrismaService } from '../prisma/prisma.service';
import { CollectionMemberGuard } from './collection-member.guard';
import { CollectionNotFoundException } from './collections.service';

const COLLECTION_ID = '4f0c2a8e-7c1b-4d7e-9b9a-2f6d1c3e5a7b';

const contextFor = (id: string): ExecutionContext =>
  ({
    switchToHttp: () => ({
      getRequest: () => ({ params: { id }, user: { sub: 'user-1' } }),
    }),
    getHandler: () => undefined,
    getClass: () => undefined,
  }) as unknown as ExecutionContext;

describe('CollectionMemberGuard', () => {
  const findUnique = jest.fn();
  const prisma = {
    collectionMember: { findUnique },
  } as unknown as PrismaService;
  const reflector = { getAllAndOverride: jest.fn() };
  const guard = new CollectionMemberGuard(
    prisma,
    reflector as unknown as Reflector,
  );

  beforeEach(() => jest.clearAllMocks());

  it('returns 404 for a malformed id without querying', async () => {
    await expect(guard.canActivate(contextFor('nope'))).rejects.toBeInstanceOf(
      CollectionNotFoundException,
    );
    expect(findUnique).not.toHaveBeenCalled();
  });

  it('returns 404 for a non-member', async () => {
    findUnique.mockResolvedValue(null);

    await expect(
      guard.canActivate(contextFor(COLLECTION_ID)),
    ).rejects.toBeInstanceOf(CollectionNotFoundException);
    expect(findUnique).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          collectionId_userId: {
            collectionId: COLLECTION_ID,
            userId: 'user-1',
          },
        },
      }),
    );
  });

  it('returns 403 for a member on an owner-only route', async () => {
    findUnique.mockResolvedValue({ role: CollectionRole.MEMBER });
    reflector.getAllAndOverride.mockReturnValue(true);

    await expect(
      guard.canActivate(contextFor(COLLECTION_ID)),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('lets an owner through owner-only routes', async () => {
    findUnique.mockResolvedValue({ role: CollectionRole.OWNER });
    reflector.getAllAndOverride.mockReturnValue(true);

    await expect(guard.canActivate(contextFor(COLLECTION_ID))).resolves.toBe(
      true,
    );
  });
});
