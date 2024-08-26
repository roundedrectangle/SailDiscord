# This Python file uses the following encoding: utf-8

# if __name__ == "__main__":
#     pass
import sys, time, io
import pyotherside
from threading import Thread
import asyncio, shutil
from enum import Enum, auto
from pathlib import Path

sys.path.append(Path(sys.path[0]).parent / 'deps')
import discord, requests
from PIL import Image

# when you save a file in QMLLive, the app is reloaded, and so are the Python login function
# if QMLLIVE_DEBUG is enabled, the on_ready function is restarted so qml app would get username and servers again
QMLLIVE_DEBUG = True

class Cache:
    """Cache operations"""

    class ImageType(Enum):
        SERVER = auto()
        USER = auto()

    @classmethod
    def get_cached_path(cls, id, type: ImageType, default=None):
        """If default is not None and path does not exist default is returned"""
        path = Path(comm.cache) / type.name.lower() / f"{id}.png"
        if ((default != None) and (not path.exists())) and cls.has_cached_session(id, type, False):
            return default
        return path

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
            # Only cache once in a session
            return
        cls.set_cached_session(id, type, True)
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
        """Returns True if stuff cached in this session were initialized"""
        if not hasattr(cls, 'session_cached'):
            cls.session_cached = {}
            for im in cls.ImageType:
                cls.session_cached[im.name.lower()] = {}
            return True
        return False

    @classmethod
    def set_cached_session(cls, id, type: ImageType, in_progress=False):
        cls.ensure_cached_session()
        cls.session_cached[type.name.lower()][str(id)] = in_progress
        pyotherside.send("SET "+str(cls.session_cached))

    @classmethod
    def has_cached_session(cls, id, type: ImageType, in_progress=None):
        """in_progress:
            - True for in progress only
            - False for finished only
            - None/anything else for any/both"""
        cls.ensure_cached_session()
        pyotherside.send("HAS "+str(cls.session_cached))

        if id not in cls.session_cached[type.name.lower()]:
            return False
        
        if in_progress in [False, True]:
            return cls.session_cached[type.name.lower()][id] == in_progress
        else:
            return True
        


def send_servers(guilds):
    lst = list(guilds)
    for g in reversed(lst):
        count = g.member_count if g.member_count != None else -1

        icon = '' if g.icon == None else \
                str(Cache.get_cached_path(g.id, Cache.ImageType.SERVER, default=g.icon))

        pyotherside.send('server', str(g.id), str(g.name), icon, count)
        if icon != '':
            Cache.cache_image_bg(str(g.icon), g.id, Cache.ImageType.SERVER)

def send_categories(guild, user_id):
    pyotherside.send('category', str(guild.id), str(-1), "", True)
    for c in guild.categories:
        has_permissions = True # default
        member = guild.get_member(user_id)
        if member != None:
            has_permissions = c.permissions_for(member).view_channel
        pyotherside.send('category', str(guild.id), str(c.id), str(c.name), has_permissions)

def send_channels(category, user_id):
    for c in reversed(category.channels):
        has_permissions = True # default
        member = category.guild.get_member(user_id)
        if member != None:
            has_permissions = c.permissions_for(member).view_channel
        pyotherside.send(f'channel{category.guild.id} {category.id}', str(c.id), str(c.name), has_permissions, str(getattr(getattr(c, 'type'), 'name')))

def send_channels_no_category(guild, user_id):
    for c in reversed(guild.channels):
        if c.category == None and not (getattr(c, 'type') == discord.ChannelType.category or isinstance(c, discord.CategoryChannel)):
            has_permissions = True # default
            member = c.guild.get_member(user_id)
            if member != None:
                has_permissions = c.permissions_for(member).view_channel
            pyotherside.send(f'channel{c.guild.id} -1', str(c.id), str(c.name), has_permissions, str(getattr(getattr(c, 'type'), 'name')))

def send_message(message, is_history=False):
    """Ironically, this is for incoming messages (or already sent messages by you or anyone else in the past)."""

    icon = '' if message.author.display_avatar == None else \
            str(Cache.get_cached_path(message.author.id, Cache.ImageType.USER, default=message.author.display_avatar))

    pyotherside.send('message',
        str(message.guild.id), str(message.channel.id),
        str(message.id), str(message.author.name), str(message.content),
        icon, message.author.id == comm.client.user.id,
        is_history)

    if icon != '':
        Cache.cache_image_bg(str(message.author.display_avatar), message.author.id, Cache.ImageType.USER)

class MyClient(discord.Client):
    current_server = None
    current_channel = None
    loop = None

    async def on_ready(self, first_run=True):
        pyotherside.send('logged_in', str(self.user.name))
        send_servers(self.guilds)

        # Setup control variables
        self.current_server = None
        if first_run:
            self.loop = asyncio.get_running_loop()

    async def on_message(self, message):
        if self.current_server == None or self.current_channel == None:
            return
        if message.guild.id == self.current_server.id and message.channel.id == self.current_channel.id:
            #pyotherside.send(f"Got message from {message.author} in server {message.guild.name}: {message.content}")
            send_message(message)
            #await message.channel.send('pong')

    async def get_last_messages(self):
        async for m in self.current_channel.history(limit=30):
            send_message(m, True)

    def set_current_channel(self, guild, channel):
        self.current_server = guild
        self.current_channel = channel
        # This will be used when discord.py-self 2.1 will be out.
        #asyncio.run(guild.subscribe())

        asyncio.run_coroutine_threadsafe(self.get_last_messages(), self.loop)

    def unset_current_channel(self):
        # This will be used when discord.py-self 2.1 will be out.
        #if self.current_server == None:
        #    return
        #asyncio.run(self.current_server.subscribe(typing=False, activities=False, threads=False, member_updates=False))
        self.current_server = None
        self.current_channel = None

class Communicator:
    def __init__(self):
        self.loginth = Thread()
        self.loginth.start()
        self.client = MyClient(guild_subscriptions=False)
        self.token = ''
        self.cache = ''

    def login(self, token):
        if self.loginth.is_alive():
            if QMLLIVE_DEBUG:
                asyncio.run(self.client.on_ready(False))
            return
        self.token = token
        self.loginth = Thread(target=self._login)
        self.loginth.start()

    def set_cache(self, cache):
        self.cache = str(cache)

    def ensure_cache(self):
        while len(self.cache) <= 0: pass

    def clear_cache(self):
        shutil.rmtree(Path(self.cache), ignore_errors=True)

    def _login(self):
        self.client.run(self.token)

    def get_categories(self, guild_id):
        #self.set_server(guild_id)
        g = self.client.get_guild(int(guild_id))
        if g == None:
            return
        send_categories(g, self.client.user.id)

    def get_channels(self, guild_id, category_id):
        g = self.client.get_guild(int(guild_id))
        if g != None:
            if int(category_id) == -1:
                #pyotherside.send("requested channels for "+guild_id+" categoryid "+category_id)
                send_channels_no_category(g, self.client.user.id)
                return
            c = g.get_channel(int(category_id))
            if c != None:
                send_channels(c, self.client.user.id)

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


comm = Communicator()
