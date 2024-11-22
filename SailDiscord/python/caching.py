"""Cache operations"""

import sys, shutil
from enum import Enum, auto
from pathlib import Path
from datetime import datetime, timezone, timedelta
from threading import Thread
from pyotherside import send as qsend
from typing import Union, Optional

from exceptions import *

script_path = Path(__file__).absolute().parent # /usr/share/harbour-saildiscord/python
sys.path.append(str(script_path.parent / 'lib/deps')) # /usr/share/harbour-saildiscord/lib/deps
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
    MYSELF = auto()

def cached_path(cache: AnyPath, id, type: ImageType):
    return Path(cache) / type.name.lower() / f"{id}.png"

def verify_pillow(path: AnyPath):
    try:
        im = Image.open(path)
        im.verify()
        im.close()
        im = Image.open(path) 
        im.transpose(Image.FLIP_LEFT_RIGHT)
        im.close()
    except Exception as e:
        return e
    return None

def download_pillow(url, proxies: Optional[dict]):
    """Generate a Pillow object from downloaded URL. Returns None if URL is not valid."""
    try: r = requests.get(url, stream=True, proxies=proxies)
    except requests.ConnectionError as e:
        qsend("cacheConnectionError", str(e))
        return
    except requests.RequestException as e:
        qsend("cacheError", str(type(e)), str(e))
        return
    if r.status_code != 200: return
    im = Image.open(r.raw)
    return im

def update_required(path: Path, minimum_time: timedelta):
    """Returns if the file at `path` was modified more or `minimum_time` ago"""
    mod = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
    now = datetime.now(timezone.utc)
    dif = now-mod
    return dif >= minimum_time

def convert_to_timedelta(data: AnyTimedelta) -> TimedeltaResult:
    try:
        if isinstance(data, int):
            return CachePeriodMapping[data]
        else: return data # Already converted
    except:
        qsend(f"An error occured when converting timedeltas.\ndata of type {type(data)}: {data}\nFalling back to None.")
        return None # failsafe

class Cacher:
    @property
    def update_period(self):
        return self._update_period

    @update_period.setter
    def update_period(self, value: AnyTimedelta): # pyright: ignore[reportPropertyTypeMismatch]
        self._update_period = convert_to_timedelta(value)

    @property
    def proxy(self):
        return self._proxy

    @proxy.setter
    def proxy(self, value: Optional[str]):
        self._proxy = value
        if value == None:
            self.proxies = {}
        else:
            self.proxies = {
                "http": value,
                "https": value,
            }

    def __init__(self, cache: AnyPath, update_period: AnyTimedelta, proxy: Optional[str] = None):
        self._update_period = None

        self.cache: Path = Path(cache)
        self.temp: Path = Path(cache) / 'temporary' # FIXME: use StandardPaths.Temporary without private-tmp instead
        self.clear_temporary()
        self.recreate_temporary()
        self.update_period = update_period
        self.proxies = {}
        self._proxy: Optional[str] = None
        self.proxy = proxy

        self.session_cached = {}
        for im in ImageType:
            self.session_cached[im.name.lower()] = {}

    def get_cached_path(self, id, type: ImageType, default=None):
        """If default is not None and any of these:
        - path does not exist
        - path contains broken image
        - update_period set to None (Never)
        then default is returned"""
        path = cached_path(self.cache, id, type)
        if default != None:
            if not self.verify_image(id, type) or self.update_period == None:
                return default
        return path

    def update_required(self, id, type: ImageType):
        p = self.get_cached_path(id, type)
        if not p.exists() or self.update_period == timedelta(0):
            return True
        if self.update_period == None:
            return False
        return update_required(p, self.update_period)

    def broken_image(self, id, type: ImageType):
        """Checks if an image is broken or image is not cached. Returns None if not or an error if yes."""
        path = self.get_cached_path(id, type)
        if not path.exists():
            return DoesNotExistError
        return verify_pillow(path)

    def verify_image(self, id, type: ImageType):
        """Returns if an image is not broken and is cached"""
        return self.broken_image(id, type) == None

    def save_temporary(self, url: str, filename: AnyPath):
        dest = self.temp / filename
        r = requests.get(url, stream=True, proxies=self.proxies)
        if r.status_code == 200:
            with open(dest, 'wb') as f:
                for chunk in r:
                    f.write(chunk)
        return dest

    def clear_temporary(self):
        shutil.rmtree(self.temp, ignore_errors=True)
    
    def recreate_temporary(self):
        self.temp.mkdir(parents=True, exist_ok=True)

    def cache_image(self, url, id, type: ImageType):
        if self.update_period == None: return # Never set in settings
        if self.has_cached_session(id, type) or not self.update_required(id, type):
            return # Only cache once in a session or update_period
        self.set_cached_session(id, type, False)
        im = download_pillow(url, self.proxies)
        if im == None: return
        path = self.get_cached_path(id, type)
        path.parent.mkdir(exist_ok=True, parents=True)
        im.save(path) # We use Pillow to convert JPEG, GIF and others to PNG
        self.set_cached_session(id, type)

    def cache_image_bg(self, url, id, type: ImageType):
        Thread(target=self.cache_image, args=(url, id, type)).start()

    def set_cached_session(self, id, type: ImageType, finished=True):
        self.session_cached[type.name.lower()][str(id)] = finished
        #qsend(f"SET {self.session_cached} {id} {str(id) in self.session_cached[type.name.lower()]}")

    def has_cached_session(self, id, type: ImageType, finished=None):
        """Returns was ever the image cached in the current session.
        
        finished:
            - True for checking finished only
            - False for checking in progress only
            - Anything else (or None) for checking any/both"""
        #qsend(f"HAS {self.session_cached} {id} {str(id) in self.session_cached[type.name.lower()]}")

        if str(id) not in self.session_cached[type.name.lower()]:
            return False
        
        if finished in [False, True]:
            return self.session_cached[type.name.lower()][str(id)] == finished
        else:
            return True