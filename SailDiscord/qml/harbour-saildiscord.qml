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
import "modules/js/twemoji.min.js" as Twemoji

ApplicationWindow {
    id: mainWindow
    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Component.onDestruction: py.disconnectClient()

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
            underline: true,
            backslashEscapesHTMLTags: true,
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

        function showInfo(summary, text) {
            notifier.appIcon = "image://theme/icon-lock-information"
            notifier.summary = summary || ''
            notifier.body = text || ''
            notifier.publish()
        }

        function showError(summary, text) {
            notifier.appIcon = "image://theme/icon-lock-warning"
            notifier.summary = summary || ''
            notifier.body = text || ''
            notifier.publish()
            console.log(text)
        }

        function imageLoadError(name) {
            showError(qsTranslate("Errors", "Error loading image %1. Please report this to developers").arg(name))
        }

        function download(url, name) {
            py.call('main.comm.download_file', [url, name], function(r) {
                showInfo(qsTr("Downloaded file %1").arg(name))
            })
        }

        function shareFile(url, name, mime) {
            py.call('main.comm.save_temp', [url, name], function(path) {
                shareApi.mimeType = mime
                shareApi.resources = [path]
                shareApi.trigger()
            })
        }

        function constructMessageCallback(type, guildid, channelid, finalCallback) {
            return function(_serverid, _channelid, _id, _date, edited, editedAt, userinfo, history, attachments, jumpUrl) {
                if (guildid != undefined && channelid != undefined)
                    if ((_serverid != guildid) || (_channelid != channelid)) return
                var data = {
                    type: type, messageId: _id, _author: emojify(userinfo.name), _pfp: userinfo.pfp,
                    _sent: userinfo.sent, _masterWidth: -1, _date: new Date(_date), _from_history: history,
                    _wasUpdated: false, userid: userinfo.id, _attachments: attachments,
                    _flags: {
                        edit: edited, bot: userinfo.bot, editedAt: editedAt,
                        system: userinfo.system, color: userinfo.color
                    }, APIType: '', contents: '', formatted: '', _ref: {}, highlightStarted: false,
                    jumpUrl: jumpUrl,
                }

                var extraStart = 10
                if (type === "" || type === "unknown") {
                    data.contents = arguments[extraStart]
                    data.formatted = markdown(arguments[extraStart+1], undefined, data._flags.edit)
                    data._ref = arguments[extraStart+2]
                }
                if (type === "unknown") data.APIType = arguments[extraStart+3]
                finalCallback(history, data)
            }
        }

        function convertCallbackType(pyType) {
            switch(pyType) {
            case "message": return ''
            case "newmember": return 'join'
            case "unknownmessage": return 'unknown'
            }
        }

        function registerMessageCallbacks(guildid, channelid, finalCallback, editCallback) {
            // see convertCallbackType()
            py.setHandler("message", constructMessageCallback('', guildid, channelid, finalCallback))
            py.setHandler("newmember", constructMessageCallback('join', guildid, channelid, finalCallback))
            py.setHandler("unknownmessage", constructMessageCallback('unknown', guildid, channelid, finalCallback))
            py.setHandler("messageedit", function(before, event, args) {
                constructMessageCallback(convertCallbackType(event), guildid, channelid, function(history, data) {
                    editCallback(before, data)
                }).apply(null, args)
            })
            py.setHandler("messagedelete", function(id) { editCallback(id) })
        }

        function cleanupMessageCallbacks() {
            // we unset handler so app won't crash on appending items to destroyed list because resetCurrentChannel is not instant
            py.reset("message")
            py.reset("newmember")
            py.reset("uknownmessage")
            py.reset("messageedit")
            py.reset("messagedelete")
        }

        function markdown(text, linkColor, edited) {
            var e = emojify(text)
            return "<style>a:link{color:" + (linkColor ? linkColor : Theme.highlightColor) + ";}</style>"
                        +showdown.makeHtml(((appSettings.twemoji && /^<img/.test(e)) ? '<span style="color:transparent">.</span>': '')
                                           +e
                                           +(edited ? (" <a href='sailcord://showEditDate' style='text-decoration:none;font-size:" + Theme.fontSizeExtraSmall + "px;color:"+ Theme.secondaryColor +";'>" + qsTr("(edited)") + "</a>") : "")
                                           )
        }

        function processServer(_id, name, icon) {
            if (appConfiguration.legacyMode && _id == "1261605062162251848") {
                name = "RoundedRectangle's server"
                icon = Qt.resolvedUrl("../images/%1.png".arg(Qt.application.name))
            }
            // heads up: QQMLListModel can convert:
            // arrays to QQMLListModel instances
            // undefined to empty objects aka {} when other elements are objects
            return {_id: _id, name: shared.emojify(name), image: icon,
                folder: false, color: '', servers: [], // QML seems to need same element keys in all model entries
            }
        }

        function attachmentsToListModel(_parent, attachments) {
            // Make attachments a ListModel: a (bug?) which exists in QML and I have to enable it manually where it is fixed
            // Also see https://stackoverflow.com/questions/37069565/qml-listmodel-append-broken-for-object-containing-an-array
            var listModel = Qt.createQmlObject('import QtQuick 2.0;ListModel{}', _parent)
            attachments.forEach(function(attachment, i) { listModel.append(attachment) })
            return listModel
        }

        function emojify(text) {
            if (!appSettings.twemoji) return text
            return Twemoji.twemoji.parse(text, { base: Qt.resolvedUrl('../images/twemoji/'), attributes: function () { return { width: '%1'.arg(Theme.fontSizeMedium), height: '%1'.arg(Theme.fontSizeMedium) } } })
        }

        function constructStatus(statusIndex, onMobile) {
            var result = ["",
                          qsTranslate("status", "Online"),
                          qsTranslate("status", "Offline"),
                          qsTranslate("status", "Do Not Disturb"),
                          qsTranslate("status", "Invisible"),
                          qsTranslate("status", "Idle")
                    ][statusIndex]
            if (onMobile && result !== "")
                result += " "+qsTranslate("status", "(Phone)", "Used with e.g. Online (Phone)")
            return result
        }

        function loadLastChannels() {
            try { return JSON.parse(appConfiguration.serverLastChannels) }
            catch(e) { appConfiguration.serverLastChannels = "{}"; return {} }
        }

        function getLastChannel(serverid) {
            var loaded = loadLastChannels()
            return serverid in loaded ? loaded[serverid] : '-1'
        }

        function setLastChannel(serverid, channelid) {
            var loaded = loadLastChannels()
            loaded[serverid] = channelid
            appConfiguration.serverLastChannels = JSON.stringify(loaded)
        }
    }

    ConfigurationGroup {
        // An experimental configuration system replacing old C++ one
        id: appConfiguration
        path: "/apps/harbour-saildiscord"

        property string token: ""
        property bool legacyMode: false
        property string modernLastServerId: "-1"
        property string serverLastChannels: "{}"

        Component.onCompleted: {
            if (appSettings.sentBehaviour != "r" && appSettings.sentBehaviour != "n")
                appSettings.sentBehaviour = "r"
            if (value("usernameTutorialCompleted", null) !== null)
                setValue("usernameTutorialCompleted", undefined)
            if (appSettings.value("folders", null) !== null)
                appSettings.setValue("folders", undefined)
            if (appSettings.value("defaultUnknownReferences", null) !== null)
                appSettings.setValue("defaultUnknownReferences", undefined)
            if (appSettings.value("emptySpace", null) !== null)
                appSettings.setValue("emptySpace", undefined)
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
            //property bool emptySpace: false
            property string sentBehaviour: "r"
            property bool alignMessagesText: true
            property bool modernUI: false
            property string messageGrouping: "d"
            property string oneAuthorPadding: "a"
            property bool highContrastMessages: false
            property bool twemoji: true

            // Session
            property int cachePeriod: 1

            // Advanced
            property string proxyType: "g"
            property string customProxy: ""
            property bool infoInNotifications: false
            property bool unformattedText: false
            property bool unreadState: true
            property bool friendRequests: false
            property bool developerMode: false

            onCachePeriodChanged: py.setCachePeriod(cachePeriod)
        }
    }

    Connections {
        target: globalProxy
        onUrlChanged: py.call('main.comm.set_proxy', [py.getProxy()])
    }

    Python {
        id: py
        property bool initialized: false
        property var _refreshFirstPage: function() {}

        function init(loggedInHandler, serverHandler, dmHandler, dmUpdateHandler, refreshHandler) {
            setHandler('logged_in', loggedInHandler) // function(username, icon, status, isOnMobile)
            setHandler('server', function() { serverHandler(shared.processServer.apply(null, arguments)) }) // function(serverObject)
            setHandler('serverfolder', function(_id, name, color, servers) {
                var data = {image: '', folder: true, _id: _id, name: shared.emojify(name), color: color, servers: []}
                servers.forEach(function(server, i) { data.servers.push(shared.processServer.apply(null, server)) })
                serverHandler(data)
            }) // function(folderObject)
            setHandler('dm', function(channelId, unread, mentions, name, icon, perm, _id) { dmHandler({_id: _id, name: shared.emojify(name), image: icon, dmChannel: channelId, textSendPermissions: perm, iconBase: '', unread: unread, mentions: mentions}) })
            setHandler('group', function(channelId, unread, mentions, name, icon, iconBase) { dmHandler({_id: '-1', name: name ? shared.emojify(name) : qsTr("Unnamed"), image: icon, dmChannel: channelId, textSendPermissions: true, iconBase: iconBase ? iconBase : qsTr("Unnamed"), unread: unread, mentions: mentions}) })
            setHandler('dmUpdate', dmUpdateHandler)
            _refreshFirstPage = refreshHandler

            setHandler('connectionError', function(e){ shared.showError(qsTranslate("Errors", "Connection failure"), e) })
            setHandler('loginFailure', function(e){ shared.showError(qsTranslate("Errors", "Login failure"), e) })
            setHandler('captchaError', function(e){ shared.showError(qsTranslate("Errors", "Captcha required but not implemented"), e) })
            setHandler('notfoundError', function(e){ shared.showError(qsTranslate("Errors", "404 Not Found"), e) })
            setHandler('messageError', function(e){ shared.showError(qsTranslate("Errors", "A message failed to load"), e) })
            setHandler('referenceError', function(e){ shared.showError(qsTranslate("Errors", "A reference failed to load"), e) })
            setHandler('channelError', function(e){ shared.showError(qsTranslate("Errors", "Channel failed to load"), e) })
            setHandler('unknownPrivateChannel', function(e){ shared.showError(qsTranslate("Errors", "Unknown private channel: %1. Please report this to developers").arg(e)) })
            setHandler('cacheConnectionError', function(e){ shared.showError(qsTranslate("Errors", "Unable to receive cache: connection failed"), e) })
            setHandler('cacheError', function(name, e){ shared.showError(qsTranslate("Errors", "Unknown caching error"), name+": "+e) })

            addImportPath(Qt.resolvedUrl("../python"))
            importModule('main', function() {
                reloadConstants()
                initialized = true
            })
        }

        onError: shared.showError(qsTranslate("Errors", "Python error"), traceback)
        onReceived: console.log("got message from python: " + data)

        function login(token) { call('main.comm.login', [token]) }

        function request(func, handlerName, args, handler) {
            setHandler(handlerName, handler)
            call('main.comm.'+func, args)
        }
        function reset(handler) {
            // we unset handler so app won't crash on operating destroyed items
            // undefined is not used for messages not to be logged
            py.setHandler(handler, function() {})
        }

        function requestChannels(guildid){ call('main.comm.get_channels', [guildid]) }
        function setCurrentChannel(guildid, channelid) { call('main.comm.set_channel', [guildid, channelid]) }
        function resetCurrentChannel() { setCurrentChannel("", "") }

        function clearCache() { call('main.comm.clear_cache', []) }
        function setCachePeriod(period) {
            if (!initialized) return;
            call('main.comm.set_cache_period', [period])
        }

        function sendMessage(text) { call('main.comm.send_message', [text]) }
        function requestOlderHistory(messageId) { call('main.comm.get_history_messages', [messageId])}

        function disconnectClient() {
            if (!initialized || appConfiguration.token.length <= 0) return;
            call_sync('main.comm.disconnect')
        }

        function requestUserInfo(userId) { call('main.comm.request_user_info', [userId])}

        function getProxy() {
            switch (appSettings.proxyType) {
            case "g": return globalProxy.url
            case "n": return ''
            case "c": return appSettings.customProxy
            }
        }

        function getReference(channel, message, callback) { call2('get_reference', [channel, message], callback)}

        function refresh() {
            disconnectClient()
            reloadConstants()
            _refreshFirstPage()
        }

        function reloadConstants() { call('main.comm.set_constants', [StandardPaths.cache, appSettings.cachePeriod, StandardPaths.download, getProxy(), Theme.fontSizeMedium, appSettings.unreadState]) }

        function call2(name, args, callback) { call('main.comm.'+name, args, callback) }
    }
}
