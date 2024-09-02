"""Cache operations"""

import sys
from enum import Enum, auto
from pathlib import Path
from datetime import datetime, timezone, timedelta
from threading import Thread
import pyotherside
from typing import Union

sys.path.append(Path(sys.path[0]).parent / 'deps')
import requests
from PIL import Image

AnyPath = Union[Path, str]
TimedeltaResult = Union[timedelta, None]
AnyTimedelta = Union[TimedeltaResult, int]

CachePeriodMapping = [
    None, # Never
    timedelta(), # On app restart
    timedelta(hours=1),
    timedelta(1),
    timedelta(weeks=1),
    timedelta(30),
    timedelta(182.5), # half-yearly
    timedelta(365),
]
#CachePeriodMapping.__doc__ = """Maps QML cache period slider system to timedelta objects. On app restart is timedelta(0), Never is None."""

class ImageType(Enum):
    SERVER = auto()
    USER = auto()

def cached_path(cache: AnyPath, id, type: ImageType):
    return Path(cache) / type.name.lower() / f"{id}.png"

def verify_pillow(path: AnyPath):
    try:
        im = Image.load(path)
        im.verify()
        im.close()
        im = Image.load(path) 
        im.transpose(Image.FLIP_LEFT_RIGHT)
        im.close()
    except Exception as e:
        return e
    return None

def download_pillow(url):
    """Generate a Pillow object from downloaded URL. Returns None if URL is not valid."""
    r = requests.get(url, stream=True)
    if r.status_code != 200: return
    im = Image.open(r.raw)
    return im

def update_required(path: Path, minimum_time: timedelta):
    """Returns if the file at `path` was modified more or `minimum_time` ago"""
    mod = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
    pyotherside.send(str(mod), str(path))
    now = datetime.now(timezone.utc)
    dif = now-mod
    return dif >= minimum_time

def convert_to_timedelta(data: AnyTimedelta) -> TimedeltaResult:
    try:
        if isinstance(data, int):
            return CachePeriodMapping[data]
        else: return data # Already converted
    except:
        pyotherside.send(f"An error occured when converting timedeltas.\ndata of type {type(data)}: {data}\nFalling back to None.")
        return None # failsafe

class Cacher:
    @property
    def update_period(self):
        return self._update_period

    @update_period.setter
    def update_period(self, value: AnyTimedelta):
        self._update_period = convert_to_timedelta(value)

    def __init__(self, cache: AnyPath, update_period: AnyTimedelta):
        self._update_period = None

        self.cache = Path(cache)
        self.update_period = update_period

        self.session_cached = {}
        for im in ImageType:
            self.session_cached[im.name.lower()] = {}

    def get_cached_path(self, id, type: ImageType, default=None):
        """If default is not None and any of these:
        - path does not exist
        - path was cached in this session (finished only)
        - path contains broken image
        then default is returned"""
        path = cached_path(self.cache, id, type)
        if default != None:
            if self.verify_image(id, type):
                return default
        return path

    def update_required(self, id, type: ImageType):
        t = timedelta(1)

        p = self.get_cached_path(id, type)
        if not p.exists():
            return
        return update_required(p, t)

    def broken_image(self, id, type: ImageType):
        """Checks if an image is broken or image is not cached. Returns None if not or an error if yes."""
        path = self.get_cached_path(id, type)
        if not path.exists():
            return DoesNotExistError
        return verify_pillow(path)

    def verify_image(self, id, type: ImageType):
        """Returns if an image is not broken and is cached"""
        return self.broken_image(id, type) == None

    def cache_image(self, url, id, type: ImageType):
        if self.has_cached_session(id, type):
            return # Only cache once in a session
        self.set_cached_session(id, type, False)
        im = download_pillow(url)
        if im == None: return
        path = self.get_cached_path(id, type)
        path.parent.mkdir(exist_ok=True, parents=True)
        pyotherside.send(f"CACHING STARTED FOR {id}!")
        im.save(path) # We use Pillow to convert JPEG, GIF and others to PNG
        pyotherside.send(f"caching stopped for {id}!")
        self.set_cached_session(id, type)

    def cache_image_bg(self, url, id, type: ImageType):
        Thread(target=self.cache_image, args=(url, id, type)).start()

    def set_cached_session(self, id, type: ImageType, finished=True):
        self.session_cached[type.name.lower()][str(id)] = finished
        #pyotherside.send(f"SET {self.session_cached} {id} {id in self.session_cached[type.name.lower()]}")

    def has_cached_session(self, id, type: ImageType, finished=None):
        """Returns was ever the image cached in the current session.
        
        finished:
            - True for checking finished only
            - False for checking in progress only
            - Anything else (or None) for checking any/both"""
        #pyotherside.send(f"HAS {self.session_cached} {str(id)} {str(id) in self.session_cached[type.name.lower()]}")

        if str(id) not in self.session_cached[type.name.lower()]:
            return False
        
        if finished in [False, True]:
            return self.session_cached[type.name.lower()][str(id)] == finished
        else:
            return True
  