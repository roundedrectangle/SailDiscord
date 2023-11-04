# This Python file uses the following encoding: utf-8

# if __name__ == "__main__":
#     pass
import pyotherside
from threading import Thread
import os, sys
import discord

class MyClient(discord.Client):
    async def on_ready(self):
        pyotherside.send('logged_in', str(self.user))

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
        pyotherside.send(f"Got token: {self.token}")
        self.client.run(self.token)

comm = Communicator()
