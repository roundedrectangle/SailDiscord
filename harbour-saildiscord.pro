# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-saildiscord

CONFIG += sailfishapp

#PKGCONFIG += qt5embedwidget

SOURCES += \
    src/harbour-saildiscord.cpp

DISTFILES += \
    harbour-saildiscord.desktop \
    qml/components/Asset.qml \
    qml/components/AttachmentsPreview.qml \
    qml/components/ChannelItem.qml \
    qml/components/FadeableFlickable.qml \
    qml/components/GeneralAttachmentView.qml \
    qml/components/ListImage.qml \
    qml/components/MessageItem.qml \
    qml/components/MessageReference.qml \
    qml/components/PlaceholderImage.qml \
    qml/components/PressEffect.qml \
    qml/components/ServerListItem.qml \
    qml/components/SettingsComboBox.qml \
    qml/components/Shared.qml \
    qml/components/SystemMessageItem.qml \
    qml/components/ZoomableImage.qml \
    qml/cover/CoverPage.qml \
    qml/harbour-saildiscord.qml \
    qml/modules/FancyContextMenu/FancyAloneMenuItem.qml \
    qml/pages/AboutPage.qml \
    qml/pages/AboutServerPage.qml \
    qml/pages/AboutUserPage.qml \
    qml/pages/ChannelsPage.qml \
    qml/pages/DMsView.qml \
    qml/pages/FirstPage.qml \
    qml/pages/FullscreenAttachmentPage.qml \
    qml/pages/LoginDialog.qml \
    qml/pages/MessagesPage.qml \
    qml/pages/SecondPage.qml \
    qml/pages/SettingsPage.qml \
    rpm/SailDiscord.changes.in \
    rpm/SailDiscord.changes.run.in \
    rpm/SailDiscord.spec \
    translations/*.ts

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += \
    translations/harbour-saildiscord-it.ts \
    translations/harbour-saildiscord-ru.ts \
    translations/harbour-saildiscord-sv.ts

HEADERS +=

images.files = images
images.path = /usr/share/$${TARGET}

pyotherside_utils.target = $$OUT_PWD/deps/pyotherside_utils_
pyotherside_utils.commands = python3 -m pip install --no-cache-dir --force-reinstall --upgrade https://github.com/roundedrectangle/pyotherside-utils/releases/download/latest/pyotherside_utils-1.0-py3-none-any.whl --target=$$OUT_PWD/deps/pyotherside_utils_
#pyotherside_utils.depends = FORCE

discordpyself.target = $$OUT_PWD/deps/discord_
discordpyself.commands = python3 -m pip install $$PWD/libs/discord.py-self --target=$$OUT_PWD/deps/discord_ && rm -rf $$OUT_PWD/deps/discord_/bin && (strip -s $$OUT_PWD/deps/discord_/charset_normalizer/*.so 2>/dev/null || :) && (strip -s $$OUT_PWD/deps/discord_/google/_upb/*.so 2>/dev/null || :)
#discordpyself.depends = FORCE

QMAKE_EXTRA_TARGETS += pyotherside_utils discordpyself
PRE_TARGETDEPS += $$pyotherside_utils.target $$discordpyself.target
QMAKE_DISTCLEAN += $$pyotherside_utils.target $$discordpyself.target

pythondeps.files = $${pyotherside_utils.target}/* $${discordpyself.target}/*
pythondeps.path = /usr/share/$${TARGET}/lib/deps
#pythondeps.depends = $$pyotherside_utils.target $$discordpyself.target

python.files = python
python.path = /usr/share/$${TARGET}

INSTALLS += images pythondeps python

DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_RELEASE=\\\"$$RELEASE\\\"
include(libs/opal-cached-defines.pri)
