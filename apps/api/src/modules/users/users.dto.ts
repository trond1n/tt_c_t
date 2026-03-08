import { z } from 'zod';

export const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(2).max(100)
});

export const UpdateUserNameSchema = z.object({
  name: z.string().min(2).max(100)
});

export type CreateUserDto = z.infer<typeof CreateUserSchema>;
export type UpdateUserNameDto = z.infer<typeof UpdateUserNameSchema>;
