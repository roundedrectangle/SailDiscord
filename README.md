# SailDiscord

A SailfishOS Discord client

Not working yet

**By using this, you are breaking Discord Terms of Services!**

I can forget about my projects and pause the developing, but then I come back (not always). I'm also new to developing SailfishOS apps, and it's really hard to find how to develop them.

## TODO

- [X] Package library with app
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

There's an issue that the app refuses to build. A workaround for now is to build these two awesome projects for the same target as for this project - [harbour-moremahjong](https://github.com/poetaster/harbour-moremahjong) and [sailfish-rpn-calculator](https://github.com/poetaster/sailfish-rpn-calculator)
I haven't found a fix yet

## Build

Get Sailfish IDE, open the project, open Other Files -> rpm -> `SailDiscord.spec`, then replace `no` in the first line with `yes` if you want to make a production package. Now just run or build.

If you didn't uncomment, you'll get faster build but aditional steps needed for phone. This is needed only once. Once the installation is completed, open Terminal from the developer options on your phone and type this command:

	python3 -m pip install discord.py-self>=2.0

Then open the app. If you ever want to switch to production version, type this command to undo:

	python3 -m pip uninstall discord.py-self

You might also want to uninstall pip and/or python3-devel, although this might break other packages:

	pkcon remove python3-pip
	pkcon remove python3-devel

Credits for some code to the:
- SailfishOS telegram client Fernschreiber
- sailfish-rpn-calculator
