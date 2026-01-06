# HR Portal

Full-stack HR management application for managing employees, departments, leave requests, and attendance.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Next.js 16.1.1, React 19, TypeScript, Tailwind CSS v4 |
| Backend | FastAPI, SQLAlchemy 2.0, asyncpg, Pydantic v2 |
| Database | PostgreSQL (async) |
| State | Zustand, React Query |

## Quick Start

### 1. Start Backend

```bash
cd backend
source venv/bin/activate
uvicorn main:app --reload --port 8000
```

- API: http://localhost:8000
- Swagger UI: http://localhost:8000/api/v1/docs
- ReDoc: http://localhost:8000/api/v1/redoc

### 2. Start Frontend

```bash
cd frontend
npm run dev
```

- App: http://localhost:3000

## Project Structure

```
dev_agent/
├── frontend/                  # Next.js application
│   ├── src/
│   │   ├── app/              # App router pages
│   │   ├── components/       # React components (layout, common)
│   │   ├── hooks/            # Custom hooks (useDebounce)
│   │   ├── services/         # API client (Axios)
│   │   ├── stores/           # Zustand stores (auth)
│   │   ├── types/            # TypeScript interfaces
│   │   └── utils/            # Utility functions
│   └── package.json
│
├── backend/                   # FastAPI application
│   ├── main.py               # App entry point
│   ├── config.py             # Pydantic settings
│   ├── dependencies.py       # DI container
│   ├── database/             # SQLAlchemy connection
│   ├── common/               # Exceptions, constants, logger
│   ├── tests/                # Pytest tests
│   ├── venv/                 # Python virtual environment
│   └── requirements.txt
│
└── README.md
```

## Backend Commands

```bash
cd backend
source venv/bin/activate

# Development server
uvicorn main:app --reload

# Format code
black . && isort .

# Lint
flake8 . --max-line-length=88 --exclude=venv

# Run tests
pytest tests/ -v

# Install new dependencies
pip install <package> && pip freeze > requirements.txt
```

## Frontend Commands

```bash
cd frontend

# Development server
npm run dev

# Production build
npm run build

# Start production server
npm run start

# Lint
npm run lint
npm run lint:fix

# Format
npm run format
npm run format:check

# Type check
npm run type-check
```

## Environment Setup

### Backend

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env`:

```env
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/hr_portal
SECRET_KEY=your-secret-key-change-in-production
DEBUG=false
LOG_LEVEL=INFO
```

### Frontend

Create `frontend/.env.local`:

```env
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Welcome message |
| GET | `/health` | Health check |
| GET | `/api/v1/docs` | Swagger UI |
| GET | `/api/v1/redoc` | ReDoc |

## Dependencies

### Backend (requirements.txt)

- fastapi >= 0.128.0
- uvicorn[standard] >= 0.40.0
- sqlalchemy >= 2.0.45
- asyncpg >= 0.31.0
- pydantic-settings >= 2.12.0
- bcrypt >= 5.0.0
- alembic >= 1.17.2
- pytest >= 9.0.2
- black >= 25.12.0
- isort >= 7.0.0
- flake8 >= 7.3.0

### Frontend (package.json)

- next: 16.1.1
- react: 19.2.3
- typescript: ^5
- tailwindcss: ^4
- zustand: ^5.0.9
- @tanstack/react-query: ^5.90.16
- axios: ^1.13.2
- react-hook-form: ^7.70.0
- zod: ^4.3.5
- lucide-react: ^0.562.0
