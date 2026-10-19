import shutil
from pathlib import Path
from fastapi import APIRouter, HTTPException, UploadFile, File

import database.artists as db
from models.artists import ArtistResponse, ArtistDetailResponse, UpdateArtistImageResponse
from utils.path_resolver import get_assets_dir

router = APIRouter()


@router.get("", response_model=list[ArtistResponse])
def get_artists():
    return db.list_artists()


@router.get("/{artist_id}", response_model=ArtistDetailResponse)
def get_artist_by_id(artist_id: int):
    artist = db.get_artist(artist_id)
    if not artist:
        raise HTTPException(status_code=404, detail="Artist not found")
    return artist


@router.get("/name/{artist_name}", response_model=ArtistDetailResponse)
def get_artist_by_name(artist_name: str):
    artist = db.get_artist_by_name(artist_name)
    if not artist:
        raise HTTPException(status_code=404, detail="Artist not found")
    return artist


@router.post("/{artist_id}/image", response_model=UpdateArtistImageResponse)
async def upload_artist_image(artist_id: int, file: UploadFile = File(...)):
    ext = Path(file.filename).suffix.lower()
    if ext not in (".jpg", ".jpeg", ".png", ".webp"):
        raise HTTPException(status_code=400, detail="Invalid format. Only JPG, PNG, and WEBP are supported.")

    artist_name = db.get_artist_name(artist_id)
    if not artist_name:
        raise HTTPException(status_code=404, detail="Artist not found")

    # Save image to disk
    artist_images_dir = get_assets_dir() / "artist-images"
    artist_images_dir.mkdir(parents=True, exist_ok=True)
    img_filename  = f"{artist_name.lower().replace(' ', '_')}{ext}"
    img_path      = artist_images_dir / img_filename
    image_db_path = f"/artist-images/{img_filename}"

    try:
        with open(img_path, "wb") as buf:
            shutil.copyfileobj(file.file, buf)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save image: {e}")

    # Persist to DB
    db.update_artist_image(artist_id, image_db_path)

    return UpdateArtistImageResponse(message="Artist image updated successfully", image=image_db_path)
