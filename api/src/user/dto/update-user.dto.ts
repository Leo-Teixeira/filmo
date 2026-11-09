import { IsOptional, IsString, Length } from 'class-validator';
import { Trim } from '../../common/transformers';

// Email and password changes need a dedicated flow that re-checks the current password.
export class UpdateUserDto {
  @IsOptional()
  @Trim()
  @IsString()
  @Length(1, 50)
  displayName?: string;
}
