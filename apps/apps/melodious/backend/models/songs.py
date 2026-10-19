from pydantic import BaseModel


class SongResponse(BaseModel):
    id:         int
    title:      str
    album:      str | None = None
    genre:      str | None = None
    year:       int | None = None
    duration:   int | None = None
    file:       str | None = None
    albumArt:   str | None = None
    rating:     int        = 0
    isFavorite: bool       = False
    artists:    list[str]  = []


class SongCreate(BaseModel):
    title:        str
    album:        str | None  = None
    genre:        str | None  = None
    year:         int | None  = None
    duration:     int         = 0
    file_path:    str
    album_art:    str | None  = None
    artist_names: list[str]   = []


class UploadSongResponse(BaseModel):
    status:    str
    song_id:   int
    file_path: str
    album_art: str | None = None


class ToggleFavoriteResponse(BaseModel):
    status:     str
    isFavorite: bool


class DeleteResponse(BaseModel):
    status:  str
    message: str

