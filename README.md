# Sailcord

Previously SailDiscord

An unofficial SailfishOS Discord client

Very very WIP

**By using this, you are breaking Discord Terms of Services! This app might even get you banned! It stores your token in plain text and it is really easy to hack you with it!**

Join the [Telegram channel](https://t.me/saildiscord) for Sailcord development logs and releases.

Join [SailfishOS Fan Club](https://discord.gg/j7zRh2gkGc) Discord server! Besides general SailfishOS discussion, it also has several Sailcord-related channels including info, discussion and major announcements like releases.

## TODO

- [X] Login using Discord
- [X] Connect Python
- [X] Servers
- [ ] Text channels
	- [X] Text
	- [ ] Attachments
    	- [X] Full support for downloading and sharing
    	- [X] Photos and GIFs (non-embedded)
    	- [ ] Other types (videos, proper preview for non-previewable files, etc.)
    - [ ] Embeds
        - [ ] GIFs from Giphy, Tensor, etc.
        - [ ] General embeds/EmbedProxy support
- [X] DMs
- [X] Settings
- [X] About page
- [ ] Caching
	- [X] Avatars
- [X] References (forwarded, replies)
- [X] Markdown
- [ ] Automate translating, maybe with something like weblate
- [ ] More features?

## Known issues

- App lags in a text channel sometimes. Very similar to the issue below except this one lags besides being slow
- App is very slow at loading almost everything. This is not fully fixable because app uses Python as the backend, which is slow

## Troubleshooting

### Login page isn't loading!

Check if you are able to open https://discord.com/login in the native browser. If you can't, here are the possible workarounds:

- Update to [ESR91 beta](https://www.flypig.co.uk/geckoinstall)
- Login using token (see below)

### Logging in via token

See [discord.py-self docs page](https://discordpy-self.readthedocs.io/en/latest/authenticating.html) for up to date information. In short, you should:

- Login into discord with a desktop web browser
- Open developer tools (ctrl+shift+i on most browsers) and click on Console
- Type this code and press enter:
	`(webpackChunkdiscord_app.push([[''],{},e=>{m=[];for(let c in e.c)m.push(e.c[c])}]),m).find(m => m?.exports?.default?.getToken).exports.default.getToken()`
- Copy the token it will show you without the quotes (`"`)

After obtaining you token, in Sailcord top menu, when logging in, choose Login with token. Then paste your token and click Accept.

## Screenshots

<p float="left">
	<img src="pictures/FirstPage.png" alt="Server list" width="200"/>
	<img src="pictures/Channels.png" alt="Server list" width="200"/>
	<img src="pictures/Messages.png" alt="Server list" width="200"/>
	<img src="pictures/Settings.png" alt="Server list" width="200"/>
	<img src="pictures/About.png" alt="Server list" width="200"/>
</p>

*Screenshots are for version 0.6.0*

## Translating

1. Fork the repo from GitHub UI. When creating the fork, select the "Copy the `main` branch only" checkmark. Only needed once
2. If required, click on "Sync fork" on your fork.
3. *(Optional)* You can create a new branch with your translation by selecting the `main` branch you forked -> "View all branches" -> "New branch" and typing whatever branch name you want. I recommend `patch-n` where `n` is 1 for the first branch, 2 for the second, etc. Then go to your branch on the GitHub.
4. Go to folder `SailDiscord` -> `translations`.
   -  If there is a file with your language code, click on it and select the edit icon
   -  If not:
      1. Click on `harbour-saildiscord.ts` file
      2. Select copy icon (Copy raw file)
      3. Go back, click Add file -> Create new file
      4. Enter `harbour-saildiscord-xx.ts` replacing `xx` with your language code as the name. For example, `ru` for Russian
      5. Paste the copied file in the new file's contents
5. Make your changes. Note that:
   - **Do not update Opal modules translations.** They include About page translations, and their context name is prefixed with `Opal.`. Do it [here](https://hosted.weblate.org/projects/opal) instead. An example:

		 <context>
			<name>Opal.About</name>
			...
		 </context>

   - When translating a string, read its comments if available. They include things which describe the context of the string (where it is used).
   - `%1`, `%2`, `%3`, etc. parts will be replaced with additional data
   - Parts starting with `&` and ending with `;` mean that they'll be replaced with special characters. You can check the full list by googling "html entities list". The most common are:
     | code     | rendered |
	 |----------|----------|
	 | `&lt;`   | >        |
	 | `&gt;`   | <        |
	 | `&amp`   | &        |
	 | `&quot;` | "        |
	 | `&apos;` | '        |
   - To translate a string, modify the lines starting with `<translation`. Remove ` type="unfinished"` parts and insert your translation between `>` and `<` characters. As the source use the lines starting with `<source>`, which are above the actual translation. Example:

		 Original:

     		 <message>
		       <location filename="../qml/pages/FirstPage.qml" line="62"/>
		       <location filename="../qml/pages/LoginDialog.qml" line="20"/>
		       <source>About</source>
		       <comment>App</comment>
		       <translation type="unfinished"></translation>
		 </message>

		 Modified:

		 <message>
		       <location filename="../qml/pages/FirstPage.qml" line="62"/>
		       <location filename="../qml/pages/LoginDialog.qml" line="20"/>
		       <source>About</source>
		       <comment>App</comment>
		       <translation>О программе</translation>
		 </message>
6. Click on Commit changes -> Commit changes. Leave the commit options default
7. Go to the main page of your fork, select your branch if you created it
8. Click on Contribute -> Open pull request -> Create pull request

## Donations

Don't

## Build

### Removing the debug flag (disabling faster build)

Get Sailfish IDE, open the project, open Other Files -> rpm -> `SailDiscord.spec`, then replace `no` in the first line with `yes` if you want to make a production package. Now just run or build.

### Faster build (not to package the library, **NOT RECOMMENDED IN PRODUCTION**)

If you didn't replace, you'll get faster build but aditional steps needed for phone. This is needed only once. Once the installation is completed, open Terminal from the developer options on your phone and type this command:

	python3 -m pip install --user --upgrade "discord.py-self>=2.0" "requests" "Pillow"

Then open the app. If you ever want to switch back to the production version, type this command to undo:

	python3 -m pip uninstall discord.py-self

SailJail will NOT work in this case

### Some general build issues

- ~You might need to remove the build_folder/deps/google/_upb folder~ Should not be needed now.
- ~There's an issue that the `BuildRequires: python3-pip;` line in the spec file throws an error. A workaround for now is to build these two awesome projects for the same target as for this project - [harbour-moremahjong](https://github.com/poetaster/harbour-moremahjong) and [sailfish-rpn-calculator](https://github.com/poetaster/sailfish-rpn-calculator).~
	- ~A fix could be to use `python3 -m ensurepip --default-pip` instead of `BuildRequires: python3-pip;` in the spec, but it might break the build vm/container so I am not recommending it. You can still do so by uncommenting a line in the spec file.~
	- The fix has been found, and it turns out very simple. Open the project in Sailfish IDE, right click on it in the file structure and click Run QMake.
- You might need to `cd` into the build folder, run `sfdk config target=<a target>` and then `sfdk build-shell --maintain`, finally inside that shell run `python3 -m pip install --upgrade pip`.

### Code Design

- When sharing IDs between Python and QML, we convert them to strings. QML can mess up large integers so we use strings. We never really operate IDs in QML except for sending them back to Python in exchange for other data.

## Credits

The code is based on:

- a lot:
  - [SailfishOS telegram client Fernschreiber](https://github.com/Wunderfitz/harbour-fernschreiber) - most of the UI

- a little:
  - [sailfish-rpn-calculator](https://github.com/lainwir3d/sailfish-rpn-calculator), and its [@poetaster's fork](https://github.com/poetaster/sailfish-rpn-calculator) - early packaging issues
  - https://github.com/Rapptz/discord.py/issues/9690#issuecomment-2417783032 - going offline/closing connection
  - https://github.com/ichthyosaurus/harbour-file-browser - zoom pictures

Core functionality:

- [discord.py-self library](https://github.com/dolfies/discord.py-self)
- [Opal](https://github.com/Pretty-SFOS/opal) ([About](https://github.com/Pretty-SFOS/opal-about), [LinkHandler](https://github.com/Pretty-SFOS/opal-linkhandler), [Tabs](https://github.com/Pretty-SFOS/opal-tabs) and the snippets)
- [Showdown](https://github.com/showdownjs/showdown)
- [Twemoji](https://github.com/jdecked/twemoji)

Developers:

- [@roundedrectangle](https://github.com/roundedrectangle) (me)

Contributors (translations):

- [@legacychimera247](https://github.com/legacychimera247) - Italian
- [@eson57](https://github.com/eson57) - Swedish
