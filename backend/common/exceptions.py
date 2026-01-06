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
