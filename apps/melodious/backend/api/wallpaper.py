import shutil
from pathlib import Path
from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse

import database.wallpaper as db
from models.wallpaper import WallpaperResponse, WallpaperUploadResponse
from models.songs import DeleteResponse
from utils.path_resolver import get_wallpaper_dir
from .songs import sanitize_filename, _unique_path

router = APIRouter()
VALID_IMAGE_FORMATS = {".jpg", ".jpeg", ".png", ".webp"}


@router.get("", response_model=list[WallpaperResponse])
def get_wallpapers():
    """List all available wallpapers from database."""
    return db.list_wallpapers()


@router.get("/{identifier}")
def get_wallpaper_file(identifier: str):
    """Serve a wallpaper image file by filename or by ID."""
    wallpaper_dir = get_wallpaper_dir()

    # Check if identifier is an integer ID
    target_filename = identifier
    if identifier.isdigit():
        wp = db.get_wallpaper_by_id(int(identifier))
        if wp:
            target_filename = wp.filename

    # Prevent directory traversal
    clean_name = Path(target_filename).name
    file_path = wallpaper_dir / clean_name

    if not file_path.is_file():
        raise HTTPException(status_code=404, detail="Wallpaper not found")

    return FileResponse(file_path)


@router.post("/upload", response_model=WallpaperUploadResponse)
async def upload_wallpaper(
    file: UploadFile = File(...),
    name: str = Form(None),
):
    """Upload a new wallpaper image and register it in the database."""
    wallpaper_dir = get_wallpaper_dir()
    wallpaper_dir.mkdir(parents=True, exist_ok=True)

    ext = Path(file.filename).suffix.lower()
    if ext not in VALID_IMAGE_FORMATS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid image format. Allowed formats: {', '.join(sorted(VALID_IMAGE_FORMATS))}",
        )

    clean_filename = sanitize_filename(Path(file.filename).name)
    target_path = _unique_path(wallpaper_dir, clean_filename)

    try:
        with open(target_path, "wb") as buf:
            shutil.copyfileobj(file.file, buf)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save wallpaper: {e}")

    try:
        saved_wp = db.create_wallpaper(
            filename=target_path.name,
            name=name.strip() if name and name.strip() else Path(clean_filename).stem,
        )
    except Exception as e:
        target_path.unlink(missing_ok=True)
        raise HTTPException(status_code=500, detail=f"Database error: {e}")

    return WallpaperUploadResponse(
        status="success",
        id=saved_wp.id,
        filename=saved_wp.filename,
        name=saved_wp.name,
        url=saved_wp.url,
    )


@router.delete("/{wallpaper_id}", response_model=DeleteResponse)
def delete_wallpaper(wallpaper_id: int):
    """Delete a wallpaper from database and disk."""
    filename = db.delete_wallpaper(wallpaper_id)
    if not filename:
        raise HTTPException(status_code=404, detail="Wallpaper not found")

    file_path = get_wallpaper_dir() / filename
    if file_path.is_file():
        try:
            file_path.unlink()
        except Exception as e:
            print(f"Error deleting wallpaper file {filename}: {e}")

    return DeleteResponse(status="success", message="Wallpaper deleted successfully")