import { IsEnum, IsInt, IsOptional, Max, Min } from 'class-validator';
import { WatchStatus } from '../../generated/prisma/enums';

// No userId or titleId: the user comes from the token, the title from the URL.
export class UpsertLibraryEntryDto {
  @IsEnum(WatchStatus)
  status: WatchStatus;

  @IsOptional()
  // Rejects "7" and 7.5: the global pipe has no implicit conversion.
  @IsInt()
  @Min(1)
  @Max(10)
  rating?: number | null;
}
