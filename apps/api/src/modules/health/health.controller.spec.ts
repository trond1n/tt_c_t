import { describe, expect, it } from 'vitest';
import { HealthController } from './health.controller';

describe('HealthController', () => {
  it('returns service heartbeat', () => {
    const controller = new HealthController();
    const response = controller.getHealth();

    expect(response.status).toBe('ok');
    expect(response.service).toBe('api');
  });
});
