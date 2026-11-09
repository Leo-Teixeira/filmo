import { IsEmail, IsNotEmpty, IsString, MaxLength } from 'class-validator';

// No MinLength here: password policy belongs to registration, not login.
export class LoginAuthDto {
  @IsEmail()
  email: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(128)
  password: string;
}
