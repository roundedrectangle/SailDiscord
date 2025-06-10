from __future__ import annotations

"""Cache operations"""

from enum import Enum, auto
from pathlib import Path
from datetime import timedelta
from threading import Thread
from pyotherside import send as qsend

from exceptions import *

from pyotherside_utils import *

VALID_ANIMATED_FORMATS = frozenset({'gif'}) # discord.asset.VALID_ASSET_FORMATS - discord.asset.VALID_STATIC_FORMATS

STUB_QML_ASSET = (
    False,
    '',
    '',
    False,
    -1,
    -1,
    'png',
)
"""Asset format (current):
[
    0: source: str,
    1: originalSource: str,
    2: animated: bool,
    3: extension: str,
]

Original format:
[
    0: available: bool,
    1: source: str,
    2: originalSource: str,
    3: animated: bool,
    4: type: int(ImageType.value),
    5: id: str(int),
    6: extension: str,
]"""

class ImageType(Enum):
    SERVER = auto()
    USER = auto()
    MYSELF = auto()
    EMOJI = auto()
    GROUP = auto()
    DECORATION = auto()


def cached_path(cache: Path | str, id, type: ImageType, format: str | None = None):
    return find_file(Path(cache) / type.name.lower(), id, format, 'png')

# discord supports static formats: jpeg, jpg, webp, png (taken from discord.asset)
# and one non-static format: gif (also taken from there)
# BUT it seems like avatar decorations can be .apng (Animated PNG, sometimes extension is .png)
# upd on APNG: seems like anything can be it and it's just png in original quality, besides (and if!) being animated

def construct_qml_data(path, url=None, animated=None, extension=None):
    if animated is None:
        animated = get_extension_from_url(path) in VALID_ANIMATED_FORMATS
    if url == path:
        url = None
    if extension is None:
        extension = get_extension_from_url(path)
    return (
        str(path or ''),
        str(url or ''),
        bool(animated),
        extension,
    )

class Cacher(CacherBase):
    def __init__(self, cache: Path | str, update_period: timedelta | int | None, proxy: str | None = None, user_agent: str | None = None):
        super().__init__(update_period, proxy=proxy, user_agent=user_agent)
        self.cache: Path = Path(cache)

        self.session_cached = {}
        for im in ImageType:
            self.session_cached[im.name.lower()] = {}

    def get_cached_path(self, id, type: ImageType, default=None, format: str|None=None):
        """If default is not None and any of these:
        - path does not exist
        - update_period set to None (Never)

        then default is returned
        
        Earlier it was also checked if path contains broken image, now not."""
        if default != None:
            if not self.verify_image(id, type) or self.update_period == None:
                return default
        return cached_path(self.cache, id, type, format)

    def update_required(self, id, type: ImageType):
        return super().update_required(self.get_cached_path(id, type))

    def verify_image(self, id, type: ImageType) -> bool:
        """Returns if an image is cached.
        
        Erlier this also checked if the image is not broken."""
        return self.get_cached_path(id, type).exists()

    def cache_image(self, url, id, type: ImageType, format: str|None=None, force=False):
        if self.update_period == None: return # Never set in settings
        if not force and (self.has_cached_session(id, type) or not self.update_required(id, type)):
            return # Only cache once in a session or update_period
        self.set_cached_session(id, type, False)
        path = self.get_cached_path(id, type, format=format or get_extension_from_url(url))
        path.parent.mkdir(exist_ok=True, parents=True)
        if self.download_save(url, path, False):
            self.set_cached_session(id, type)

    def cache_image_bg(self, url, id, type: ImageType, format: str|None=None, force=False):
        Thread(target=self.cache_image, args=(url, id, type, format, force)).start()

    def set_cached_session(self, id, type: ImageType, finished=True):
        self.session_cached[type.name.lower()][str(id)] = finished
        #qsend(f"SET {self.session_cached} {id} {str(id) in self.session_cached[type.name.lower()]}")

    def has_cached_session(self, id, type: ImageType, finished=None):
        """Returns if the image was cached in the current session.
        
        finished:
            - True for checking finished only
            - False for checking in progress only
            - Anything else (or None) for checking any/both"""
        #qsend(f"HAS {self.session_cached} {id} {str(id) in self.session_cached[type.name.lower()]}")

        if str(id) not in self.session_cached[type.name.lower()]:
            return False
        
        if isinstance(finished, bool):
            return self.session_cached[type.name.lower()][str(id)] == finished
        else:
            return True
    
    def easy(self, url, id, type: ImageType, format: str|None=None, as_qml_data=True):
        icon = '' if url is None else \
            str(self.get_cached_path(id, type, url, format))
        if icon != '':
            self.cache_image_bg(str(url), id, type, format)
        if as_qml_data:
            if icon == '':
                return STUB_QML_ASSET
            return construct_qml_data(icon, url)
        return icon