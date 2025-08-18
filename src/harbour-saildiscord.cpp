#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QScopedPointer>
#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include <QQmlEngine>

#include <sailfishapp.h>

#include "requires_defines.h"

#include "cacher.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setApplicationName("harbour-saildiscord");
    app->setOrganizationDomain("io.github.roundedrectangle");
    app->setOrganizationName("io.github.roundedrectangle");

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    QQmlEngine *engine = view->engine();
    QQmlContext *context = view->rootContext();

    Cacher assetCacher("assets", view.data());

    engine->addImageProvider("cachedAsset", assetCacher.provider());

    context->setContextProperty("APP_VERSION", QString(APP_VERSION));
    context->setContextProperty("APP_RELEASE", QString(APP_RELEASE));

    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
