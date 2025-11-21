#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrl>
#include <QJsonObject>
#include <QUrlQuery>

class NetworkManager : public QObject
{
    Q_OBJECT

public:
    // 使用局部静态变量的线程安全单例模式
    static NetworkManager* instance() {
        static NetworkManager inst;
        return &inst;
    }

    NetworkManager(const NetworkManager&) = delete;
    NetworkManager& operator=(const NetworkManager&) = delete;

    void setBaseUrl(const QString &base) { m_baseUrl = base; }
    QString baseUrl() const { return m_baseUrl; }

    // 网络请求接口
    QNetworkReply* get(const QUrl &url);
    QNetworkReply* postJson(const QUrl &url, const QJsonObject &payload);
    QNetworkReply* postForm(const QUrl &url, const QUrlQuery &form);
    QNetworkReply* deleteRequest(const QUrl &url);

signals:
    void requestError(const QString &errorString);

private:
    explicit NetworkManager(QObject *parent = nullptr);
    ~NetworkManager() = default;

    QNetworkAccessManager* m_manager;
    QString m_baseUrl;

    void handleError(QNetworkReply *reply);
};

#endif // NETWORKMANAGER_H
