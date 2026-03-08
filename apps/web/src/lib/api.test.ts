import { describe, expect, it } from 'vitest';
import { z } from 'zod';

const HealthResponseSchema = z.object({
  status: z.literal('ok'),
  service: z.literal('api'),
  timestamp: z.string()
});

describe('HealthResponseSchema', () => {
  it('validates expected payload', () => {
    const parsed = HealthResponseSchema.parse({
      status: 'ok',
      service: 'api',
      timestamp: new Date().toISOString()
    });

    expect(parsed.status).toBe('ok');
  });
});
