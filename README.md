# SailDiscord

A SailfishOS Discord client

Not working yet

**By using this, you are breaking Discord Terms of Services!**

I can forget about my projects and pause the developing, but then I come back (not always). I'm also new to developing SailfishOS apps, and it's really hard to find how to develop them.

## TODO

- [ ] Package library with app
- [X] Login using Discord
- [X] Save token after logging in
- [X] Open the login page or the main page depending on is user logged in or not
- [X] Connect Python
- [X] Integrate discord.py-self
- [ ] Servers/DMs list
	- [ ] Servers
		- [X] Backend
		- [X] Connection
		- [ ] Frontend
	- [ ] DMs
		- [ ] Backend
		- [ ] Connection
		- [ ] Frontend
- [ ] Develop the whole app

Credits to discord.py-self library
You should install that library on your device with pip via Terminal, which is a part of developer mode for SFOS in Settings
In an emulator just ssh as root like this:

	ssh -p 2223 -i ~/SailfishOS/vmshare/ssh/private_keys/sdk root@localhost

Remember to replace `~/SailfishOS` with your SDK path if needed and `/` with `\` on Windows.

	pkcon install python3-pip # install pip

Now on emulator login as a normal user by typing `exit` and running the command above replacing `root` with `defaultuser`
On mobile just proceed in the same terminal

	pip install discord.py-self --user # install the library

Don't forget to add the `--user` option! Otherwise it won't work!

You might also need to install pyotherside on the emulator:

	

<strike>
For now you should install the development version of the library. Here's how to do that (installing pip is still needed):

	pkcon install git # install git, not sure if this is needed on mobile
	cd ~ # go to the directory where you want to clone the library
	git clone https://github.com/dolfies/discord.py-self # clone the development version
	cd discord.py-self # go inside of the library source
	python3 -m pip install -U . --user # install the library
</strike>
~~If you had installed the old library version before, you should run this command before installing the development one: `pip uninstall discord.py-self`~~
The 2.0 library version got released and stable works fine now.



Credits for some code to the:
- SailfishOS telegram client Fernschreiber
- sailfish-rpn-calculator
