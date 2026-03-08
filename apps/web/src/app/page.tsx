import { HealthCard } from '../components/health-card';

export default function HomePage() {
  return (
    <main style={{ maxWidth: 900, margin: '40px auto', padding: '0 20px' }}>
      <h1>🚀 TT Modern Stack</h1>
      <p>Next.js 15 + NestJS + PostgreSQL + NX monorepo starter.</p>
      <HealthCard />
    </main>
  );
}
