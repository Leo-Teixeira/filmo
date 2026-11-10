import { Injectable, NotFoundException } from '@nestjs/common';
import { WatchStatus } from '../generated/prisma/enums';
import { isPrismaError, PrismaErrorCode } from '../prisma/prisma-errors';
import { PrismaService } from '../prisma/prisma.service';
import { TitleNotFoundException } from '../titles/titles.service';
import { UpsertLibraryEntryDto } from './dto/upsert-library-entry.dto';

// Shape of every entry we send back: the title embedded (the app needs name + poster),
// and userId omitted (the client already knows who it is; no need to echo internal ids).
const entryShape = {
  include: { title: true },
  omit: { userId: true },
} as const;

// ANTI-IDOR RULE for this whole file: every query filters on userId, and userId always comes
// from the JWT (controller → @CurrentUser). There is no method that takes a "target user".
@Injectable()
export class LibraryService {
  constructor(private readonly prisma: PrismaService) {}

  list(userId: string, status?: WatchStatus) {
    return this.prisma.userTitle.findMany({
      // status undefined → Prisma ignores the filter, so one query covers "all" and "by status".
      where: { userId, status },
      ...entryShape,
      // Most recently touched first: what you're watching now is at the top.
      orderBy: { updatedAt: 'desc' },
    });
  }

  async findOne(userId: string, titleId: string) {
    const entry = await this.prisma.userTitle.findUnique({
      // Composite primary key @@id([userId, titleId]) → Prisma names it userId_titleId.
      where: { userId_titleId: { userId, titleId } },
      ...entryShape,
    });
    // 404 here means "this title is not in YOUR library" (it may exist in someone else's: we don't say).
    if (!entry) throw new LibraryEntryNotFoundException();
    return entry;
  }

  // PUT semantics: creates the entry or replaces it. Idempotent: sending the same body twice = same result.
  async upsert(userId: string, titleId: string, dto: UpsertLibraryEntryDto) {
    const completed = dto.status === WatchStatus.COMPLETED;
    // undefined → null: with PUT, an absent rating means "no rating", not "keep the old one".
    const rating = dto.rating ?? null;
    const key = { userId_titleId: { userId, titleId } };

    try {
      // Interactive transaction: the steps below see the same data and succeed or fail together.
      return await this.prisma.$transaction(async (tx) => {
        // No include/select here ON PURPOSE: Prisma only uses a native "INSERT ... ON CONFLICT" upsert
        // when the query has no nested read. With an include it falls back to SELECT then INSERT,
        // and two simultaneous first PUTs (double tap) would crash with P2002 → 500.
        const entry = await tx.userTitle.upsert({
          where: key,
          create: {
            userId,
            titleId,
            status: dto.status,
            rating,
            watchedAt: completed ? new Date() : null,
          },
          update: {
            status: dto.status,
            rating,
            // Leaving COMPLETED (rewatch, dropped...) clears the date. Staying COMPLETED: field untouched.
            ...(completed ? {} : { watchedAt: null }),
          },
        });

        // Entry just switched to COMPLETED: stamp the date once. Re-saving a COMPLETED entry
        // (e.g. to change the rating) keeps the original date instead of resetting it.
        if (completed && !entry.watchedAt) {
          await tx.userTitle.update({
            where: key,
            data: { watchedAt: new Date() },
          });
        }
        // Read back with the response shape, in the same transaction (sees our own writes).
        return tx.userTitle.findUniqueOrThrow({ where: key, ...entryShape });
      });
    } catch (e) {
      // P2003 = foreign key violation: titleId doesn't exist in Title. Without this, the client gets a 500.
      // (The userId FK could also trigger it if the account was deleted mid-request: rare, and 404 stays honest.)
      if (isPrismaError(e, PrismaErrorCode.ForeignKeyViolation)) {
        throw new TitleNotFoundException();
      }
      throw e;
    }
  }

  async remove(userId: string, titleId: string): Promise<void> {
    try {
      // delete on the composite key: impossible to delete another user's row, the key includes userId.
      await this.prisma.userTitle.delete({
        where: { userId_titleId: { userId, titleId } },
      });
    } catch (e) {
      // P2025 = nothing to delete → 404 instead of 500.
      if (isPrismaError(e, PrismaErrorCode.RecordNotFound)) {
        throw new LibraryEntryNotFoundException();
      }
      throw e;
    }
  }
}

export class LibraryEntryNotFoundException extends NotFoundException {
  constructor() {
    super('Library entry not found');
  }
}
