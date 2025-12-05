#ifndef AUTHMANAGER_H
#define AUTHMANAGER_H

#include <QObject>
#include <QString>
#include <QVariantMap>

class AuthManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY loginStatusChanged)
    Q_PROPERTY(QString userType READ userType NOTIFY loginStatusChanged)
    Q_PROPERTY(QVariantMap userInfo READ userInfo NOTIFY loginStatusChanged)

public:
    explicit AuthManager(QObject *parent = nullptr);

    bool isLoggedIn() const;
    QString userType() const; // "user", "system_admin", "lot_admin"
    QVariantMap userInfo() const;

    Q_INVOKABLE void saveToken(const QString &token, const QString &type, const QVariantMap &userInfo);
    Q_INVOKABLE void clearAuth();
    Q_INVOKABLE QString getToken() const;

private:
    QString m_token;
    QString m_userType;
    QVariantMap m_userInfo;
    bool m_loggedIn;

signals:
    void loginStatusChanged();
};

#endif // AUTHMANAGER_H

