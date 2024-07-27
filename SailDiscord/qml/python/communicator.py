# This Python file uses the following encoding: utf-8

# if __name__ == "__main__":
#     pass
import os, sys, time
import pyotherside
from threading import Thread
import asyncio

sys.path.append(os.path.join(os.path.dirname(sys.path[0]),'deps'))
import discord

QMLLIVE_DEBUG = True

#def send_server_info(g):
#    pyotherside.send('SERVERname', f"{g.id}~{g.name}")
#    pyotherside.send('SERVERchunked', f"{g.id}~{g.chunked}")
#    pyotherside.send('SERVERmember_count', f"{g.id}~{g.member_count}")

def send_servers(guilds):
    lst = list(guilds)
    for g in reversed(lst):
        pyotherside.send('server', str(g.id), str(g.name), str(g.icon))
        #send_server_info(g)

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



class MyClient(discord.Client):
    async def on_ready(self):
        pyotherside.send('logged_in', str(self.user))
        send_servers(self.guilds)

    async def on_message(self, message):
        server_name = "No server" if message.guild == None else message.guild
        pyotherside.send(f"Got message from {message.author} in server : {message.content}")
        #await message.channel.send('pong')

class Communicator:
    def __init__(self):
        self.loginth = Thread()
        self.loginth.start()
        self.client = MyClient()
        self.token = ''

    def login(self, token):
        if self.loginth.is_alive():
            if QMLLIVE_DEBUG:
                asyncio.run(self.client.on_ready())
            return
        #elif token != '':
        #    self.client.close()
        self.token = token
        self.loginth = Thread(target=self._login)
        self.loginth.start()

    def _login(self):
        self.client.run(self.token)

    def get_categories(self, guild_id):
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

comm = Communicator()
