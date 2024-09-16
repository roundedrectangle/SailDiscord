import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import io.thp.pyotherside 1.5
import harboursaildiscord.Logic 1.0
import Nemo.Configuration 1.0

ApplicationWindow {
    id: mainWindow
    initialPage: FirstPage { id: myPage } // TODO: bring back Component without removing Python from mainWindow
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

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
    }

    SettingsMigrationAssistant { id: migrateSettings }

    ConfigurationGroup {
        // An experimental configuration system replacing old C++ one
        id: appConfiguration
        path: "/apps/harbour-saildiscord"

        property string token: ""

        Component.onCompleted: {
            //clear()
            migrateSettings.migrateConfiguration()
        }

        ConfigurationGroup {
            id: appSettings
            path: "settings"

            property bool emptySpace: false
            property bool ignorePrivate: false
            property bool messagesLessWidth: false
            property bool alignMessagesText: false
            property bool sendByEnter: false
            property bool focusAfterSend: true
            property bool focudOnChatOpen: false

            property string sentBehaviour: "r"
            property string messagesPadding: "n"
            property string oneAuthorPadding: "n"
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

            call('communicator.comm.set_cache', [StandardPaths.cache, appSettings.cachePeriod], function() {})

            initialized = true
        }

        onError: {
            // when an exception is raised, this error handler will be called
            console.log('python error: ' + traceback);
            //Notices.show("err: "+traceback, Notice.Long, Notice.Center)
        }

        onReceived: {
            // asychronous messages from Python arrive here
            // in Python, this can be accomplished via pyotherside.send()
            console.log('got message from python: ' + data);
            //Notices.show("dat: "+data, Notice.Long, Notice.Center)
        }

        function login(token) {
            myPage.loading = true;
            call('communicator.comm.login', [token], function() {})
        }

        function updateServer(what, updater) {
            var arr = what.split('~')
            const id = arr.shift()
            updater(myPage.serversModel.findById(id), arr.join(' '))
        }

        function requestCategories(guildid) {
            //call('communicator.comm.get_categories', [guildid], function() {})
        }

        function requestChannels(guildid){//, categoryid) {
            //call('communicator.comm.get_channels', [guildid, categoryid], function() {})
            call('communicator.comm.get_channels', [guildid], function () {})
        }

        function setCurrentChannel(guildid, channelid) {
            call('communicator.comm.set_channel', [guildid, channelid], function() {})
        }

        function resetCurrentChannel() {
            setCurrentChannel("", "")
        }

        function clearCache() {
            call('communicator.comm.clear_cache', [], function() {})
        }

        function setCachePeriod(period) {
            if (!initialized) return;
            python.call('communicator.comm.set_cache_period', [period], function() {})
        }

        function sendMessage(text, callback) {
            python.call('communicator.comm.send_message', [text], callback)
        }
    }
}
