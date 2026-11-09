import {
  IsEmail,
  IsString,
  Length,
  MaxLength,
  MinLength,
} from 'class-validator';

export class RegisterAuthDto {
  @IsEmail()
  email: string;
  @IsString()
  @MinLength(9)
  @MaxLength(128)
  password: string;
  @IsString()
  @Length(1, 50)
  displayName: string;
}
