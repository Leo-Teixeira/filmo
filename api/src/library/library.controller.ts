import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Put,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtPayload } from '../auth/jwt-auth.guard';
import { ListLibraryDto } from './dto/list-library.dto';
import { UpsertLibraryEntryDto } from './dto/upsert-library-entry.dto';
import { LibraryService } from './library.service';

// No user id in the URL: nothing to tamper with.
@Controller('library')
export class LibraryController {
  constructor(private readonly libraryService: LibraryService) {}

  @Get()
  list(@CurrentUser() user: JwtPayload, @Query() { status }: ListLibraryDto) {
    return this.libraryService.list(user.sub, status);
  }

  @Get(':titleId')
  findOne(
    @CurrentUser() user: JwtPayload,
    @Param('titleId', ParseUUIDPipe) titleId: string,
  ) {
    return this.libraryService.findOne(user.sub, titleId);
  }

  @Put(':titleId')
  upsert(
    @CurrentUser() user: JwtPayload,
    @Param('titleId', ParseUUIDPipe) titleId: string,
    @Body() dto: UpsertLibraryEntryDto,
  ) {
    return this.libraryService.upsert(user.sub, titleId, dto);
  }

  @Delete(':titleId')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @CurrentUser() user: JwtPayload,
    @Param('titleId', ParseUUIDPipe) titleId: string,
  ) {
    return this.libraryService.remove(user.sub, titleId);
  }
}
