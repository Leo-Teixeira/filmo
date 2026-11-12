import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { SearchTitlesDto } from './dto/search-titles.dto';
import { TitlesService } from './titles.service';

// No @Public(): logged-in users only, so the TMDB quota isn't open to the world.
@Controller('titles')
export class TitlesController {
  constructor(private readonly titlesService: TitlesService) {}

  // Query param instead of /titles/search: no collision with /titles/:id.
  @Get()
  search(@Query() { q }: SearchTitlesDto) {
    return this.titlesService.search(q);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.titlesService.findOne(id);
  }
}
