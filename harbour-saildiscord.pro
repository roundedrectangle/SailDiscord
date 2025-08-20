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

PKGCONFIG += zlib

DEFINES += QT_STATICPLUGIN

#PKGCONFIG += qt5embedwidget

SOURCES += \
    src/harbour-saildiscord.cpp \
    src/lottieioplugin.cpp

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
    src/lottieioplugin.json \
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

HEADERS += \
    src/lottieioplugin.h

images.files = images
images.path = /usr/share/$${TARGET}

python.files = python
python.path = /usr/share/$${TARGET}

INSTALLS += images python

DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_RELEASE=\\\"$$RELEASE\\\"
include(libs/opal-cached-defines.pri)


# https://github.com/Samsung/rlottie.git

RLOTTIE_CONFIG = $${PWD}/libs/rlottie/src/vector/config.h
PRE_TARGETDEPS += $${RLOTTIE_CONFIG}
QMAKE_EXTRA_TARGETS += rlottie_config

rlottie_config.target = $${RLOTTIE_CONFIG}
rlottie_config.commands = touch $${RLOTTIE_CONFIG} # Empty config is fine

DEFINES += LOTTIE_THREAD_SUPPORT

INCLUDEPATH += \
    libs/rlottie/inc \
    libs/rlottie/src/vector \
    libs/rlottie/src/vector/freetype \
    libs/rlottie/zip

SOURCES += \
    libs/rlottie/src/lottie/lottieanimation.cpp \
    libs/rlottie/src/lottie/lottieitem.cpp \
    libs/rlottie/src/lottie/lottieitem_capi.cpp \
    libs/rlottie/src/lottie/lottiekeypath.cpp \
    libs/rlottie/src/lottie/lottieloader.cpp \
    libs/rlottie/src/lottie/lottiemodel.cpp \
    libs/rlottie/src/lottie/lottieparser.cpp \
    libs/rlottie/src/lottie/zip/zip.cpp

SOURCES += \
    libs/rlottie/src/vector/freetype/v_ft_math.cpp \
    libs/rlottie/src/vector/freetype/v_ft_raster.cpp \
    libs/rlottie/src/vector/freetype/v_ft_stroker.cpp \
    libs/rlottie/src/vector/stb/stb_image.cpp \
    libs/rlottie/src/vector/varenaalloc.cpp \
    libs/rlottie/src/vector/vbezier.cpp \
    libs/rlottie/src/vector/vbitmap.cpp \
    libs/rlottie/src/vector/vbrush.cpp \
    libs/rlottie/src/vector/vdasher.cpp \
    libs/rlottie/src/vector/vdrawable.cpp \
    libs/rlottie/src/vector/vdrawhelper.cpp \
    libs/rlottie/src/vector/vdrawhelper_common.cpp \
    libs/rlottie/src/vector/vdrawhelper_neon.cpp \
    libs/rlottie/src/vector/vdrawhelper_sse2.cpp \
    libs/rlottie/src/vector/vmatrix.cpp \
    libs/rlottie/src/vector/vimageloader.cpp \
    libs/rlottie/src/vector/vinterpolator.cpp \
    libs/rlottie/src/vector/vpainter.cpp \
    libs/rlottie/src/vector/vpath.cpp \
    libs/rlottie/src/vector/vpathmesure.cpp \
    libs/rlottie/src/vector/vraster.cpp \
    libs/rlottie/src/vector/vrle.cpp

NEON = $$system(g++ -dM -E -x c++ - < /dev/null | grep __ARM_NEON__)
SSE2 = $$system(g++ -dM -E -x c++ - < /dev/null | grep __SSE2__)

!isEmpty(NEON) {
    message(Using NEON render functions)
    SOURCES += libs/rlottie/src/vector/pixman/pixman-arm-neon-asm.S
} else {
    !isEmpty(SSE2) {
        message(Using SSE2 render functions)
        SOURCES += libs/rlottie/src/vector/vdrawhelper_sse2.cpp
    } else {
        message(Using default render functions)
    }
}
