# Database - PostgreSQL/SQLAlchemy Patterns

Database setup, migrations, and query patterns.

---

## Project Structure

```
database/
├── __init__.py
├── connection.py          # Async engine and session
├── base.py                # Base model class
└── migrations/
    ├── env.py             # Alembic environment
    ├── script.py.mako     # Migration template
    ├── alembic.ini        # Alembic configuration
    └── versions/          # Migration files
```

---

## Connection Setup

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

## Base Model

```python
"""SQLAlchemy Base model."""
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Base class for all database models."""

    pass
```

---

## Model Pattern

```python
"""Example database model."""
from datetime import datetime
from typing import Optional

from sqlalchemy import String, Boolean, DateTime, Integer, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database.base import Base


class User(Base):
    """User database model."""

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
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

    # Relationships
    orders: Mapped[list["Order"]] = relationship(back_populates="user")

    def __repr__(self) -> str:
        return f"<User(id={self.id}, email={self.email})>"


class Order(Base):
    """Order database model."""

    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    total: Mapped[float] = mapped_column()
    status: Mapped[str] = mapped_column(String(50), default="pending")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="orders")
```

---

## Alembic Setup

### alembic.ini

```ini
[alembic]
script_location = database/migrations
prepend_sys_path = .
sqlalchemy.url = driver://user:pass@localhost/dbname

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
```

### env.py

```python
"""Alembic migration environment."""
import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from alembic import context

from config import get_settings
from database.base import Base

# Import all models for autogenerate
from users.users_models import User
from orders.orders_models import Order

config = context.config
settings = get_settings()

# Set database URL from settings
config.set_main_option("sqlalchemy.url", settings.database_url)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    """Run migrations with connection."""
    context.configure(connection=connection, target_metadata=target_metadata)

    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Run migrations in async mode."""
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

---

## Migration Commands

```bash
# Initialize alembic
alembic init database/migrations

# Create migration
alembic revision --autogenerate -m "add users table"

# Run migrations
alembic upgrade head

# Rollback one step
alembic downgrade -1

# Show current revision
alembic current

# Show migration history
alembic history
```

---

## Query Patterns

### Basic CRUD

```python
"""Database query patterns."""
from typing import Optional, List
from sqlalchemy import select, update, delete
from sqlalchemy.ext.asyncio import AsyncSession


async def get_by_id(db: AsyncSession, model, id: int):
    """Get single record by ID."""
    return await db.get(model, id)


async def get_all(
    db: AsyncSession,
    model,
    skip: int = 0,
    limit: int = 20,
):
    """Get paginated records."""
    query = select(model).offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


async def create(db: AsyncSession, model, **kwargs):
    """Create new record."""
    instance = model(**kwargs)
    db.add(instance)
    await db.commit()
    await db.refresh(instance)
    return instance


async def update_by_id(db: AsyncSession, model, id: int, **kwargs):
    """Update record by ID."""
    query = update(model).where(model.id == id).values(**kwargs)
    await db.execute(query)
    await db.commit()
    return await db.get(model, id)


async def delete_by_id(db: AsyncSession, model, id: int):
    """Delete record by ID."""
    query = delete(model).where(model.id == id)
    await db.execute(query)
    await db.commit()
```

### Filtering & Sorting

```python
"""Advanced query patterns."""
from sqlalchemy import select, desc, asc


async def get_filtered(
    db: AsyncSession,
    model,
    filters: dict,
    sort_by: str = "created_at",
    sort_desc: bool = True,
    skip: int = 0,
    limit: int = 20,
):
    """Get filtered and sorted records."""
    query = select(model)

    # Apply filters
    for key, value in filters.items():
        if hasattr(model, key) and value is not None:
            query = query.where(getattr(model, key) == value)

    # Apply sorting
    sort_column = getattr(model, sort_by, model.created_at)
    query = query.order_by(desc(sort_column) if sort_desc else asc(sort_column))

    # Apply pagination
    query = query.offset(skip).limit(limit)

    result = await db.execute(query)
    return result.scalars().all()
```

### Relationships

```python
"""Eager loading relationships."""
from sqlalchemy import select
from sqlalchemy.orm import selectinload, joinedload


async def get_user_with_orders(db: AsyncSession, user_id: int):
    """Get user with orders eagerly loaded."""
    query = (
        select(User)
        .where(User.id == user_id)
        .options(selectinload(User.orders))
    )
    result = await db.execute(query)
    return result.scalar_one_or_none()
```

---

## Environment Variables

```bash
# .env
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/dbname
DB_POOL_SIZE=5
DB_MAX_OVERFLOW=10
```

```bash
# .env.example
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/dbname
DB_POOL_SIZE=5
DB_MAX_OVERFLOW=10
```

---

## Configuration

```python
"""Database configuration in config.py."""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Database
    database_url: str
    db_pool_size: int = 5
    db_max_overflow: int = 10

    class Config:
        env_file = ".env"
```

---

## DO NOT

- Use raw SQL without parameterization
- Commit credentials to version control
- Skip connection pooling in production
- Use synchronous drivers with async code
- Forget to close sessions
- Skip migrations for schema changes
- Use `expire_on_commit=True` with async sessions
