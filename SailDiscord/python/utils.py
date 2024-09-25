from datetime import datetime, timezone
import pyotherside
from typing import Callable, Union, Optional # TODO: use collections.abc.Callable, pipe (|) (needs newer python)
import functools
import time
from contextlib import suppress
from enum import Enum
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