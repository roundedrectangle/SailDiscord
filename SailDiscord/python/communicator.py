# This Python file uses the following encoding: utf-8

# if __name__ == "__main__":
#     pass
import sys, time
import pyotherside
from threading import Thread
import asyncio, shutil
from pathlib import Path
import itertools
from datetime import datetime, timezone
from typing import Any, Optional, Union # TODO: use pipe (|) (needs newer python)
from concurrent.futures._base import CancelledError

from exceptions import *
from utils import *
from caching import Cacher, ImageType, CachePeriodMapping

script_path = Path(__file__).absolute().parent # /usr/share/harbour-saildiscord/python
sys.path.append(str(script_path.parent / 'lib/deps')) # /usr/share/harbour-saildiscord/lib/deps
import discord

# when you save a file in QMLLive, the app is reloaded, and so is the Python login function
# if QMLLIVE_DEBUG is enabled, the on_ready function is restarted so qml app would get username and servers again
QMLLIVE_DEBUG = True

def send_servers(guilds):
    comm.ensure_cache()
    lst = list(guilds)
    for g in reversed(lst):
        count = g.member_count if g.member_count != None else -1

        icon = '' if g.icon == None else \
                str(comm.cacher.get_cached_path(g.id, ImageType.SERVER, default=g.icon))

        pyotherside.send('server', str(g.id), str(g.name), icon, count)
        if icon != '':
            comm.cacher.cache_image_bg(str(g.icon), g.id, ImageType.SERVER)

def send_channel(c, user_id):
    if c.type == discord.ChannelType.category:
        return
    #category_position = getattr(c.category, 'position', -1)+1 # Position is used instead of ID
    text_sending_allowed = c.type == discord.ChannelType.text and permissions_for(c, user_id).send_messages
    pyotherside.send(f'channel{c.guild.id}', c.id, getattr(c.category, 'name', ''), str(c.id), str(c.name), permissions_for(c, user_id).view_channel, str(getattr(getattr(c, 'type'), 'name')), text_sending_allowed)

def send_channels(guild: discord.Guild, user_id):
    for c in guild.channels:
        if c.category == None and not (getattr(c, 'type') == discord.ChannelType.category or isinstance(c, discord.CategoryChannel)):
            send_channel(c, user_id)
    for category in guild.categories:
        for c in category.channels:
            send_channel(c, user_id)

def generate_base_message(message: Union[discord.Message, Any], is_history=False):
    """Returns a sequence of the base author-dependent message callback arguments to pass at the start"""
    icon = '' if message.author.display_avatar == None else \
            str(comm.cacher.get_cached_path(message.author.id, ImageType.USER, default=message.author.display_avatar))
    
    if icon != '':
        comm.cacher.cache_image_bg(str(message.author.display_avatar), message.author.id, ImageType.USER)
    
    return (str(message.guild.id), str(message.channel.id),
            str(message.id), date_to_qmlfriendly_timestamp(message.created_at),
            str(message.author.id), message.author.id == comm.client.user.id,
            str(message.author.name), icon, is_history
        )

def send_default_message(message: Union[discord.Message, Any], is_history=False):
    pyotherside.send('message', *generate_base_message(message, is_history), message.content)

def send_message(message: Union[discord.Message, Any], is_history=False):
    """Ironically, this is for incoming messages (or already sent messages by you or anyone else in the past)."""
    t = message.type
    if t in (discord.MessageType.default, discord.MessageType.reply):
        send_default_message(message, is_history)

def send_user(user: Union[discord.MemberProfile, discord.UserProfile]):
    status, is_on_mobile = 0, False # default
    if isinstance(user, discord.MemberProfile):
        if StatusMapping.has_value(user.status):
            status = StatusMapping(user.status).index
        is_on_mobile = user.is_on_mobile()
    pyotherside.send(f"user{user.id}", user.bio or '', date_to_qmlfriendly_timestamp(user.created_at), status, is_on_mobile)

def send_myself(client: discord.Client):
    user = client.user
    status = 0 # default
    if StatusMapping.has_value(client.status):
        status = StatusMapping(client.status).index

    icon = '' if user.display_avatar == None else \
            str(comm.cacher.get_cached_path(user.id, ImageType.MYSELF, default=user.display_avatar))
    
    pyotherside.send("user", user.bio or '', date_to_qmlfriendly_timestamp(user.created_at), status, client.is_on_mobile(), icon)

    if icon != '':
        comm.cacher.cache_image_bg(str(user.display_avatar), user.id, ImageType.MYSELF)

class MyClient(discord.Client):
    current_server: Optional[discord.Guild] = None
    current_channel: Optional[discord.TextChannel] = None
    loop = None
    current_channel_deletion_pending = False

    async def on_ready(self, first_run=True):
        pyotherside.send('logged_in', str(self.user.name))
        send_servers(self.guilds)

        # Setup control variables
        self.current_server = None
        if first_run:
            self.loop = asyncio.get_running_loop()

    async def on_message(self, message):
        if self.ensure_current_channel(message.channel, message.guild):
            send_message(message)

    async def get_last_messages(self, before: Optional[Union[discord.abc.Snowflake, datetime, int]]=None, limit=30):
        ch = self.get_channel(self.current_channel.id)
        _before = before
        if isinstance(before, int):
            _before = ch.get_partial_message(before)

        gen = ch.history(limit=limit, before=_before, oldest_first=False)

        async for m in gen:
            if self.current_channel == None: # this doesn't work!
                cancel_gen(gen)
                break
            send_message(m, True)

    def run_asyncio_threadsafe(self, courutine, result_required=False, timeout:Optional[float]=None):
        """Without `result_required`, no exceptions will be raised. timeout id passed to future.result()"""
        future = asyncio.run_coroutine_threadsafe(courutine, self.loop)
        if result_required: return future.result(timeout)
        return future

    def set_current_channel(self, guild, channel):
        self.current_server = guild
        self.current_channel = channel
        # This will be used when discord.py-self 2.1 will be out.
        #asyncio.run(guild.subscribe())

        self.run_asyncio_threadsafe(self.get_last_messages())
        self.run_asyncio_threadsafe(self.current_channel.ack())

    def unset_current_channel(self):
        # This will be used when discord.py-self 2.1 will be out.
        #if self.current_server == None:
        #    return
        #asyncio.run(self.current_server.subscribe(typing=False, activities=False, threads=False, member_updates=False))
        self.current_server = None
        self.current_channel = None
    
    def send_message(self, text):
        if self.ensure_current_channel():
            return self.run_asyncio_threadsafe(self.current_channel.send(text))
    
    def ensure_current_channel(self, channel=None, server=None):
        if (self.current_server == None) or (self.current_channel == None):
            return
        ch = (self.current_channel == channel) if channel != None else True
        se = (self.current_server == server) if server != None else True
        return ch and se

    async def send_user_info(self, user_id):
        user_id = int(user_id)
        if user_id == -1:
            send_myself(self)
            return
        elif self.ensure_current_channel():
            user = await self.current_server.fetch_member_profile(user_id)
        else: user = await self.fetch_user_profile(user_id)

        #await self.loop.run_in_executor(None, send_user, user)
        send_user(user)
    

class Communicator:
    def __init__(self):
        self.loginth = Thread()
        self.loginth.start()
        self.client = MyClient(guild_subscriptions=False)
        self.token = ''
        self.cacher = None

    def login(self, token):
        if self.loginth.is_alive():
            if QMLLIVE_DEBUG:
                asyncio.run(self.client.on_ready(False))
            return
        self.token = token
        self.loginth = Thread(target=self._login)
        self.loginth.start()

    def set_cache(self, cache, cache_period):
        if self.cacher != None:
            self.set_cache_period(cache_period)
            return
        self.cacher = Cacher(cache, cache_period)
        #pyotherside.send(self.cacher.update_required(1021310444167778364, ImageType.SERVER))

    def set_cache_period(self, cache_period):
        """Run when cacher is initialized but cache period was changed"""
        self.cacher.update_period = cache_period

    def ensure_cache(self):
        while self.cacher == None: pass

    def clear_cache(self):
        shutil.rmtree(self.cacher.cache, ignore_errors=True)

    def _login(self):
        self.client.run(self.token)

    def get_channels(self, guild_id):
        g = self.client.get_guild(int(guild_id))
        if g != None:
            send_channels(g, self.client.user.id)

    def set_channel(self, guild_id, channel_id):
        if guild_id in GeneralNone:
            self.client.unset_current_channel()
        else:
            try:
                guild = self.client.get_guild(int(guild_id))
                channel = guild.get_channel(int(channel_id))
                self.client.set_current_channel(guild, channel)
            except Exception as e:
                pyotherside.send(f"ERROR: couldn't set current_server: {e}. Falling back to None")
                self.client.unset_current_channel()
    
    def send_message(self, message_text):
        self.client.send_message(message_text)

    @exception_decorator(AttributeError, discord.NotFound)
    def get_history_messages(self, before_id):
        self.client.run_asyncio_threadsafe(self.client.get_last_messages(int(before_id)))

    @exception_decorator(CancelledError)
    def disconnect(self):
        self.client.run_asyncio_threadsafe(self.client.close(), True)
    
    #@attributeerror_safe
    def request_user_info(self, user_id:int=None):
        self.client.run_asyncio_threadsafe(self.client.send_user_info(-1 if user_id in (None, "") else user_id), True)


comm = Communicator()