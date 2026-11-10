import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { SearchTitlesDto } from './dto/search-titles.dto';
import { TitlesService } from './titles.service';

// No @Public(): the global JwtAuthGuard protects both routes. Logged-in users only, so TMDB quota isn't open to the world.
@Controller('titles')
export class TitlesController {
  constructor(private readonly titlesService: TitlesService) {}

  // GET /titles?q=dune — query params instead of /titles/search so no route can collide with /titles/:id.
  @Get()
  search(@Query() { q }: SearchTitlesDto) {
    return this.titlesService.search(q);
  }

  // ParseUUIDPipe: "abc" gets a clear 400 instead of a DB lookup ending in a misleading 404.
  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.titlesService.findOne(id);
  }
}
