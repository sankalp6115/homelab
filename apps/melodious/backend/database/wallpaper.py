from pathlib import Path
from sqlalchemy import select

from .database import get_session
from models.database import Wallpaper
from models.wallpaper import WallpaperResponse
from utils.path_resolver import get_wallpaper_dir

VALID_IMAGE_FORMATS = {".jpg", ".jpeg", ".png", ".webp"}


# ---------- Internal ----------

def _to_response(wallpaper: Wallpaper) -> WallpaperResponse:
    return WallpaperResponse(
        id=wallpaper.id,
        filename=wallpaper.filename,
        name=wallpaper.name or Path(wallpaper.filename).stem,
        url=f"/api/wallpaper/{wallpaper.filename}",
    )


# ---------- Queries ----------

def list_wallpapers() -> list[WallpaperResponse]:
    with get_session() as session:
        wallpapers = session.scalars(select(Wallpaper).order_by(Wallpaper.id)).all()
        return [_to_response(w) for w in wallpapers]


def get_wallpaper_by_id(wallpaper_id: int) -> WallpaperResponse | None:
    with get_session() as session:
        wallpaper = session.get(Wallpaper, wallpaper_id)
        return _to_response(wallpaper) if wallpaper else None


def get_wallpaper_by_filename(filename: str) -> WallpaperResponse | None:
    with get_session() as session:
        wallpaper = session.scalar(
            select(Wallpaper).where(Wallpaper.filename == filename)
        )
        return _to_response(wallpaper) if wallpaper else None


def create_wallpaper(filename: str, name: str | None = None) -> WallpaperResponse:
    with get_session() as session:
        existing = session.scalar(
            select(Wallpaper).where(Wallpaper.filename == filename)
        )
        if existing:
            if name and existing.name != name:
                existing.name = name
                session.commit()
            return _to_response(existing)

        display_name = name or Path(filename).stem
        wallpaper = Wallpaper(filename=filename, name=display_name)
        session.add(wallpaper)
        session.commit()
        session.refresh(wallpaper)
        return _to_response(wallpaper)


def delete_wallpaper(wallpaper_id: int) -> str | None:
    """Delete wallpaper from database. Returns filename for disk cleanup."""
    with get_session() as session:
        wallpaper = session.get(Wallpaper, wallpaper_id)
        if not wallpaper:
            return None
        filename = wallpaper.filename
        session.delete(wallpaper)
        session.commit()
        return filename


def sync_wallpapers_from_disk() -> int:
    """Scan the wallpaper directory and insert any untracked images into the database."""
    wallpaper_dir = get_wallpaper_dir()
    wallpaper_dir.mkdir(parents=True, exist_ok=True)

    disk_files = [
        item.name
        for item in wallpaper_dir.iterdir()
        if item.is_file() and item.suffix.lower() in VALID_IMAGE_FORMATS
    ]

    added = 0
    with get_session() as session:
        existing_filenames = set(
            session.scalars(select(Wallpaper.filename)).all()
        )
        for fname in disk_files:
            if fname not in existing_filenames:
                session.add(Wallpaper(filename=fname, name=Path(fname).stem))
                existing_filenames.add(fname)
                added += 1
        if added > 0:
            session.commit()

    return added

