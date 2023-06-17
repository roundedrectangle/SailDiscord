#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>

class Settings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString token READ token WRITE setToken NOTIFY tokenChanged)

public:
    explicit Settings(QObject *parent = nullptr);

    QString token() const;
    Q_INVOKABLE void setToken(QString token);
private:
    QSettings settings;

signals:
    void tokenChanged();
};

#endif // SETTINGS_H
