import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { isUUID } from 'class-validator';
import type { AuthenticatedRequest } from '../auth/jwt-auth.guard';
import { CollectionRole } from '../generated/prisma/enums';
import { PrismaService } from '../prisma/prisma.service';
import { CollectionNotFoundException } from './collections.service';

const OWNER_ONLY_KEY = 'collectionOwnerOnly';
export const OwnerOnly = () => SetMetadata(OWNER_ONLY_KEY, true);

// Guards every /collections/:id route; runs after the global JwtAuthGuard.
@Injectable()
export class CollectionMemberGuard implements CanActivate {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const collectionId = request.params.id;
    if (typeof collectionId !== 'string' || !isUUID(collectionId)) {
      throw new CollectionNotFoundException();
    }

    const membership = await this.prisma.collectionMember.findUnique({
      where: {
        collectionId_userId: { collectionId, userId: request.user.sub },
      },
      select: { role: true },
    });
    // 404 rather than 403: a non-member must not learn that the collection exists.
    if (!membership) throw new CollectionNotFoundException();

    const ownerOnly = this.reflector.getAllAndOverride<boolean>(
      OWNER_ONLY_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (ownerOnly && membership.role !== CollectionRole.OWNER) {
      throw new ForbiddenException('Only the collection owner can do this');
    }
    return true;
  }
}
