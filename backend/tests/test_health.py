"""Tests for health check endpoint."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_check(client: AsyncClient) -> None:
    """Test health check endpoint returns healthy status."""
    response = await client.get("/health")

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "version" in data


@pytest.mark.asyncio
async def test_api_root(client: AsyncClient) -> None:
    """Test API root endpoint."""
    response = await client.get("/api/v1/")

    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "HR Portal API"
    assert "version" in data
    assert "docs" in data
