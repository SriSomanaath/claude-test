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

    _logger = logging.getLogger(name)
    _logger.setLevel(getattr(logging, log_level.upper()))

    if not _logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(getattr(logging, log_level.upper()))

        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        handler.setFormatter(formatter)
        _logger.addHandler(handler)

    return _logger


# Default application logger
logger = setup_logger("app")
