import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import io.thp.pyotherside 1.5
import harboursaildiscord.Logic 1.0
import Nemo.Configuration 1.0
import QtGraphicalEffects 1.0
import Nemo.Notifications 1.0
import Sailfish.Share 1.0
import Nemo.DBus 2.0

ApplicationWindow {
    id: mainWindow
    initialPage: FirstPage { id: myPage } // TODO: bring back Component without removing Python from mainWindow
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Component.onDestruction: python.disconnectClient()

    Notification { // Notifies about app status
        id: notifier
        replacesId: 0
        onReplacesIdChanged: if (replacesId !== 0) replacesId = 0
        isTransient: !appSettings.infoInNotifications
    }

    ShareAction { id: shareApi }

    DBusInterface {
        id: globalProxy
        bus: DBus.SystemBus
        service: 'net.connman'
        path: '/'
        iface: 'org.sailfishos.connman.GlobalProxy'

        signalsEnabled: true
        function propertyChanged(name, value) { updateProxy() }

        property string url
        Component.onCompleted: updateProxy()

        function updateProxy() {
            // Sets the `url` to the global proxy URL, if enabled. Only manual proxy is supported, only the first address is used and excludes are not supported: FIXME
            // When passing only one parameter, you can pass it without putting it into an array (aka [] brackets)
            typedCall('GetProperty', {type: 's', value: 'Active'}, function (active){
                if (active) typedCall('GetProperty', {type: 's', value: 'Configuration'}, function(conf) {
                    if (conf['Method'] === 'manual') url = conf['Servers'][0]
                    else url=''
                }, function(e){url=''}); else url=''
            }, function(e){url=''})
        }
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

        function showInfo(text) {
            notifier.appIcon = "image://theme/icon-lock-information"
            notifier.body = text
            notifier.publish()
        }

        function showError(text) {
            notifier.appIcon = "image://theme/icon-lock-warning"
            notifier.body = text
            notifier.publish()
            console.log(text)
        }

        function imageLoadError(name) {
            showError(qsTranslate("Errors", "Error loading image %1. Please report this to developers").arg(name))
        }

        function download(url, name) {
            python.call('communicator.comm.download_file', [url, name], function(r) {
                showInfo(qsTr("Downloaded file %1").arg(name))
            })
        }

        function shareFile(url, name, mime) {
            python.call('communicator.comm.save_temp', [url, name], function(path) {
                shareApi.mimeType = mime
                shareApi.resources = [path]
                shareApi.trigger()
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

            // Behavior
            property bool ignorePrivate: false
            property bool defaultUnknownMessages: false
            property bool sendByEnter: false
            property bool focusAfterSend: true
            property bool focudOnChatOpen: false

            // Look and feel
            property bool emptySpace: true
            property string sentBehaviour: "r"
            property bool messagesLessWidth: true
            property string messagesPadding: "a"
            property bool alignMessagesText: true
            property string messageGrouping: "d"
            property string oneAuthorPadding: "a"

            // Session
            property int cachePeriod: 1

            // Advanced
            property string proxyType: "g"
            property string customProxy: ""
            property bool infoInNotifications: false

            onCachePeriodChanged: python.setCachePeriod(cachePeriod)
        }
    }

    Connections {
        target: globalProxy
        onUrlChanged: python.call('communicator.comm.set_proxy', [python.getProxy()])
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

            setHandler('connectionError', function(e){ shared.showError(qsTranslate("Errors", "Connection failure: %1").arg(e)) })
            setHandler('loginFailure', function(e){ shared.showError(qsTranslate("Errors", "Login failure: %1").arg(e)) })

            addImportPath(Qt.resolvedUrl("../python"))
            importModule('communicator', function () {})

            call('communicator.comm.set_constants', [StandardPaths.cache, appSettings.cachePeriod, StandardPaths.download, getProxy()])

            initialized = true
        }

        onError: shared.showError(qsTranslate("Errors", "Python error: %1").arg(traceback))
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
            call('communicator.comm.set_cache_period', [period])
        }

        function sendMessage(text) { call('communicator.comm.send_message', [text]) }
        function requestOlderHistory(messageId) { call('communicator.comm.get_history_messages', [messageId])}

        function disconnectClient() {
            if (!initialized || appConfiguration.token.length <= 0) return;
            call_sync('communicator.comm.disconnect')
        }

        function requestUserInfo(userId) { call('communicator.comm.request_user_info', [userId])}

        function getProxy() {
            switch (appSettings.proxyType) {
            case "g": return globalProxy.url
            case "n": return ''
            case "c": return appSettings.customProxy
            }
        }

        function getReference(ref, callback) {
            call('communicator.comm.get_reference', [ref], callback)
            //return constructCallback(event).apply(null, arguments)
            //console.log(arguments)
        }
    }
}
