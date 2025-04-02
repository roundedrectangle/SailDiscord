from __future__ import annotations
import sys, re
from datetime import datetime, timezone, timedelta
from caching import Cacher, ImageType
from pyotherside import send as qsend
from typing import Any, Callable, List, Union # TODO: use collections.abc.Callable, pipe (|) (needs newer python)
import functools
from contextlib import suppress
from enum import Enum, auto
from pathlib import Path
import asyncio
import urllib.parse
import traceback as tb

script_path = Path(__file__).absolute().parent # /usr/share/harbour-saildiscord/python
sys.path.append(str(script_path.parent / 'lib/deps')) # /usr/share/harbour-saildiscord/lib/deps
import discord

GeneralNone = ('', None) # usage: x in GenralNone
AnyChannel = Union[discord.abc.GuildChannel, discord.abc.PrivateChannel]
dummy_qml_user_info = {"id": '-1', "sent": False, "name": '', "avatar": '', "bot": False, "system": False, "color": ''}
CUSTOM_EMOJI_RE_ESCAPED = re.compile(f'\\\\?({discord.PartialEmoji._CUSTOM_EMOJI_RE.pattern})') # pyright: ignore[reportPrivateUsage]

def exception_decorator(*exceptions: Exception):
    """Generates a decorator for handling exceptions in `exceptions`. Calls `pyotherside.send` on error. Preserves __doc__, __name__ and other attributes."""
    def decorator(func: Callable):
        @functools.wraps(func)
        def f(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except exceptions as e: # pyright: ignore[reportGeneralTypeIssues]
                qsend(f"An error occured while running function '{func.__name__}': {type(e).__name__}: {e}")

        return f
    return decorator


attributeerror_safe = exception_decorator(AttributeError)

async def cancel_gen(agen):
    task = asyncio.create_task(agen.__anext__())
    task.cancel()
    with suppress(asyncio.CancelledError):
        await task
    await agen.aclose()

def qml_date(date: datetime):
    """Convert to UTC Unix timestamp using milliseconds"""
    return date.replace(tzinfo=timezone.utc).timestamp()*1000

class classproperty(property):
    def __get__(self, owner_self, owner_cls=None):
        return self.fget(owner_cls) # pyright:ignore[reportOptionalCall]

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

def permissions_for(channel, user_id) -> discord.Permissions | None:
    member = channel.guild.get_member(user_id)
    return None if member == None else channel.permissions_for(member)

class AttachmentMapping(Enum):
    UNKNOWN = auto()
    IMAGE = auto()
    ANIMATED_IMAGE = auto()

    @classmethod
    def from_attachment(cls, attachment: discord.Attachment):
        parts = (attachment.content_type or '').split('/') # e.g.: image/png for image
        t = parts[0]
        if t == 'image':
            if parts[1] == 'gif':
                return cls.ANIMATED_IMAGE
            return cls.IMAGE
        else: return cls.UNKNOWN

def attachment_type(attachment: discord.Attachment):
    t = attachment.content_type or ''
    if t.startswith('image'):
        return AttachmentMapping.IMAGE

def convert_attachments(attachments: List[discord.Attachment]):
    """Converts to QML-friendly attachment format, object (dict)"""
    # TODO: caching, more types
    res = [{"maxheight": -2, "maxwidth": -2, "filename": a.filename, "_height": a.height, "type": AttachmentMapping.from_attachment(a).value, "realtype": None if a.content_type is None else a.content_type.split(';')[0], "url": a.url, "alt": a.description or '', "spoiler": a.is_spoiler()} for a in attachments]
    if len(res) > 0:
        res[0]['maxheight'] = max((a.height or -1) if (a.content_type or '').startswith('image') else -1 for a in attachments)
        res[0]['maxwidth'] = max((a.width or -1) if (a.content_type or '').startswith('image') else -1 for a in attachments)
    return res

def hex_color(color: discord.Color):
    return '' if color in (None, discord.Color.default()) else str(color)

def dict_folder(folder: discord.GuildFolder | Any) -> dict | None:
    if not isinstance(folder, discord.GuildFolder): return
    return {
        '_id': folder.id,
        'name': folder.name,
        'color': hex_color(folder.color),
    }

def isurl(obj: str):
    """Returns True if an object is an internet URL"""
    return urllib.parse.urlparse(obj).scheme != '' #not in ('file','')

def emojify(message: discord.Message | str, cacher: Cacher, size: int | None=None, pattern=discord.PartialEmoji._CUSTOM_EMOJI_RE, pattern_match_index=0): # pyright:ignore[reportPrivateUsage]
    res = message if isinstance(message, str) else message.content
    remove_size = pattern.sub('', res).strip() == '' # checks if the message only contains emojis and/or blank characters
    search = pattern.search(res)
    while search:
        e = discord.PartialEmoji.from_str(search[pattern_match_index])
        fmt = 'gif' if e.animated else 'png'
        path = str(cacher.get_cached_path(e.id, ImageType.EMOJI, e.url, fmt))
        cacher.cache_image_bg(e.url, e.id, ImageType.EMOJI, fmt)
        res = res[:search.start()] + '<img '+ ('' if size is None or remove_size else f'width="{size}" height="{size}" ') +f'class="emoji" draggable="false" alt=":{e.name}:" src="{path}">' + res[search.end():]
        search = pattern.search(res)
    return res

def usernames(user: discord.User | discord.Member):
    additional = {'global': '', 'username': ''}
    if getattr(user, 'nick', None):
        if user.global_name:
            additional['global'] = user.global_name
    additional['username'] = user.name
    return additional

def format_exc(e: Exception):
    return f'{type(e).__name__}: {e}\n' + ''.join(tb.format_exception(None,e,e.__traceback__))

def group_name(group: discord.GroupChannel):
    if group.name:
        return (group.name,)*2
    recipients = [x.display_name for x in group.recipients if x.id != group.me.id]
    return ', '.join([f'@{x}' for x in recipients]), ', '.join(recipients)

async def is_channel_unread(channel: discord.TextChannel | discord.DMChannel | discord.GroupChannel, return_none = True) -> bool | None:
    try:
        return (await channel.fetch_message(channel.last_message_id)).created_at - (await channel.fetch_message(channel.acked_message_id)).created_at > timedelta()
    except:
        return None if return_none else False

def show_error(name, info = '', other = None):
    qsend('error', name, str(info), other)