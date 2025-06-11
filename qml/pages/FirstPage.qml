import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../js/shared.js" as Shared

Page {
    id: root
    allowedOrientations: Orientation.All

    property bool loading: true
    property string username: ""
    property var avatar
    property int status: 0
    property bool onMobile: false

    property alias dmModel: dmModel
    property alias serversModel: serversModel

    Timer {
        //credit: Fernschreiber
        id: openLoginDialogTimer
        interval: 0
        onTriggered: pageStack.push(Qt.resolvedUrl("LoginDialog.qml"))
    }

    function updatePage() {
        if (appConfiguration.token == "") {
            // For log out
            serversModel.clear()
            dmModel.clear()
            username = ""
            avatar = ""

            loading = false
            openLoginDialogTimer.start()
        } else { // logged in, connect with python
            loading = true
            py.call2('login', appConfiguration.token)
        }
    }

    Connections {
        target: appConfiguration
        onTokenChanged: updatePage()
    }

    Component.onCompleted: {
        py.init(function(u, i, s, m) {
            loading = false
            username = Shared.emojify(u)
            avatar = i
            status = s
            onMobile = m
        }, serversModel, dmModel.append, function(channelId, unread, mentions) {
            var i = dmModel.findIndexById(channelId)
            if (i >= 0) {
                dmModel.setProperty(i, 'unread', unread)
                dmModel.setProperty(i, 'mentions', mentions)
            }
        },
        function() {
            serversModel.clear()
            dmModel.clear()
            username = ""
            updatePage()
        })
        updatePage()
    }

    BusyLabel { running: loading }

    Loader {
        anchors.fill: parent
        sourceComponent: appSettings.modernUI ? modernComponent : classicComponent

        Component {
            id: classicComponent
            ClassicOverview {
                username: root.username
                dmModel: root.dmModel
                serversModel: root.serversModel
                loading: root.loading
            }
        }

        Component {
            id: modernComponent
            ModernOverview {
                username: root.username
                avatar: root.avatar
                status: root.status
                onMobile: root.onMobile
                dmModel: root.dmModel
                serversModel: root.serversModel
                loading: root.loading
            }
        }
    }

    ListModel {
        id: serversModel
        //dynamicRoles: true
        function findIndexById(id) {
            for(var i=0; i < count; i++) {
                if (get(i).folder) {
                    var s = get(i).servers
                    for (var j=0; j < s.length; j++)
                        if (s[j] == id) return [i, j]
                } else if (get(i)._id == id) return [i, -1]
            }
            return [-1, -1]
        }
    }
    ListModel {
        id: dmModel

        function findIndexById(id) {
            for(var i=0; i < count; i++)
                if (get(i).dmChannel == id) return i
            return -1
        }
    }
}
