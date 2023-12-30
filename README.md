# SailDiscord

A SailfishOS Discord client

Not working yet

**By using this, you are breaking Discord Terms of Services!**

I can forget about my projects and pause the developing, but then I come back (not always). I'm also new to developing SailfishOS apps, and it's really hard to find how to develop them.

## TODO

- [X] Login using Discord
- [X] Save token after logging in
- [X] Open the login page or the main page depending on is user logged in or not
- [X] Connect Python
- [X] Integrate discord.py-self
- [ ] Servers/DMs list
	- [ ] Frontend
		- [ ] Servers
		- [ ] DMs
	- [ ] Backend
		- [X] Servers
		- [ ] DMs
- [ ] Develop the whole app

Credits to discord.py-self library
You should install that library on your device with pip via Terminal, which is a part of developer mode for SFOS in Settings

	pkcon install python3-pip # install pip
~~`pip install discord.py-self --user # install the library`~~

For now you should install the development version of the library. Here's how to do that (installing pip is still needed):

	pkcon install git # install git, not sure if this is needed on mobile
	cd ~ # go to the directory where you want to clone the library
	git clone https://github.com/dolfies/discord.py-self # clone the development version
	cd discord.py-self # go inside of the library source
	python3 -m pip install -U . --user # install the library

Don't forget to add the --user option! Otherwise it won't work!

If you had installed the old library version before, you should run this command before installing the development one: `pip uninstall discord.py-self`

Also credits to the SailfishOS telegram client Fernschreiber for some code.
