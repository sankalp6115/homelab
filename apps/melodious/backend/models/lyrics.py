from pydantic import BaseModel


class LyricsResponse(BaseModel):
    song_id: int
    lyrics:  str | None = None

