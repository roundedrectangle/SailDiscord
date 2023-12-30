# This Python file uses the following encoding: utf-8

# if __name__ == "__main__":
#     pass
import pyotherside
from threading import Thread
import os, sys
import discord
import time

#def send_server_info(g):
#    pyotherside.send('SERVERname', f"{g.id}~{g.name}")
#    pyotherside.send('SERVERchunked', f"{g.id}~{g.chunked}")
#    pyotherside.send('SERVERmember_count', f"{g.id}~{g.member_count}")

def send_servers(guilds):
    lst = list(guilds)
    for g in lst:
        pyotherside.send('server', str(g.id), str(g.name))
        #send_server_info(g)

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
            return
        self.token = token
        self.loginth = Thread(target=self._login)
        self.loginth.start()

    def _login(self):
        self.client.run(self.token)

comm = Communicator()
