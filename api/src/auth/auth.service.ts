import { Injectable, UnauthorizedException } from '@nestjs/common';
import { RegisterAuthDto } from './dto/register-auth.dto';
import { LoginAuthDto } from './dto/login-auth.dto';
import { PrismaService } from 'src/prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as argon from 'argon2';
import { PrismaClientKnownRequestError } from '@prisma/client/runtime/wasm-compiler-edge';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterAuthDto) {
    try {
      const hash = await argon.hash(dto.password);
      const user = await this.prisma.user.create({
        data: {
          email: dto.email,
          passwordHash: hash,
          displayName: dto.displayName,
        },
      });
      return this.signToken(user.id);
    } catch (e) {
      if (e instanceof PrismaClientKnownRequestError) {
        if (e.code === 'P2002') {
          throw new UnauthorizedException('User already exists');
        }
      }
      throw e;
    }
  }

  async login(dto: LoginAuthDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user) throw new UnauthorizedException('Invalid credentials');
    const isMatch = await argon.verify(user.passwordHash, dto.password);
    if (!isMatch) throw new UnauthorizedException('Invalid credentials');
    return this.signToken(user.id);
  }

  private async signToken(sub: string) {
    return { access_token: await this.jwt.signAsync({ sub }) };
  }
}
