from __future__ import annotations

import sys
# These aren't available in release builds with packaged library,
# but may be installed on the device when started without Sailjail and cause some issues:
sys.modules['httpx'] = None
sys.modules['requests'] = None

from pyotherside import send as qsend
from threading import Thread
import asyncio, shutil
from pathlib import Path
from datetime import datetime
from typing import Any
from concurrent.futures._base import CancelledError
import logging
import traceback as tb

from exceptions import *
from utils import *
from sending import *
from caching import Cacher

from pyotherside_utils import *
import discord, aiohttp.connector

# when you save a file in QMLLive, the app is reloaded, and so is the Python login function
# if QMLLIVE_DEBUG is enabled, the on_ready function is restarted so qml app would get username and servers again
QMLLIVE_DEBUG = True

async def generate_message(message: discord.Message, is_history=False):
    base = generate_base_message(message, comm.cacher, comm.client.user.id, is_history)

    ref = {'type': 0, # No reference
        #'channel': '-1', 'message': '-1',
        'state': 0, # 0: failed to load, 1: deleted, 2: loaded, 3: loaded from snapshot
        'resolvedType': '', 'resolved': {}}
    if message.reference:
        #ref['channel'], ref['message'] = str(message.reference.channel_id), str(message.reference.message_id)
        ref['type'] = 1 if message.reference.type == discord.MessageReferenceType.reply else \
            2 if message.reference.type == discord.MessageReferenceType.forward else 0

        if message.reference.resolved is None:
            # First check if there is a snapshot attached
            if message.message_snapshots:
                s = message.message_snapshots[-1]
                if s.cached_message:
                    ref['resolvedType'], ref['resolved'] = await generate_message(s.cached_message)
                    ref['state'] = 2
                else:
                    # Construct everything manually
                    
                    ref['resolvedType'], extra = generate_extra_message(s)
                    ref['resolved'] = (
                        '-1', '-1', '-1', qml_date(s.created_at), bool(message.edited_at), dummy_qml_user_info, False, convert_attachments(s.attachments),
                        *extra,
                        )
                    ref['state'] = 3
            else:
                # Try to resolve manually
                try:
                    m = await (await comm.client.fetch_channel(message.reference.channel_id)).fetch_message(message.reference.message_id) # pyright: ignore[reportAttributeAccessIssue]
                    ref['resolvedType'], ref['resolved'] = await generate_message(m)
                    ref['state'] = 2
                except Exception as e:
                    show_error('reference', format_exc(e))
                    ref['state'] = 0
        elif isinstance(message.reference.resolved, discord.DeletedReferencedMessage):
            ref['state'] = 1
        else:
            ref['resolvedType'], ref['resolved'] = await generate_message(message.reference.resolved)
            ref['state'] = 2

    event, args = generate_extra_message(message, comm.cacher, comm.emoji_size, ref)
    return event, base+args

async def send_message(message: discord.Message | Any, is_history=False):
    """Ironically, this is for incoming messages (or already sent messages by you or anyone else in the past)."""
    try:
        event, args = await generate_message(message, is_history)
        qsend(event, *args)
    except Exception as e:
        show_error('message', format_exc(e))

async def send_edited_message(before_id: int, after: discord.Message | Any):
    """Ironically, this is for incoming messages (or already sent messages by you or anyone else in the past)."""
    event, args = await generate_message(after)
    qsend('messageedit', before_id, event, args)

class MyClient(discord.Client):
    current_server: discord.Guild | None = None
    current_channel: discord.TextChannel | None = None
    current_channel_deletion_pending = False
    pending_close_task: asyncio.Task | None = None

    async def on_ready(self):
        comm.ensure_constants()
        comm.set_user_agent()

        qsend('logged_in', self.user.display_name, comm.cacher.easy(self.user.display_avatar, self.user.id, ImageType.MYSELF),
            StatusMapping(self.status).index if StatusMapping.has_value(self.status) else 0,
            self.is_on_mobile(),
        )
        
        send_servers(self.sorted_guilds_and_folders, comm.cacher)
        send_dms(self.private_channels, comm.cacher, self.run_asyncio_threadsafe, comm.send_unread)

    async def on_message(self, message: discord.Message):
        if self.ensure_current_channel(message.channel, message.guild):
            await send_message(message)
            await message.ack()
        comm.ensure_constants()
        if comm.send_unread and message.author != self.user and message.channel != self.current_channel:
            if message.guild and self.current_server == message.guild:
                qsend(f'channelUpdate{message.guild.id}', str(message.channel.id), True, message.channel.mention_count) # pyright:ignore[reportAttributeAccessIssue]
            elif isinstance(message.channel, (discord.GroupChannel, discord.DMChannel)):
                qsend('dmUpdate', str(message.channel.id), True, getattr(message.channel, 'mention_count', 0))

    async def on_message_edit(self, before: discord.Message, after: discord.Message):
        if self.ensure_current_channel(before.channel, before.guild):
            await send_edited_message(before.id, after)
            await after.ack()

    async def on_message_delete(self, message: discord.Message):
        if self.ensure_current_channel(message.channel, message.guild):
            qsend('messagedelete', message.id)

    async def get_last_messages(self, before: discord.abc.Snowflake | datetime | int | None = None, limit=30):
        ch: discord.TextChannel | discord.DMChannel = self.get_channel(self.current_channel.id) # pyright: ignore[reportAssignmentType]
        _before = before
        if isinstance(before, int):
            _before = ch.get_partial_message(before)

        gen = ch.history(limit=limit, before=_before, oldest_first=False)

        async for m in gen:
            if self.current_channel == None: # this doesn't work!
                await cancel_gen(gen)
                break
            await send_message(m, True)

    def run_asyncio_threadsafe(self, courutine, result_required=True, timeout:float | None=None) -> Any:
        """Without `result_required`, no exceptions will be raised. timeout id passed to future.result()"""
        future = asyncio.run_coroutine_threadsafe(courutine, self.loop)
        if result_required: return future.result(timeout)
        return future

    def set_current_channel(self, guild: discord.Guild | None, channel):
        if guild:
            self.current_server = guild
        self.current_channel = channel
        #self.run_asyncio_threadsafe(guild.subscribe(typing=True, member_updates=True))

        self.run_asyncio_threadsafe(self.get_last_messages())
        self.run_asyncio_threadsafe(self.current_channel.ack(), False)
        comm.ensure_constants()
        if comm.send_unread:
            if guild:
                qsend(f'channelUpdate{guild.id}', self.current_channel.id, False, 0)
            else:
                qsend('dmUpdate', self.current_channel.id, False, 0)

    def unset_current_channel(self):
        #if not self.current_server: return
        #self.run_asyncio_threadsafe(self.current_server.subscribe(typing=False, activities=False, threads=False, member_updates=False))
        #self.current_server = None
        self.current_channel = None
    
    def send_message(self, text):
        if self.ensure_current_channel():
            return self.run_asyncio_threadsafe(self.current_channel.send(text), False)
    
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
            send_myself(self)
            return
        elif self.ensure_current_channel() and self.current_server != None:
            try: user = await self.current_server.fetch_member_profile(user_id)
            except: user = await self.fetch_user_profile(user_id)
        else: user = await self.fetch_user_profile(user_id)

        send_user(user)

    def begin_disconnect(self):
        self.pending_close_task = self.loop.create_task(self.close())
    
    @property
    def sorted_guilds_and_folders(self) -> List[discord.Guild | discord.GuildFolder]:
        folders, loaded_ids = [], []
        if self.settings:
            for f in self.settings.guild_folders:
                folders.append(f if f.id or len(f) != 1 else f.guilds[0])
                loaded_ids += (g.id for g in f.guilds)
        return folders + list(g for g in self.guilds if g.id not in loaded_ids)
    
    async def get_message(self, message_id) -> discord.Message:
        message_id = int(message_id)
        if not self.current_channel:
            raise RuntimeError("Current channel was not set but delete requested")
        return await self.current_channel.fetch_message(message_id)

    async def on_error(self, event_method: str, /, *args: Any, **kwargs: Any) -> None:
        await super().on_error(event_method, *args, **kwargs)
        show_error("discord", event_method, tb.format_exc())

class Communicator:
    downloads: Path | None = None
    cacher: Cacher | None = None
    temp: TemporaryManager | None = None
    token: str = ''
    loginth: Thread
    client: MyClient
    emoji_size: int | None = None
    send_unread: bool | None = None
    active: bool = True

    def __init__(self):
        self.loginth = Thread()
        self.loginth.start()
        self.client = MyClient()
        discord.utils.setup_logging()

    def login(self, token):
        if QMLLIVE_DEBUG and self.client.is_closed():
            current_proxy = self.client.http.proxy
            self.client = MyClient(guild_subscriptions=False)
            self.client.http.proxy = current_proxy
        self.token = token
        self.loginth = Thread(target=asyncio.run, args=(self._login(),))
        self.loginth.start()

    def set_constants(self, cache: str, cache_period, downloads: str, proxy: str, emoji_size: int, send_unread: bool, active: bool):
        self.set_active(active)
        self.emoji_size = emoji_size
        self.send_unread = send_unread
        if self.cacher:
            self.set_cache_period(cache_period)
        else:
            self.cacher = Cacher(cache, cache_period)
        if self.temp:
            self.temp.recreate_temporary()
        else:
            self.temp = TemporaryManager(cache)
        
        self.set_proxy(proxy)
        self.downloads = Path(downloads)

    def set_cache_period(self, cache_period):
        """Run when cacher is initialized but cache period was changed"""
        self.cacher.update_period = cache_period
    
    def set_proxy(self, proxy):
        if not proxy:
            self.client.http.proxy = None
            if self.cacher:
                self.cacher.proxy = None
            if self.temp:
                self.temp.proxy = None
            return

        p = convert_proxy(proxy)
        self.client.http.proxy = p
        if self.cacher:
            self.cacher.proxy = p
        if self.temp:
            self.temp.proxy = p
    
    def set_user_agent(self):
        if not self.client.http.user_agent:
            return
        if self.cacher:
            self.cacher.user_agent = self.client.http.user_agent
        if self.temp:
            self.temp.user_agent = self.client.http.user_agent

    def set_active(self, active):
        self.active = active

    def ensure_constants(self):
        while None in (self.cacher, self.downloads): pass

    def clear_cache(self):
        shutil.rmtree(self.cacher.cache, ignore_errors=True)

    async def _login(self):
        try:
            await self.client.start(self.token)
        except aiohttp.connector.ClientConnectorError as e:
            show_error('connection', e)
        except discord.errors.LoginFailure as e:
            show_error('login', e)
        # Once the app is being closed, pyotherside.send/qsend no longer works since ApplicationWindow is partitialy destructed.
        # We have to use something like the logging module instead
        if self.client.pending_close_task:
            logging.info("Running close task")
            await self.client.pending_close_task
        logging.info("Client was disconnected succsessfully")

    def get_channels(self, guild_id):
        g = self.client.get_guild(int(guild_id))
        if g != None:
            comm.ensure_constants()
            try: self.client.current_server = self.client.get_guild(int(guild_id))
            except: pass
            send_channels(g, self.client.user.id, self.client.run_asyncio_threadsafe, comm.send_unread, lambda: self.client.current_server)
    
    def unset_server(self, guild_id):
        if not self.client.current_channel and self.client.current_server and self.client.current_server.id == guild_id:
            self.client.current_server = None

    def set_channel(self, guild_id, channel_id):
        if guild_id in GeneralNone:
            self.client.unset_current_channel()
        else:
            try:
                guild = self.client.current_server or (self.client.get_guild(int(guild_id)) if guild_id != '-2' else None)
                channel = guild.get_channel(int(channel_id)) if guild_id != '-2' else self.client.run_asyncio_threadsafe(self.client.fetch_channel(int(channel_id)))
                self.client.set_current_channel(guild, channel)
            except Exception as e:
                self.client.unset_current_channel()
                qsend('channel', format_exc(e))
    
    def send_message(self, message_text):
        self.client.send_message(message_text)

    @exception_safe(AttributeError, discord.NotFound)
    def get_history_messages(self, before_id):
        self.client.run_asyncio_threadsafe(self.client.get_last_messages(int(before_id)), False)

    @exception_safe(CancelledError)
    def disconnect(self):
        self.temp.clear_temporary()

        self.client.begin_disconnect()
        self.loginth.join() # App gets terminated once this function ends, so we end it only once the thread finishes
    
    @exception_safe({AttributeError: 'userInfo'})
    def request_user_info(self, user_id:int=None):
        self.client.run_asyncio_threadsafe(self.client.send_user_info(user_id or -1))

    def download_file(self, url, filename):
        self.ensure_constants()
        dest = autoincrement_file_path(self.downloads / filename)
        if isurl(url):
            download_save(url, dest, self.cacher.proxies)
        else:
            shutil.copy(url, dest)
        return True

    def save_temp(self, url, name):
        """Returns saved temp file path"""
        if isurl(url):
            return str(self.temp.save_temporary(url, name))
        return url

    def get_reference(self, channel_id, message_id):
        if channel_id == '-1':
            ch = self.client.current_channel
        else: ch = self.client.run_asyncio_threadsafe(self.client.fetch_channel(int(channel_id)))
        m = self.client.run_asyncio_threadsafe(ch.fetch_message(int(message_id)))
        event, args = self.client.run_asyncio_threadsafe(generate_message(m))
        return (event, *args)

    @exception_safe({AttributeError: 'serverInfo'})
    def request_server_info(self, server_id:int=None):
        if not server_id:
            logging.warning(f"Requested info for a server with non-truthful ID: {server_id}")
            return
        try: server_id = int(server_id)
        except ValueError:
            logging.warning(f"Requested info for a server with non-integer ID: {server_id}")
            return
        send_guild_info(self.client.run_asyncio_threadsafe(self.client.fetch_guild(server_id)))

    def send_friend_request(self, user_id: int):
        user = self.client.run_asyncio_threadsafe(self.client.fetch_user(user_id))
        try:
            if not user.is_friend():
                self.client.run_asyncio_threadsafe(user.send_friend_request())
        except discord.errors.CaptchaRequired as e:
            show_error('captcha', e)
    
    def edit_message(self, message_id: str | int, new_content: str):
        msg: discord.Message = self.client.run_asyncio_threadsafe(self.client.get_message(message_id))
        self.client.run_asyncio_threadsafe(msg.edit(content=new_content))
    
    def delete_message(self, message_id: str | int):
        msg: discord.Message = self.client.run_asyncio_threadsafe(self.client.get_message(message_id))
        self.client.run_asyncio_threadsafe(msg.delete())

    def reply_to(self, message_id: str | int, content: str):
        msg: discord.Message = self.client.run_asyncio_threadsafe(self.client.get_message(message_id))
        self.client.run_asyncio_threadsafe(msg.reply(content))


comm = Communicator()