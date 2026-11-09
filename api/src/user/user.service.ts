import { Injectable } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { PrismaService } from 'src/prisma/prisma.service';
import * as argon from 'argon2';
import { argon2 } from 'crypto';

@Injectable()
export class UserService {
  constructor(private readonly prisma: PrismaService) {}

  create(createUserDto: CreateUserDto) {
    return 'This action adds a new user';
  }

  findAll = async () => {
    return await this.prisma.user.findMany();
  };

  findOne = async (id: string) => {
    return await this.prisma.user.findUnique({ where: { id: id } });
  };

  findByEmail = async (email: string) => {
    return await this.prisma.user.findUnique({ where: { email } });
  };

  update = async (id: string, updateUserDto: UpdateUserDto) => {
    return await this.prisma.user.update({
      data: {
        displayName: updateUserDto.displayName,
        email: updateUserDto.email,
        passwordHash: await argon.hash(updateUserDto.password),
      },
      where: { id: id },
    });
  };

  remove = async (id: string) => {
    return await this.prisma.user.delete({ where: { id } });
  };
}
