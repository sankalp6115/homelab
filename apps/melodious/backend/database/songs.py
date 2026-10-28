from sqlalchemy import select, func, delete
from sqlalchemy.orm import selectinload
from pathlib import Path

from .database import get_session
from models.database import Song, Artist, song_artists
from models.songs import SongResponse, SongCreate, ToggleFavoriteResponse
from utils.path_resolver import get_assets_dir


# ---------- Internal ----------

def _to_response(song: Song) -> SongResponse:
    return SongResponse(
        id=song.id,
        title=song.title,
        album=song.album,
        genre=song.genre,
        year=song.year,
        duration=song.duration,
        file=song.file_path,
        albumArt=song.album_art,
        rating=song.rating,
        isFavorite=song.is_favorite,
        artists=[a.name for a in song.artists],
    )


def _find_artist_image(name: str) -> str | None:
    """Return a DB-relative image path if one already exists on disk for this artist."""
    artist_images_dir = get_assets_dir() / "artist-images"
    if not artist_images_dir.exists():
        return None
    for ext in (".jpg", ".jpeg", ".png", ".webp"):
        if (artist_images_dir / f"{name.lower()}{ext}").exists():
            return f"/artist-images/{name.lower()}{ext}"
    return None


# ---------- Queries ----------

def list_songs() -> list[SongResponse]:
    with get_session() as session:
        songs = session.scalars(
            select(Song).options(selectinload(Song.artists)).order_by(Song.title)
        ).all()
        return [_to_response(s) for s in songs]


def get_song(song_id: int) -> SongResponse | None:
    with get_session() as session:
        song = session.scalar(
            select(Song).options(selectinload(Song.artists)).where(Song.id == song_id)
        )
        return _to_response(song) if song else None


def search_songs(q: str) -> list[SongResponse]:
    pattern = f"%{q.lower()}%"
    with get_session() as session:
        matching_ids = session.scalars(
            select(Song.id)
            .outerjoin(Song.artists)
            .where(
                func.lower(Song.title).like(pattern)
                | func.lower(Song.album).like(pattern)
                | func.lower(Artist.name).like(pattern)
            )
            .distinct()
        ).all()

        if not matching_ids:
            return []

        songs = session.scalars(
            select(Song)
            .options(selectinload(Song.artists))
            .where(Song.id.in_(matching_ids))
            .order_by(Song.title)
        ).all()
        return [_to_response(s) for s in songs]


def create_song(data: SongCreate) -> SongResponse:
    """Insert a song, upsert its artists, and return the created song."""
    with get_session() as session:
        song = Song(
            title=data.title,
            album=data.album,
            genre=data.genre,
            year=data.year,
            duration=data.duration,
            file_path=data.file_path,
            album_art=data.album_art,
            rating=0,
        )
        session.add(song)
        session.flush()  # populate song.id

        for name in data.artist_names:
            artist = session.scalar(
                select(Artist).where(func.lower(Artist.name) == name.lower())
            )
            if not artist:
                artist = Artist(name=name, image=_find_artist_image(name))
                session.add(artist)
                session.flush()
            elif not artist.image:
                artist.image = _find_artist_image(name)

            if artist not in song.artists:
                song.artists.append(artist)

        session.commit()

        # Re-fetch with artists eager-loaded before session closes
        loaded = session.scalar(
            select(Song).options(selectinload(Song.artists)).where(Song.id == song.id)
        )
        return _to_response(loaded)


def toggle_favorite(song_id: int) -> ToggleFavoriteResponse | None:
    """Flip is_favorite. Returns None if song not found."""
    with get_session() as session:
        song = session.get(Song, song_id)
        if not song:
            return None
        song.is_favorite = not song.is_favorite
        session.commit()
        return ToggleFavoriteResponse(status="success", isFavorite=song.is_favorite)


def delete_song(song_id: int) -> tuple[str | None, str | None] | None:
    """
    Delete a song row. Returns (file_path, album_art) so the caller can
    clean up the files from disk. Returns None if the song does not exist.
    """
    with get_session() as session:
        song = session.get(Song, song_id)
        if not song:
            return None
        file_path = song.file_path
        album_art = song.album_art
        session.delete(song)
        session.commit()
        return file_path, album_art

