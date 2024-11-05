import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0
import harboursaildiscord.Logic 1.0

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

            Loader {
                id: loader
                property string token: status == Loader.Ready ? (useToken ? item.token : item.getToken()) : ""
                width: parent.width
                height: parent.height - header.height
                sourceComponent: useToken ? tokenLogin : webViewLogin
            }
        }
    }

    Component {
        id: webViewLogin
        WebView {
            property string discord_token: ""

            id: webview
            url: "https://discord.com/login"
            anchors.fill: parent

             function getToken() {
                 // if the webpage is loaded and there's a token, return it (string).
                 // otherwise return an empty string
                 if (!loaded) return ""
                 updateToken()
                 return discord_token
             }

             function updateToken() {
                 webview.runJavaScript(
                     // this code returns the token:
                     "return (webpackChunkdiscord_app.push([[''],{},e=>{m=[];for(let c in e.c)m.push(e.c[c])}]),m).find(m => m?.exports?.default?.getToken).exports.default.getToken()",

                     function (res) { if (res !== null) webview.discord_token = res }, // callback: if there is a token, store it in discord_token
                     function (err) {}// showError(qsTranslate("Errors", "Error getting token: %1").arg(err)) } // error callback
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
