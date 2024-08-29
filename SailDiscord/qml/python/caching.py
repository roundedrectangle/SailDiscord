from enum import Enum, auto
from pathlib import Path
from datetime import datetime, timezone, timedelta
from threading import Thread
import pyotherside

class Cache:
    """Cache operations"""

    class ImageType(Enum):
        SERVER = auto()
        USER = auto()

    @classmethod
    def _cached_path(cls, id, type: ImageType):
        return Path(comm.cache) / type.name.lower() / f"{id}.png"

    @classmethod
    def get_cached_path(cls, id, type: ImageType, default=None):
        """If default is not None and any of these:
        - path does not exist
        - path was cached in this session (finished only)
        - path contains broken image
        then default is returned"""
        path = cls._cached_path(id, type)
        if default != None:
            if cls.verify_image(id, type):
                return default
        return path

    @classmethod
    def _update_required(cls, path: Path, minimum_time: timedelta):
        """Returns if the file at `path` was modified more or `minimum_time` ago."""
        mod = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
        pyotherside.send(str(mod), str(path))
        now = datetime.now(timezone.utc)
        dif = now-mod
        return dif >= minimum_time

    @classmethod
    def update_required(cls, id, type: ImageType):
        t = timedelta(1)

        p = cls.get_cached_path(id, type)
        if not p.exists():
            return
        return cls._update_required(p, t)

    @classmethod
    def _verify_pillow(cls, path):
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

    @classmethod
    def broken_image(cls, id, type: ImageType):
        """Checks if an image is broken or image is not cached. Returns None if not or an error if yes."""
        path = cls.get_cached_path(id, type)
        if not path.exists():
            return DoesNotExistError
        return cls._verify_pillow(path)
    
    @classmethod
    def verify_image(cls, id, type: ImageType):
        """Returns if an image is not broken and is cached"""
        return cls.broken_image(id, type) == None

    @classmethod
    def download_pillow(cls, url):
        """Generate a Pillow object from downloaded URL. Returns None if URL is not valid."""
        r = requests.get(url, stream=True)
        if r.status_code != 200: return
        im = Image.open(r.raw)
        return im

    @classmethod
    def cache_image(cls, url, id, type: ImageType):
        if cls.has_cached_session(id, type):
            return # Only cache once in a session
        cls.set_cached_session(id, type, False)
        im = cls.download_pillow(url)
        if im == None: return
        comm.ensure_cache()
        path = cls.get_cached_path(id, type)
        path.parent.mkdir(exist_ok=True, parents=True)
        im.save(path) # We use Pillow to convert JPEG, GIF and others to PNG
        cls.set_cached_session(id, type)

    @classmethod
    def cache_image_bg(cls, url, id, type: ImageType):
        Thread(target=cls.cache_image, args=(url, id, type)).start()

    @classmethod
    def ensure_cached_session(cls):
        """Returns True if stuff cached in this session was initialized"""
        if not hasattr(cls, 'session_cached'):
            cls.session_cached = {}
            for im in cls.ImageType:
                cls.session_cached[im.name.lower()] = {}
            return True
        return False

    @classmethod
    def set_cached_session(cls, id, type: ImageType, finished=True):
        cls.ensure_cached_session()
        cls.session_cached[type.name.lower()][str(id)] = finished
        #pyotherside.send(f"SET {cls.session_cached} {id} {id in cls.session_cached[type.name.lower()]}")

    @classmethod
    def has_cached_session(cls, id, type: ImageType, finished=None):
        """Returns was ever the image cached in the current session.
        
        finished:
            - True for checking finished only
            - False for checking in progress only
            - Anything else (or None) for checking any/both"""
        cls.ensure_cached_session()
        #pyotherside.send(f"HAS {cls.session_cached} {str(id)} {str(id) in cls.session_cached[type.name.lower()]}")

        if str(id) not in cls.session_cached[type.name.lower()]:
            return False
        
        if finished in [False, True]:
            return cls.session_cached[type.name.lower()][str(id)] == finished
        else:
            return True
  