#ifndef USER_H
#define USER_H

#include <QObject>
#include <QString>

class User : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int userId READ userId WRITE setUserId NOTIFY userIdChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(QString phone READ phone WRITE setPhone NOTIFY phoneChanged)
    Q_PROPERTY(QString email READ email WRITE setEmail NOTIFY emailChanged)
    Q_PROPERTY(QString realName READ realName WRITE setRealName NOTIFY realNameChanged)

public:
    explicit User(QObject *parent = nullptr);

    int userId() const { return m_userId; }
    void setUserId(int id);

    QString username() const { return m_username; }
    void setUsername(const QString &username);

    QString phone() const { return m_phone; }
    void setPhone(const QString &phone);

    QString email() const { return m_email; }
    void setEmail(const QString &email);

    QString realName() const { return m_realName; }
    void setRealName(const QString &realName);

    static User* fromJson(const QJsonObject &json, QObject *parent = nullptr);

signals:
    void userIdChanged();
    void usernameChanged();
    void phoneChanged();
    void emailChanged();
    void realNameChanged();

private:
    int m_userId;
    QString m_username;
    QString m_phone;
    QString m_email;
    QString m_realName;
};

#endif // USER_H

