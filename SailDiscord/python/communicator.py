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
from typing import Optional, Union

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

def permissions_for(channel, user_id) -> discord.Permissions:
    member = channel.guild.get_member(user_id)
    return None if member == None else channel.permissions_for(member)

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


def send_message(message, is_history=False):
    """Ironically, this is for incoming messages (or already sent messages by you or anyone else in the past)."""

    icon = '' if message.author.display_avatar == None else \
            str(comm.cacher.get_cached_path(message.author.id, ImageType.USER, default=message.author.display_avatar))

    pyotherside.send('message',
        str(message.guild.id), str(message.channel.id),
        str(message.id), str(message.author.name), str(message.content),
        icon, message.author.id == comm.client.user.id,
        message.created_at.replace(tzinfo=timezone.utc).timestamp()*1000, # Convert to UTC Unix timestamp using milliseconds
        is_history)

    if icon != '':
        comm.cacher.cache_image_bg(str(message.author.display_avatar), message.author.id, ImageType.USER)

class MyClient(discord.Client):
    current_server: Optional[discord.Guild] = None
    current_channel: Optional[discord.abc.GuildChannel] = None
    loop = None

    async def on_ready(self, first_run=True):
        pyotherside.send('logged_in', str(self.user.name))
        send_servers(self.guilds)

        # Setup control variables
        self.current_server = None
        if first_run:
            self.loop = asyncio.get_running_loop()

    async def on_message(self, message):
        if self.ensure_current_channel(message.channel, message.guild):
            #pyotherside.send(f"Got message from {message.author} in server {message.guild.name}: {message.content}")
            send_message(message)
            #await message.channel.send('pong')

    async def get_last_messages(self, before: Optional[Union[discord.abc.Snowflake, datetime]]=None, limit=30):
        # this_thread_channel = self.current_channel
        # history = this_thread_channel.history(limit=None)
        # async for m in history:
        #     send_message(m, True)
        #     if self.current_channel != this_thread_channel:
        #         pyotherside.send("Channel closed!")
        #         await history.aclose()
        async for m in self.current_channel.history(limit=limit, before=before, oldest_first=False):
            send_message(m, True)

    def run_asyncio_threadsafe(self, courutine):
        return asyncio.run_coroutine_threadsafe(courutine, self.loop)

    def set_current_channel(self, guild, channel):
        self.current_server = guild
        self.current_channel = channel
        # This will be used when discord.py-self 2.1 will be out.
        #asyncio.run(guild.subscribe())

        self.run_asyncio_threadsafe(self.get_last_messages())

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
        if guild_id in [None, '']:
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

    async def lazy_last_messages(self, channel_id, after_id):
        ch = self.client.get_channel(int(channel_id))
        coro = ch.fetch_message(int(after_id))
        pyotherside.send(f"Awaiting message {after_id} for channel {ch.name}, {coro}")
        msg = self.client.run_asyncio_threadsafe(coro)
        await msg

        pyotherside.send(f"History requested after message {msg.result().content}")

    @exception_decorator(AttributeError, discord.NotFound)
    def get_history_messages(self, channel_id, before_id):
        ch = self.client.get_channel(int(channel_id))
        coro = ch.fetch_message(int(before_id))
        pyotherside.send(f"Awaiting message {before_id} for channel {ch.name}, {coro}")
        msg = self.client.run_asyncio_threadsafe(coro)
        msg.add_done_callback(lambda msg: pyotherside.send(f"History requested after message {msg.result().content}"))

        #self.client.run_asyncio_threadsafe(self.lazy_last_messages(channel_id, before_id))


comm = Communicator()
