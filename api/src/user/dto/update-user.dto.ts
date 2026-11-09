import { PartialType } from '@nestjs/mapped-types';
import { CreateUserDto } from './create-user.dto';
import {
  IsEmail,
  IsOptional,
  IsString,
  Length,
  MaxLength,
  MinLength,
} from 'class-validator';

export class UpdateUserDto {
  @IsString()
  @Length(1, 50)
  @IsOptional()
  displayName: string;

  @IsEmail()
  @IsOptional()
  email: string;

  @IsString()
  @MinLength(9)
  @MaxLength(128)
  @IsOptional()
  password: string;
}
