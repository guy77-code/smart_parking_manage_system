#include "models/user.h"
#include <QJsonObject>

User::User(QObject *parent)
    : QObject(parent)
    , m_userId(0)
{
}

void User::setUserId(int id)
{
    if (m_userId != id) {
        m_userId = id;
        emit userIdChanged();
    }
}

void User::setUsername(const QString &username)
{
    if (m_username != username) {
        m_username = username;
        emit usernameChanged();
    }
}

void User::setPhone(const QString &phone)
{
    if (m_phone != phone) {
        m_phone = phone;
        emit phoneChanged();
    }
}

void User::setEmail(const QString &email)
{
    if (m_email != email) {
        m_email = email;
        emit emailChanged();
    }
}

void User::setRealName(const QString &realName)
{
    if (m_realName != realName) {
        m_realName = realName;
        emit realNameChanged();
    }
}

User* User::fromJson(const QJsonObject &json, QObject *parent)
{
    User *user = new User(parent);
    user->setUserId(json["id"].toInt());
    user->setUsername(json["username"].toString());
    user->setPhone(json["phone"].toString());
    user->setEmail(json["email"].toString());
    user->setRealName(json["real_name"].toString());
    return user;
}

