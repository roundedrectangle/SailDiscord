import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"


Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    property bool loading: true
    property bool loggingIn: false
    property string username: ""

    Timer {
        //credit: Fernschreiber
        id: openLoginDialogTimer
        interval: 0
        onTriggered: {
            pageStack.push(Qt.resolvedUrl("LoginDialog.qml"))
        }
    }

    function updatePage() {
        console.log(loggingIn.toString() + " " + loading.toString())
        if (appSettings.token == "" && !loggingIn) {
            loggingIn = true
            loading = false
            openLoginDialogTimer.start()
        } else { // logged in, connect with python
            loggingIn = false
            python.login(appSettings.token)
        }
        console.log(loggingIn.toString() + " " + loading.toString())
    }

    Connections {
        target: appSettings

        onTokenChanged: updatePage()
    }

    Component.onCompleted: {
        //appSettings.setToken("")
        console.log("Completed!")
        updatePage()
    }

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
    //SilicaListView {
        id: firstPageContainer
        anchors.fill: parent

        BusyLabel {
            text: "Loading"
            running: loading
        }

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            busy: loading

            MenuItem {
                text: qsTr("Second Page")
                onClicked: pageStack.push("SecondPage.qml")
            }

            MenuItem {
                text: qsTr("Login")
                onClicked: pageStack.push("LoginDialog.qml")
            }
        }

        PageHeader {
            id: header_name
            title: username
        }

        Label {
            id: appname
            anchors.top: header_name.bottom
            x: Theme.horizontalPageMargin
            text: qsTr("SailDiscord")
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeExtraLarge
        }

        // Tell SilicaFlickable the height of its content.
        //contentHeight: column.height
        //contentWidth: column.width

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.

        /*Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            visible: !loading
            PageHeader {
                title: username
            }
            /*Label {
                x: Theme.horizontalPageMargin
                text: qsTr("SailDiscord")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }/*

            ExpandingSectionGroup {

                ExpandingSection {
                    id: dmSection
                    title: qsTr("Direct Messages")

                    content.sourceComponent: SilicaListView {
                       id: dmList
                    }
                }

                ExpandingSection {
                    id: serversSection
                    title: qsTr("Servers")

                    content.sourceComponent: SilicaListView {
                        id: serversList
                        model: serversModel
                        anchors.top: parent
                        anchors.bottom: parent

                        ViewPlaceholder {
                            enabled: serversModel.count === 0
                            text: "No servers"
                            hintText: "Pull down to join (TODO)"
                        }
                    }
                }
            }*/

                //anchors.top: appname.bottom
                //model: serversModel

        SilicaListView {

            anchors {
                top: appname.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }

            id: serversListView
            model: serversModel

            delegate: ListItem {
                width: parent.width
                //ListView.view.width
               height: Theme.itemSizeSmall

               //Label {
               //    text: name
               //}
               ServerListItem {
                   title: name
                   icon: icon
               }
            }
        }
    }

    ListModel {
        id: serversModel

        function find(pattern) {
            for (var i = 0; i<count; i++) if (pattern(get(i))) return get(i)
            return null
        }

        function findById(_id) { return find(function (item) { return item.id === _id }) }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl("./python"));

            setHandler('logged_in', function(_username) {
                loading = false;
                username = _username
            })

            setHandler('server', function(_id, _name, _icon) { serversModel.append({"id": _id, "name": _name, "icon": _icon/*, "chunked": true, "memberCount": 0*/}) })

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
            loading = true;
            call('communicator.comm.login', [token], function() {})
        }

        function updateServer(what, updater) {
            var arr = what.split('~')
            const id = arr.shift()
            updater(serversModel.findById(id), arr.join(' '))
        }
    }
}
