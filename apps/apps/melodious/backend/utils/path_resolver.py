from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent


def get_data_dir() -> Path:
    return BASE_DIR / "data"


def get_assets_dir() -> Path:
    return BASE_DIR / "assets"


def get_songs_dir() -> Path:
    return BASE_DIR / "assets" / "songs"


def get_wallpaper_dir() -> Path:
    wp_dir = BASE_DIR / "assets" / "wallpaper"
    wp_dir.mkdir(parents=True, exist_ok=True)
    return wp_dir