import { Transform } from 'class-transformer';
import { IsString, Matches } from 'class-validator';
import { INVITE_CODE_PATTERN } from '../invite-code';

export class JoinCollectionDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @IsString()
  @Matches(INVITE_CODE_PATTERN, { message: 'inviteCode is invalid' })
  inviteCode: string;
}
