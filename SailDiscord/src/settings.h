#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>
#include <QFile>

class SettingsMigrationAssistant : public QObject
{
    Q_OBJECT
public:
    explicit SettingsMigrationAssistant(QObject *parent = nullptr);

    Q_INVOKABLE void migrateConfiguration();
private:
signals:
};

#endif // SETTINGS_H
