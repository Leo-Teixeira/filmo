import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtPayload } from '../auth/jwt-auth.guard';
import { UpdateUserDto } from './dto/update-user.dto';
import { UserService } from './user.service';

// The user id always comes from the verified token, never from the client.
@Controller('me')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get()
  findMe(@CurrentUser() user: JwtPayload) {
    return this.userService.findMe(user.sub);
  }

  @Patch()
  updateMe(@CurrentUser() user: JwtPayload, @Body() dto: UpdateUserDto) {
    return this.userService.updateMe(user.sub, dto);
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  removeMe(@CurrentUser() user: JwtPayload) {
    return this.userService.removeMe(user.sub);
  }
}
