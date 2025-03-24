import QtQuick 2.0
import Sailfish.Silica 1.0
import "../modules/js/showdown.min.js" as ShowDown
import "../modules/js/twemoji.min.js" as Twemoji

QtObject {
    property var showdown: new ShowDown.showdown.Converter({
            simplifiedAutoLink: true,
            underline: true,
            backslashEscapesHTMLTags: true,
        })

    function log() {
      var f = ""
      for (var i = 0; i < arguments.length; i++) {
        f += arguments[i]
        if (i != arguments.length-1) f += "|||"
      }
      console.log(f)
    }

    function markdown(text, linkColor, edited) {
        var e = emojify(text)
        return "<style>a:link{color:" + (linkColor ? linkColor : Theme.highlightColor) + ";}</style>"
                    +showdown.makeHtml(((appSettings.twemoji && /^<img/.test(e)) ? '<span style="color:transparent">.</span>': '')
                                       +e
                                       +(edited ? (" <a href='sailcord://showEditDate' style='text-decoration:none;font-size:" + Theme.fontSizeExtraSmall + "px;color:"+ Theme.secondaryColor +";'>" + qsTr("(edited)") + "</a>") : "")
                                       )
    }

    function emojify(text) {
        if (!appSettings.twemoji) return text
        return Twemoji.twemoji.parse(text, { base: Qt.resolvedUrl('../../images/twemoji/'), attributes: function () { return { width: '%1'.arg(Theme.fontSizeMedium), height: '%1'.arg(Theme.fontSizeMedium) } } })
    }

    function showInfo(summary, text) {
        notifier.appIcon = "image://theme/icon-lock-information"
        notifier.summary = summary || ''
        notifier.body = text || ''
        notifier.publish()
    }

    function showError(summary, text) {
        notifier.appIcon = "image://theme/icon-lock-warning"
        notifier.summary = summary || ''
        notifier.body = text || ''
        notifier.publish()
        console.log(text)
    }

    function imageLoadError(name) {
        showError(qsTranslate("Errors", "Error loading image %1").arg(name))
    }

    function download(url, name) {
        py.call('main.comm.download_file', [url, name], function(r) {
            showInfo(qsTr("Downloaded file %1").arg(name))
        })
    }

    function shareFile(url, name, mime) {
        py.call('main.comm.save_temp', [url, name], function(path) {
            shareApi.mimeType = mime
            shareApi.resources = [path]
            shareApi.trigger()
        })
    }

    function constructMessageCallback(type, guildid, channelid, finalCallback) {
        return function(_serverid, _channelid, _id, _date, edited, editedAt, userinfo, history, attachments, jumpUrl) {
            if (guildid != undefined && channelid != undefined)
                if ((_serverid != guildid) || (_channelid != channelid)) return
            var data = {
                type: type, messageId: _id, _author: emojify(userinfo.name), _pfp: userinfo.pfp,
                _sent: userinfo.sent, _masterWidth: -1, _date: new Date(_date), _from_history: history,
                _wasUpdated: false, userid: userinfo.id, _attachments: attachments,
                _flags: {
                    edit: edited, bot: userinfo.bot, editedAt: editedAt,
                    system: userinfo.system, color: userinfo.color
                }, APIType: '', contents: '', formatted: '', _ref: {}, highlightStarted: false,
                jumpUrl: jumpUrl,
            }

            var extraStart = 10
            if (type === "" || type === "unknown") {
                data.contents = arguments[extraStart]
                data.formatted = markdown(arguments[extraStart+1], undefined, data._flags.edit)
                data._ref = arguments[extraStart+2]
            }
            if (type === "unknown") data.APIType = arguments[extraStart+3]
            finalCallback(history, data)
        }
    }

    function convertCallbackType(pyType) {
        switch(pyType) {
        case "message": return ''
        case "newmember": return 'join'
        case "unknownmessage": return 'unknown'
        }
    }

    function registerMessageCallbacks(guildid, channelid, finalCallback, editCallback) {
        // see convertCallbackType()
        py.setHandler("message", constructMessageCallback('', guildid, channelid, finalCallback))
        py.setHandler("newmember", constructMessageCallback('join', guildid, channelid, finalCallback))
        py.setHandler("unknownmessage", constructMessageCallback('unknown', guildid, channelid, finalCallback))
        py.setHandler("messageedit", function(before, event, args) {
            constructMessageCallback(convertCallbackType(event), guildid, channelid, function(history, data) {
                editCallback(before, data)
            }).apply(null, args)
        })
        py.setHandler("messagedelete", function(id) { editCallback(id) })
    }

    function cleanupMessageCallbacks() {
        // we unset handler so app won't crash on appending items to destroyed list because resetCurrentChannel is not instant
        py.reset("message")
        py.reset("newmember")
        py.reset("uknownmessage")
        py.reset("messageedit")
        py.reset("messagedelete")
    }

    function processServer(_id, name, icon) {
        if (appConfiguration.legacyMode && _id == "1261605062162251848") {
            name = "RoundedRectangle's server"
            icon = Qt.resolvedUrl("../images/%1.png".arg(Qt.application.name))
        }
        // heads up: QQMLListModel can convert:
        // arrays to QQMLListModel instances
        // undefined to empty objects aka {} when other elements are objects
        return {_id: _id, name: shared.emojify(name), image: icon,
            folder: false, color: '', servers: [], // QML seems to need same element keys in all model entries
        }
    }

    function attachmentsToListModel(_parent, attachments) {
        // Make attachments a ListModel: a (bug?) which exists in QML and I have to enable it manually where it is fixed
        // Also see https://stackoverflow.com/questions/37069565/qml-listmodel-append-broken-for-object-containing-an-array
        var listModel = Qt.createQmlObject('import QtQuick 2.0;ListModel{}', _parent)
        attachments.forEach(function(attachment, i) { listModel.append(attachment) })
        return listModel
    }

    function constructStatus(statusIndex, onMobile) {
        var result = ["",
                      qsTranslate("status", "Online"),
                      qsTranslate("status", "Offline"),
                      qsTranslate("status", "Do Not Disturb"),
                      qsTranslate("status", "Invisible"),
                      qsTranslate("status", "Idle")
                ][statusIndex]
        if (onMobile && result !== "")
            result += " "+qsTranslate("status", "(Phone)", "Used with e.g. Online (Phone)")
        return result
    }

    function loadLastChannels() {
        try { return JSON.parse(appConfiguration.serverLastChannels) }
        catch(e) { appConfiguration.serverLastChannels = "{}"; return {} }
    }

    function getLastChannel(serverid) {
        var loaded = loadLastChannels()
        return serverid in loaded ? loaded[serverid] : '-1'
    }

    function setLastChannel(serverid, channelid) {
        var loaded = loadLastChannels()
        loaded[serverid] = channelid
        appConfiguration.serverLastChannels = JSON.stringify(loaded)
    }

    function removeConfigurationValue(conf, value) {
        if (conf.value(value, null) !== null)
            conf.setValue(value, undefined)
    }

    function pythonErrorHandler(name, info, other) {
        switch(name){
        case 'connection':
            text = qsTranslate("Errors", "Connection failure")
            break
        case 'login':
            text = qsTranslate("Errors", "Login failure")
            break
        case 'captcha':
            text = qsTranslate("Errors", "Captcha required but not implemented")
            break
        case '404':
            text = qsTranslate("Errors", "404 Not Found")
            break
        case 'message':
            text = qsTranslate("Errors", "A message failed to load")
            break
        case 'reference':
            text = qsTranslate("Errors", "A reference failed to load")
            break
        case 'channel':
            text = qsTranslate("Errors", "Channel failed to load")
            break
        case 'unknownPrivateChannel':
            text = qsTranslate("Errors", "Unknown private channel: %1. Please report this to developers")
            break
        case 'cacheConnection':
            text = qsTranslate("Errors", "Unable to receive cache: connection failed")
            break
        case 'cache':
            text = qsTranslate("Errors", "Unknown caching error")
            break
        default:
            // generally should not happen unless I forget to put an error
            showError(qsTranslate("Errors", "Unknown error: %1").arg(name), info + ": " + JSON.stringify(other))
            return
        }
        switch(name) {
        case 'unknownPrivateChannel':
            showError(text.arg(info))
            break
        case 'cache':
            showError(text, info+': '+other)
            break
        default:
            showError(text, info)
        }
    }
}
