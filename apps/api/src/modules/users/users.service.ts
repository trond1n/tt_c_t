import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { UserRow } from '../../database/user-row.type';
import { CreateUserDto, UpdateUserNameDto } from './users.dto';

@Injectable()
export class UsersService {
  constructor(private readonly dataSource: DataSource) {}

  list(): Promise<UserRow[]> {
    return this.dataSource.query<UserRow[]>('SELECT * FROM v_users ORDER BY created_at DESC');
  }

  async create(payload: CreateUserDto): Promise<UserRow> {
    const [user] = await this.dataSource.query<UserRow[]>(
      'SELECT * FROM fn_create_user($1, $2)',
      [payload.email, payload.name]
    );

    return user;
  }

  async updateName(id: string, payload: UpdateUserNameDto): Promise<UserRow | null> {
    const [user] = await this.dataSource.query<UserRow[]>(
      'SELECT * FROM fn_update_user_name($1::uuid, $2)',
      [id, payload.name]
    );

    return user ?? null;
  }
}
