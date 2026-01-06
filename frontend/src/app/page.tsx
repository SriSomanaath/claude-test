'use client';

import { useEffect, useState } from 'react';

interface HealthStatus {
  status: string;
  version: string;
}

export default function Home() {
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const checkHealth = async () => {
      try {
        const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';
        const response = await fetch(`${apiUrl.replace('/api/v1', '')}/health`);
        if (response.ok) {
          const data = await response.json();
          setHealth(data);
        } else {
          setError('Backend unavailable');
        }
      } catch (err) {
        setError('Failed to connect to backend');
      }
    };

    checkHealth();
  }, []);

  return (
    <main style={{
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'system-ui, sans-serif',
      backgroundColor: '#f5f5f5'
    }}>
      <h1 style={{ fontSize: '2.5rem', marginBottom: '1rem', color: '#333' }}>
        HR Portal
      </h1>
      <div style={{
        padding: '2rem',
        backgroundColor: 'white',
        borderRadius: '8px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
        textAlign: 'center'
      }}>
        {health ? (
          <>
            <p style={{ color: '#22c55e', fontSize: '1.2rem' }}>
              Backend Status: {health.status}
            </p>
            <p style={{ color: '#666' }}>
              Version: {health.version}
            </p>
          </>
        ) : error ? (
          <p style={{ color: '#ef4444' }}>{error}</p>
        ) : (
          <p style={{ color: '#666' }}>Checking backend status...</p>
        )}
      </div>
    </main>
  );
}
