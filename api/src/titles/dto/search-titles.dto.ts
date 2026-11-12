import { IsString, Length } from 'class-validator';
import { Trim } from '../../common/transformers';

export class SearchTitlesDto {
  @Trim()
  @IsString()
  // Min 2: shorter queries are noise and waste TMDB quota.
  @Length(2, 100)
  q: string;
}
