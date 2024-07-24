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
    for g in lst:
        pyotherside.send('server', str(g.id), str(g.name), str(g.icon))
        #send_server_info(g)

def send_categories(guild):
    for c in guild.categories:
        pyotherside.send('category', str(g.id), str(c.id), str(g.name))

class MyClient(discord.Client):
    async def on_ready(self):
        pyotherside.send('logged_in', str(self.user))
        send_servers(self.guilds)

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
        g = self.client.get_guild(guild_id)
        if g == None:
            return
        send_categories(g)

comm = Communicator()
