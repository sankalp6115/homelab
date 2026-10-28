from fastapi import APIRouter, HTTPException

import database.lyrics as db
from models.lyrics import LyricsResponse

router = APIRouter()


@router.get("", response_model=list[LyricsResponse])
def get_all_lyrics():
    return db.list_lyrics()


@router.get("/{song_id}", response_model=LyricsResponse)
def get_lyrics(song_id: int):
    lyrics = db.get_lyrics(song_id)
    if not lyrics:
        raise HTTPException(status_code=404, detail="Lyrics not found for this song")
    return lyrics