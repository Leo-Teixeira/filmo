import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtPayload } from '../auth/jwt-auth.guard';
import { CollectionMemberGuard, OwnerOnly } from './collection-member.guard';
import { CollectionsService } from './collections.service';
import { CollectionNameDto } from './dto/collection-name.dto';
import { TitleCollectionDto } from './dto/title-collection-dto';

@Controller('collections/:id')
@UseGuards(CollectionMemberGuard)
export class CollectionMemberController {
  constructor(private readonly collectionsService: CollectionsService) {}

  @Get()
  findOne(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.collectionsService.findOne(id, user.sub);
  }

  @Patch()
  @OwnerOnly()
  rename(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CollectionNameDto,
  ) {
    return this.collectionsService.rename(id, user.sub, dto.name);
  }

  @Delete()
  @OwnerOnly()
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.collectionsService.remove(id, user.sub);
  }

  @Get('members')
  listMembers(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.collectionsService.listMembers(id, user.sub);
  }

  @Post('leave')
  @HttpCode(HttpStatus.NO_CONTENT)
  leave(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.collectionsService.leave(id, user.sub);
  }

  @Post('items')
  addItem(
    @CurrentUser() user: JwtPayload,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: TitleCollectionDto,
  ) {
    return this.collectionsService.addItem(id, user.sub, dto.titleId);
  }

  @Delete('items/:titleId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeItem(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('titleId', ParseUUIDPipe) titleId: string,
  ) {
    return this.collectionsService.removeItem(id, titleId);
  }
}
