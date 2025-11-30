#ifndef AUTHMANAGER_H
#define AUTHMANAGER_H

#include <QObject>
#include <QString>
#include <QJsonObject>

class AuthManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY loginStatusChanged)
    Q_PROPERTY(QString userType READ userType NOTIFY loginStatusChanged)
    Q_PROPERTY(QJsonObject userInfo READ userInfo NOTIFY loginStatusChanged)

public:
    explicit AuthManager(QObject *parent = nullptr);

    bool isLoggedIn() const;
    QString userType() const; // "user", "system_admin", "lot_admin"
    QJsonObject userInfo() const;

    Q_INVOKABLE void saveToken(const QString &token, const QString &type, const QJsonObject &userInfo);
    Q_INVOKABLE void clearAuth();
    Q_INVOKABLE QString getToken() const;

private:
    QString m_token;
    QString m_userType;
    QJsonObject m_userInfo;
    bool m_loggedIn;

signals:
    void loginStatusChanged();
};

#endif // AUTHMANAGER_H

