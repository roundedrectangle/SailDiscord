import sys
import logging
from typing import Any, List
from pyotherside import send as qsend

from caching import Cacher, ImageType
from utils import *

script_path = Path(__file__).absolute().parent # /usr/share/harbour-saildiscord/python
sys.path.append(str(script_path.parent / 'lib/deps')) # /usr/share/harbour-saildiscord/lib/deps
import discord

# Servers

def gen_server(g: discord.Guild, cacher: Cacher):
    icon = '' if g.icon == None else \
            str(cacher.get_cached_path(g.id, ImageType.SERVER, default=g.icon))
    if icon != '':
        cacher.cache_image_bg(str(g.icon), g.id, ImageType.SERVER)
    return (str(g.id), g.name, icon)

def send_servers(guilds: List[Union[discord.Guild, discord.GuildFolder, Any]], cacher: Cacher):
    for g in guilds:
        if isinstance(g, discord.Guild):
            qsend('server', *gen_server(g, cacher))
        elif isinstance(g, discord.GuildFolder):
            qsend('serverfolder', str(g.id), g.name or '', hex_color(g.color), [gen_server(i, cacher) for i in g.guilds])

# Server Channels

def send_channel(c: discord.abc.GuildChannel, myself_id):
    if c.type == discord.ChannelType.category:
        return
    #category_position = getattr(c.category, 'position', -1)+1 # Position is used instead of ID
    perms = permissions_for(c, myself_id)
    qsend(f'channel{c.guild.id}', c.id, getattr(c.category, 'name', ''),
            str(c.id), c.name, perms.view_channel, str(c.type.name),
            isinstance(c, discord.TextChannel) and perms.send_messages, # If sending text is allowed
            perms.manage_messages, getattr(c, 'topic', '') or '',
    )

def send_channels(guild: discord.Guild, user_id):
    for c in guild.channels:
        if c.category == None and not (getattr(c, 'type') == discord.ChannelType.category or isinstance(c, discord.CategoryChannel)):
            send_channel(c, user_id)
    for category in guild.categories:
        for c in category.channels:
            send_channel(c, user_id)

# DMs
# Keep in mind that DMs or groups don't have permissions and calling permissions_for returns dummy permissions

def send_dm_channel(channel: Union[discord.DMChannel, discord.GroupChannel, Any], cacher: Cacher):
    base = (str(channel.id),)

    if isinstance(channel, discord.DMChannel):
        user = channel.recipient
        icon = cacher.easy(user.display_avatar, user.id, ImageType.USER)
        qsend('dm', *base, user.display_name, icon, not user.system, str(user.id))

    elif isinstance(channel, discord.GroupChannel):
        icon = cacher.easy(channel.icon, channel.id, ImageType.GROUP)
        name, icon_base = group_name(channel)
        qsend('group', *base, name, icon, icon_base)
    else:
        qsend('unknownPrivateChannel', type(channel).__name__)

def send_dms(channel_list: List[Union[discord.DMChannel, discord.GroupChannel, Any]], cacher: Cacher):
    for user in sorted(channel_list, key=lambda u: u.last_viewed_timestamp, reverse=True):
        send_dm_channel(user, cacher)

# Messages

async def generate_extra_message(message: Union[discord.Message, discord.MessageSnapshot], cacher: Optional[Cacher]=None, emoji_size: Optional[Any]=None, ref={}):
    t = message.type
    if t == discord.MessageType.new_member:
        return 'newmember', ()
    content = await emojify(message, cacher, emoji_size) if isinstance(message, discord.Message) else message.content
    if t in (discord.MessageType.default, discord.MessageType.reply):
        return 'message', (message.content, content, ref or {})
    else: return 'unknownmessage', (message.content, content, ref or {}, message.type.name)

def generate_base_message(message: Union[discord.Message, Any], cacher: Cacher, myself_id, is_history=False):
    """Returns a sequence of the base author-dependent message callback arguments to pass at the start"""
    icon = '' if message.author.display_avatar == None else \
            str(cacher.get_cached_path(message.author.id, ImageType.USER, default=message.author.display_avatar))
    
    if icon != '':
        cacher.cache_image_bg(str(message.author.display_avatar), message.author.id, ImageType.USER)
    
    return (str(message.guild.id) if message.guild else '-2', str(message.channel.id),
            str(message.id), qml_date(message.created_at),
            bool(message.edited_at), qml_date(message.edited_at) if message.edited_at else None,

            {"id": str(message.author.id), "sent": message.author.id == myself_id,
            "name": message.author.display_name,
            "pfp": icon, "bot": message.author.bot, "system": message.author.system,
            "color": hex_color(message.author.color)},
            
            is_history, convert_attachments(message.attachments, cacher),
            message.jump_url,
        )

# About

def send_user(user: Union[discord.MemberProfile, discord.UserProfile]):
    status, is_on_mobile = 0, False # default
    if isinstance(user, discord.MemberProfile):
        if StatusMapping.has_value(user.status):
            status = StatusMapping(user.status).index
        is_on_mobile = user.is_on_mobile()
    qsend(f"user{user.id}", user.bio or '', qml_date(user.created_at), status, is_on_mobile, #str(user.display_avatar), 
    usernames(user), user.bot, user.system, user.is_friend(), hex_color(user.color))

def send_myself(client: discord.Client):
    user = client.user
    status = 0 # default
    if StatusMapping.has_value(client.status):
        status = StatusMapping(client.status).index

    # We are not bots or system users. Or are we?
    qsend("user", user.bio or '', qml_date(user.created_at), status, client.is_on_mobile(), usernames(client.user))

def send_guild_info(g: discord.Guild):
    qsend(f'serverinfo{g.id}',
        #g.icon,
        str(-1 if g.member_count is None else g.member_count),
        str(-1 if g.online_count is None else g.online_count),
        {feature.lower(): feature in g.features for feature in
            ('VERIFIED','PARTNERED','COMMUNITY','DISCOVERABLE','FEATURABLE')
        },
        g.description or '',
    )