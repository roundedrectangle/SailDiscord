#include "settings.h"

Settings::Settings(QObject *parent) : QObject(parent), settings(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/io.github.roundedrectangle/SailDiscord/settings.conf", QSettings::NativeFormat) {

}

QString Settings::token()
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
