import { IsEnum, IsInt, IsOptional, Max, Min } from 'class-validator';
import { WatchStatus } from '../../generated/prisma/enums';

// Body of PUT /library/:titleId. No userId and no titleId here on purpose:
// the user comes from the token, the title from the URL. The client can't smuggle another user's id.
export class UpsertLibraryEntryDto {
  // IsEnum on the Prisma const object: only WANT_TO_WATCH | WATCHING | COMPLETED | DROPPED pass.
  @IsEnum(WatchStatus)
  status: WatchStatus;

  // PUT = full replacement: omitting rating (or sending null) clears it. IsOptional lets null/undefined through.
  @IsOptional()
  // IsInt rejects 7.5 and "7": the global pipe has transform: true but no implicit conversion for bodies.
  @IsInt()
  @Min(1)
  @Max(10)
  rating?: number | null;
}
