"""
Create tables from the current SQLAlchemy models, for LOCAL DEVELOPMENT ONLY.

Not a migration tool — it can't alter existing tables or track schema history, only
create what's missing on a fresh database. Real schema evolution belongs in a proper
migration tool (Alembic, or Flyway/Liquibase per the reference doc's approach), run as
a deploy-time step — never as application-startup code, which is untestable and can't
be gated/rolled back independently of the app itself.

Usage: python scripts/create_tables.py   (reads DB connection from the same env vars /
.env file as the app itself — see app/config.py)
"""

from app.database import Base, engine
from app.models import Appointment  # noqa: F401  (import registers the table with Base)

if __name__ == "__main__":
    Base.metadata.create_all(bind=engine)
    print("Tables created.")
