import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

ListItem {
    property var reference

    property string contents
    property string author
    property date date
    property bool loaded: false

    id: root
    width: parent.width
    contentHeight: column.height

    Column {
        id: column
        width: parent.width

        Label {
            text: contents
        }

        /*Loader {
            sourceComponent: reference == '-1' ? null : referenceComponent
            anchors.fill: parent
            asynchronous: true
            Component {
                id: referenceComponent
                MessageReference {

                }
            }
        }

        Label {
            property bool loaded: false
            visible: reference != '-1'
            text: qsTr("Loading reference...")
            color: loaded ? Theme.primaryColor : Theme.secondaryColor

            Component.onCompleted: {
                if (reference == '-1') return
                python.getReference(reference, function(data) { text = data[11]; loaded = true })
            }
        }

        Row {
            id: row
            //width: parent.width
            width: {
                if(_firstSameAuthor) {
                    if (appSettings.sentBehaviour !== "n")
                        return Math.min(parent.width - _sentLessWidth,
                                        _infoWidth + Math.max(contentsLbl.implicitWidth, infoRow.width));
                    else return parent.width-_sentLessWidth
                } else return Math.max(masterWidth,
                                       Math.min(parent.width-_sentLessWidth,
                                                _infoWidth + contentsLbl.implicitWidth));
            }
            height: !_firstSameAuthor ? textContainer.height : childrenRect.height
            // align right if sent and set to reversed/right aligned
            anchors.right: (sent && appSettings.sentBehaviour !== "n") ? parent.right : undefined
            // reverse if sent and set to reversed
            layoutDirection: (sent && appSettings.sentBehaviour === "r") ? Qt.RightToLeft : Qt.LeftToRight

            Item { id: leftPadding; height: 1; width: switch (appSettings.messagesPadding) {
               default: case "n": return 0
               case "s": return (visible && sent) ? Theme.horizontalPageMargin : 0
               case "r": return (visible && sent) ? 0 : Theme.horizontalPageMargin
               case "a": return visible ? Theme.horizontalPageMargin : 0
            }
                visible: _firstSameAuthor || appSettings.oneAuthorPadding !== "n"
            }

            ListImage {
                id: profileIcon
                icon: _firstSameAuthor ? pfp : ""
                visible: _firstSameAuthor || (appSettings.oneAuthorPadding === "p")
                opacity: _firstSameAuthor ? 1 : 0
                errorString: author
            }

            Item { id: iconPadding; height: 1; width: visible ? Theme.paddingLarge : 0;
                // visible the same as for authorLbl or profileIcon; but if oneAuthorPadding is enabled then ignore everything and set to true
                visible: _firstSameAuthor || appSettings.oneAuthorPadding !== "n";
            }

            Column {
                id: textContainer
                width: {
                    if(_firstSameAuthor) {
                        if (appSettings.sentBehaviour === "a") // If sentBehaviour is right-aligned,
                        return Math.min(parent.width - _infoWidth, Math.max(contentsLbl.paintedWidth, infoRow.width))
                        else return (parent.width - _infoWidth)
                    } else return parent.width - _infoWidth;
                }
                Row {
                    id: infoRow
                    visible: _firstSameAuthor
                    spacing: Theme.paddingSmall
                    Label {
                        id: authorLbl
                        text: author
                        color: Theme.secondaryColor
                    }

                    Label {
                        id: timeLbl
                        text: Format.formatDate(date, Formatter.TimepointRelative)
                        color: Theme.secondaryHighlightColor
                    }
                }

                Label {
                    id: contentsLbl
                    text: contents
                    wrapMode: Text.Wrap
                    width: Math.min(parent.width, implicitWidth)
                                   // if sent, sentBehaviour is set to reversed or right-aligned, and aligning text is enabled
                    anchors.right: (sent && appSettings.sentBehaviour !== "n" && appSettings.alignMessagesText) ? parent.right : undefined
                }

                Item { height: _firstSameAuthor ? Theme.paddingLarge : Theme.paddingSmall; width: 1; }
            }
        }

        AttachmentsPreview { model: root.attachments }*/
    }

    Component.onCompleted: {
        if (reference['type'] == 0) return
        python.getReference(reference['channel'], reference['message'], function(data) { contents = data[11]; author = data[7]; date = new Date(data[4]); loaded = true })
    }
}
