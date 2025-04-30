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
from yarl import URL # a dependency in discord.py-self, so why not use it?

AnyPath = Union[Path, str]
TimedeltaResult = Optional[timedelta]
AnyTimedelta = Union[TimedeltaResult, int]
VALID_ANIMATED_FORMATS = frozenset({'gif'}) # discord.asset.VALID_ASSET_FORMATS - discord.asset.VALID_STATIC_FORMATS

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

STUB_QML_ASSET = {
    'available': False,
    'source': '',
    'originalSource': '',
    'animated': False,
    'type': -1,
    'id': -1,
}

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

def download(url, proxies: dict | None):
    """Returns requests.Response object or None if URL is invalid"""
    try:
        r = requests.get(str(url), stream=True, proxies=proxies)
        if r.status_code != 200: return
        return r
    except requests.ConnectionError as e:
        qsend('error', 'cacheConnection', str(e))
    except requests.RequestException as e:
        qsend('error', 'cache', str(type(e)), str(e))

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

def construct_qml_data(path, asset_type: ImageType | int, asset_id=-1, url=None, animated=None):
    if animated is None:
        animated = get_extension_from_url(path) in VALID_ANIMATED_FORMATS
    if url == path:
        url = None
    return {
        'available': True,
        'source': str(path or ''),
        'originalSource': str(url or ''),
        'animated': bool(animated),
        'type': asset_type.value if isinstance(asset_type, ImageType) else asset_type,
        'id': str(asset_id),
    }

def notify_qml(path, asset_type: ImageType | int, asset_id=-1, url=None, animated=None):
    asset_type = asset_type.value if isinstance(asset_type, ImageType) else asset_type
    qsend(f'recache{asset_type}{asset_id}', construct_qml_data(path, asset_type, asset_id, url, animated))

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
        - update_period set to None (Never)

        then default is returned
        
        Earlier it was also checked if path contains broken image, now not."""
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

    def verify_image(self, id, type: ImageType) -> bool:
        """Returns if an image is cached.
        
        Erlier this also checked if the image is not broken."""
        return self.get_cached_path(id, type).exists()
    
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

    def cache_image(self, url, id, type: ImageType, format: str|None=None, force=False):
        if self.update_period == None: return # Never set in settings
        if not force and (self.has_cached_session(id, type) or not self.update_required(id, type)):
            return # Only cache once in a session or update_period
        self.set_cached_session(id, type, False)
        path = self.get_cached_path(id, type, format=format or get_extension_from_url(url))
        path.parent.mkdir(exist_ok=True, parents=True)
        if self.download_save(url, path):
            self.set_cached_session(id, type)
            notify_qml(url, type, id, url)

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
            return construct_qml_data(icon, type, id, url)
        return icon