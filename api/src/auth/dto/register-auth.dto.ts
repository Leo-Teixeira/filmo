import {
  IsEmail,
  IsString,
  Length,
  MaxLength,
  MinLength,
} from 'class-validator';
import { NormalizeEmail, Trim } from '../../common/transformers';

export class RegisterAuthDto {
  @NormalizeEmail()
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(9)
  @MaxLength(128)
  password: string;

  @Trim()
  @IsString()
  @Length(1, 50)
  displayName: string;
}
