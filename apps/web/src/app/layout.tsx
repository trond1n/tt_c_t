import type { Metadata } from 'next';
import { PropsWithChildren } from 'react';
import { AppQueryProvider } from '../providers/query-client-provider';

export const metadata: Metadata = {
  title: 'TT Stack Starter',
  description: 'NX monorepo with Next.js 15 + NestJS + PostgreSQL'
};

export default function RootLayout({ children }: PropsWithChildren) {
  return (
    <html lang="en">
      <body style={{ margin: 0, padding: 0, fontFamily: 'Inter, sans-serif' }}>
        <AppQueryProvider>{children}</AppQueryProvider>
      </body>
    </html>
  );
}
