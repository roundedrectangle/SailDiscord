from __future__ import annotations
import re
from datetime import timedelta
from caching import ImageType
from pyotherside import send as qsend
from typing import Union, TYPE_CHECKING
from enum import Enum, auto
import traceback as tb

if TYPE_CHECKING:
    from typing import Any
    from caching import Cacher

from pyotherside_utils import *
import discord

GeneralNone = ('', None) # usage: x in GenralNone
AnyChannel = Union[discord.abc.GuildChannel, discord.abc.PrivateChannel]
dummy_qml_user_info = {"id": '-1', "sent": False, "name": '', "avatar": '', "bot": False, "system": False, "color": ''}
CUSTOM_EMOJI_RE_ESCAPED = re.compile(f'\\\\?({discord.PartialEmoji._CUSTOM_EMOJI_RE.pattern})') # pyright: ignore[reportPrivateUsage]

USER_MENTION_RE = re.compile(r'\\?' + r'<@([1-9][0-9]*)>')
ROLE_MENTION_RE = re.compile(r'\\?' + r'<@&([1-9][0-9]*)>')
CHANNEL_MENTION_RE = re.compile(r'\\?' + r'<#([1-9][0-9]*)>')

class classproperty(property):
    def __get__(self, owner_self, owner_cls=None):
        return self.fget(owner_cls) # pyright:ignore[reportOptionalCall]

def permissions_for(channel, user_id) -> discord.Permissions | None:
    member = channel.guild.get_member(user_id)
    return None if member == None else channel.permissions_for(member)

def hex_color(color: discord.Color):
    return '' if color in (None, discord.Color.default()) else str(color)

def dict_folder(folder: discord.GuildFolder | Any) -> dict | None:
    if not isinstance(folder, discord.GuildFolder): return
    return {
        '_id': folder.id,
        'name': folder.name,
        'color': hex_color(folder.color),
    }

def emojify(message: discord.Message | str, cacher: Cacher, size: int | None=None, pattern=discord.PartialEmoji._CUSTOM_EMOJI_RE, pattern_match_index=0): # pyright:ignore[reportPrivateUsage]
    res = message if isinstance(message, str) else message.content
    remove_size = pattern.sub('', res).strip() == '' # checks if the message only contains emojis and/or blank characters
    search = pattern.search(res)
    while search:
        e = discord.PartialEmoji.from_str(search[pattern_match_index])
        #fmt = 'gif' if e.animated else 'png' # taken from discord.PartialEmoji.url
        path = cacher.easy(e.url, e.id, ImageType.EMOJI, as_qml_data=False)
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

def escape_mentions(content: str, message: discord.Message):
    def user_mention_replacer(m: re.Match):
        result: discord.User | discord.Member | None = next(filter(lambda u: u.id == int(m[1]), message.mentions), None)
        if not result:
            return m[0]
        return f'<a class="mention" href="sailcord://user/{result.id}">@{result.display_name}</a>'
    def role_mention_replacer(m: re.Match):
        result: discord.Role | None = next(filter(lambda u: u.id == int(m[1]), message.role_mentions), None)
        if not result:
            return m[0]

        color = hex_color(result.color)
        # hex color format is #RRGGBB (RR is the red in hex and so on)
        # adding a cc in the end makes the opacity/alpha 0.8/204/0xCC
        return '<span class="mention"' + (f' style="background-color:{color}cc;color:{color}"' if color else '') + f'>@{result}</span>'
    def channel_mention_replacer(m: re.Match):
        result: discord.abc.GuildChannel | discord.Thread | None = next(filter(lambda u: u.id == int(m[1]), message.channel_mentions), None)
        if not result:
            return m[0]
        return f'<a class="mention" href="sailcord://channel/{result.id}">#{result.name}</a>'

    content = USER_MENTION_RE.sub(user_mention_replacer, content)
    content = ROLE_MENTION_RE.sub(role_mention_replacer, content)
    content = CHANNEL_MENTION_RE.sub(channel_mention_replacer, content)

    if message.mention_everyone:
        content = content.replace('@everyone', '<span class="mention">@everyone</span>')
        content = content.replace('@here', '<span class="mention">@here</span>')

    return content