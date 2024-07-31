#include "settings.h"

Settings::Settings(QObject *parent) : QObject(parent), settings(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/io.github.roundedrectangle/SailDiscord/settings.conf", QSettings::NativeFormat) {

}

QString Settings::token() const
{
    return settings.value("token", "").toString();
}

void Settings::setToken(QString token)
{
    if (this->token() != token) {
        settings.setValue("token", token);
        emit tokenChanged();
    }
}


bool Settings::emptySpace() const
{
    return settings.value("emptySpace", "").toBool();
}

void Settings::setEmptySpace(bool emptySpace)
{
    if (this->emptySpace() != emptySpace) {
        settings.setValue("emptySpace", emptySpace);
        emit emptySpaceChanged();
    }
}


bool Settings::ignorePrivate() const
{
    return settings.value("ignorePrivate", "").toBool();
}

void Settings::setIgnorePrivate(bool ignorePrivate)
{
    if (this->ignorePrivate() != ignorePrivate) {
        settings.setValue("ignorePrivate", ignorePrivate);
        emit ignorePrivateChanged();
    }
}


QString Settings::serverSize() const
{
    return settings.value("serverSize", "").toString();
}

void Settings::setServerSize(QString serverSize)
{
    if (this->serverSize() != serverSize) {
        settings.setValue("serverSize", serverSize);
        emit serverSizeChanged();
    }
}


QString Settings::messageSize() const
{
    return settings.value("messageSize", "").toString();
}

void Settings::setMessageSize(QString messageSize)
{
    if (this->messageSize() != messageSize) {
        settings.setValue("messageSize", messageSize);
        emit messageSizeChanged();
    }
}


bool Settings::messagesLessWidth() const
{
    return settings.value("messagesLessWidth", "").toBool();
}

void Settings::setMessagesLessWidth(bool messagesLessWidth)
{
    if (this->messagesLessWidth() != messagesLessWidth) {
        settings.setValue("messagesLessWidth", messagesLessWidth);
        emit messagesLessWidthChanged();
    }
}


QString Settings::sentBehaviour() const
{
    return settings.value("sentBehaviour", "").toString();
}

void Settings::setSentBehaviour(QString sentBehaviour)
{
    if (this->sentBehaviour() != sentBehaviour) {
        settings.setValue("sentBehaviour", sentBehaviour);
        emit sentBehaviourChanged();
    }
}


QString Settings::messagesPadding() const
{
    return settings.value("messagesPadding", "").toString();
}

void Settings::setMessagesPadding(QString messagesPadding)
{
    if (this->messagesPadding() != messagesPadding) {
        settings.setValue("messagesPadding", messagesPadding);
        emit messagesPaddingChanged();
    }
}


bool Settings::alignMessagesText() const
{
    return settings.value("alignMessagesText", "").toBool();
}

void Settings::setAlignMessagesText(bool alignMessagesText)
{
    if (this->alignMessagesText() != alignMessagesText) {
        settings.setValue("alignMessagesText", alignMessagesText);
        emit alignMessagesTextChanged();
    }
}


bool Settings::oneAuthor() const
{
    return settings.value("oneAuthor", "").toBool();
}

void Settings::setOneAuthor(bool oneAuthor)
{
    if (this->oneAuthor() != oneAuthor) {
        settings.setValue("oneAuthor", oneAuthor);
        emit oneAuthorChanged();
    }
}


bool Settings::oneAuthorPadding() const
{
    return settings.value("oneAuthorPadding", "").toBool();
}

void Settings::setOneAuthorPadding(bool oneAuthorPadding)
{
    if (this->oneAuthorPadding() != oneAuthorPadding) {
        settings.setValue("oneAuthorPadding", oneAuthorPadding);
        emit oneAuthorPaddingChanged();
    }
}
