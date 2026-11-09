import { IsOptional, IsString, Length } from 'class-validator';

// Email and password changes need a dedicated flow that re-checks the current password.
export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @Length(1, 50)
  displayName?: string;
}
