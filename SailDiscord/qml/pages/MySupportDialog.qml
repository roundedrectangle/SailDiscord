import QtQuick 2.0
import Sailfish.Silica 1.0
import "../modules/Opal/SupportMe"

SupportDialog {
    SupportAction {
        icon: SupportIcon.Weblate
        title: qsTr("Translate on Weblate")
        description: qsTr("Help with translating this app in as many " +
                            "languages as possible.")
        link: "https://weblate.zaborostroitelnyuniversity.ru/projects/saildiscord"
    }

    SupportAction {
        icon: SupportIcon.Git
        title: qsTr("Develop on Github")
        description: qsTr("Support with maintenance and packaging, " +
                            "write code, or provide valuable bug reports.")
        link: "https://github.com/roundedrectangle/SailDiscord"
    }
}
