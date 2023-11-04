import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5


Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    property bool loading: true
    property bool loggingIn: false

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
        id: firstPageContainer
        anchors.fill: parent

        BusyLabel {
            text: "Loading"
            running: loading
        }

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Second Page")
                onClicked: pageStack.push("SecondPage.qml")
            }

            MenuItem {
                text: qsTr("Login")
                onClicked: pageStack.push("LoginDialog.qml")
            }
        }

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height
        contentWidth: column.width

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("UI Template")
            }
            Label {
                x: Theme.horizontalPageMargin
                text: appSettings.token
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl("./python"));

            importModule('communicator', function () {});
        }

        onError: {
            // when an exception is raised, this error handler will be called
            console.log('python error: ' + traceback);
        }

        onReceived: {
            // asychronous messages from Python arrive here
            // in Python, this can be accomplished via pyotherside.send()
            console.log('got message from python: ' + data);
        }

        function login(token) {
            loading = true;
            call('communicator.comm.login', [token], function() {})
        }
    }
}
