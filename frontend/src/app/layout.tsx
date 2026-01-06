import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'HR Portal',
  description: 'Human Resources Management Portal',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
