import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0
import harboursaildiscord.Logic 1.0

Dialog {
    id: loginDialog

    canAccept: webview.getToken() !== ""

    onAccepted: {
        appSettings.setToken(webview.getToken());
    }

    Column {
            id: column
            anchors.fill: parent

            DialogHeader {
                id: header
                title: "Please login"
                acceptText: "Log in"
            }

            WebView {
                    property string discord_token: ""

                    id: webview
                    url: "https://discord.com/login"
                    width: parent.width
                    // it didn't work with subtraction:
                    height: parent.height// - header.height

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

                                     function (res) {
                                         // callback: if there is a token, store it in discord_token
                                         if (res !== null) webview.discord_token = res;
                                     },

                                     function (err) {
                                         // error callback
                                         console.log("error getting token!")
                                         console.log(err)
                                     }

                                     )
                     }
           }
        }
    //}
}
