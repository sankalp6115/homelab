import argparse
import random
import sys
from pathlib import Path
from mutagen.mp3 import MP3
from mutagen.id3 import ID3, APIC
from sqlalchemy import select, delete

BASE_DIR = Path(__file__).resolve().parent.parent.parent
BACKEND_DIR = BASE_DIR / "backend"
for p in (str(BACKEND_DIR), str(BASE_DIR)):
    if p not in sys.path:
        sys.path.insert(0, p)

from utils.path_resolver import get_assets_dir, get_songs_dir
from database.database import get_session, init_db, engine
from models.database import Song, Artist, Lyrics, Playlist, Wallpaper, song_artists, playlist_songs


# -------------------- CONFIGURATION --------------------

SONGS_DIR         = get_songs_dir()
ASSETS_DIR        = get_assets_dir()
LYRICS_DIR        = ASSETS_DIR / "lyrics"
ALBUM_ARTS_DIR    = ASSETS_DIR / "album-arts"
FALLBACK_ARTS_DIR = ALBUM_ARTS_DIR / "fallback"
ARTIST_IMAGES_DIR = ASSETS_DIR / "artist-images"

fallback_art_arr = (
    [f.name for f in FALLBACK_ARTS_DIR.iterdir() if f.suffix.lower() == ".png"]
    if FALLBACK_ARTS_DIR.exists() else []
)


# -------------------- HELPERS --------------------

def split_artists(artist_string: str) -> list[str]:
    if not artist_string:
        return ["Unknown"]
    for sep in ["/", ",", " feat. ", " ft. ", "&", ";"]:
        artist_string = artist_string.replace(sep, "|")
    return [a.strip() for a in artist_string.split("|") if a.strip()]


def fallback_album_art() -> str:
    if fallback_art_arr:
        return f"assets/album-arts/fallback/{random.choice(fallback_art_arr)}"
    return "assets/album-arts/fallback/song-icon4.png"


def find_artist_image(name: str) -> str | None:
    """Check artist-images dir for a matching image file."""
    if not ARTIST_IMAGES_DIR.exists():
        return None
    for ext in (".jpg", ".png", ".webp", ".jpeg"):
        if (ARTIST_IMAGES_DIR / f"{name.lower()}{ext}").exists():
            return f"/artist-images/{name.lower()}{ext}"
    return None


def extract_metadata(file_path: Path) -> dict | None:
    """Extract metadata and album art from various audio formats."""
    suffix     = file_path.suffix.lower()
    title      = file_path.stem
    artist_raw = "Unknown Artist"
    album      = "Unknown Album"
    genre      = "Unknown Genre"
    year       = 0
    duration   = 0
    art_data   = None

    try:
        if suffix == ".mp3":
            audio = MP3(file_path, ID3=ID3)
            title      = str(audio.get("TIT2", title))
            artist_raw = str(audio.get("TPE1", artist_raw))
            album      = str(audio.get("TALB", album))
            genre      = str(audio.get("TCON", genre))
            year_raw   = audio.get("TYER") or audio.get("TDRC")
            year       = int(str(year_raw)[:4]) if year_raw and str(year_raw)[:4].isdigit() else 0
            duration   = int(audio.info.length)
            if audio.tags:
                for tag in audio.tags.values():
                    if isinstance(tag, APIC):
                        art_data = tag.data
                        break

        elif suffix == ".flac":
            from mutagen.flac import FLAC
            audio      = FLAC(file_path)
            title      = audio.get("title",  [title])[0]
            artist_raw = audio.get("artist", [artist_raw])[0]
            album      = audio.get("album",  [album])[0]
            genre      = audio.get("genre",  [genre])[0]
            year_raw   = audio.get("date", [""])[0] or audio.get("year", [""])[0]
            year       = int(str(year_raw)[:4]) if year_raw and str(year_raw)[:4].isdigit() else 0
            duration   = int(audio.info.length)
            if audio.pictures:
                art_data = audio.pictures[0].data

        elif suffix == ".ogg":
            from mutagen.oggvorbis import OggVorbis
            audio      = OggVorbis(file_path)
            title      = audio.get("title",  [title])[0]
            artist_raw = audio.get("artist", [artist_raw])[0]
            album      = audio.get("album",  [album])[0]
            genre      = audio.get("genre",  [genre])[0]
            year_raw   = audio.get("date", [""])[0] or audio.get("year", [""])[0]
            year       = int(str(year_raw)[:4]) if year_raw and str(year_raw)[:4].isdigit() else 0
            duration   = int(audio.info.length)
            if "metadata_block_picture" in audio:
                import base64
                from mutagen.flac import Picture
                for tag in audio["metadata_block_picture"]:
                    try:
                        art_data = Picture(base64.b64decode(tag)).data
                        break
                    except Exception:
                        pass

        elif suffix == ".wav":
            from mutagen.wave import WAVE
            audio    = WAVE(file_path)
            duration = int(audio.info.length)
            if audio.tags:
                title      = str(audio.tags.get("TIT2", title))
                artist_raw = str(audio.tags.get("TPE1", artist_raw))
                album      = str(audio.tags.get("TALB", album))
                genre      = str(audio.tags.get("TCON", genre))
                year_raw   = audio.tags.get("TYER") or audio.tags.get("TDRC")
                year       = int(str(year_raw)[:4]) if year_raw and str(year_raw)[:4].isdigit() else 0
                for tag in audio.tags.values():
                    if isinstance(tag, APIC):
                        art_data = tag.data
                        break

        elif suffix in (".m4a", ".mp4"):
            from mutagen.mp4 import MP4, MP4Cover
            audio      = MP4(file_path)
            title      = audio.get("\xa9nam", [title])[0]
            artist_raw = audio.get("\xa9ART", [artist_raw])[0]
            album      = audio.get("\xa9alb", [album])[0]
            genre      = audio.get("\xa9gen", [genre])[0]
            year_raw   = audio.get("\xa9day", [""])[0]
            year       = int(str(year_raw)[:4]) if year_raw and str(year_raw)[:4].isdigit() else 0
            duration   = int(audio.info.length)
            if "covr" in audio:
                art_data = bytes(audio["covr"][0])

        else:
            import mutagen
            audio = mutagen.File(file_path)
            if audio is None:
                return None
            duration = int(audio.info.length)
            if hasattr(audio, "get"):
                title      = audio.get("title",  [title])[0]
                artist_raw = audio.get("artist", [artist_raw])[0]
                album      = audio.get("album",  [album])[0]
                genre      = audio.get("genre",  [genre])[0]

        art_filename = f"{file_path.stem}.jpg"
        art_path     = ALBUM_ARTS_DIR / art_filename
        if art_data and not art_path.exists():
            with open(art_path, "wb") as img:
                img.write(art_data)

        return {
            "title":    title,
            "artists":  split_artists(artist_raw),
            "album":    album,
            "genre":    genre,
            "year":     year,
            "duration": duration,
            "file":     file_path.relative_to(SONGS_DIR).as_posix(),
            "albumArt": f"assets/album-arts/{art_filename}" if art_path.exists() else fallback_album_art(),
        }

    except Exception as e:
        print(f"Error extracting {file_path.name}: {e}")
        return None


# -------------------- SYNC --------------------

def reset_database():
    """Drop and recreate all tables."""
    print("Dropping old tables and recreating schema...")
    from models.database import Base
    Base.metadata.drop_all(engine)
    init_db()
    print("Database schema initialized.")



def sync(reset: bool = False, cleanup: bool = False):
    print("Starting Library Sync...")
    print(f"Songs Dir: {SONGS_DIR}")

    if reset:
        reset_database()

    # ---- Load existing state directly from DB ----
    with get_session() as session:
        # file_path → (id, rating) for preserving IDs and user ratings across syncs
        db_songs = {
            s.file_path: {"id": s.id, "rating": s.rating}
            for s in session.scalars(select(Song)).all()
        }
        # artist name → current image (preserve manually-uploaded images)
        db_artist_images = {
            a.name: a.image
            for a in session.scalars(select(Artist)).all()
        }
        # song_id set for quick lyrics lookup
        db_lyrics_ids = {
            l.song_id for l in session.scalars(select(Lyrics)).all()
        }

    max_id = max((v["id"] for v in db_songs.values()), default=0)

    # ---- Scan filesystem ----
    supported = {".mp3", ".flac", ".ogg", ".wav", ".m4a", ".mp4"}
    files = sorted(
        [p for p in SONGS_DIR.rglob("*") if p.is_file() and p.suffix.lower() in supported],
        key=lambda x: x.name.lower(),
    )
    print(f"Found {len(files)} audio files.")

    scanned: list[dict] = []
    valid_paths: set[str] = set()

    for i, file_path in enumerate(files):
        if "lyrics" in file_path.parts:
            continue
        rel_path = file_path.relative_to(SONGS_DIR).as_posix()
        valid_paths.add(rel_path)
        print(f"[{i+1}/{len(files)}] {rel_path}", end="\r")

        metadata = extract_metadata(file_path)
        if not metadata:
            continue

        if rel_path in db_songs:
            metadata["id"]     = db_songs[rel_path]["id"]
            metadata["rating"] = db_songs[rel_path]["rating"]
        else:
            max_id += 1
            metadata["id"]     = max_id
            metadata["rating"] = 0
            print(f"\nNew song: {metadata['title']} ({rel_path})")

        scanned.append(metadata)

    print(f"\nScanned: {len(scanned)} songs.")

    # ---- Write everything to DB ----
    with get_session() as session:

        # Upsert songs
        for s in scanned:
            song = session.get(Song, s["id"])
            if song:
                song.title    = s["title"]
                song.album    = s["album"]
                song.genre    = s["genre"]
                song.year     = s["year"]
                song.duration = s["duration"]
                song.file_path = s["file"]
                song.album_art = s["albumArt"]
                song.rating   = s["rating"]
            else:
                song = Song(
                    id=s["id"], title=s["title"], album=s["album"],
                    genre=s["genre"], year=s["year"], duration=s["duration"],
                    file_path=s["file"], album_art=s["albumArt"], rating=s["rating"],
                )
                session.add(song)

        session.flush()

        # Upsert artists — preserve existing DB images, only auto-discover for new ones
        artist_id_map: dict[str, int] = {}
        all_artist_names = {name for s in scanned for name in s["artists"]}

        for name in sorted(all_artist_names):
            artist = session.scalar(select(Artist).where(Artist.name == name))
            if artist:
                # Only fill in image if the artist currently has none
                if not artist.image:
                    artist.image = find_artist_image(name)
            else:
                artist = Artist(name=name, image=find_artist_image(name))
                session.add(artist)
            session.flush()
            artist_id_map[name] = artist.id

        # Rebuild song↔artist links
        for s in scanned:
            session.execute(delete(song_artists).where(song_artists.c.song_id == s["id"]))
            for name in s["artists"]:
                artist_id = artist_id_map.get(name)
                if artist_id:
                    session.execute(
                        song_artists.insert()
                        .prefix_with("OR IGNORE")
                        .values(song_id=s["id"], artist_id=artist_id)
                    )

        # Sync lyrics from .lrc files on disk
        if LYRICS_DIR.exists():
            lrc_files = {f.stem: f for f in LYRICS_DIR.rglob("*.lrc")}
            for s in scanned:
                lrc = lrc_files.get(Path(s["file"]).stem)
                if lrc:
                    try:
                        content = lrc.read_text("utf-8").strip()
                        lyrics  = session.get(Lyrics, s["id"])
                        if lyrics:
                            lyrics.content = content
                        else:
                            session.add(Lyrics(song_id=s["id"], content=content))
                    except Exception as e:
                        print(f"Error reading lyrics for {lrc.stem}: {e}")

        # Remove stale songs (files deleted from disk)
        if cleanup:
            stale = [
                song for song in session.scalars(select(Song)).all()
                if song.file_path not in valid_paths
            ]
            for song in stale:
                session.delete(song)
            if stale:
                print(f"Removed {len(stale)} stale song(s) from the database.")

        session.commit()

    print("Sync complete!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Synchronize Melodious Library")
    parser.add_argument("--reset",   action="store_true", help="Drop and recreate the database from scratch")
    parser.add_argument("--cleanup", action="store_true", help="Remove DB entries for files no longer on disk")
    args = parser.parse_args()
    sync(reset=args.reset, cleanup=args.cleanup)
