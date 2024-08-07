#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QScopedPointer>
#include <QGuiApplication>
#include <QQuickView>

#include <sailfishapp.h>

#include "settings.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setApplicationName("harbour-saildiscord");
    app->setOrganizationDomain("io.github.roundedrectangle");
    app->setOrganizationName("io.github.roundedrectangle");
    qmlRegisterType<SettingsMigrationAssistant>("harboursaildiscord.Logic", 1, 0, "SettingsMigrationAssistant");

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
