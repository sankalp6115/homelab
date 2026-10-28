from sqlalchemy import select, func, delete
from sqlalchemy.orm import selectinload

from .database import get_session
from models.database import Playlist, Song, playlist_songs
from models.playlists import PlaylistResponse, PlaylistDetailResponse, CreatePlaylistResponse
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

def list_playlists() -> list[PlaylistResponse]:
    with get_session() as session:
        playlists = session.scalars(select(Playlist).order_by(Playlist.name)).all()
        return [PlaylistResponse(id=p.id, name=p.name, poster=p.poster) for p in playlists]


def get_playlist(playlist_id: int) -> PlaylistDetailResponse | None:
    with get_session() as session:
        playlist = session.get(Playlist, playlist_id)
        if not playlist:
            return None

        # Fetch songs in position order, with artists eager-loaded
        ordered = session.execute(
            select(Song, playlist_songs.c.position)
            .join(playlist_songs, Song.id == playlist_songs.c.song_id)
            .options(selectinload(Song.artists))
            .where(playlist_songs.c.playlist_id == playlist_id)
            .order_by(playlist_songs.c.position)
        ).all()

        return PlaylistDetailResponse(
            id=playlist.id,
            name=playlist.name,
            poster=playlist.poster,
            songs=[_song_to_response(s) for s, _ in ordered],
        )


def create_playlist(name: str, poster: str | None) -> CreatePlaylistResponse:
    with get_session() as session:
        playlist = Playlist(name=name, poster=poster)
        session.add(playlist)
        session.commit()
        session.refresh(playlist)
        return CreatePlaylistResponse(
            status="success", id=playlist.id, name=playlist.name, poster=playlist.poster
        )


def delete_playlist(playlist_id: int) -> str | None | bool:
    """
    Delete a playlist. Returns the poster path (for disk cleanup), or
    False if the playlist does not exist.
    """
    with get_session() as session:
        playlist = session.get(Playlist, playlist_id)
        if not playlist:
            return False
        poster = playlist.poster
        session.delete(playlist)
        session.commit()
        return poster


def add_song_to_playlist(playlist_id: int, song_id: int) -> str:
    """
    Add a song to a playlist. Returns 'added', 'already_exists',
    'playlist_not_found', or 'song_not_found'.
    """
    with get_session() as session:
        if not session.get(Playlist, playlist_id):
            return "playlist_not_found"
        if not session.get(Song, song_id):
            return "song_not_found"

        existing = session.execute(
            select(playlist_songs).where(
                playlist_songs.c.playlist_id == playlist_id,
                playlist_songs.c.song_id == song_id,
            )
        ).first()
        if existing:
            return "already_exists"

        max_pos = session.scalar(
            select(func.max(playlist_songs.c.position))
            .where(playlist_songs.c.playlist_id == playlist_id)
        )
        session.execute(
            playlist_songs.insert().values(
                playlist_id=playlist_id,
                song_id=song_id,
                position=(max_pos or -1) + 1,
            )
        )
        session.commit()
        return "added"


def remove_song_from_playlist(playlist_id: int, song_id: int) -> None:
    with get_session() as session:
        session.execute(
            delete(playlist_songs).where(
                playlist_songs.c.playlist_id == playlist_id,
                playlist_songs.c.song_id == song_id,
            )
        )
        session.commit()

