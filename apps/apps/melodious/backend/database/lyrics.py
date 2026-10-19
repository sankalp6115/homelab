from sqlalchemy import select

from .database import get_session
from models.database import Lyrics
from models.lyrics import LyricsResponse


def list_lyrics() -> list[LyricsResponse]:
    with get_session() as session:
        rows = session.scalars(select(Lyrics)).all()
        return [LyricsResponse(song_id=l.song_id, lyrics=l.content) for l in rows]


def get_lyrics(song_id: int) -> LyricsResponse | None:
    with get_session() as session:
        lyrics = session.get(Lyrics, song_id)
        return LyricsResponse(song_id=lyrics.song_id, lyrics=lyrics.content) if lyrics else None

