import { IsString, Matches } from 'class-validator';
import { NormalizeInviteCode } from '../../common/transformers';
import { INVITE_CODE_PATTERN } from '../invite-code';

export class JoinCollectionDto {
  @NormalizeInviteCode()
  @IsString()
  @Matches(INVITE_CODE_PATTERN, { message: 'inviteCode is invalid' })
  inviteCode!: string;
}
