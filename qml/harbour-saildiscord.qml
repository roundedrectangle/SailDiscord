import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import 'components'
import io.thp.pyotherside 1.5
import Nemo.Configuration 1.0
import QtGraphicalEffects 1.0
import Nemo.Notifications 1.0
import Sailfish.Share 1.0
import Nemo.DBus 2.0

ApplicationWindow {
    id: mainWindow
    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Component.onDestruction: py.disconnectClient()

    Shared {
        id: shared
        onActiveChanged: py.runUpdate('active', active)
    }

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
        onUrlChanged: py.call2('set_proxy', py.getProxy())

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

    ConfigurationGroup {
        id: appConfiguration
        path: "/apps/harbour-saildiscord"

        property string token: ''
        property bool legacyMode: false
        property string modernLastServerId: '-1'
        property string serverLastChannels: '{}'

        function removeValue(value, root) { shared.removeConfigurationValue(root ? appConfiguration : appSettings, value) }

        Component.onCompleted: {
            if (appSettings.sentBehaviour != "r" && appSettings.sentBehaviour != "n")
                appSettings.sentBehaviour = "r"
            removeValue('usernameTutorialCompleted', true)
            removeValue('folders')
            removeValue('defaultUnknownReferences')
            removeValue('emptySpace')
        }

        ConfigurationGroup {
            id: appSettings
            path: "settings"

            // Behavior
            property bool defaultUnknownMessages: false
            property bool sendByEnter: false
            property bool focusAfterSend: true
            property bool focudOnChatOpen: false
            property bool modernUIServersQuickScroll: true

            // Appearance (Look and feel)
            //property bool emptySpace: false
            property string sentBehaviour: 'r'
            property bool alignMessagesText: true
            property bool modernUI: false
            property string messageGrouping: 'd'
            property string oneAuthorPadding: 'a'
            property bool highContrastMessages: false
            property bool twemoji: true

            // Session
            property int cachePeriod: 1

            // Spying
            property bool ignorePrivate: false

            // Advanced
            property string proxyType: 'g'
            property string customProxy: ''
            property bool infoInNotifications: false
            property bool unformattedText: false
            property bool unreadState: true
            property bool friendRequests: false
            property bool developerMode: false

            onCachePeriodChanged: py.runUpdate('cache_period', cachePeriod)
        }
    }

    Python {
        id: py
        property bool initialized: false
        property var _refreshFirstPage: function() {}

        function init(loggedInHandler, serversModel, dmHandler, dmUpdateHandler, refreshHandler) {
            setHandler('logged_in', loggedInHandler) // function(username, icon, status, isOnMobile)
            setHandler('server', function() {
                serversModel.append(shared.processServer.apply(null, arguments))
                shared.serverAdded(arguments[0], serversModel.count-1, -1)
            })
            setHandler('serverfolder', function(_id, name, color, servers) {
                var data = {image: {}, folder: true, _id: _id, name: shared.emojify(name), color: color, servers: []}
                servers.forEach(function(server, i) { data.servers.push(shared.processServer.apply(null, server)) })
                serversModel.append(data)
                servers.forEach(function(server, i) { shared.serverAdded(server[0], serversModel.count-1, i) })
            })
            setHandler('dm', function(channelId, unread, mentions, name, icon, perm, _id) { dmHandler({_id: _id, name: shared.emojify(name), image: icon, dmChannel: channelId, textSendPermissions: perm, iconBase: '', unread: unread, mentions: mentions}) })
            setHandler('group', function(channelId, unread, mentions, name, icon, iconBase) { dmHandler({_id: '-1', name: name ? shared.emojify(name) : qsTr("Unnamed", "group"), image: icon, dmChannel: channelId, textSendPermissions: true, iconBase: iconBase ? iconBase : qsTr("Unnamed"), unread: unread, mentions: mentions}) })
            setHandler('dmUpdate', dmUpdateHandler)
            _refreshFirstPage = refreshHandler

            var errorStrings = {
                connection: qsTranslate("Errors", "Connection failure"),
                login: qsTranslate("Errors", "Login failure"),
                captcha: qsTranslate("Errors", "Captcha required but not implemented"),
                '404': qsTranslate("Errors", "404 Not Found"),
                message: qsTranslate("Errors", "A message failed to load"),
                reference: qsTranslate("Errors", "A reference failed to load"),
                channel: qsTranslate("Errors", "Channel failed to load"),
                userInfo: qsTranslate("Errors", "Could not get user information"),
                serverInfo: qsTranslate("Errors", "Could not get server information"),
                unknownPrivateChannel: qsTranslate("Errors", "Unknown private channel: %1. Please report this to developers"),
                discord: qsTranslate("Errors", "Ignoring Discord error: %1"),

                // Caching
                cacheConnection: qsTranslate("Errors", "Unable to receive cache: connection failed"),
                cache: qsTranslate("Errors", "Unknown caching error"),
            }

            setHandler('error', function(name, info, other) {
                if (name in errorStrings) var text = errorStrings[name]
                else {
                    // generally should not happen unless I forget to put an error
                    shared.showError(qsTranslate("Errors", "Unknown error: %1").arg(name), info + ": " + JSON.stringify(other))
                    return
                }

                switch(name) {
                case 'unknownPrivateChannel':
                    shared.showError(text.arg(info))
                    break
                case 'cache':
                    shared.showError(text, info+': '+other)
                    break
                case 'discord':
                    shared.showError(text.arg(info), other)
                default:
                    shared.showError(text, info)
                }
            })

            addImportPath(Qt.resolvedUrl('../lib/deps'))
            addImportPath(Qt.resolvedUrl('../python'))
            importModule('main', function() {
                reloadConstants()
                initialized = true
            })
        }

        onError: shared.showError(qsTranslate("Errors", "Python error"), traceback)
        onReceived: console.log("got message from python: " + data)

        function call2(name, args, callback) { call('main.comm.'+name, typeof args === 'undefined' ? [] : (Array.isArray(args) ? args : [args]), callback) }
        function request(func, handlerName, args, handler) {
            setHandler(handlerName, handler)
            call2(func, args)
        }
        function reset(handler, empty) {
            // we unset handler so app won't crash on operating destroyed items
            // undefined is not used for messages not to be logged
            py.setHandler(handler, empty ? undefined : function() {})
        }

        function setCurrentChannel(guildid, channelid) { call2('set_channel', [guildid, channelid]) }
        function resetCurrentChannel() { setCurrentChannel("", "") }

        function runUpdate(name, value) {
            if (!initialized) return
            call2('set_'+name, value)
        }

        function disconnectClient() {
            if (!initialized || appConfiguration.token.length <= 0) return
            call_sync('main.comm.disconnect')
        }

        function getProxy() {
            switch (appSettings.proxyType) {
            case 'g': return globalProxy.url
            case 'n': return ''
            case 'c': return appSettings.customProxy
            }
        }

        function getReference(channel, message, callback) { call2('get_reference', [channel, message], callback) }

        function refresh() {
            disconnectClient()
            reloadConstants()
            _refreshFirstPage()
        }

        function reloadConstants() { call2('set_constants', [StandardPaths.cache, appSettings.cachePeriod, StandardPaths.download, getProxy(), Theme.fontSizeMedium, appSettings.unreadState, shared.active]) }
    }
}
