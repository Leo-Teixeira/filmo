import { IsString, Length } from 'class-validator';
import { Trim } from '../../common/transformers';

export class CollectionNameDto {
  @Trim()
  @IsString()
  @Length(1, 80)
  name!: string;
}
