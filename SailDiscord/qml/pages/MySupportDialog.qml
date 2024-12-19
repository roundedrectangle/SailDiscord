import QtQuick 2.0
import Sailfish.Silica 1.0
import "../modules/Opal/SupportMe"

SupportDialog {
    SupportAction {
        icon: SupportIcon.Git
        title: qsTr("View translating guide")
        description: qsTr("Help with translating this app in as many " +
                            "languages as possible.")
        //link: "https://weblate.zaborostroitelnyuniversity.ru/projects/saildiscord"
        link: "https://gist.github.com/roundedrectangle/c4ac530ca276e0d65c3593b8491473b6"
    }

    SupportAction {
        icon: Qt.resolvedUrl("../../images/%1.png".arg(Qt.application.name))
        title: qsTr("Help testing beta versions")
        description: qsTr("Get new features earlier. Remember to report any bugs you find!")
        link: "https://github.com/roundedrectangle/SailDiscord/releases"
    }

    SupportAction {
        icon: SupportIcon.Git
        title: qsTr("Develop on Github")
        description: qsTr("Support with maintenance and packaging, " +
                            "write code, or provide valuable bug reports.")
        link: "https://github.com/roundedrectangle/SailDiscord"
    }
}
