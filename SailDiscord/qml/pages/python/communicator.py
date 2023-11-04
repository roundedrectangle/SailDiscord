# This Python file uses the following encoding: utf-8

# if __name__ == "__main__":
#     pass
import pyotherside
from threading import Thread
import discord

class Communicator:
    def __init__(self):
        self.loginth = Thread()
        self.loginth.start()

    def login(self, token):
        if self.loginth.is_alive():
            return
        self.loginth = Thread(target=self._login, args=(token,))
        self.loginth.start()

    def _login(self, token):
        pyotherside.send(f"Got token: {token}")

comm = Communicator()
