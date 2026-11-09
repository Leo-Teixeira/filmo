import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { UserService } from './user.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Controller('user')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get('me')
  findOne() {
    return this.userService.findOne();
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  findByEmail(@Body('email') email: string) {
    return this.userService.findByEmail(email);
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  update(@Body() updateUserDto: UpdateUserDto) {
    return this.userService.update(updateUserDto);
  }

  @Delete('me')
  remove() {
    return this.userService.remove();
  }
}
