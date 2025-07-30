#ifndef DISCORDWRAPPER_H
#define DISCORDWRAPPER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class DiscordWrapper : public QNetworkAccessManager
{
    Q_OBJECT
public:
    explicit DiscordWrapper(QObject *parent = nullptr);

signals:

private:
    typedef void (DiscordWrapper::*Handler)(QNetworkReply &);

    QHash<QString, Handler> handlers;

private slots:
    void processReply(QNetworkReply *reply);
};

#endif // DISCORDWRAPPER_H
