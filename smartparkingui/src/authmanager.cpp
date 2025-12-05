#include "authmanager.h"
#include <QSettings>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>

AuthManager::AuthManager(QObject *parent)
    : QObject(parent)
    , m_loggedIn(false)
{
    // Load saved token from settings
    QSettings settings;
    m_token = settings.value("auth/token").toString();
    m_userType = settings.value("auth/userType").toString();
    
    if (!m_token.isEmpty()) {
        m_loggedIn = true;
        // Load user info if available
        QString userInfoStr = settings.value("auth/userInfo").toString();
        if (!userInfoStr.isEmpty()) {
            QJsonDocument doc = QJsonDocument::fromJson(userInfoStr.toUtf8());
            if (doc.isObject()) {
                m_userInfo = doc.object().toVariantMap();
            }
        }
        emit loginStatusChanged();
    }
}

bool AuthManager::isLoggedIn() const
{
    return m_loggedIn;
}

QString AuthManager::userType() const
{
    return m_userType;
}

QVariantMap AuthManager::userInfo() const
{
    return m_userInfo;
}

void AuthManager::saveToken(const QString &token, const QString &type, const QVariantMap &userInfo)
{
    m_token = token;
    m_userType = type;
    m_userInfo = userInfo;
    m_loggedIn = true;

    QSettings settings;
    settings.setValue("auth/token", token);
    settings.setValue("auth/userType", type);
    QJsonDocument doc = QJsonDocument::fromVariant(userInfo);
    settings.setValue("auth/userInfo", QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
    
    emit loginStatusChanged();
}

void AuthManager::clearAuth()
{
    m_token.clear();
    m_userType.clear();
    m_userInfo.clear();
    m_loggedIn = false;

    QSettings settings;
    settings.remove("auth/token");
    settings.remove("auth/userType");
    settings.remove("auth/userInfo");
    
    emit loginStatusChanged();
}

QString AuthManager::getToken() const
{
    return m_token;
}

