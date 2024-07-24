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
