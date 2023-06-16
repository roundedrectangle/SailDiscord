#include "settings.h"

Settings::Settings(QObject *parent) : QObject(parent), settings(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/io.github.roundedrectangle/SailDiscord/settings.conf", QSettings::NativeFormat) {

}
