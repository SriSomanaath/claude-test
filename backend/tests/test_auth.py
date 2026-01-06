"""Tests for authentication endpoints."""

import pytest
from httpx import AsyncClient

from auth.auth_service import hash_password, create_access_token


class TestRegister:
    """Tests for user registration."""

    @pytest.mark.asyncio
    async def test_register_success(self, client: AsyncClient) -> None:
        """Test successful user registration."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "test@example.com",
                "password": "password123",
                "name": "Test User",
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "test@example.com"
        assert data["name"] == "Test User"
        assert data["is_active"] is True
        assert "id" in data
        assert "password" not in data
        assert "password_hash" not in data

    @pytest.mark.asyncio
    async def test_register_duplicate_email(self, client: AsyncClient) -> None:
        """Test registration with existing email fails."""
        user_data = {
            "email": "duplicate@example.com",
            "password": "password123",
            "name": "First User",
        }

        # Register first user
        response = await client.post("/api/v1/auth/register", json=user_data)
        assert response.status_code == 201

        # Try to register with same email
        user_data["name"] = "Second User"
        response = await client.post("/api/v1/auth/register", json=user_data)
        assert response.status_code == 400
        assert "already registered" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_register_invalid_email(self, client: AsyncClient) -> None:
        """Test registration with invalid email fails."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "not-an-email",
                "password": "password123",
                "name": "Test User",
            },
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_register_short_password(self, client: AsyncClient) -> None:
        """Test registration with short password fails."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "test@example.com",
                "password": "short",
                "name": "Test User",
            },
        )

        assert response.status_code == 422


class TestLogin:
    """Tests for user login."""

    @pytest.mark.asyncio
    async def test_login_success(self, client: AsyncClient) -> None:
        """Test successful login."""
        # Register user first
        await client.post(
            "/api/v1/auth/register",
            json={
                "email": "login@example.com",
                "password": "password123",
                "name": "Login User",
            },
        )

        # Login
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "login@example.com",
                "password": "password123",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"

    @pytest.mark.asyncio
    async def test_login_wrong_password(self, client: AsyncClient) -> None:
        """Test login with wrong password fails."""
        # Register user first
        await client.post(
            "/api/v1/auth/register",
            json={
                "email": "wrongpass@example.com",
                "password": "password123",
                "name": "Test User",
            },
        )

        # Try login with wrong password
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "wrongpass@example.com",
                "password": "wrongpassword",
            },
        )

        assert response.status_code == 401
        assert "Invalid email or password" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_login_nonexistent_user(self, client: AsyncClient) -> None:
        """Test login with non-existent user fails."""
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "nonexistent@example.com",
                "password": "password123",
            },
        )

        assert response.status_code == 401
        assert "Invalid email or password" in response.json()["detail"]


class TestProtectedRoutes:
    """Tests for protected routes."""

    @pytest.mark.asyncio
    async def test_get_me_success(self, client: AsyncClient) -> None:
        """Test getting current user info with valid token."""
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "email": "me@example.com",
                "password": "password123",
                "name": "Me User",
            },
        )

        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "me@example.com",
                "password": "password123",
            },
        )
        token = login_response.json()["access_token"]

        # Get current user
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "me@example.com"
        assert data["name"] == "Me User"

    @pytest.mark.asyncio
    async def test_get_me_no_token(self, client: AsyncClient) -> None:
        """Test getting current user without token fails."""
        response = await client.get("/api/v1/auth/me")

        # 401 Unauthorized when no token provided (403 is HTTPBearer default)
        assert response.status_code in (401, 403)

    @pytest.mark.asyncio
    async def test_get_me_invalid_token(self, client: AsyncClient) -> None:
        """Test getting current user with invalid token fails."""
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "Bearer invalid-token"},
        )

        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_refresh_token(self, client: AsyncClient) -> None:
        """Test refreshing access token."""
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "email": "refresh@example.com",
                "password": "password123",
                "name": "Refresh User",
            },
        )

        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "refresh@example.com",
                "password": "password123",
            },
        )
        token = login_response.json()["access_token"]

        # Refresh token
        response = await client.post(
            "/api/v1/auth/refresh",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        # Verify the new token is valid (can decode it)
        assert len(data["access_token"].split(".")) == 3


class TestPasswordHashing:
    """Tests for password hashing utilities."""

    def test_hash_password(self) -> None:
        """Test password hashing produces hash."""
        password = "mysecretpassword"
        hashed = hash_password(password)

        assert hashed != password
        assert len(hashed) > 0
        assert hashed.startswith("$2b$")  # bcrypt prefix

    def test_hash_password_different_each_time(self) -> None:
        """Test same password produces different hashes."""
        password = "mysecretpassword"
        hash1 = hash_password(password)
        hash2 = hash_password(password)

        assert hash1 != hash2  # Salts should be different


class TestTokenCreation:
    """Tests for token creation utilities."""

    def test_create_access_token(self) -> None:
        """Test access token creation."""
        token = create_access_token(user_id=123)

        assert len(token) > 0
        assert isinstance(token, str)
        # JWT has 3 parts separated by dots
        assert len(token.split(".")) == 3
