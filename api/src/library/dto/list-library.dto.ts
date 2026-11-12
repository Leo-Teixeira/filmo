import { IsEnum, IsOptional } from 'class-validator';
import { WatchStatus } from '../../generated/prisma/enums';

// Query string of GET /library?status=WATCHING. Without status: the whole library.
export class ListLibraryDto {
  @IsOptional()
  @IsEnum(WatchStatus)
  status?: WatchStatus;
}
