'use client';

import { useQuery } from '@tanstack/react-query';
import { fetchHealth } from '../lib/api';

export function HealthCard() {
  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['health'],
    queryFn: fetchHealth
  });

  if (isLoading) return <p>Checking API health...</p>;
  if (isError) return <p>API error: {(error as Error).message}</p>;

  return (
    <div style={{ border: '1px solid #ddd', borderRadius: 12, padding: 16 }}>
      <h2>API health</h2>
      <p>Status: {data.status}</p>
      <p>Service: {data.service}</p>
      <p>Timestamp: {new Date(data.timestamp).toLocaleString()}</p>
    </div>
  );
}
