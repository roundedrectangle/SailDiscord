#include "settings.h"

SettingsMigrationAssistant::SettingsMigrationAssistant(QObject *parent) : QObject(parent) {

}

void SettingsMigrationAssistant::migrateConfiguration()
{
    QFile oldFile(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/io.github.roundedrectangle/SailDiscord/settings.conf");
    if (oldFile.exists()) oldFile.remove();
}
