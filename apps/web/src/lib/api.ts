import { z } from 'zod';

const HealthResponseSchema = z.object({
  status: z.literal('ok'),
  service: z.literal('api'),
  timestamp: z.string()
});

export type HealthResponse = z.infer<typeof HealthResponseSchema>;

export async function fetchHealth(): Promise<HealthResponse> {
  const apiBaseUrl = process.env.NEXT_PUBLIC_API_URL;

  if (!apiBaseUrl) {
    throw new Error('NEXT_PUBLIC_API_URL is not set');
  }

  const response = await fetch(`${apiBaseUrl}/api/health`, {
    cache: 'no-store'
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch API health: ${response.status}`);
  }

  const payload = await response.json();
  return HealthResponseSchema.parse(payload);
}
