#ifndef CACHER_H
#define CACHER_H

#include <QObject>
#include <QQuickAsyncImageProvider>
#include <QNetworkAccessManager>
#include <QNetworkDiskCache>
#include <QNetworkReply>
#include <QStandardPaths>
#include <QDir>

class Cacher : public QObject {
    Q_OBJECT
    Q_PROPERTY(qlonglong maximumCacheSize READ maximumCacheSize WRITE setMaximumCacheSize)

public:
    explicit Cacher(const QString &name, QObject *parent = nullptr);

    inline QQuickAsyncImageProvider *provider() { return imageProvider; }

private:
    inline qlonglong maximumCacheSize() const { if (cache) return cache->maximumCacheSize(); else return 0; }
    inline void setMaximumCacheSize(qlonglong size) { if (cache) cache->setMaximumCacheSize(size); }

    class CachedImageProvider : public QQuickAsyncImageProvider {
    public:
        explicit CachedImageProvider(QNetworkAccessManager *manager);

        QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;
    private:
        class CachedImageResponse : public QQuickImageResponse {
        public:
            explicit CachedImageResponse(QNetworkAccessManager *manager, const QString &id, const QSize &requestedSize);
            ~CachedImageResponse();

            virtual QQuickTextureFactory *textureFactory() const override;
            virtual QString errorString() const override;

        public slots:
            void cancel() override;

        private slots:
            void handleReplyFinished();

        private:
            QImage image;
            QSize requestedSize;
            QNetworkReply *reply;

            QNetworkAccessManager *manager;
        };

        QNetworkAccessManager *manager;
    };
    CachedImageProvider *imageProvider;

    QNetworkDiskCache *cache;
    QNetworkAccessManager *manager;
};

#endif // CACHER_H
