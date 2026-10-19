from pydantic import BaseModel
from .songs import SongResponse, DeleteResponse


class PlaylistResponse(BaseModel):
    id:     int
    name:   str
    poster: str | None = None


class PlaylistDetailResponse(PlaylistResponse):
    songs: list[SongResponse] = []


class CreatePlaylistResponse(BaseModel):
    status: str
    id:     int
    name:   str
    poster: str | None = None


class SongInPlaylistResponse(BaseModel):
    status:  str
    message: str

