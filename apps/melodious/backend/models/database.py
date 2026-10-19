from sqlalchemy import String, Integer, Boolean, Text, ForeignKey, Table, Column
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


# ---------- Association Tables ----------

song_artists = Table(
    "song_artists",
    Base.metadata,
    Column("song_id",   Integer, ForeignKey("songs.id",   ondelete="CASCADE"), primary_key=True),
    Column("artist_id", Integer, ForeignKey("artists.id", ondelete="CASCADE"), primary_key=True),
)

playlist_songs = Table(
    "playlist_songs",
    Base.metadata,
    Column("playlist_id", Integer, ForeignKey("playlists.id", ondelete="CASCADE"), primary_key=True),
    Column("song_id",     Integer, ForeignKey("songs.id",     ondelete="CASCADE"), primary_key=True),
    Column("position",    Integer),
)


# ---------- Models ----------

class Song(Base):
    __tablename__ = "songs"

    id:          Mapped[int]           = mapped_column(Integer, primary_key=True)
    title:       Mapped[str]           = mapped_column(String,  nullable=False)
    album:       Mapped[str | None]    = mapped_column(String)
    genre:       Mapped[str | None]    = mapped_column(String)
    year:        Mapped[int | None]    = mapped_column(Integer)
    duration:    Mapped[int | None]    = mapped_column(Integer)
    file_path:   Mapped[str | None]    = mapped_column(String)
    album_art:   Mapped[str | None]    = mapped_column(String)
    rating:      Mapped[int]           = mapped_column(Integer, default=0)
    is_favorite: Mapped[bool]          = mapped_column(Boolean, default=False)

    artists:   Mapped[list["Artist"]]   = relationship("Artist",   secondary=song_artists,   back_populates="songs")
    playlists: Mapped[list["Playlist"]] = relationship("Playlist", secondary=playlist_songs, back_populates="songs")
    lyrics:    Mapped["Lyrics | None"]  = relationship("Lyrics",   back_populates="song", uselist=False)


class Artist(Base):
    __tablename__ = "artists"

    id:    Mapped[int]        = mapped_column(Integer, primary_key=True, autoincrement=True)
    name:  Mapped[str]        = mapped_column(String,  unique=True, nullable=False)
    image: Mapped[str | None] = mapped_column(String)

    songs: Mapped[list["Song"]] = relationship("Song", secondary=song_artists, back_populates="artists")


class Playlist(Base):
    __tablename__ = "playlists"

    id:     Mapped[int]        = mapped_column(Integer, primary_key=True, autoincrement=True)
    name:   Mapped[str]        = mapped_column(String,  nullable=False)
    poster: Mapped[str | None] = mapped_column(String)

    songs: Mapped[list["Song"]] = relationship("Song", secondary=playlist_songs, back_populates="playlists")


class Lyrics(Base):
    __tablename__ = "lyrics"

    song_id: Mapped[int]        = mapped_column(Integer, ForeignKey("songs.id", ondelete="CASCADE"), primary_key=True)
    content: Mapped[str | None] = mapped_column(Text)

    song: Mapped["Song"] = relationship("Song", back_populates="lyrics")


class Wallpaper(Base):
    __tablename__ = "wallpapers"

    id:       Mapped[int]        = mapped_column(Integer, primary_key=True, autoincrement=True)
    filename: Mapped[str]        = mapped_column(String, unique=True, nullable=False)
    name:     Mapped[str | None] = mapped_column(String)