#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QScopedPointer>
#include <QGuiApplication>
#include <QQuickView>

#include <sailfishapp.h>

#include "settings.h"

QObject* createSettings(QQmlEngine *engine, QJSEngine *jsEngine) {
    return new Settings;
}

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setApplicationName("saildiscord");
    app->setOrganizationDomain("io.github.roundedrectangle");
    app->setOrganizationName("io.github.roundedrectangle");
    qmlRegisterSingletonType<Settings>("SailDiscord.Logic", 1, 0, "AppSettings", createSettings);

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
