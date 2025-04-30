from __future__ import annotations
"""Cache operations"""

import sys, os, shutil
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
from yarl import URL # a dependency in discord.py-self, so why not use it?

AnyPath = Union[Path, str]
TimedeltaResult = Optional[timedelta]
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
    EMOJI = auto()
    GROUP = auto()
    DECORATION = auto()

def get_extension_from_url(url: str, default='png'):
    res = os.path.splitext(URL(url).path)[1]
    if res.startswith('.'): # removeprefix() was sadly introduced in python 3.9
        res = res[1:]
    return res or default

def cached_path(cache: AnyPath, id, type: ImageType, format: str | None = None):
    path = Path(cache) / type.name.lower()
    if format is None:# and isinstance(cache, Path):
        for f in sorted(path.glob(f'{id}.*'), key=lambda p: Path.stat(p).st_mtime):
            if not f.is_dir():
                return f
        format = 'png'
    return path / f"{id}.{format}"

# discord supports static formats: jpeg, jpg, webp, png (taken from discord.asset)
# and one non-static format: gif (also taken from there)
# BUT it seems like avatar decorations can be .apng (Animated PNG, sometimes extension is .png)
# upd on APNG: seems like anything can be it and it's just png in original quality, besides (and if!) being animated

def verify_pillow(path: AnyPath):
    # TODO: remove this and rely on errors from qt (implement Cacher.recache or something)
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

def download(url, proxies: dict | None):
    """Returns requests.Response object or None if URL is invalid"""
    try:
        r = requests.get(url, stream=True, proxies=proxies)
        if r.status_code != 200: return
        return r
    except requests.ConnectionError as e:
        qsend('error', 'cacheConnection', str(e))
    except requests.RequestException as e:
        qsend('error', 'cache', str(type(e)), str(e))

def download_pillow(url, proxies: dict | None):
    """Create a Pillow object from downloaded URL. Returns None if URL is not valid."""
    data = download(url, proxies)
    if data:
        return Image.open(data.raw)

def update_required(path: Path, minimum_time: timedelta):
    """Returns if the file at `path` was modified more or `minimum_time` ago"""
    mod = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
    now = datetime.now(timezone.utc)
    diff = now-mod
    return diff >= minimum_time

def convert_to_timedelta(data: AnyTimedelta) -> TimedeltaResult:
    try:
        if isinstance(data, int):
            return CachePeriodMapping[data]
        else: return data # Already converted
    except:
        qsend(f"An error occured when converting timedeltas.\ndata of type {type(data)}: {data}\nFalling back to None.")
        return None # failsafe

def download_save(url, destination: AnyPath, proxies: dict | None):
    r = download(url, proxies)
    if r:
        with open(destination, 'wb') as f:
            for chunk in r: # r.__iter__() is same as r.iter_content(chunk_size=128)
                f.write(chunk)
        return True
    return False

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
    def proxy(self, value: str | None):
        self._proxy = value
        if value == None:
            self.proxies = {}
        else:
            self.proxies = {
                "http": value,
                "https": value,
            }

    def __init__(self, cache: AnyPath, update_period: AnyTimedelta, proxy: str | None = None):
        self._update_period = None

        self.cache: Path = Path(cache)
        self.temp: Path = Path(cache) / 'temporary' # FIXME: use StandardPaths.Temporary without private-tmp instead
        self.clear_temporary()
        self.recreate_temporary()
        self.update_period = update_period
        self.proxies = {}
        self._proxy: str | None = None
        self.proxy = proxy

        self.session_cached = {}
        for im in ImageType:
            self.session_cached[im.name.lower()] = {}

    def get_cached_path(self, id, type: ImageType, default=None, format: str|None=None):
        """If default is not None and any of these:
        - path does not exist
        - path contains broken image
        - update_period set to None (Never)
        then default is returned"""
        if default != None:
            if not self.verify_image(id, type) or self.update_period == None:
                return default
        return cached_path(self.cache, id, type, format)

    def update_required(self, id, type: ImageType):
        path = self.get_cached_path(id, type)
        if not path.exists() or self.update_period == timedelta(0):
            return True
        if self.update_period == None:
            return False
        return update_required(path, self.update_period)

    def broken_image(self, id, type: ImageType):
        """Checks if an image is broken or image is not cached. Returns None if not or an error if yes."""
        path = self.get_cached_path(id, type)
        if not path.exists():
            return DoesNotExistError
        return verify_pillow(path)

    def verify_image(self, id, type: ImageType):
        """Returns if an image is not broken and is cached"""
        return self.broken_image(id, type) == None
    
    def download_save(self, url, dest):
        return download_save(url, dest, self.proxies)

    def save_temporary(self, url: str, filename: AnyPath):
        dest = self.temp / filename
        self.download_save(url, dest)
        return dest

    def clear_temporary(self):
        shutil.rmtree(self.temp, ignore_errors=True)
    
    def recreate_temporary(self):
        self.temp.mkdir(parents=True, exist_ok=True)

    def cache_image(self, url, id, type: ImageType, format: str|None=None):
        if self.update_period == None: return # Never set in settings
        if self.has_cached_session(id, type) or not self.update_required(id, type):
            return # Only cache once in a session or update_period
        self.set_cached_session(id, type, False)
        path = self.get_cached_path(id, type, format=format or get_extension_from_url(url))
        path.parent.mkdir(exist_ok=True, parents=True)
        if self.download_save(url, path):
            self.set_cached_session(id, type)

    def cache_image_bg(self, url, id, type: ImageType, format: str|None=None):
        Thread(target=self.cache_image, args=(url, id, type, format)).start()

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
    
    def easy(self, url, id, type: ImageType, format: str|None=None):
        icon = '' if url is None else \
            str(self.get_cached_path(id, type, url, format))
        if icon != '':
            self.cache_image_bg(str(url), id, type, format)
        return icon