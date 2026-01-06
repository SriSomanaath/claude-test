"""Common utilities module."""

from .exceptions import (
    AppError,
    ValidationError,
    NotFoundError,
    AuthenticationError,
    AuthorizationError,
    DatabaseError,
)
from .logger import logger, setup_logger

__all__ = [
    "AppError",
    "ValidationError",
    "NotFoundError",
    "AuthenticationError",
    "AuthorizationError",
    "DatabaseError",
    "logger",
    "setup_logger",
]
