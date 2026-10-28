from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from .database import get_session
from models.database import Artist, Song
from models.artists import ArtistResponse, ArtistDetailResponse
from models.songs import SongResponse


# ---------- Internal ----------

def _song_to_response(song: Song) -> SongResponse:
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


# ---------- Queries ----------

def list_artists() -> list[ArtistResponse]:
    with get_session() as session:
        artists = session.scalars(select(Artist).order_by(Artist.name)).all()
        return [ArtistResponse(id=a.id, name=a.name, image=a.image) for a in artists]


def get_artist(artist_id: int) -> ArtistDetailResponse | None:
    with get_session() as session:
        artist = session.scalar(
            select(Artist)
            .options(selectinload(Artist.songs).selectinload(Song.artists))
            .where(Artist.id == artist_id)
        )
        if not artist:
            return None
        return ArtistDetailResponse(
            id=artist.id,
            name=artist.name,
            image=artist.image,
            songs=[_song_to_response(s) for s in sorted(artist.songs, key=lambda s: s.title or "")],
        )


def get_artist_by_name(name: str) -> ArtistDetailResponse | None:
    with get_session() as session:
        artist = session.scalar(
            select(Artist).where(func.lower(Artist.name) == name.lower())
        )
        if not artist:
            return None
        return get_artist(artist.id)


def update_artist_image(artist_id: int, image_path: str) -> bool:
    """Set the artist's image path. Returns False if artist not found."""
    with get_session() as session:
        artist = session.get(Artist, artist_id)
        if not artist:
            return False
        artist.image = image_path
        session.commit()
        return True


def get_artist_name(artist_id: int) -> str | None:
    """Lightweight fetch — just the artist name."""
    with get_session() as session:
        artist = session.get(Artist, artist_id)
        return artist.name if artist else None
