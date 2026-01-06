import { render, screen, waitFor } from '@testing-library/react';
import Home from '../app/page';

describe('Home Page', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders the HR Portal title', () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      ok: false,
    });

    render(<Home />);

    expect(screen.getByText('HR Portal')).toBeInTheDocument();
  });

  it('shows loading state initially', () => {
    (global.fetch as jest.Mock).mockImplementation(
      () => new Promise(() => {}) // Never resolves
    );

    render(<Home />);

    expect(screen.getByText('Checking backend status...')).toBeInTheDocument();
  });

  it('displays backend status when healthy', async () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: async () => ({ status: 'healthy', version: '1.0.0' }),
    });

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText(/Backend Status: healthy/)).toBeInTheDocument();
    });

    expect(screen.getByText(/Version: 1.0.0/)).toBeInTheDocument();
  });

  it('displays error when backend is unavailable', async () => {
    (global.fetch as jest.Mock).mockResolvedValueOnce({
      ok: false,
    });

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText('Backend unavailable')).toBeInTheDocument();
    });
  });

  it('displays error when fetch fails', async () => {
    (global.fetch as jest.Mock).mockRejectedValueOnce(new Error('Network error'));

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText('Failed to connect to backend')).toBeInTheDocument();
    });
  });
});
