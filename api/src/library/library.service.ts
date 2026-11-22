import { Injectable, NotFoundException } from '@nestjs/common';
import { WatchStatus } from '../generated/prisma/enums';
import { isPrismaError, PrismaErrorCode } from '../prisma/prisma-errors';
import { PrismaService } from '../prisma/prisma.service';
import { TitleNotFoundException } from '../titles/titles.service';
import { UpsertLibraryEntryDto } from './dto/upsert-library-entry.dto';

const entryShape = {
  include: { title: true },
  // Never echo internal ids to the client.
  omit: { userId: true },
} as const;

// Every query filters on userId, which always comes from the JWT.
@Injectable()
export class LibraryService {
  constructor(private readonly prisma: PrismaService) {}

  list(userId: string, status?: WatchStatus) {
    return this.prisma.userTitle.findMany({
      // status undefined: Prisma ignores the filter.
      where: { userId, status },
      ...entryShape,
      orderBy: { updatedAt: 'desc' },
    });
  }

  async findOne(userId: string, titleId: string) {
    const entry = await this.prisma.userTitle.findUnique({
      where: { userId_titleId: { userId, titleId } },
      ...entryShape,
    });
    // 404 = not in YOUR library; never reveal whether it exists in someone else's.
    if (!entry) throw new LibraryEntryNotFoundException();
    return entry;
  }

  async upsert(userId: string, titleId: string, dto: UpsertLibraryEntryDto) {
    const completed = dto.status === WatchStatus.COMPLETED;
    // PUT: an absent rating means no rating, not keep the old one.
    const rating = dto.rating ?? null;
    const key = { userId_titleId: { userId, titleId } };

    try {
      return await this.prisma.$transaction(async (tx) => {
        // No include/select: keeps the native atomic upsert (two first PUTs would race into P2002).
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
            // Leaving COMPLETED clears the date; staying COMPLETED keeps it.
            ...(completed ? {} : { watchedAt: null }),
          },
        });

        // Stamp watchedAt once, when the entry switches to COMPLETED.
        if (completed && !entry.watchedAt) {
          await tx.userTitle.update({
            where: key,
            data: { watchedAt: new Date() },
          });
        }
        return tx.userTitle.findUniqueOrThrow({ where: key, ...entryShape });
      });
    } catch (e) {
      // P2003: unknown titleId (or account deleted mid-request) gives a 404, not a 500.
      if (isPrismaError(e, PrismaErrorCode.ForeignKeyViolation)) {
        throw new TitleNotFoundException();
      }
      throw e;
    }
  }

  async remove(userId: string, titleId: string): Promise<void> {
    try {
      await this.prisma.userTitle.delete({
        where: { userId_titleId: { userId, titleId } },
      });
    } catch (e) {
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
