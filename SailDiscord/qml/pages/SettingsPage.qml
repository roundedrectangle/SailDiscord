import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "../components"

Page {
    id: settingsPage
    allowedOrientations: Orientation.All


    SilicaFlickable {
        id: settingsContainer
        width: parent.width
        height: parent.height
        bottomMargin: Theme.paddingLarge

        PageHeader {
            id: header
            title: qsTr("Settings")
        }

        /*SectionHeader {
            text: qsTr("Session")
        }*/

        /*ExpandingSectionGroup {
            anchors {
                top: header.bottom
                bottom: parent.bottom
            }


            currentIndex: 0

            ExpandingSection {
                anchors {

                }

                id: sessionSection

                title: qsTr("Session")

                content.sourceComponent: Column {
//                    width: sessionSection.width

                    Button {
                        text: "Log out"
                        onClicked: {
                            appSettings.setToken("");
                        }
                    }
                }
            }
        }*/

        ExpandingSectionGroup {
            anchors {
                top: header.bottom
                bottom: parent.bottom
            }

            //currentIndex: 0

            ExpandingSection {
                id: section

                //property int sectionIndex: model.index
                title: qsTr("Behaviour")

                content.sourceComponent: Column {
                    width: section.width

                    TextSwitch {
                        text: qsTr("Keep empty space in servers without icons")
                        onCheckedChanged: {
                            appSettings.setEmptySpace(checked)
                        }

                        Component.onCompleted: {
                            checked = appSettings.emptySpace;
                        }
                    }

                    TextSwitch {
                        text: qsTr("Ignore private setting for channels and channel categories")
                        onCheckedChanged: {
                            appSettings.setIgnorePrivate(checked)
                        }

                        Component.onCompleted: {
                            checked = appSettings.ignorePrivate;
                        }
                    }
                }
            }

            ExpandingSection {
                id: sessionSection

                //property int sectionIndex: model.index
                title: qsTr("Session")

                content.sourceComponent: Column {
                    width: sessionSection.width

                    Button {
                        text: qsTr("Log out")
                        onClicked: {
                            appSettings.setToken("");
                        }
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
