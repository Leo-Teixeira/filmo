import { IsUUID } from 'class-validator';

export class CollectionItemDto {
  @IsUUID()
  titleId!: string;
}
