import { IsUUID } from 'class-validator';

export class TitleCollectionDto {
  @IsUUID()
  titleId: string;
}
