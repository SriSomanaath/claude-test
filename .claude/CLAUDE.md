# Developer Agent

Full-stack development agent for HR Portal.

---

## Agents

| Agent | Purpose |
|-------|---------|
| `frontend` | Next.js/React/TypeScript setup and development |
| `backend` | FastAPI/Python setup and development |

## Commands

| Command | Purpose |
|---------|---------|
| `/component-test` | Full component validation (standards, optimization, browser compatibility, accessibility, security) |
| `/docker` | Build, start, stop Docker containers |
| `/update-docs` | Scan codebase and update README.md, frontend/DOCS.md, backend/DOCS.md |

## Output Style

| Style | Purpose |
|-------|---------|
| `/output-style test-report` | Structured test report with scores, issues, fixes |

## Skills (Reference)

| Skill | Purpose |
|-------|---------|
| `backend` | FastAPI/Python backend patterns |
| `frontend` | React/TypeScript frontend patterns |
| `database` | PostgreSQL/SQLAlchemy patterns |
| `devops` | Docker, CI/CD, deployment |

## Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| Auto-format | PostToolUse (Edit/Write) | Run `black` and `isort` on Python files |
| File Protection | PreToolUse (Edit/Write) | Block edits to `.env`, `alembic/versions`, `package-lock.json` |
| Command Log | PreToolUse (Bash) | Log all commands to `~/.claude/command-log.txt` |
| Notification | Notification | macOS desktop alert when Claude needs attention |

---

# Project Coding Standards

Standards and conventions for Python microservice development.

---

## Project Structure

### Microservice Module Structure

```
service_name/
├── main.py                    # FastAPI app entry point
├── config.py                  # Settings and configuration
├── dependencies.py            # Dependency injection
│
├── module_name/               # Feature module (e.g., users/, orders/, products/)
│   ├── __init__.py
│   ├── module_name_api.py     # API routes/endpoints
│   ├── module_name_service.py # Business logic
│   ├── module_name_models.py  # SQLAlchemy/ORM models
│   ├── module_name_schemas.py # Pydantic request/response schemas
│   ├── module_name_helper.py  # Module-specific helper functions
│   └── module_name_utils.py   # Module-specific utilities
│
├── database/                  # Database configuration
│   ├── __init__.py
│   ├── connection.py          # Database connection/session
│   ├── base.py                # SQLAlchemy Base model
│   └── migrations/            # Alembic migrations
│       ├── env.py
│       └── versions/
│
├── common/                    # Shared utilities across modules
│   ├── __init__.py
│   ├── exceptions.py          # Custom exceptions
│   ├── constants.py           # Application constants
│   ├── logger.py              # Logging configuration
│   └── utils.py               # Shared utility functions
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py            # Pytest fixtures
│   ├── test_module_name/
│   │   ├── test_api.py
│   │   ├── test_service.py
│   │   └── test_models.py
│   └── integration/
│
├── .env.example
├── .gitignore
├── pyproject.toml
├── requirements.txt
└── README.md
```

---

## File Naming Conventions

| File Type | Pattern | Example |
|-----------|---------|---------|
| API Routes | `{module}_api.py` | `users_api.py`, `orders_api.py` |
| Services | `{module}_service.py` | `users_service.py` |
| Models (DB) | `{module}_models.py` | `users_models.py` |
| Schemas (Pydantic) | `{module}_schemas.py` | `users_schemas.py` |
| Helpers | `{module}_helper.py` | `users_helper.py` |
| Utilities | `{module}_utils.py` | `users_utils.py` |
| Config | `config.py` | Single file at root |
| Database | `database/connection.py` | In database folder |

---

## File Responsibilities

### `*_api.py` - API Routes Only

```python
"""User API endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status

from .users_schemas import UserCreate, UserResponse, UserUpdate
from .users_service import UserService

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    service: UserService = Depends(),
) -> UserResponse:
    """
    Get user by ID.

    Args:
        user_id: The unique user identifier.
        service: Injected user service.

    Returns:
        User details.

    Raises:
        HTTPException: If user not found.
    """
    user = await service.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User {user_id} not found",
        )
    return user


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    service: UserService = Depends(),
) -> UserResponse:
    """Create a new user."""
    return await service.create(user_data)
```

### `*_service.py` - Business Logic

```python
"""User business logic."""
from typing import Optional, List

from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends

from database.connection import get_db
from .users_models import User
from .users_schemas import UserCreate, UserUpdate
from .users_helper import hash_password, verify_email_format


class UserService:
    """Service class for user operations."""

    def __init__(self, db: AsyncSession = Depends(get_db)) -> None:
        """
        Initialize user service.

        Args:
            db: Database session dependency.
        """
        self.db = db

    async def get_by_id(self, user_id: int) -> Optional[User]:
        """
        Get user by ID.

        Args:
            user_id: The user's unique identifier.

        Returns:
            User if found, None otherwise.
        """
        return await self.db.get(User, user_id)

    async def create(self, data: UserCreate) -> User:
        """
        Create a new user.

        Args:
            data: User creation data.

        Returns:
            Created user instance.

        Raises:
            ValidationError: If email format is invalid.
        """
        verify_email_format(data.email)
        
        user = User(
            email=data.email,
            password_hash=hash_password(data.password),
            name=data.name,
        )
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user
```

### `*_models.py` - Database Models Only

```python
"""User database models."""
from datetime import datetime
from typing import Optional

from sqlalchemy import String, Boolean, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column

from database.base import Base


class User(Base):
    """User database model."""

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    name: Mapped[str] = mapped_column(String(100))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
    updated_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        onupdate=func.now(),
    )

    def __repr__(self) -> str:
        """String representation."""
        return f"<User(id={self.id}, email={self.email})>"
```

### `*_schemas.py` - Pydantic Schemas Only

```python
"""User request/response schemas."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, ConfigDict


class UserBase(BaseModel):
    """Base user schema with common fields."""

    email: EmailStr
    name: str = Field(..., min_length=1, max_length=100)


class UserCreate(UserBase):
    """Schema for creating a user."""

    password: str = Field(..., min_length=8, max_length=128)


class UserUpdate(BaseModel):
    """Schema for updating a user."""

    email: Optional[EmailStr] = None
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    is_active: Optional[bool] = None


class UserResponse(UserBase):
    """Schema for user response."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
```

### `*_helper.py` - Module-Specific Helpers

```python
"""User module helper functions."""
import re
from typing import Optional

import bcrypt

from common.exceptions import ValidationError


def hash_password(password: str) -> str:
    """
    Hash a password using bcrypt.

    Args:
        password: Plain text password.

    Returns:
        Hashed password string.
    """
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode(), salt).decode()


def verify_password(plain: str, hashed: str) -> bool:
    """
    Verify a password against its hash.

    Args:
        plain: Plain text password.
        hashed: Hashed password to compare against.

    Returns:
        True if password matches, False otherwise.
    """
    return bcrypt.checkpw(plain.encode(), hashed.encode())


def verify_email_format(email: str) -> None:
    """
    Verify email format is valid.

    Args:
        email: Email address to validate.

    Raises:
        ValidationError: If email format is invalid.
    """
    pattern = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
    if not re.match(pattern, email):
        raise ValidationError(f"Invalid email format: {email}")
```

### `*_utils.py` - Module-Specific Utilities

```python
"""User module utilities."""
from typing import List, Dict, Any
from datetime import datetime


def format_user_for_export(user_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Format user data for export/reporting.

    Args:
        user_data: Raw user data dictionary.

    Returns:
        Formatted user data.
    """
    return {
        "id": user_data["id"],
        "email": user_data["email"],
        "name": user_data["name"],
        "status": "active" if user_data["is_active"] else "inactive",
        "member_since": user_data["created_at"].strftime("%Y-%m-%d"),
    }


def batch_user_ids(user_ids: List[int], batch_size: int = 100) -> List[List[int]]:
    """
    Split user IDs into batches.

    Args:
        user_ids: List of user IDs.
        batch_size: Maximum size per batch.

    Returns:
        List of batched user ID lists.
    """
    return [
        user_ids[i : i + batch_size]
        for i in range(0, len(user_ids), batch_size)
    ]
```

---

## Database Module Structure

### `database/connection.py`

```python
"""Database connection and session management."""
from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from config import get_settings

settings = get_settings()

engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Get database session dependency.

    Yields:
        AsyncSession: Database session.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
```

### `database/base.py`

```python
"""SQLAlchemy Base model."""
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Base class for all database models."""

    pass
```

---

## Common Module Structure

### `common/exceptions.py`

```python
"""Custom application exceptions."""


class AppError(Exception):
    """Base exception for the application."""

    def __init__(self, message: str = "An error occurred") -> None:
        self.message = message
        super().__init__(self.message)


class ValidationError(AppError):
    """Raised when validation fails."""

    pass


class NotFoundError(AppError):
    """Raised when a resource is not found."""

    def __init__(self, resource: str, identifier: str) -> None:
        self.resource = resource
        self.identifier = identifier
        super().__init__(f"{resource} with id '{identifier}' not found")


class AuthenticationError(AppError):
    """Raised when authentication fails."""

    pass


class AuthorizationError(AppError):
    """Raised when user lacks permission."""

    pass


class DatabaseError(AppError):
    """Raised when database operation fails."""

    pass


class ExternalServiceError(AppError):
    """Raised when external service call fails."""

    def __init__(self, service: str, message: str) -> None:
        self.service = service
        super().__init__(f"{service}: {message}")
```

### `common/constants.py`

```python
"""Application constants."""


class Defaults:
    """Default values for the application."""

    TIMEOUT: int = 30
    MAX_RETRIES: int = 3
    PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100


class Limits:
    """Application limits."""

    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    MAX_BATCH_SIZE: int = 1000
    RATE_LIMIT_PER_MINUTE: int = 60


class Status:
    """Status constants."""

    ACTIVE: str = "active"
    INACTIVE: str = "inactive"
    PENDING: str = "pending"
    DELETED: str = "deleted"
```

### `common/logger.py`

```python
"""Logging configuration."""
import logging
import sys
from typing import Optional

from config import get_settings


def setup_logger(
    name: Optional[str] = None,
    level: Optional[str] = None,
) -> logging.Logger:
    """
    Set up and return a configured logger.

    Args:
        name: Logger name. None for root logger.
        level: Log level. None uses settings.

    Returns:
        Configured logger instance.
    """
    settings = get_settings()
    log_level = level or settings.log_level

    logger = logging.getLogger(name)
    logger.setLevel(getattr(logging, log_level.upper()))

    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(getattr(logging, log_level.upper()))

        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)

    return logger


# Default application logger
logger = setup_logger("app")
```

---

## Configuration (config.py)

```python
"""Application configuration."""
from functools import lru_cache
from typing import Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Application
    app_name: str = "microservice"
    app_version: str = "1.0.0"
    debug: bool = False
    log_level: str = "INFO"

    # Database
    database_url: str
    db_pool_size: int = 5
    db_max_overflow: int = 10

    # API
    api_prefix: str = "/api/v1"
    api_key: Optional[str] = None
    api_timeout: int = 30

    # Security
    secret_key: str
    access_token_expire_minutes: int = 30

    # External Services
    redis_url: Optional[str] = None

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


@lru_cache
def get_settings() -> Settings:
    """
    Get cached application settings.

    Returns:
        Settings instance (singleton via lru_cache).
    """
    return Settings()
```

---

## Main Application (main.py)

```python
"""FastAPI application entry point."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import get_settings
from users.users_api import router as users_router
from orders.orders_api import router as orders_router

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    docs_url=f"{settings.api_prefix}/docs",
    redoc_url=f"{settings.api_prefix}/redoc",
    openapi_url=f"{settings.api_prefix}/openapi.json",
)

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(users_router, prefix=settings.api_prefix)
app.include_router(orders_router, prefix=settings.api_prefix)


@app.get("/health")
async def health_check() -> dict:
    """Health check endpoint."""
    return {"status": "healthy", "version": settings.app_version}
```

---

## Code Style Requirements

### Auto-formatters (MUST use)

```bash
black .                    # Line length: 88 chars
isort .                    # Import sorting
flake8 . --max-line-length=88
```

### Before every commit

```bash
black . && isort . && flake8 . --max-line-length=88
```

---

## Naming Conventions

```python
# Classes - PascalCase
class UserService:
class DatabaseConnection:

# Functions/Methods - snake_case
def process_data():
def _internal_method():  # Private with underscore prefix

# Constants - UPPER_SNAKE_CASE
DEFAULT_TIMEOUT = 30
MAX_RETRIES = 3

# Variables - snake_case
is_active: bool
user_count: int

# Files - snake_case with suffix
users_api.py
users_service.py
users_models.py
users_schemas.py
```

---

## Must Follow Rules

### 1. No Magic Strings/Numbers

```python
# Bad
if retries >= 5:
    raise Exception("Too many retries")

# Good
from common.constants import Defaults

if retries >= Defaults.MAX_RETRIES:
    raise MaxRetriesExceeded(f"Limit: {Defaults.MAX_RETRIES}")
```

### 2. Type Hints Required

```python
from typing import Optional, List

def process(
    data: str,
    timeout: Optional[int] = None,
) -> bool:
    """Process the input data."""
    pass
```

### 3. No Bare Except

```python
# Bad
try:
    return client.connect()
except:
    return None

# Good
try:
    return client.connect()
except ConnectionError as e:
    logger.error(f"Connection failed: {e}")
    return None
```

### 4. Docstrings Required

```python
def execute(command: str, timeout: Optional[int] = None) -> bool:
    """
    Execute the given command.

    Args:
        command: The command string to execute.
        timeout: Maximum time to wait (seconds).

    Returns:
        True if execution succeeded, False otherwise.

    Raises:
        ExecutionError: If command execution fails.
    """
    pass
```

### 5. Use Custom Exceptions

```python
# Import from common
from common.exceptions import ValidationError, NotFoundError

# Raise specific exceptions
raise ValidationError("Email format is invalid")
raise NotFoundError("User", user_id)
```

---

## Import Order

```python
# 1. Standard library
import os
from datetime import datetime
from typing import Optional, List

# 2. Third-party packages
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Mapped, mapped_column
from pydantic import BaseModel, Field

# 3. Local imports - absolute
from config import get_settings
from common.exceptions import ValidationError
from database.connection import get_db

# 4. Local imports - relative
from .users_models import User
from .users_schemas import UserCreate, UserResponse
```

---

## Security Rules

- Use `.env` for all secrets
- Never commit `.env` file
- Provide `.env.example` with placeholders
- Validate all user inputs via Pydantic
- Use parameterized queries (SQLAlchemy handles this)
- Set timeouts for external connections

---

## Git Commit Format

```text
<type>(<scope>): <subject>

Types:
  feat:     New feature
  fix:      Bug fix
  docs:     Documentation
  test:     Tests
  refactor: Code refactoring
  chore:    Maintenance

Examples:
  feat(users): add password reset endpoint
  fix(orders): handle null shipping address
  test(auth): add JWT validation tests
```

---

## Quality Checks

### Before pushing

```bash
# Format
black . && isort .

# Lint
flake8 . --max-line-length=88
markdownlint "**/*.md"

# Type check
mypy .

# Tests
pytest tests/ -v --cov=. --cov-report=term-missing
```

---

## Target Metrics

| Metric | Target |
|--------|--------|
| Flake8 Errors | 0 |
| Type Hints | Required on all public APIs |
| Docstrings | Required on all public APIs |
| Test Coverage | 80%+ |

---

## DO NOT

- ❌ Use `any` type without justification
- ❌ Use bare `except:`
- ❌ Leave `print()` statements - use logger
- ❌ Hardcode secrets
- ❌ Skip error handling
- ❌ Write functions longer than 30 lines
- ❌ Use magic numbers - define constants
- ❌ Mix concerns (API logic in service, DB in API, etc.)
- ❌ Skip type hints on public functions
- ❌ Commit without running formatters