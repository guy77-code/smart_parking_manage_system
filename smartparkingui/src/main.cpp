#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include "apiclient.h"
#include "authmanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Set application properties
    app.setApplicationName("SmartParking");
    app.setOrganizationName("SmartParking");
    app.setApplicationVersion("1.0.0");

    // Use Material style
    QQuickStyle::setStyle("Material");

    // Create API client and auth manager
    ApiClient *apiClient = new ApiClient(&app);
    AuthManager *authManager = new AuthManager(&app);

    // Set auth token in API client
    QObject::connect(authManager, &AuthManager::loginStatusChanged, [=]() {
        apiClient->setAuthToken(authManager->getToken());
    });
    apiClient->setAuthToken(authManager->getToken());

    // Create QML engine
    QQmlApplicationEngine engine;

    // Register types
    qmlRegisterType<ApiClient>("SmartParking", 1, 0, "ApiClient");
    qmlRegisterType<AuthManager>("SmartParking", 1, 0, "AuthManager");

    // Expose objects to QML
    engine.rootContext()->setContextProperty("apiClient", apiClient);
    engine.rootContext()->setContextProperty("authManager", authManager);

    // Load main QML file
    const QUrl url(QStringLiteral("qrc:/ui/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}

