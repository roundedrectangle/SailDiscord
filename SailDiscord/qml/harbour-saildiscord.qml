import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import io.thp.pyotherside 1.5
import Nemo.Configuration 1.0
import QtGraphicalEffects 1.0
import Nemo.Notifications 1.0
import Sailfish.Share 1.0
import Nemo.DBus 2.0
import "modules/js/showdown.min.js" as ShowDown

ApplicationWindow {
    id: mainWindow
    initialPage: Component { FirstPage { } } // TODO: bring back Component without removing Python from mainWindow
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

    property var showdown: new ShowDown.showdown.Converter({
            simplifiedAutoLink: true,
        })

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

        function constructMessageCallback(type, guildid, channelid, finalCallback) {
            return function(_serverid, _channelid, _id, _date, edited, userinfo, history, attachments) {
                if (guildid != undefined && channelid != undefined)
                    if ((_serverid != guildid) || (_channelid != channelid)) return
                var data = {
                    type: type, messageId: _id, _author: userinfo.name, _pfp: userinfo.pfp,
                    _sent: userinfo.sent, _masterWidth: -1, _date: new Date(_date), _from_history: history,
                    _wasUpdated: false, userid: userinfo.id, _attachments: attachments,
                    _flags: {
                        edit: edited, bot: userinfo.bot, nickAvailable: userinfo.nick_avail,
                        system: userinfo.system, color: userinfo.color
                    },
                }

                if (type === "" || type === "unknown") {
                    data._contents = arguments[8]
                    data._ref = arguments[9]
                }
                if (type === "unknown") data.APIType = arguments[10]
                finalCallback(history, data)
            }
        }

        function convertCallbackType(pyType) {
            switch(pyType) {
            case "message": return ''
            case "newmember": return 'join'
            case "unkownmessage": return 'unknown'
            }
        }

        function registerMessageCallbacks(guildid, channelid, finalCallback) {
            python.setHandler("message", constructMessageCallback(convertCallbackType("message"), guildid, channelid, finalCallback))
            python.setHandler("newmember", constructMessageCallback(convertCallbackType("newmember"), guildid, channelid, finalCallback))
            python.setHandler("unkownmessage", constructMessageCallback(convertCallbackType("unkownmessage"), guildid, channelid, finalCallback))
        }

        function cleanupMessageCallbacks() {
            // we unset handler so app won't crash on appending items to destroyed list because resetCurrentChannel is not instant
            python.reset("message")
            python.reset("join")
            python.reset("uknownmessage")
        }

        function markdown(text, linkColor) {
            linkColor = linkColor ? linkColor : Theme.highlightColor
            return "<style>a:link{color:" + linkColor + ";}</style>"
                    +showdown.makeHtml(text)
        }

        function processServer(_id, name, icon) {
            if (appConfiguration.legacyMode && _id == "1261605062162251848") {
                name = "RoundedRectangle's server"
                icon = Qt.resolvedUrl("../images/%1.png".arg(Qt.application.name))
            }
            // heads up: QQMLListModel can convert:
            // arrays to QQMLListModel instances
            // undefined to empty objects aka {} when other elements are objects
            return {_id: _id, name: name, image: icon, folder: false /*default*/ }
        }

        function attachmentsToListModel(_parent, attachments) {
            // Make attachments a ListModel: a (bug?) which exists in QML and I have to enable it manually where it is fixed
            // Also see https://stackoverflow.com/questions/37069565/qml-listmodel-append-broken-for-object-containing-an-array
            var listModel = Qt.createQmlObject('import QtQuick 2.0;ListModel{}', _parent)
            attachments.forEach(function(attachment, i) { listModel.append(attachment) })
            return listModel
        }
    }

    ConfigurationGroup {
        // An experimental configuration system replacing old C++ one
        id: appConfiguration
        path: "/apps/harbour-saildiscord"

        property string token: ""
        //property bool usernameTutorialCompleted: false
        property bool legacyMode: false

        Component.onCompleted: {
            if (appSettings.sentBehaviour != "r" && appSettings.sentBehaviour != "n")
                appSettings.sentBehaviour = "r"
            if (value("usernameTutorialCompleted", null) !== null)
                setValue("usernameTutorialCompleted", undefined)
        }

        ConfigurationGroup {
            id: appSettings
            path: "settings"

            // Behavior
            property bool ignorePrivate: false
            property bool defaultUnknownMessages: false
            property bool defaultUnknownReferences: false
            property bool sendByEnter: false
            property bool focusAfterSend: true
            property bool focudOnChatOpen: false

            // Look and feel
            property bool emptySpace: true
            property string sentBehaviour: "r"
            property bool alignMessagesText: true
            property string messageGrouping: "d"
            property string oneAuthorPadding: "a"
            property bool highContrastMessages: false

            // Session
            property int cachePeriod: 1

            // Advanced
            property string proxyType: "g"
            property string customProxy: ""
            property bool infoInNotifications: false
            property bool folders: true

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
        property var _refreshFirstPage: function() {}

        function init(loggedInHandler, serverHandler, dmHandler, refreshHandler) {
            setHandler('logged_in', loggedInHandler) // function(username)
            setHandler('server', function() { serverHandler(shared.processServer.apply(null, arguments)) }) // function(serverObject)
            setHandler('serverfolder', function(_id, name, color, servers) {
                var data = {folder: true, _id: _id, name: name, color: color, servers: []}
                servers.forEach(function(server, i) { data.servers.push(shared.processServer.apply(null, server)) })
                serverHandler(data)
            }) // function(folderObject)
            setHandler('dm', function(_id, name, icon, channelId, perm) { dmHandler({_id: _id, name: name, image: icon, dmChannel: channelId, textSendPermissions: perm}) })
            _refreshFirstPage = refreshHandler

            setHandler('connectionError', function(e){ shared.showError(qsTranslate("Errors", "Connection failure: %1").arg(e)) })
            setHandler('loginFailure', function(e){ shared.showError(qsTranslate("Errors", "Login failure: %1").arg(e)) })

            addImportPath(Qt.resolvedUrl("../python"))
            importModule('communicator', function() {
                reloadConstants()
                initialized = true
            })
        }

        onError: shared.showError(qsTranslate("Errors", "Python error: %1").arg(traceback))
        onReceived: console.log("got message from python: " + data)

        function login(token) { call('communicator.comm.login', [token]) }

        function request(func, handlerName, args, handler) {
            setHandler(handlerName, handler)
            call('communicator.comm.'+func, args)
        }
        function reset(handler) {
            // we unset handler so app won't crash on operating destroyed items
            // undefined is not used for messages not to be logged
            python.setHandler(handler, function() {})
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

        function getReference(channel, message, callback) { call('communicator.comm.get_reference', [channel, message], callback)}

        function refresh() {
            disconnectClient()
            reloadConstants()
            _refreshFirstPage()
        }

        function reloadConstants() { call('communicator.comm.set_constants', [StandardPaths.cache, appSettings.cachePeriod, StandardPaths.download, getProxy(), appSettings.folders]) }
    }
}
