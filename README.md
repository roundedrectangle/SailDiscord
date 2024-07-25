# SailDiscord

A SailfishOS Discord client

Not working yet

**By using this, you are breaking Discord Terms of Services! This app might even get you banned! It stores your token in plain text and it is really easy to hack you with it!**

Join our discord [server](https://discord.gg/Q3u7ejjzFg) with detailed development logs!

I can forget about my projects and pause the developing, but then I come back (not always). I'm also new to developing SailfishOS apps, and it's really hard to find how to develop them.

## TODO

- [X] Login using Discord
- [X] Save token after logging in
- [X] Open the login page or the main page depending on is user logged in or not
- [X] Connect Python
- [X] Integrate discord.py-self
- [X] Servers
	- [X] List
		- [ ] Make it follow the same sorting as in the real discord, probably not possible yet because no such thing is implemented in discord.py-self. mb this is also an issue with qml?
	- [ ] Channels list
		- [X] Categories
		- [ ] Channels themselves
	- [ ] Messages read
	- [ ] Messages write
- [ ] DMs list
	|      | Backend | Connection | Frontend |
	|------|---------|------------|----------|
	| Name | :x:     | :x:        | :x:      |
	| Icon | :x:     | :x:        | :x:      |
- [ ] Develop the whole app
- [X] Package library with app
	- [ ] Fix `BuildRequires: python3-pip;` not working
- [X] SailJail
- [X] Settings
	- [ ] Add more options
- [ ] Automate translating, maybe something like weblate

## Build

### Removing the debug flag (disabling faster build)

Get Sailfish IDE, open the project, open Other Files -> rpm -> `SailDiscord.spec`, then replace `no` in the first line with `yes` if you want to make a production package. Now just run or build.

### Faster build (not to package the library)

If you didn't replace, you'll get faster build but aditional steps needed for phone. This is needed only once. Once the installation is completed, open Terminal from the developer options on your phone and type this command:

	python3 -m pip install "discord.py-self>=2.0" --user

Then open the app. If you ever want to switch to production version, type this command to undo:

	python3 -m pip uninstall discord.py-self

You might also want to uninstall pip and/or python3-devel, although this might break other packages:

	pkcon remove python3-pip
	pkcon remove python3-devel

### Some general build issues

- ~You might need to remove the build_folder/deps/google/_upb folder~ Should not be needed now.
- There's an issue that the `BuildRequires: python3-pip;` line in the spec file throws an error. A workaround for now is to build these two awesome projects for the same target as for this project - [harbour-moremahjong](https://github.com/poetaster/harbour-moremahjong) and [sailfish-rpn-calculator](https://github.com/poetaster/sailfish-rpn-calculator).
	- A fix could be to use `python3 -m ensurepip --default-pip` instead of `BuildRequires: python3-pip;` in the spec, but it might break the build vm/container so I am not recommending it. You can still do so by uncommenting a line in the spec file.

## Credits

The code is based on:

- [SailfishOS telegram client Fernschreiber](https://github.com/Wunderfitz/harbour-fernschreiber)
- [sailfish-rpn-calculator](https://github.com/lainwir3d/sailfish-rpn-calculator), and its [@poetaster's fork](https://github.com/poetaster/sailfish-rpn-calculator)

Core functionality:

- [discord.py-self library](https://github.com/dolfies/discord.py-self)
- [Opal](https://github.com/Pretty-SFOS/opal) ([Opal.About](https://github.com/Pretty-SFOS/opal-about))

Developers:

- [@roundedrectangle](https://github.com/roundedrectangle)

Contributors (translations):

- [@legacychimera247](https://github.com/legacychimera247) - italian
