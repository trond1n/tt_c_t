import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { CreateUserSchema, UpdateUserNameSchema } from './users.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  getAll() {
    return this.usersService.list();
  }

  @Post()
  create(@Body() body: unknown) {
    const payload = CreateUserSchema.parse(body);
    return this.usersService.create(payload);
  }

  @Patch(':id/name')
  updateName(@Param('id') id: string, @Body() body: unknown) {
    const payload = UpdateUserNameSchema.parse(body);
    return this.usersService.updateName(id, payload);
  }

  @Get('schema')
  getSchema() {
    return {
      createUser: {
        email: 'string(email)',
        name: 'string(2..100)'
      },
      updateUserName: {
        name: 'string(2..100)'
      }
    };
  }
}
