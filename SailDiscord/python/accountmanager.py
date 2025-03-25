from __future__ import annotations
from pyotherside import send as qsend
from utils import *

from pathlib import Path

# Format:
# {
#   'active': int | None, # user_id
#   'accounts': {
#       int: { # id
#           'token': str,
#           'name': str,
#           'avatar': str,
#       }, ...
#   }
# }

class AccountManager(ConfigBase):
    _name = 'accounts'
    _default = {'active': None, 'accounts': {}}
    _data: dict

    @property
    def active_account(self):
        if 'active' not in self._data or not isinstance(self._data['active'], (int, None)):
            self._data['active'] = None
            self.save()
        return self._data['active']
    
    @active_account.setter
    def active_account(self, value: int | None):
        self._data['active'] = value
        self.save()

    @property
    def accounts(self):
        # self.reset_if('accounts' not in self._data)
        if 'accounts' not in self._data or not isinstance(self._data['accounts'], dict):
            self._data['accounts'] = {}
            self.save()
        return self._data['accounts']

    def __init__(self, location: str | Path):
        super().__init__(location)
    
    def has_account(self, id):
        return id in self.accounts
    
    def add_account(self, id, token, name, avatar=None):
        self.accounts[id] = {
            'token': token,
            'name': name,
            'avatar': avatar,
        }
        self.active_account = id
    
    def remove_account(self, id):
        self.accounts.pop(id, None)
        if self.active_account == id:
            self.active_account = None
    
    def load(self):
        if super().load():
            if not isinstance(self._data, dict): # pyright:ignore[reportUnnecessaryIsInstance]
                self.reset()
            return True