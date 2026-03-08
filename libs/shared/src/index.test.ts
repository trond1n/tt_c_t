import { describe, expect, it } from 'vitest';
import { EnvironmentSchema } from './index';

describe('EnvironmentSchema', () => {
  it('parses required environment values', () => {
    const result = EnvironmentSchema.parse({
      DATABASE_URL: 'postgres://user:pass@localhost:5432/db',
      NEXT_PUBLIC_API_URL: 'http://localhost:3333'
    });

    expect(result.DATABASE_URL).toContain('postgres://');
  });
});
