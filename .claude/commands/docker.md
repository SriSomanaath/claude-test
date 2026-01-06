Docker container management for HR Portal.

## Actions

### Build
```bash
docker-compose build
```

### Start (Development)
```bash
docker-compose up -d
```

### Start (Production)
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Stop
```bash
docker-compose down
```

### Logs
```bash
docker-compose logs -f [service_name]
```

### Rebuild Single Service
```bash
docker-compose up -d --build [service_name]
```

## Docker Compose Structure

Create `docker-compose.yml`:
```yaml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8000/api/v1
    depends_on:
      - backend

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql+asyncpg://postgres:postgres@db:5432/hr_portal
      - SECRET_KEY=${SECRET_KEY}
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=hr_portal
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## Dockerfiles

### Backend Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Frontend Dockerfile
```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

CMD ["npm", "start"]
```

## Quick Commands
- Build all: `docker-compose build`
- Start all: `docker-compose up -d`
- Stop all: `docker-compose down`
- View logs: `docker-compose logs -f`
- Shell into service: `docker-compose exec [service] sh`
