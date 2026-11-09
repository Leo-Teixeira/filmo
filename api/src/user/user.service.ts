import { Injectable, NotFoundException } from '@nestjs/common';
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
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  updateMe(userId: string, dto: UpdateUserDto) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { displayName: dto.displayName },
      select: publicUserFields,
    });
  }

  async removeMe(userId: string): Promise<void> {
    await this.prisma.user.delete({ where: { id: userId } });
  }
}
