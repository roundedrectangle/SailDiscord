import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"
import "../modules/Opal/About"
import "../modules/Opal/Attributions"

AboutPageBase {
    id: page
    allowedOrientations: Orientation.All

    appName: "Sailcord"
    appIcon: Qt.resolvedUrl("../../images/%1.png".arg(Qt.application.name))
    appVersion: APP_VERSION
    appRelease: APP_RELEASE
    sourcesUrl: "https://github.com/roundedrectangle/SailDiscord"
    licenses: License { spdxId: "GPL-3.0-or-later" }
    description: qsTr("A SailfishOS Discord client")
    autoAddOpalAttributions: true

    authors: "roundedrectangle"
    attributions: [
        Attribution {
            name: "discord.py-self"
            entries: ["dolfies", "2015-present Rapptz"]
            licenses:License { spdxId: "MIT" }
            sources: "https://github.com/dolfies/discord.py-self"
            homepage: "https://discordpy-self.rtfd.io/en/latest/"
        },
        Attribution {
            name: qsTr("Tester")
            entries: "247"
            homepage: "https://github.com/legacychimera247"
        },
        Attribution {
            name: "Showdown"
            entries: "2018,2021 ShowdownJS"
            licenses:License { spdxId: "MIT" }
            sources: "https://github.com/showdownjs/showdown"
            homepage: "http://www.showdownjs.com/"
        },
        Attribution {
            name: "Twemoji"
            entries: ["2022–present Jason Sofonia & Justine De Caires", "2014–2021 Twitter"]
            licenses:License { spdxId: "MIT" }
            sources: "https://github.com/jdecked/twemoji"
            homepage: "https://jdecked.github.io/twemoji/index.html"
        }
    ]
    contributionSections: [
        ContributionSection {
            title: qsTr("Translations")
            groups: [
                ContributionGroup {
                    title: qsTr("Italian")
                    entries: ["247"]
                },
                ContributionGroup {
                    title: qsTr("Swedish")
                    entries: ["eson57"]
                }
            ]
        }
    ]

    extraSections: [
        InfoSection {
            buttons: [
                InfoButton {
                    text: "Telegram"
                    onClicked: page.openOrCopyUrl("https://t.me/saildiscord")
                }
            ]
        },
        InfoSection {
            title: qsTr("Disclaimer")
            text: qsTr("Discord is trademark of Discord Inc. Sailcord is in no way associated with Discord Inc. Using Sailcord violates Discord's terms of service. Use at your own risk")
        }
    ]
}
