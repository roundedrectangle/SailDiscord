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
    appIcon: Qt.resolvedUrl("../../images/%1.png".arg(Qt.application.name))
    appVersion: "0.0.61"
    appRelease: "1"
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
    contributionSections: [
        ContributionSection {
            title: qsTr("Translations")
            groups: [
                ContributionGroup {
                    title: qsTr("Italian")
                    entries: ["legacychimera247"]
                }
            ]
        }

    ]
}
