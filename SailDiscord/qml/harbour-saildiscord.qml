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
            path: "/settings"

            property bool emptySpace: false
            property bool ignorePrivate: false
            property bool messagesLessWidth: false
            property bool alignMessagesText: false
            property bool oneAuthor: true

            property string sentBehaviour: "r"
            property string messagesPadding: "n"
            property string oneAuthorPadding: "n"
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl("./python"));

            setHandler('logged_in', function(_username) {
                myPage.loading = false;
                myPage.username = _username;
            })

            setHandler('server', function(_id, _name, _icon, _memberCount) { myPage.serversModel.append({"id": _id, "name": _name, "image": _icon, "memberCount": _memberCount}) })

            //setHandler('SERVERname', function (what) { updateServer(what, function(item, name) { item.name  = name }) })
            //setHandler('SERVERchunked', function (what) { updateServer(what, function(item, chunked) { item.chunked = chunked }) })
            //setHandler('SERVERmember_count', function (what) { updateServer(what, function(item, memberCount) { item.memberCount = memberCount }) })

            importModule('communicator', function () {});
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
            call('communicator.comm.get_categories', [guildid], function() {})
        }

        function requestChannels(guildid, categoryid) {
            call('communicator.comm.get_channels', [guildid, categoryid], function() {})
        }

        function setCurrentChannel(guildid, channelid) {
            call('communicator.comm.set_channel', [guildid, channelid], function() {})
        }

        function resetCurrentChannel() {
            setCurrentChannel("", "")
        }
    }
}
