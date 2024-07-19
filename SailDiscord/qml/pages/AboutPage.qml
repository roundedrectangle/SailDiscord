import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"
import "../modules/Opal/About"
import "../modules/Opal/Attributions"

AboutPageBase {
    id: page
    allowedOrientations: Orientation.All

    appName: qsTr("SailDiscord")
    appIcon: Qt.resolvedUrl("../../icons/%1.png".arg(Qt.application.name))
    appVersion: APP_VERSION
    appRelease: APP_RELEASE
    sourcesUrl: "https://github.com/roundedrectangle/SailDiscord"
    licenses: License { spdxId: "GPL-3.0-or-later" }
    description: qsTr("A SailfishOS Discord client")

    authors: "roundedrectangle"
    attributions: [
        OpalAboutAttribution { },
        Attribution {
            name: "discord.py-self"
            entries: "2015-present Rapptz"
            licenses:License { spdxId: "MIT" }
            sources: "https://github.com/dolfies/discord.py-self"
            homepage: "https://discordpy-self.rtfd.io/en/latest/"
        }

    ]
}
