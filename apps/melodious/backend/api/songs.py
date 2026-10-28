import os
import re
import random
import shutil
import urllib.parse
import unicodedata
import mimetypes
from pathlib import Path
from fastapi import Request, APIRouter, HTTPException, UploadFile, File, Form
from fastapi.responses import StreamingResponse

import database.songs as db
from models.songs import SongResponse, UploadSongResponse, ToggleFavoriteResponse, DeleteResponse, SongCreate
from utils.path_resolver import get_songs_dir, get_assets_dir

router   = APIRouter()
SONGS_DIR = get_songs_dir()


# ---------- HELPERS (file I/O only — no DB) ----------

def sanitize_filename(filename: str) -> str:
    filename = urllib.parse.unquote(Path(filename).name)
    stem, suffix = Path(filename).stem, Path(filename).suffix.lower()
    stem = unicodedata.normalize("NFKD", stem).encode("ascii", "ignore").decode("ascii")
    stem = re.sub(r"[\s\-]+", "_", stem)
    stem = re.sub(r"[^a-zA-Z0-9._-]", "", stem)
    stem = re.sub(r"_+", "_", stem).strip("_.-") or "file"
    return f"{stem}{suffix}"


def _unique_path(directory: Path, filename: str) -> Path:
    target = directory / filename
    counter = 1
    while target.exists():
        stem, suffix = Path(filename).stem, Path(filename).suffix
        target = directory / f"{stem}_{counter}{suffix}"
        counter += 1
    return target


def _save_file(upload: UploadFile, directory: Path) -> Path:
    directory.mkdir(parents=True, exist_ok=True)
    target = _unique_path(directory, sanitize_filename(upload.filename))
    with open(target, "wb") as buf:
        shutil.copyfileobj(upload.file, buf)
    return target


def _fallback_art() -> str:
    fallback_dir = get_assets_dir() / "album-arts" / "fallback"
    files = [f for f in os.listdir(fallback_dir) if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp"))] if fallback_dir.exists() else []
    return f"assets/album-arts/fallback/{random.choice(files)}" if files else "assets/album-arts/fallback/song-icon4.png"


# ---------- ROUTES ----------

@router.get("", response_model=list[SongResponse])
def get_all_songs():
    return db.list_songs()


@router.get("/search/", response_model=list[SongResponse])
def search_songs(q: str):
    return db.search_songs(q)


@router.get("/stream/{filename:path}")
def stream_song(filename: str, request: Request):
    """Stream an audio file with HTTP range support."""
    file_path = SONGS_DIR / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail=f"File not found: {filename}")

    file_size    = os.path.getsize(file_path)
    range_header = request.headers.get("range")
    start, end   = 0, file_size - 1

    if range_header:
        parts = range_header.replace("bytes=", "").split("-")
        start = int(parts[0])
        if parts[1]:
            end = int(parts[1])

    chunk_size = end - start + 1

    def iter_file():
        with open(file_path, "rb") as f:
            f.seek(start)
            remaining = chunk_size
            while remaining > 0:
                chunk = f.read(min(1024 * 1024, remaining))
                if not chunk:
                    break
                remaining -= len(chunk)
                yield chunk

    content_type, _ = mimetypes.guess_type(file_path)
    headers = {
        "Content-Range":  f"bytes {start}-{end}/{file_size}",
        "Accept-Ranges":  "bytes",
        "Content-Length": str(chunk_size),
        "Content-Type":   content_type or "audio/mpeg",
    }
    return StreamingResponse(iter_file(), status_code=206, headers=headers)


@router.get("/{song_id}", response_model=SongResponse)
def get_song(song_id: int):
    song = db.get_song(song_id)
    if not song:
        raise HTTPException(status_code=404, detail="Song not found")
    return song


@router.post("/upload", response_model=UploadSongResponse)
async def upload_song(
    file:     UploadFile = File(...),
    art:      UploadFile = File(None),
    title:    str        = Form(...),
    artists:  str        = Form(...),
    album:    str        = Form(""),
    genre:    str        = Form(""),
    year:     int        = Form(None),
    duration: int        = Form(0),
):
    # 1. Save audio file
    try:
        audio_path = _save_file(file, get_songs_dir())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save audio file: {e}")

    # 2. Save cover art (or pick a fallback)
    album_art_db = None
    if art and art.filename:
        try:
            art_path     = _save_file(art, get_assets_dir() / "album-arts")
            album_art_db = f"assets/album-arts/{art_path.name}"
        except Exception as e:
            audio_path.unlink(missing_ok=True)
            raise HTTPException(status_code=500, detail=f"Failed to save cover art: {e}")
    else:
        album_art_db = _fallback_art()

    # 3. Persist to database
    data = SongCreate(
        title=title,
        album=album or None,
        genre=genre or None,
        year=year,
        duration=duration,
        file_path=audio_path.name,
        album_art=album_art_db,
        artist_names=[a.strip() for a in re.split(r"[,/;|]", artists) if a.strip()],
    )
    try:
        song = db.create_song(data)
    except Exception as e:
        audio_path.unlink(missing_ok=True)
        raise HTTPException(status_code=500, detail=f"Database insertion failed: {e}")

    return UploadSongResponse(status="success", song_id=song.id, file_path=song.file, album_art=song.albumArt)


@router.post("/{song_id}/favorite", response_model=ToggleFavoriteResponse)
def toggle_favorite(song_id: int):
    result = db.toggle_favorite(song_id)
    if not result:
        raise HTTPException(status_code=404, detail="Song not found")
    return result


@router.delete("/{song_id}", response_model=DeleteResponse)
def delete_song(song_id: int):
    paths = db.delete_song(song_id)
    if paths is None:
        raise HTTPException(status_code=404, detail="Song not found")

    file_path, album_art = paths

    if file_path:
        audio_file = get_songs_dir() / file_path
        if audio_file.is_file():
            try:
                audio_file.unlink()
            except Exception as e:
                print(f"Error deleting audio file: {e}")

    if album_art and "assets/album-arts/" in album_art:
        art_filename = album_art.split("assets/album-arts/")[-1]
        if art_filename and art_filename not in ("default.jpg", "song-icon5.png"):
            art_file = get_assets_dir() / "album-arts" / art_filename
            if art_file.is_file():
                try:
                    art_file.unlink()
                except Exception as e:
                    print(f"Error deleting album art: {e}")

    return DeleteResponse(status="success", message="Song deleted from library")