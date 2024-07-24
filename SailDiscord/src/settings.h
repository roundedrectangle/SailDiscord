#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>

class Settings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString token READ token WRITE setToken NOTIFY tokenChanged)
    Q_PROPERTY(bool emptySpace READ emptySpace WRITE setEmptySpace NOTIFY emptySpaceChanged)
    Q_PROPERTY(bool ignorePrivate READ ignorePrivate WRITE setIgnorePrivate NOTIFY ignorePrivateChanged)

public:
    explicit Settings(QObject *parent = nullptr);

    QString token() const;
    Q_INVOKABLE void setToken(QString token);

    bool emptySpace() const;
    Q_INVOKABLE void setEmptySpace(bool emptySpace);

    bool ignorePrivate() const;
    Q_INVOKABLE void setIgnorePrivate(bool ignorePrivate);
private:
    QSettings settings;

signals:
    void tokenChanged();
    void emptySpaceChanged();
    void ignorePrivateChanged();
};

#endif // SETTINGS_H
