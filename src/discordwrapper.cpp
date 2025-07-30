#include "discordwrapper.h"

DiscordWrapper::DiscordWrapper(QObject *parent) : QNetworkAccessManager(parent) {
    connect(this, &QNetworkAccessManager::finished, this, &DiscordWrapper::processReply);


}

void DiscordWrapper::processReply(QNetworkReply *reply) {
    const QString path = reply->url().path();
    Handler handler = handlers.value(path);
    if (handler)
        (this->*handler)(*reply);
    else qDebug() << "Unhandled reply for path" << path;
}
