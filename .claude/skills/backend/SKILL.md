# API Design - FastAPI/Python Patterns

REST API design patterns and conventions for Python microservices.

---

## Project Structure

```
service_name/
├── main.py                    # FastAPI app entry point
├── config.py                  # Settings and configuration
├── dependencies.py            # Dependency injection
│
├── module_name/               # Feature module (e.g., users/, orders/)
│   ├── __init__.py
│   ├── module_name_api.py     # API routes/endpoints
│   ├── module_name_service.py # Business logic
│   ├── module_name_models.py  # SQLAlchemy/ORM models
│   ├── module_name_schemas.py # Pydantic request/response schemas
│   ├── module_name_helper.py  # Module-specific helper functions
│   └── module_name_utils.py   # Module-specific utilities
│
├── database/
│   ├── connection.py          # Database connection/session
│   ├── base.py                # SQLAlchemy Base model
│   └── migrations/            # Alembic migrations
│
├── common/
│   ├── exceptions.py          # Custom exceptions
│   ├── constants.py           # Application constants
│   ├── logger.py              # Logging configuration
│   └── utils.py               # Shared utility functions
│
└── tests/
```

---

## File Naming Conventions

| File Type | Pattern | Example |
|-----------|---------|---------|
| API Routes | `{module}_api.py` | `users_api.py` |
| Services | `{module}_service.py` | `users_service.py` |
| Models (DB) | `{module}_models.py` | `users_models.py` |
| Schemas (Pydantic) | `{module}_schemas.py` | `users_schemas.py` |
| Helpers | `{module}_helper.py` | `users_helper.py` |
| Utilities | `{module}_utils.py` | `users_utils.py` |

---

## URL Structure

```
GET    /api/v1/users           # List
POST   /api/v1/users           # Create
GET    /api/v1/users/{id}      # Get one
PATCH  /api/v1/users/{id}      # Update
DELETE /api/v1/users/{id}      # Delete
GET    /api/v1/users/{id}/orders  # Nested resource
```

---

## HTTP Status Codes

| Code | Usage |
|------|-------|
| 200 | Success (GET, PUT, PATCH) |
| 201 | Created (POST) |
| 204 | No Content (DELETE) |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Validation Error |

---

## API Routes (`*_api.py`)

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

---

## Service Layer (`*_service.py`)

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

---

## Database Models (`*_models.py`)

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

---

## Pydantic Schemas (`*_schemas.py`)

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

---

## Helper Functions (`*_helper.py`)

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

---

## Database Connection

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

---

## Custom Exceptions

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
```

---

## Configuration

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

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


@lru_cache
def get_settings() -> Settings:
    """Get cached application settings."""
    return Settings()
```

---

## Pagination

```
GET /api/v1/users?page=1&size=20
```

Response includes meta:
```json
{
  "data": [...],
  "meta": {
    "page": 1,
    "size": 20,
    "total": 150,
    "pages": 8
  }
}
```

---

## Filtering & Sorting

```
GET /api/v1/users?status=active&sort=-created_at
```

---

## Constants

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

## DO NOT

- Use `any` type without justification
- Use bare `except:`
- Leave `print()` statements - use logger
- Hardcode secrets
- Skip error handling
- Write functions longer than 30 lines
- Use magic numbers - define constants
- Mix concerns (API logic in service, DB in API, etc.)
- Skip type hints on public functions
