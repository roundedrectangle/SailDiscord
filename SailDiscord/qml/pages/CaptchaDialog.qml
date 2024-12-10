import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0

Dialog {
    backNavigation: false
    allowedOrientations: Orientation.All

    property bool __captcha_dialog: true
    property string sitekey

    //canAccept: loader.token !== ""
    //onAccepted: appConfiguration.token = loader.token

    onAccepted: {
        pyShared.setHCaptcha('')
    }

    SilicaFlickable {
        anchors.fill: parent

        Column {
            id: column
            anchors.fill: parent

            DialogHeader {
                id: header
                title: qsTr("Please wait")
                Label {
                    parent: header.extraContent
                    text: qsTr("Are you a human?")
                    color: Theme.highlightColor
                }
            }

            WebView {
                property string result: ""

                id: webview
                width: parent.width
                height: parent.height = header.height

                 /*function getToken() {
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
                 }*/

                 Component.onCompleted: {
                     loadHtml('<html>
  <head>
    <title>hCaptcha</title>
    <script src="https://hcaptcha.com/1/api.js" async defer></script>
  </head>
  <body>
    <div class="h-captcha" data-sitekey="%1"></div>
    <script>
      function captchaCallback(response) {
        alert(response)
      }
    </script>
  </body>
</html>'.arg(sitekey))
                     console.log('<html>
  <head>
    <title>hCaptcha</title>
    <script src="https://hcaptcha.com/1/api.js" async defer></script>
  </head>
  <body>
    <div class="h-captcha" data-sitekey="%1"></div>
    <script>
      function captchaCallback(response) {
        alert(response)
      }
    </script>
  </body>
</html>'.arg(sitekey))
                     }
            }
        }
    }
}
