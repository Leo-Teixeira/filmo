import { Injectable, NotFoundException } from '@nestjs/common';
import { CollectionRole } from '../generated/prisma/enums';
import { isPrismaError, PrismaErrorCode } from '../prisma/prisma-errors';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';

const publicUserFields = {
  id: true,
  email: true,
  displayName: true,
  createdAt: true,
} as const;

@Injectable()
export class UserService {
  constructor(private readonly prisma: PrismaService) {}

  async findMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: publicUserFields,
    });
    // Valid token but deleted account.
    if (!user) throw new UserNotFoundException();
    return user;
  }

  async updateMe(userId: string, dto: UpdateUserDto) {
    try {
      return await this.prisma.user.update({
        where: { id: userId },
        data: { displayName: dto.displayName },
        select: publicUserFields,
      });
    } catch (e) {
      throw this.mapNotFound(e);
    }
  }

  async removeMe(userId: string): Promise<void> {
    try {
      // No ownership transfer yet: an owner's collections go with the account instead of being left ownerless.
      await this.prisma.$transaction([
        this.prisma.collection.deleteMany({
          where: {
            members: { some: { userId, role: CollectionRole.OWNER } },
          },
        }),
        this.prisma.user.delete({ where: { id: userId } }),
      ]);
    } catch (e) {
      throw this.mapNotFound(e);
    }
  }

  private mapNotFound(error: unknown): unknown {
    return isPrismaError(error, PrismaErrorCode.RecordNotFound)
      ? new UserNotFoundException()
      : error;
  }
}

export class UserNotFoundException extends NotFoundException {
  constructor() {
    super('User not found');
  }
}
