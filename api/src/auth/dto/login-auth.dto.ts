import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';

export class LoginAuthDto {
  @IsEmail()
  email: string;
  @IsString()
  @MinLength(9)
  @MaxLength(128)
  password: string;
}
