import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app

# Tests run against an in-memory SQLite DB, not real Aurora/Postgres — fast, no external
# dependency, and enough to prove the app's DB-facing logic works. This is a stand-in,
# not a substitute for testing against the real engine before anything ships.
#
# StaticPool is required here: SQLite's ":memory:" database is per-connection by
# default, so the default pool would hand create_all() one connection (and its tables)
# and a request a different connection (with a fresh, empty database) — StaticPool
# forces every checkout to reuse the same single connection.
engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture()
def client():
    Base.metadata.create_all(bind=engine)

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)
