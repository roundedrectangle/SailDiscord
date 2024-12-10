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

PKGCONFIG += qt5embedwidget

SOURCES += \
    src/harbour-saildiscord.cpp

DISTFILES += \
    harbour-saildiscord.desktop \
    qml/components/AttachmentsPreview.qml \
    qml/components/GeneralAttachmentView.qml \
    qml/components/ListImage.qml \
    qml/components/MessageItem.qml \
    qml/components/MessageReference.qml \
    qml/components/ServerListItem.qml \
    qml/components/SettingsComboBox.qml \
    qml/components/SystemMessageItem.qml \
    qml/components/ZoomableImage.qml \
    qml/cover/CoverPage.qml \
    qml/harbour-saildiscord.qml \
    qml/pages/AboutPage.qml \
    qml/pages/AboutServerPage.qml \
    qml/pages/AboutUserPage.qml \
    qml/pages/CaptchaDialog.qml \
    qml/pages/ChannelsPage.qml \
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

python.files = python
python.path = /usr/share/$${TARGET}

INSTALLS += images python

DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_RELEASE=\\\"$$RELEASE\\\"
include(libs/opal-cached-defines.pri)
