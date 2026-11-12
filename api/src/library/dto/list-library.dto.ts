import { IsEnum, IsOptional } from 'class-validator';
import { WatchStatus } from '../../generated/prisma/enums';

export class ListLibraryDto {
  @IsOptional()
  @IsEnum(WatchStatus)
  status?: WatchStatus;
}
