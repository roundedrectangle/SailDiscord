import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import io.thp.pyotherside 1.5
import harboursaildiscord.Logic 1.0
import Nemo.Configuration 1.0
import QtGraphicalEffects 1.0

ApplicationWindow {
    id: mainWindow
    initialPage: FirstPage { id: myPage } // TODO: bring back Component without removing Python from mainWindow
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Connections {
        target: Qt.application
        onAboutToQuit: python.disconnectClient()
    }

    QtObject {
        id: shared

        function log() {
          var f = ""
          for (var i = 0; i < arguments.length; i++) {
            f += arguments[i]
            if (i != arguments.length-1) f += "|||"
          }
          console.log(f)
        }

        function imageLoadError(name) { Notices.show(qsTranslate("Errors", "Error loading image %1. Please report this to developers").arg(name), Notice.Long, Notice.Top) }

        function download(url) {
            python.call('communicator.comm.download_file', [url], function(r) {
                console.log("TODO: show notification")
            })
        }
    }

    SettingsMigrationAssistant { id: migrateSettings }

    ConfigurationGroup {
        // An experimental configuration system replacing old C++ one
        id: appConfiguration
        path: "/apps/harbour-saildiscord"

        property string token: ""
        property bool usernameTutorialCompleted: false

        Component.onCompleted: {
            //clear()
            migrateSettings.migrateConfiguration()
        }

        ConfigurationGroup {
            id: appSettings
            path: "settings"

            property bool emptySpace: true
            property bool ignorePrivate: false
            property bool messagesLessWidth: true
            property bool alignMessagesText: true
            property bool sendByEnter: false
            property bool focusAfterSend: true
            property bool focudOnChatOpen: false
            property bool defaultUnknownMessages: false

            property string sentBehaviour: "r"
            property string messagesPadding: "a"
            property string oneAuthorPadding: "a"
            property string messageGrouping: "d"

            property int cachePeriod: 1

            onCachePeriodChanged: python.setCachePeriod(cachePeriod)
        }
    }

    Python {
        id: python
        property bool initialized: false

        Component.onCompleted: {
            setHandler('logged_in', function(_username) {
                myPage.loading = false;
                myPage.username = _username;
            })
            setHandler('server', function(_id, _name, _icon, _memberCount, _cached) { myPage.serversModel.append({_id: _id, name: _name, image: _icon, memberCount: _memberCount, cached: _cached, sectionId: myPage.serversModel.count == 0 ? "undefined" : _id}) })

            addImportPath(Qt.resolvedUrl("../python"))
            importModule('communicator', function () {})

            call('communicator.comm.set_constants', [StandardPaths.cache, appSettings.cachePeriod, StandardPaths.download])

            initialized = true
        }

        onError: console.log("python error: " + traceback)
        onReceived: console.log("got message from python: " + data)

        function login(token) {
            myPage.loading = true;
            call('communicator.comm.login', [token])
        }
        function updateServer(what, updater) {
            var arr = what.split('~')
            const id = arr.shift()
            updater(myPage.serversModel.findById(id), arr.join(' '))
        }

        function requestChannels(guildid){ call('communicator.comm.get_channels', [guildid], function () {}) }
        function setCurrentChannel(guildid, channelid) { call('communicator.comm.set_channel', [guildid, channelid])}
        function resetCurrentChannel() { setCurrentChannel("", "") }

        function clearCache() { call('communicator.comm.clear_cache', []) }
        function setCachePeriod(period) {
            if (!initialized) return;
            python.call('communicator.comm.set_cache_period', [period])
        }

        function sendMessage(text) { python.call('communicator.comm.send_message', [text]) }
        function requestOlderHistory(messageId) { python.call('communicator.comm.get_history_messages', [messageId])}

        function disconnectClient() { python.call_sync('communicator.comm.disconnect') }

        function requestUserInfo(userId) { python.call('communicator.comm.request_user_info', [userId])}
    }
}
