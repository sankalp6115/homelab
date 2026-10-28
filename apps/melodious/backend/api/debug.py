from fastapi import APIRouter
from sqlalchemy import select, inspect

from database.database import get_session, engine
from models.database import Song, Artist, Playlist, Lyrics, Wallpaper, song_artists, playlist_songs

router = APIRouter()


def _model_to_dicts(model) -> list[dict]:
    mapper = inspect(model)
    with get_session() as session:
        rows = session.scalars(select(model)).all()
        return [{col.key: getattr(row, col.key) for col in mapper.mapper.column_attrs} for row in rows]


@router.get("/songs")
def debug_songs():
    rows = _model_to_dicts(Song)
    return {"count": len(rows), "data": rows}


@router.get("/artists")
def debug_artists():
    rows = _model_to_dicts(Artist)
    return {"count": len(rows), "data": rows}


@router.get("/song-artists")
def debug_song_artists():
    with get_session() as session:
        rows = session.execute(select(song_artists)).all()
    data = [{"song_id": r.song_id, "artist_id": r.artist_id} for r in rows]
    return {"count": len(data), "data": data}


@router.get("/playlists")
def debug_playlists():
    rows = _model_to_dicts(Playlist)
    return {"count": len(rows), "data": rows}


@router.get("/playlist-songs")
def debug_playlist_songs():
    with get_session() as session:
        rows = session.execute(select(playlist_songs)).all()
    data = [{"playlist_id": r.playlist_id, "song_id": r.song_id, "position": r.position} for r in rows]
    return {"count": len(data), "data": data}


@router.get("/lyrics")
def debug_lyrics():
    rows = _model_to_dicts(Lyrics)
    return {"count": len(rows), "data": rows}


@router.get("/wallpapers")
def debug_wallpapers():
    rows = _model_to_dicts(Wallpaper)
    return {"count": len(rows), "data": rows}