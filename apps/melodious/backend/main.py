import os
import argparse
from pathlib import Path
from contextlib import asynccontextmanager
import uvicorn
from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

from utils.path_resolver import get_assets_dir
from database.database import init_db
from database.wallpaper import sync_wallpapers_from_disk
from api import songs, playlists, artists, lyrics, debug, wallpaper

# Load environment variables from backend directory
load_dotenv(Path(__file__).resolve().parent / ".env")

try:
    from apps.apps.gotify import Gotify
    GOTIFY_TOKEN = os.getenv("GOTIFY_TOKEN")
    GOTIFY_SERVER = os.getenv("GOTIFY_SERVER")
    gotify = Gotify(GOTIFY_SERVER, GOTIFY_TOKEN) if (GOTIFY_SERVER and GOTIFY_TOKEN) else None
except Exception:
    gotify = None

FRONTEND_DIRECTORY = Path(__file__).resolve().parent.parent / "frontend" / "dist"


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize database tables and sync wallpaper assets
    init_db()
    sync_wallpapers_from_disk()
    yield


app = FastAPI(title="Melodious Backend", lifespan=lifespan)

# ---------------- CORS ----------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------- Routes ----------------
app.include_router(songs.router, prefix="/api/songs", tags=["Songs"])
app.include_router(playlists.router, prefix="/api/playlists", tags=["Playlists"])
app.include_router(artists.router, prefix="/api/artists", tags=["Artists"])
app.include_router(lyrics.router, prefix="/api/lyrics", tags=["Lyrics"])
app.include_router(debug.router, prefix="/api/debug", tags=["Debug"])
app.include_router(wallpaper.router, prefix="/api/wallpaper", tags=["Wallpapers"])

# ---------------- Health ----------------
@app.get("/health")
def health():
    return {"status": "healthy"}

# ---------------- Static & Frontend SPA ----------------
@app.get("/{full_path:path}")
async def serve_frontend(full_path: str):
    path = FRONTEND_DIRECTORY / full_path
    if path.is_file():
        return FileResponse(path)

    if full_path.startswith("assets/"):
        asset_path = get_assets_dir() / full_path[len("assets/"):]
        if asset_path.is_file():
            return FileResponse(asset_path)
    elif (get_assets_dir() / full_path).is_file():
        return FileResponse(get_assets_dir() / full_path)


    index_file = FRONTEND_DIRECTORY / "index.html"
    if index_file.is_file():
        return FileResponse(index_file)
    return {"status": "ok", "message": "Melodious backend running (Frontend not built)"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Melodious Backend")
    parser.add_argument("--port", type=int, default=8000, help="Port to bind the server to")
    args = parser.parse_args()

    if gotify:
        try:
            gotify.info("Melodious Up", f"Melodious started on port {args.port}")
        except Exception:
            pass

    uvicorn.run("main:app", port=args.port, host="0.0.0.0")