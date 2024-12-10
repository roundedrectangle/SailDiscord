# This Python file uses the following encoding: utf-8

# if __name__ == "__main__":
#     pass
import sys
from pyotherside import send as qsend
from pyotherside import QObject
import pyotherside
from threading import Thread
import asyncio, shutil
from pathlib import Path
from datetime import datetime
from typing import Any, Optional, Union # TODO: use pipe (|) (needs newer python)
from concurrent.futures._base import CancelledError
from urllib import parse
import logging

from exceptions import *
from utils import *
from sending import *
from caching import Cacher

script_path = Path(__file__).absolute().parent # /usr/share/harbour-saildiscord/python
sys.path.append(str(script_path.parent / 'lib/deps')) # /usr/share/harbour-saildiscord/lib/deps
import discord, requests, aiohttp.connector

# when you save a file in QMLLive, the app is reloaded, and so is the Python login function
# if QMLLIVE_DEBUG is enabled, the on_ready function is restarted so qml app would get username and servers again
QMLLIVE_DEBUG = True

async def generate_message(message: discord.Message, is_history=False):
    t = message.type
    base = generate_base_message(message, comm.cacher, comm.client.user.id, is_history)

    ref = {'type': 0, # No reference
        'channel': '-1', 'message': '-1'}
    if message.reference:
        ref['channel'], ref['message'] = str(message.reference.channel_id), str(message.reference.message_id)
        if comm.client.ensure_current_channel(message.reference.channel_id, message.reference.guild_id):
            ref['type'] = 2 # Reply
            ref['channel'] = '-1'
        # message.flags.is_crossposted (.crossposted?) - followed channels feature, not forwarded messages
        # imagine not making a forward option for 9 years...
        elif not message.is_system(): # FIXME once discord.py-self implements https://discord.com/developers/docs/change-log#message-forwarding-rollout
            ref['type'] = 3 # Forward
        else: ref['type'] = 1 # Unknown

    event, args = '', ()
    if t in (discord.MessageType.default, discord.MessageType.reply):
        event, args = 'message', (*base, message.content, await emojify(message, comm.cacher, comm.emoji_size), ref)
    elif t == discord.MessageType.new_member:
        event, args = 'newmember', base
    else: event, args = 'unkownmessage', (*base, message.content, await emojify(message, comm.cacher, comm.emoji_size), ref, message.type.name)

    return (event, args)

async def send_message(message: Union[discord.Message, Any], is_history=False):
    """Ironically, this is for incoming messages (or already sent messages by you or anyone else in the past)."""
    event, args = await generate_message(message, is_history)
    qsend(event, *args)

class MyClient(discord.Client):
    current_server: Optional[discord.Guild] = None
    current_channel: Optional[discord.TextChannel] = None
    current_channel_deletion_pending = False
    pending_close_task: Optional[asyncio.Task] = None
    captcha_event: asyncio.Event # pyright: ignore[reportUninitializedInstanceVariable]

    async def on_ready(self):
        qsend('logged_in', self.user.display_name)
        comm.ensure_constants()
        send_servers(self.sorted_guilds_and_folders, comm.cacher)
        send_dms(self.users, comm.cacher)

        # Setup control variables
        self.captcha_event = asyncio.Event(loop=self.loop)

    async def on_message(self, message: discord.Message):
        if self.ensure_current_channel(message.channel, message.guild):
            await send_message(message)
            await message.ack()

    async def get_last_messages(self, before: Optional[Union[discord.abc.Snowflake, datetime, int]]=None, limit=30):
        ch: Union[discord.TextChannel, discord.DMChannel] = self.get_channel(self.current_channel.id) # pyright: ignore[reportAssignmentType]
        _before = before
        if isinstance(before, int):
            _before = ch.get_partial_message(before)

        gen = ch.history(limit=limit, before=_before, oldest_first=False)

        async for m in gen:
            if self.current_channel == None: # this doesn't work!
                await cancel_gen(gen)
                break
            await send_message(m, True)

    def run_asyncio_threadsafe(self, courutine, result_required=False, timeout:Optional[float]=None) -> Union[asyncio.Future, Any]:
        """Without `result_required`, no exceptions will be raised. timeout id passed to future.result()"""
        future = asyncio.run_coroutine_threadsafe(courutine, self.loop)
        if result_required: return future.result(timeout)
        return future

    def set_current_channel(self, guild: discord.Guild, channel):
        self.current_server = guild
        self.current_channel = channel
        #self.run_asyncio_threadsafe(guild.subscribe(), True)

        self.run_asyncio_threadsafe(self.get_last_messages(), True)
        self.run_asyncio_threadsafe(self.current_channel.ack())

    def unset_current_channel(self):
        #if not self.current_server: return
        #self.run_asyncio_threadsafe(self.current_server.subscribe(typing=False, activities=False, threads=False, member_updates=False), True)
        self.current_server = None
        self.current_channel = None
    
    def send_message(self, text):
        if self.ensure_current_channel():
            return self.run_asyncio_threadsafe(self.current_channel.send(text))
    
    def ensure_current_channel(self, channel=None, server=None):
        if self.current_channel == None:
            return
        cch = self.current_channel.id if isinstance(channel, int) else self.current_channel
        ccs = self.current_server.id if isinstance(server, int) else self.current_server
        ch = (cch == channel) if channel != None else True
        se = (ccs == server) if (server != None and self.current_server != None) else True
        return ch and se

    async def send_user_info(self, user_id):
        user_id = int(user_id)
        if user_id == -1:
            send_myself(self, comm.cacher)
            return
        elif self.ensure_current_channel() and self.current_server != None:
            user = await self.current_server.fetch_member_profile(user_id)
        else: user = await self.fetch_user_profile(user_id)

        send_user(user)

    def begin_disconnect(self):
        self.pending_close_task = self.loop.create_task(self.close())
    
    @property
    def sorted_guilds_and_folders(self) -> List[Union[discord.Guild, discord.GuildFolder]]:
        folders, loaded_ids = [], []
        if self.settings:
            for f in self.settings.guild_folders:
                folders.append(f if f.id or len(f) != 1 else f.guilds[0])
                loaded_ids += (g.id for g in f.guilds)
        return folders + list(g for g in self.guilds if g.id not in loaded_ids)
    
    async def handle_captcha(self, exception: discord.CaptchaRequired) -> str:
        if exception.service != 'hcaptcha':
            raise exception
        await self.loop.run_in_executor(None, comm.ensure_constants)
        qsend('openHCaptcha', exception.sitekey)
        logging.info("Captcha opened...")
        qsend("Captcha opened...")
        t = datetime.now()
        await self.captcha_event.wait()
        #await asyncio.sleep(5)
        qsend(str(datetime.now() - t))
        qsend("Awaited")
        #await self.captcha_event.wait()
        return comm.qml_shared.result

class Communicator:
    downloads: Optional[Path] = None
    cacher: Optional[Cacher] = None
    token: str = ''
    loginth: Thread
    client: MyClient
    emoji_size: Optional[int] = None
    qml_shared: Optional[QObject] = None

    def __init__(self):
        self.loginth = Thread()
        self.loginth.start()
        self.client = MyClient(guild_subscriptions=False)
        discord.utils.setup_logging()
        #pyotherside.atexit(self.disconnect)

    def login(self, token):
        if QMLLIVE_DEBUG and self.client.is_closed():
            current_proxy = self.client.http.proxy
            self.client = MyClient(guild_subscriptions=False)
            self.client.http.proxy = current_proxy
        self.token = token
        self.loginth = Thread(target=asyncio.run, args=(self._login(),))
        self.loginth.start()

    def set_constants(self, cache: str, cache_period, downloads: str, proxy: str, emoji_size: int, qml_shared: QObject):
        if self.cacher:
            self.set_cache_period(cache_period)
            self.cacher.recreate_temporary()
        else:
            self.cacher = Cacher(cache, cache_period)
        self.set_proxy(proxy)
        self.emoji_size = emoji_size
        self.qml_shared = qml_shared
        self.downloads = Path(downloads)

    def set_cache_period(self, cache_period):
        """Run when cacher is initialized but cache period was changed"""
        self.cacher.update_period = cache_period
    
    def set_proxy(self, proxy):
        if not proxy:
            self.client.http.proxy = None
            return

        p = parse.urlparse(proxy, 'http') # https://stackoverflow.com/a/21659195
        netloc = p.netloc or p.path
        path = p.path if p.netloc else ''
        p = parse.ParseResult('http', netloc, path, *p[3:])

        self.client.http.proxy = p.geturl()
        if self.cacher:
            self.cacher.proxy = p.geturl()

    def ensure_constants(self):
        while None in (self.cacher, self.downloads): pass

    def clear_cache(self):
        shutil.rmtree(self.cacher.cache, ignore_errors=True)

    async def _login(self):
        try:
            await self.client.start(self.token)
        except aiohttp.connector.ClientConnectorError as e:
            qsend("connectionError", str(e))
        except discord.errors.LoginFailure as e:
            qsend("loginFailure", str(e))
        # Once the app is being closed, pyotherside.send/qsend no longer works since ApplicationWindow is partitialy destructed.
        # We have to use something like the logging module instead
        if self.client.pending_close_task:
            await self.client.pending_close_task
            logging.info("Client was disconnected succsessfully")

    def get_channels(self, guild_id):
        g = self.client.get_guild(int(guild_id))
        if g != None:
            send_channels(g, self.client.user.id)

    def set_channel(self, guild_id, channel_id):
        if guild_id in GeneralNone:
            self.client.unset_current_channel()
        else:
            # try:
                guild = self.client.get_guild(int(guild_id)) if guild_id != '-2' else None
                channel = guild.get_channel(int(channel_id)) if guild_id != '-2' else self.client.run_asyncio_threadsafe(self.client.fetch_channel(int(channel_id)), True)
                self.client.set_current_channel(guild, channel)
            # except Exception as e:
            #     qsend(f"ERROR: couldn't set current_server: {e}. Falling back to None")
            #     self.client.unset_current_channel()
    
    def send_message(self, message_text):
        self.client.send_message(message_text)

    @exception_decorator(AttributeError, discord.NotFound)
    def get_history_messages(self, before_id):
        self.client.run_asyncio_threadsafe(self.client.get_last_messages(int(before_id)))

    @exception_decorator(CancelledError)
    def disconnect(self):
        self.cacher.clear_temporary()

        self.client.begin_disconnect()
        self.loginth.join() # App gets terminated once this function ends, so we end it only once the thread finishes
    
    @attributeerror_safe
    def request_user_info(self, user_id:int=None):
        self.client.run_asyncio_threadsafe(self.client.send_user_info(user_id or -1), True)

    def download_file(self, url, filename):
        dest = self.downloads / filename
        self.ensure_constants()
        if isurl(url):
            r = requests.get(url, stream=True)
            if r.status_code == 200:
                with open(dest, 'wb') as f:
                    for chunk in r:
                        f.write(chunk)
        else:
            shutil.copy(url, dest)

    def save_temp(self, url, name):
        """Returns saved temp file path"""
        if isurl(url):
            return str(self.cacher.save_temporary(url, name))
        else: return url

    def get_reference(self, channel_id, message_id):
        if channel_id == '-1':
            ch = self.client.current_channel
        else: ch = self.client.run_asyncio_threadsafe(self.client.fetch_channel(int(channel_id)), True)
        m = self.client.run_asyncio_threadsafe(ch.fetch_message(int(message_id)), True) # pyright: ignore[reportAttributeAccessIssue]
        event, args = self.client.run_asyncio_threadsafe(generate_message(m), True) # pyright: ignore[reportGeneralTypeIssues]
        return (event, *args)

    @attributeerror_safe
    def request_server_info(self, server_id:int=None):
        if not server_id:
            logging.warning(f"Requested info for a server with non-truthful ID: {server_id}")
            return
        try: server_id = int(server_id)
        except ValueError:
            logging.warning(f"Requested info for a server with non-integer ID: {server_id}")
            return
        send_guild_info(self.client.run_asyncio_threadsafe(self.client.fetch_guild(server_id), True))

    def send_friend_request(self, user_id: int):
        user = self.client.run_asyncio_threadsafe(self.client.fetch_user(user_id), True)
        try:
            if not user.is_friend(): # pyright: ignore[reportAttributeAccessIssue]
                self.client.run_asyncio_threadsafe(user.send_friend_request(), True) # pyright: ignore[reportAttributeAccessIssue]
        except discord.errors.CaptchaRequired as e:
            logging.info(f'Captcha required... {str(e)} {e.json} {e.errors} {e.service} {e.sitekey} {e.rqdata} {e.rqtoken}')
            qsend('captchaError', str(e))

    def set_captcha_event(self):
        # this method doesn't seem to be called while captcha_event.wait() is being awaited, so it is never awaited in the end
        self.client.captcha_event.set()
    
    def test(self):
        qsend("OK NOW WHAT")


comm = Communicator()