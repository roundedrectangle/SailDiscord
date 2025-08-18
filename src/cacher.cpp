#include "cacher.h"

namespace {
    const QString UNKNOWN_ERROR("Unknown cached image error");
}

Cacher::Cacher(const QString &name, QObject *parent) :
    QObject(parent),
    cache(new QNetworkDiskCache()),
    manager(new QNetworkAccessManager()),
    imageProvider(new CachedImageProvider(manager))
{
    cache->setCacheDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/" + name);
    manager->setCache(cache);
}

Cacher::CachedImageProvider::CachedImageProvider(QNetworkAccessManager *manager) :
    QQuickAsyncImageProvider(),
    manager(manager)
{}


Cacher::CachedImageProvider::CachedImageResponse::CachedImageResponse(QNetworkAccessManager *manager, const QString &id, const QSize &requestedSize) :
    QQuickImageResponse(),
    manager(manager)
{
    this->requestedSize = requestedSize;
    reply = manager->get(QNetworkRequest(QUrl(id)));
    connect(reply, &QNetworkReply::finished, this, &CachedImageResponse::handleReplyFinished);
}

void Cacher::CachedImageProvider::CachedImageResponse::handleReplyFinished() {
    if (reply) {
        if (!reply->error()) {
            image.load(reply, nullptr);
            if (!image.isNull() && requestedSize.isValid())
                image = image.scaled(requestedSize);
        }
        reply->deleteLater();
        reply = nullptr;
    }

    emit finished();
}

QString Cacher::CachedImageProvider::CachedImageResponse::errorString() const {
    if (reply) return reply->errorString();
    return UNKNOWN_ERROR;
}

void Cacher::CachedImageProvider::CachedImageResponse::cancel() {
    if (reply) reply->abort();
}

Cacher::CachedImageProvider::CachedImageResponse::~CachedImageResponse() {
    if (reply) {
        reply->abort();
        reply->deleteLater();
        reply = nullptr;
    }
}


QQuickTextureFactory *Cacher::CachedImageProvider::CachedImageResponse::textureFactory() const {
    return QQuickTextureFactory::textureFactoryForImage(image);
}

QQuickImageResponse *Cacher::CachedImageProvider::requestImageResponse(const QString &id, const QSize &requestedSize) {
    return new CachedImageResponse(manager, id, requestedSize);
}
