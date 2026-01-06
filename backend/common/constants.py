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
