from contextlib import contextmanager
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, Session
from dotenv import load_dotenv
from pathlib import Path
import os

from models.database import Base

# ---------- Config ----------
BACKEND_DIR = Path(__file__).resolve().parent.parent
ROOT_DIR    = BACKEND_DIR.parent


load_dotenv(BACKEND_DIR / ".env")

DB_PATH      = BACKEND_DIR / os.getenv("DB_NAME", "songs.db")
DATABASE_URL = f"sqlite:///{DB_PATH}"

# ---------- Engine ----------
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

# Enable foreign-key enforcement for every SQLite connection
@event.listens_for(engine, "connect")
def _set_sqlite_pragma(conn, _):
    conn.execute("PRAGMA foreign_keys = ON")

SessionLocal = sessionmaker(bind=engine)


# ---------- Helpers ----------
@contextmanager
def get_session():
    """Context-managed session — commits on success, rolls back on error."""
    session: Session = SessionLocal()
    try:
        yield session
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


def init_db():
    """Create all tables if they don't exist yet."""
    Base.metadata.create_all(engine)
