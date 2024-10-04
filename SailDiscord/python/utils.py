import sys
from datetime import datetime, timezone
from caching import Cacher
import pyotherside
from typing import Callable, List, Union, Optional # TODO: use collections.abc.Callable, pipe (|) (needs newer python)
import functools
from contextlib import suppress
from enum import Enum, auto
from pathlib import Path

script_path = Path(__file__).absolute().parent # /usr/share/harbour-saildiscord/python
sys.path.append(str(script_path.parent / 'lib/deps')) # /usr/share/harbour-saildiscord/lib/deps
import discord

GeneralNone = ('', None) # usage: x in GenralNone

def exception_decorator(*exceptions: Exception):
    """Generates a decorator for handling exceptions in `exceptions`. Calls `pyotherside.send` on error. Preserves __doc__, __name__ and other attributes."""
    def decorator(func: Callable):
        @functools.wraps(func)
        def f(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except exceptions as e:
                pyotherside.send(f"An error occured while running function '{func.__name__}': {type(e).__name__}: {e}")

        return f
    return decorator


attributeerror_safe = exception_decorator(AttributeError)

async def cancel_gen(agen):
    task = asyncio.create_task(agen.__anext__())
    task.cancel()
    with suppress(asyncio.CancelledError):
        await task
    await agen.aclose()

def date_to_qmlfriendly_timestamp(date: datetime):
    """Convert to UTC Unix timestamp using milliseconds"""
    return date.replace(tzinfo=timezone.utc).timestamp()*1000

class classproperty(property):
    def __get__(self, owner_self, owner_cls):
        return self.fget(owner_cls)

class ListEnum(Enum):
    @property
    def index(self):
        return list(StatusMapping).index(self)
    @classproperty
    def list(cls):
        return list(cls)
    @classmethod
    def has_value(cls, v):
        return v in set(i.value for i in cls)

class StatusMapping(ListEnum):
    UNKNOWN = discord.Status.unknown
    ONLINE = discord.Status.online
    OFFLINE = discord.Status.offline
    DND = discord.Status.dnd
    INVISIBLE = discord.Status.invisible
    IDLE = discord.Status.idle

def permissions_for(channel, user_id) -> Optional[discord.Permissions]:
    member = channel.guild.get_member(user_id)
    return None if member == None else channel.permissions_for(member)

class AttachmentMapping(Enum):
    UNKNOWN = auto()
    IMAGE = auto()

    @classmethod
    def from_attachment(cls, attachment: discord.Attachment):
        t = (attachment.content_type or '').split('/')[0] # e.g.: image/png to image
        if t == 'image':
            return cls.IMAGE
        else: return cls.UNKNOWN

def attachment_type(attachment: discord.Attachment):
    t = attachment.content_type or ''
    if t.startswith('image'):
        return AttachmentMapping.IMAGE

def convert_attachments(attachments: List[discord.Attachment], cacher: Cacher):
    """Converts to QML-friendly attachment format, object (dict)"""
    # TODO: caching, more types
    res = [{"_height": a.height, "type": AttachmentMapping.from_attachment(a).value, "realtype": a.content_type, "url": a.url, "alt": a.description or '', "spoiler": a.is_spoiler()} for a in attachments]
    if len(res) > 0:
        res[0]['maxheight'] = max((a.height or -1) if a.content_type.startswith('image') else -1 for a in attachments)
        res[0]['maxwidth'] = max((a.width or -1) if a.content_type.startswith('image') else -1 for a in attachments)
    return res