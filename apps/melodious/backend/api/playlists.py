import os
import random
import shutil
from pathlib import Path
from fastapi import APIRouter, HTTPException, UploadFile, File, Form

import database.playlists as db
from models.playlists import (
    PlaylistResponse, PlaylistDetailResponse,
    CreatePlaylistResponse, SongInPlaylistResponse,
)
from models.songs import DeleteResponse
from utils.path_resolver import get_assets_dir
from .songs import sanitize_filename, _unique_path

router = APIRouter()


def _fallback_poster() -> str:
    fallback_dir = get_assets_dir() / "playlist-posters" / "fallback"
    files = [f for f in os.listdir(fallback_dir) if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp"))] if fallback_dir.exists() else []
    return f"playlist-posters/fallback/{random.choice(files)}" if files else "playlist-posters/fallback/playlist-poster1.jpeg"


@router.get("", response_model=list[PlaylistResponse])
def get_playlists():
    return db.list_playlists()


@router.get("/{playlist_id}", response_model=PlaylistDetailResponse)
def get_playlist(playlist_id: int):
    playlist = db.get_playlist(playlist_id)
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist not found")
    return playlist


@router.post("", response_model=CreatePlaylistResponse)
@router.post("/", response_model=CreatePlaylistResponse, include_in_schema=False)
async def create_playlist(name: str = Form(...), poster: UploadFile = File(None)):

    poster_dir = get_assets_dir() / "playlist-posters"
    poster_dir.mkdir(parents=True, exist_ok=True)

    if poster and poster.filename:
        target = _unique_path(poster_dir, sanitize_filename(poster.filename))
        try:
            with open(target, "wb") as buf:
                shutil.copyfileobj(poster.file, buf)
            poster_path_db = f"playlist-posters/{target.name}"
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to save poster: {e}")
    else:
        poster_path_db = _fallback_poster()

    return db.create_playlist(name, poster_path_db)


@router.delete("/{playlist_id}", response_model=DeleteResponse)
def delete_playlist(playlist_id: int):
    poster = db.delete_playlist(playlist_id)
    if poster is False:
        raise HTTPException(status_code=404, detail="Playlist not found")

    # Clean up non-default poster from disk
    if poster:
        is_default = Path(poster).name.startswith("playlist-poster") or Path(poster).name in ("images.jpeg", "default.jpg")
        if not is_default:
            poster_file = get_assets_dir() / poster
            if poster_file.is_file():
                try:
                    poster_file.unlink()
                except Exception as e:
                    print(f"Error deleting playlist poster: {e}")

    return DeleteResponse(status="success", message="Playlist deleted successfully")


@router.post("/{playlist_id}/songs", response_model=SongInPlaylistResponse)
def add_song_to_playlist(playlist_id: int, song_id: int = Form(...)):
    result = db.add_song_to_playlist(playlist_id, song_id)
    match result:
        case "playlist_not_found": raise HTTPException(status_code=404, detail="Playlist not found")
        case "song_not_found":     raise HTTPException(status_code=404, detail="Song not found")
        case "already_exists":     return SongInPlaylistResponse(status="already_exists", message="Song already in playlist")
        case "added":              return SongInPlaylistResponse(status="success", message="Song added to playlist")


@router.delete("/{playlist_id}/songs/{song_id}", response_model=SongInPlaylistResponse)
def remove_song_from_playlist(playlist_id: int, song_id: int):
    db.remove_song_from_playlist(playlist_id, song_id)
    return SongInPlaylistResponse(status="success", message="Song removed from playlist")