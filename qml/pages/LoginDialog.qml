import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0

Dialog {
    id: loginDialog
    backNavigation: false
    allowedOrientations: Orientation.All

    canAccept: loader.token !== ""
    onAccepted: appConfiguration.token = loader.token

    property bool useToken: false

    SilicaFlickable {
        anchors.fill: parent
        PullDownMenu {
            MenuItem {
                text: qsTranslate("AboutApp", "About", "App")
                onClicked: pageStack.push("AboutPage.qml")
            }

            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push("SettingsPage.qml")
            }

            MenuItem {
                text: useToken ? qsTr("Use web page") : qsTr("Use token")
                onClicked: useToken = !useToken
            }
        }

        Column {
            id: column
            anchors.fill: parent

            DialogHeader {
                id: header
                title: qsTr("Please login")
                acceptText: qsTr("Login")
            }

            Column {
                id: troubleshootColumn
                visible: false

                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: visible ? implicitHeight : 0
                Behavior on height { NumberAnimation { duration: 200 } }
                spacing: Theme.paddingMedium

                Separator {
                    color: Theme.primaryColor
                    width: parent.width
                    horizontalAlignment: Qt.AlignHCenter
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.highlightColor
                    text: qsTr("Having trouble logging in?")
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    text: qsTr("Check the %1troubleshooting steps%2.").arg('<a href="%1">'.arg("https://github.com/roundedrectangle/SailDiscord#troubleshooting")).arg('</a>')
                    linkColor: Theme.highlightColor
                    bottomPadding: Theme.paddingLarge
                    onLinkActivated: Qt.openUrlExternally(link)
                }
            }

            Loader {
                id: loader
                property string token: status == Loader.Ready ? item.token : ''
                width: parent.width
                height: parent.height - header.height - troubleshootColumn.height
                sourceComponent: useToken ? tokenLogin : webViewLogin
            }
        }
    }

    Timer {
        interval: 45000
        running: true
        onTriggered: troubleshootColumn.visible = true
    }

    Component {
        id: webViewLogin
        WebView {
            id: webview
            anchors.fill: parent
            url: "https://discord.com/login"

            property string token

            Component.onCompleted: updateToken()
            onLoadedChanged: updateToken()
            onUrlChanged: updateToken()

             function updateToken() {
                 if (loaded) webview.runJavaScript(
                     // this code returns the token:
                     "iframe=document.createElement('iframe');document.body.append(iframe);token=JSON.parse(iframe.contentWindow.localStorage.token);iframe.remove();return token",

                     function (res) { if (res !== null) webview.token = res }, // callback
                     function (err) { shared.showError(qsTranslate("Errors", "Unable to retrieve token"), err)} // error callback
                 )
             }
        }
    }

    Component {
        id: tokenLogin

        Column {
            anchors.fill: parent
            property alias token: field.text

            TextField {
                id: field
                width: parent.width
                label: qsTr("Token")
            }
        }
    }
}
