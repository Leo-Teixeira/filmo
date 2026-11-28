import { Body, Controller, Get, Post } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtPayload } from '../auth/jwt-auth.guard';
import { CollectionsService } from './collections.service';
import { CollectionNameDto } from './dto/collection-name.dto';
import { JoinCollectionDto } from './dto/join-collection.dto';

// Routes that act on one collection live in CollectionMemberController, behind the membership guard.
@Controller('collections')
export class CollectionsController {
  constructor(private readonly collectionsService: CollectionsService) {}

  @Get()
  listMine(@CurrentUser() user: JwtPayload) {
    return this.collectionsService.listMine(user.sub);
  }

  @Post()
  create(@CurrentUser() user: JwtPayload, @Body() dto: CollectionNameDto) {
    return this.collectionsService.create(user.sub, dto.name);
  }

  // Code in the body, not the URL, so it does not end up in access logs.
  @Post('join')
  join(@CurrentUser() user: JwtPayload, @Body() dto: JoinCollectionDto) {
    return this.collectionsService.join(user.sub, dto.inviteCode);
  }
}
