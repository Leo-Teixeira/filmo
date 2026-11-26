import { randomInt } from 'node:crypto';

// No 0/O/1/I: codes are shared by hand between friends.
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
export const INVITE_CODE_LENGTH = 10;
export const INVITE_CODE_PATTERN = new RegExp(
  `^[${ALPHABET}]{${INVITE_CODE_LENGTH}}$`,
);

export function generateInviteCode(): string {
  return Array.from(
    { length: INVITE_CODE_LENGTH },
    () => ALPHABET[randomInt(ALPHABET.length)],
  ).join('');
}
