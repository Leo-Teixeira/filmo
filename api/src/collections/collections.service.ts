import { Injectable } from '@nestjs/common';
import { Prisma } from '../generated/prisma/client';
import { CollectionRole } from '../generated/prisma/enums';
import { isPrismaError, PrismaErrorCode } from '../prisma/prisma-errors';
import { PrismaService } from '../prisma/prisma.service';
import { TitleNotFoundException } from '../titles/titles.service';
import { UserNotFoundException } from '../user/user.service';
import {
  AlreadyMemberException,
  CollectionItemNotFoundException,
  CollectionNotFoundException,
  InviteCodeNotFoundException,
  OwnerCannotLeaveException,
  TitleAlreadyInCollectionException,
} from './collections.errors';
import { generateInviteCode } from './invite-code';

const summarySelect = (userId: string) =>
  ({
    id: true,
    name: true,
    inviteCode: true,
    createdAt: true,
    members: { where: { userId }, select: { role: true } },
    _count: { select: { items: true, members: true } },
  }) as const;

const itemSelect = {
  addedAt: true,
  title: true,
  addedBy: { select: { id: true, displayName: true } },
} as const;

type CollectionSummaryRow = Prisma.CollectionGetPayload<{
  select: ReturnType<typeof summarySelect>;
}>;

// Only the owner may invite, so only the owner sees the invite code.
function toSummary(row: CollectionSummaryRow) {
  const membership = row.members.at(0);
  if (!membership) throw new CollectionNotFoundException();
  const role = membership.role;
  return {
    id: row.id,
    name: row.name,
    createdAt: row.createdAt,
    role,
    ...(role === CollectionRole.OWNER ? { inviteCode: row.inviteCode } : {}),
    itemCount: row._count.items,
    memberCount: row._count.members,
  };
}

// CollectionMemberGuard is the access check; the membership/owner filters below are a second line if a route ever skips it.
@Injectable()
export class CollectionsService {
  constructor(private readonly prisma: PrismaService) {}

  async listMine(userId: string) {
    const rows = await this.prisma.collection.findMany({
      where: { members: { some: { userId } } },
      select: summarySelect(userId),
      orderBy: { createdAt: 'asc' },
    });
    return rows.map(toSummary);
  }

  async create(userId: string, name: string) {
    try {
      const row = await this.prisma.collection.create({
        data: {
          name,
          // 50 bits of entropy: a collision is not worth a retry loop.
          inviteCode: generateInviteCode(),
          members: { create: { userId, role: CollectionRole.OWNER } },
        },
        select: summarySelect(userId),
      });
      return toSummary(row);
    } catch (e) {
      if (isPrismaError(e, PrismaErrorCode.ForeignKeyViolation)) {
        throw new UserNotFoundException();
      }
      throw e;
    }
  }

  async findOne(collectionId: string, userId: string) {
    const row = await this.prisma.collection.findFirst({
      where: { id: collectionId, members: { some: { userId } } },
      select: {
        ...summarySelect(userId),
        items: { select: itemSelect, orderBy: { addedAt: 'desc' } },
      },
    });
    if (!row) throw new CollectionNotFoundException();
    return { ...toSummary(row), items: row.items };
  }

  async rename(collectionId: string, userId: string, name: string) {
    try {
      const row = await this.prisma.collection.update({
        where: {
          id: collectionId,
          members: { some: { userId, role: CollectionRole.OWNER } },
        },
        data: { name },
        select: summarySelect(userId),
      });
      return toSummary(row);
    } catch (e) {
      if (isPrismaError(e, PrismaErrorCode.RecordNotFound)) {
        throw new CollectionNotFoundException();
      }
      throw e;
    }
  }

  async remove(collectionId: string, userId: string): Promise<void> {
    try {
      await this.prisma.collection.delete({
        where: {
          id: collectionId,
          members: { some: { userId, role: CollectionRole.OWNER } },
        },
      });
    } catch (e) {
      if (isPrismaError(e, PrismaErrorCode.RecordNotFound)) {
        throw new CollectionNotFoundException();
      }
      throw e;
    }
  }

  async join(userId: string, inviteCode: string) {
    const collection = await this.prisma.collection.findUnique({
      where: { inviteCode },
      select: { id: true },
    });
    if (!collection) throw new InviteCodeNotFoundException();

    try {
      await this.prisma.collectionMember.create({
        data: { collectionId: collection.id, userId },
      });
    } catch (e) {
      if (isPrismaError(e, PrismaErrorCode.UniqueConstraintViolation)) {
        throw new AlreadyMemberException();
      }
      // Collection deleted or account deleted between the lookup and the insert.
      if (isPrismaError(e, PrismaErrorCode.ForeignKeyViolation)) {
        throw new InviteCodeNotFoundException();
      }
      throw e;
    }
    return this.findSummary(collection.id, userId);
  }

  async leave(collectionId: string, userId: string): Promise<void> {
    const key = { collectionId_userId: { collectionId, userId } };
    const membership = await this.prisma.collectionMember.findUnique({
      where: key,
      select: { role: true },
    });
    if (!membership) throw new CollectionNotFoundException();
    // Exactly one owner per collection until ownership transfer exists.
    if (membership.role === CollectionRole.OWNER) {
      throw new OwnerCannotLeaveException();
    }
    try {
      await this.prisma.collectionMember.delete({ where: key });
    } catch (e) {
      if (isPrismaError(e, PrismaErrorCode.RecordNotFound)) {
        throw new CollectionNotFoundException();
      }
      throw e;
    }
  }

  listMembers(collectionId: string, userId: string) {
    return this.prisma.collectionMember.findMany({
      where: { collectionId, collection: { members: { some: { userId } } } },
      select: {
        role: true,
        joinedAt: true,
        user: { select: { id: true, displayName: true } },
      },
      orderBy: { joinedAt: 'asc' },
    });
  }

  async addItem(collectionId: string, userId: string, titleId: string) {
    try {
      return await this.prisma.collectionItem.create({
        data: { collectionId, titleId, addedById: userId },
        select: itemSelect,
      });
    } catch (e) {
      if (isPrismaError(e, PrismaErrorCode.UniqueConstraintViolation)) {
        throw new TitleAlreadyInCollectionException();
      }
      if (isPrismaError(e, PrismaErrorCode.ForeignKeyViolation)) {
        throw await this.missingReferenceError(titleId);
      }
      throw e;
    }
  }

  async removeItem(
    collectionId: string,
    userId: string,
    titleId: string,
  ): Promise<void> {
    try {
      await this.prisma.collectionItem.delete({
        where: {
          collectionId_titleId: { collectionId, titleId },
          collection: { members: { some: { userId } } },
        },
      });
    } catch (e) {
      if (isPrismaError(e, PrismaErrorCode.RecordNotFound)) {
        throw new CollectionItemNotFoundException();
      }
      throw e;
    }
  }

  // P2003 does not say which foreign key failed: unknown title, or collection/account deleted mid-request.
  private async missingReferenceError(titleId: string) {
    const title = await this.prisma.title.findUnique({
      where: { id: titleId },
      select: { id: true },
    });
    return title
      ? new CollectionNotFoundException()
      : new TitleNotFoundException();
  }

  private async findSummary(collectionId: string, userId: string) {
    const row = await this.prisma.collection.findFirst({
      where: { id: collectionId, members: { some: { userId } } },
      select: summarySelect(userId),
    });
    if (!row) throw new CollectionNotFoundException();
    return toSummary(row);
  }
}
