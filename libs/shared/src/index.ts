import { z } from 'zod';

export const EnvironmentSchema = z.object({
  DATABASE_URL: z.string().url(),
  NEXT_PUBLIC_API_URL: z.string().url()
});

export type Environment = z.infer<typeof EnvironmentSchema>;
