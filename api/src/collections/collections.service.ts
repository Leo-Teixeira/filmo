import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CollectionRole } from '../generated/prisma/enums';
import { isPrismaError, PrismaErrorCode } from '../prisma/prisma-errors';
import { PrismaService } from '../prisma/prisma.service';
import { TitleNotFoundException } from '../titles/titles.service';
import { UserNotFoundException } from '../user/user.service';
import { generateInviteCode } from './invite-code';

const MAX_INVITE_CODE_ATTEMPTS = 3;

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

interface CollectionSummaryRow {
  id: string;
  name: string;
  inviteCode: string;
  createdAt: Date;
  members: { role: CollectionRole }[];
  _count: { items: number; members: number };
}

// Only the owner may invite, so only the owner sees the invite code.
function toSummary(row: CollectionSummaryRow) {
  const role = row.members[0].role;
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

// Access to /collections/:id is enforced by CollectionMemberGuard; queries still scope to the caller where it is free.
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
    for (let attempt = 1; ; attempt++) {
      try {
        const row = await this.prisma.collection.create({
          data: {
            name,
            inviteCode: generateInviteCode(),
            members: { create: { userId, role: CollectionRole.OWNER } },
          },
          select: summarySelect(userId),
        });
        return toSummary(row);
      } catch (e) {
        // The only unique column on a new collection is inviteCode: retry on collision.
        if (
          isPrismaError(e, PrismaErrorCode.UniqueConstraintViolation) &&
          attempt < MAX_INVITE_CODE_ATTEMPTS
        ) {
          continue;
        }
        if (isPrismaError(e, PrismaErrorCode.ForeignKeyViolation)) {
          throw new UserNotFoundException();
        }
        throw e;
      }
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
        throw new ConflictException('Already a member of this collection');
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
    await this.prisma.$transaction(async (tx) => {
      const key = { collectionId_userId: { collectionId, userId } };
      const membership = await tx.collectionMember.findUnique({
        where: key,
        select: { role: true },
      });
      if (!membership) throw new CollectionNotFoundException();

      if (membership.role === CollectionRole.OWNER) {
        const owners = await tx.collectionMember.count({
          where: { collectionId, role: CollectionRole.OWNER },
        });
        if (owners <= 1) {
          throw new ConflictException(
            'The last owner cannot leave; delete the collection instead',
          );
        }
      }
      await tx.collectionMember.delete({ where: key });
    });
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
        throw new ConflictException('Title already in this collection');
      }
      if (isPrismaError(e, PrismaErrorCode.ForeignKeyViolation)) {
        throw new TitleNotFoundException();
      }
      throw e;
    }
  }

  async removeItem(collectionId: string, titleId: string): Promise<void> {
    try {
      await this.prisma.collectionItem.delete({
        where: { collectionId_titleId: { collectionId, titleId } },
      });
    } catch (e) {
      if (isPrismaError(e, PrismaErrorCode.RecordNotFound)) {
        throw new CollectionItemNotFoundException();
      }
      throw e;
    }
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

export class CollectionNotFoundException extends NotFoundException {
  constructor() {
    super('Collection not found');
  }
}

export class InviteCodeNotFoundException extends NotFoundException {
  constructor() {
    super('Invite code not found');
  }
}

export class CollectionItemNotFoundException extends NotFoundException {
  constructor() {
    super('Title not in this collection');
  }
}
