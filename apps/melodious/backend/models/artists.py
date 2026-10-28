from pydantic import BaseModel
from .songs import SongResponse


class ArtistResponse(BaseModel):
    id:    int
    name:  str
    image: str | None = None


class ArtistDetailResponse(ArtistResponse):
    songs: list[SongResponse] = []


class UpdateArtistImageResponse(BaseModel):
    message: str
    image:   str

