import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon from 'argon2';
import { isPrismaError, PrismaErrorCode } from '../prisma/prisma-errors';
import { PrismaService } from '../prisma/prisma.service';
import { LoginAuthDto } from './dto/login-auth.dto';
import { RegisterAuthDto } from './dto/register-auth.dto';

export interface AuthTokens {
  accessToken: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterAuthDto): Promise<AuthTokens> {
    const passwordHash = await argon.hash(dto.password);
    try {
      const user = await this.prisma.user.create({
        data: {
          email: dto.email,
          passwordHash,
          displayName: dto.displayName,
        },
        select: { id: true },
      });
      return this.signToken(user.id);
    } catch (e) {
      if (isPrismaError(e, PrismaErrorCode.UniqueConstraintViolation)) {
        throw new ConflictException('Email already in use');
      }
      throw e;
    }
  }

  async login(dto: LoginAuthDto): Promise<AuthTokens> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      select: { id: true, passwordHash: true },
    });
    const isMatch =
      user !== null && (await argon.verify(user.passwordHash, dto.password));
    if (!user || !isMatch) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return this.signToken(user.id);
  }

  private async signToken(userId: string): Promise<AuthTokens> {
    return { accessToken: await this.jwt.signAsync({ sub: userId }) };
  }
}
