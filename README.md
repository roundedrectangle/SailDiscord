# Sailcord

Previously SailDiscord

An unofficial SailfishOS Discord client

Basic functionality is already there. More features are coming through updates

**By using this, you are breaking Discord Terms of Services! This app might even get you banned! It stores your token in plain text and it is really easy to hack you with it!**

Join the [Telegram channel](https://t.me/saildiscord) for Sailcord development logs and releases.

You can join the [SailfishOS Fan Club](https://discord.gg/j7zRh2gkGc) Discord server. Besides general SailfishOS discussion, it also has several Sailcord-related channels including info, discussion and major announcements like releases. Keep in mind that these channels may be out of date; the main channel is in Telegram.

## TODO

- [X] Login
- [X] Servers
- [ ] Text channels
	- [X] Text
	- [ ] Attachments
    	- [X] Full support for downloading and sharing
    	- [X] Photos and GIFs (non-embedded)
    	- [X] Unknown files
    	- [ ] Preview for other types (videos, etc.)
    - [ ] Embeds
        - [ ] GIFs from Giphy, Tensor, etc.
        - [ ] General embeds/EmbedProxy support
- [X] DMs
- [ ] Caching
	- [X] Avatars
- [X] References (forwarded, replies)
- [X] Markdown and emojis
- [ ] Automate translating with weblate or anything similar

## Known issues

- App lags in a text channel sometimes. Very similar to the issue below except this one lags besides being slow
- App is very slow at loading almost everything. This is not fully fixable because app uses Python as the backend, which is slow
- Friend requests might fail because of captcha. If other things fail because of it for you please report it

## Troubleshooting

### Login page isn't loading!

Check if you are able to open https://discord.com/login in the native browser. If you can't, here are the possible workarounds:

- Update to [ESR91 beta](https://www.flypig.co.uk/geckoinstall)
- Login using token (see below)

### Logging in via token

For up to date information, please search for a method using a search engine like Google. In short, you should:

1. Login into discord with a desktop web browser
2. Open developer tools (Ctrl+Shift+M on most browsers)

#### Method 1 (usually works, the instruction is for Firefox, for other browsers it may be different):
2. Select Network
3. Select one of the requests (usually, the ones requred are under the XHR filter)
4. Select Headers, scroll down to Request Headers, under which find Authorization and copy its value
   In case you can't find such header, try again from step 3 with another request
   If the header value starts with `Bearer: `, remove it; if it is in quotes (`"`), remove them too.

#### Method 2 (used in the app's WebView login):
2. Select Console
3. Enable Mobile device emulation (Ctrl+Shift+M on most browsers, or an icon with a phone)
4. Type this code and press enter:
	`iframe=document.createElement('iframe');document.body.appendChild(iframe);console.log(JSON.parse(iframe.contentWindow.localStorage.token));iframe.remove()`
	In case an error shows up, refresh the page
5. Copy the token it will show you

#### Method 3 (stopped working recently):
2. Select Console
3. Type this code and press enter:
	`(webpackChunkdiscord_app.push([[''],{},e=>{m=[];for(let c in e.c)m.push(e.c[c])}]),m).find(m => m?.exports?.default?.getToken).exports.default.getToken()`
4. Copy the token it will show you without the quotes (`"`)

After obtaining you token, in Sailcord top menu, when logging in, choose Login with token. Then paste your token and click Accept.

## Screenshots

<p float="left">
	<img src="pictures/FirstPage.png" alt="Server list (classic)" width="200"/>
	<img src="pictures/SecondPage.png" alt="Modern overview" width="200"/>
	<img src="pictures/Messages.png" alt="A channel" width="200"/>
	<img src="pictures/About.png" alt="Me (modern)" width="200"/>
</p>

*Screenshots are for version 0.8.0*

## Translating

~Read instructions [here](https://gist.github.com/roundedrectangle/c4ac530ca276e0d65c3593b8491473b6). Make sure not to skip them even if you know how to translate other apps, because there are some pitfalls. When reading instruction, replace `appname` with `saildiscord`, and when opening `translations` folder open `SailDiscord` -> `translations` folder.~ translate as usual or read that guide ignoring opal stuff

## Build

### Removing the debug flag (disabling faster build)

Get Sailfish IDE, open the project, open Other Files -> rpm -> `SailDiscord.spec`, then replace `no` in the first line with `yes` if you want to make a production package. Now just run or build.

### Faster build (disable library packaging, **NOT RECOMMENDED IN PRODUCTION**)

If you didn't replace, you'll get faster build but aditional steps needed for phone. This is only required once. Once the installation is completed, open Terminal from the developer options on your phone and type this command:

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

- When sharing discord snowflake IDs between Python and QML, they should be converted to strings. QML can mess up with large integers so strings are used. IDs are never really operated in QML except for sending them back to Python in exchange for other data.

## Credits

The code is based on:

  - [SailfishOS telegram client Fernschreiber](https://github.com/Wunderfitz/harbour-fernschreiber) - some of the UI
  - [sailfish-rpn-calculator](https://github.com/lainwir3d/sailfish-rpn-calculator), and its [@poetaster's fork](https://github.com/poetaster/sailfish-rpn-calculator) - early packaging issues
  - https://github.com/Rapptz/discord.py/issues/9690#issuecomment-2417783032 - going offline/closing connection
  - https://github.com/ichthyosaurus/harbour-file-browser - zooming pictures

Core functionality:

- [discord.py-self library](https://github.com/dolfies/discord.py-self)
- [Opal](https://github.com/Pretty-SFOS/opal) ([About](https://github.com/Pretty-SFOS/opal-about), [LinkHandler](https://github.com/Pretty-SFOS/opal-linkhandler), [Tabs](https://github.com/Pretty-SFOS/opal-tabs) and the snippets)
- [Showdown](https://github.com/showdownjs/showdown)
- [Twemoji](https://github.com/jdecked/twemoji)
- [FancyContextMenu](https://github.com/roundedrectangle/sf-fancycontextmenu) based on [Quickddit](https://github.com/accumulator/Quickddit)

Developers:

- [@roundedrectangle](https://github.com/roundedrectangle) (me)

Contributors (translations):

- [@legacychimera247](https://github.com/legacychimera247) - Italian
- [@eson57](https://github.com/eson57) - Swedish
- Check [contributors tab](https://github.com/roundedrectangle/SailDiscord/graphs/contributors) for up to date information