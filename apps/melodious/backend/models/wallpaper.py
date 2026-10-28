from pydantic import BaseModel


class WallpaperResponse(BaseModel):
    id: int
    filename: str
    name: str | None = None
    url: str


class WallpaperUploadResponse(BaseModel):
    status: str
    id: int
    filename: str
    name: str | None = None
    url: str

