import { IsString, Length } from 'class-validator';
import { Trim } from '../../common/transformers';

// Query string of GET /titles?q=... — validated by the global ValidationPipe like a body DTO.
export class SearchTitlesDto {
  // Trim runs first anyway (class-transformer always runs before class-validator): "  a  " counts as 1 char.
  @Trim()
  @IsString()
  // Min 2: a 1-letter search returns noise and wastes TMDB quota. Max 100: no giant strings sent upstream.
  @Length(2, 100)
  q: string;
}
