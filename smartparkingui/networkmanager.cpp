#include "networkmanager.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QDebug>

NetworkManager::NetworkManager(QObject *parent)
    : QObject(parent),
    m_manager(new QNetworkAccessManager(this)),
    m_baseUrl("http://127.0.0.1:8080")
{
    // 全局错误处理（可选）
    connect(m_manager, &QNetworkAccessManager::finished, this, [this](QNetworkReply *reply) {
        if (reply->error() != QNetworkReply::NoError) {
            handleError(reply);
        }
    });
}

void NetworkManager::handleError(QNetworkReply *reply) {
    QString err = reply->errorString();
    qWarning() << "[Network Error]:" << err;
    emit requestError(err);
    reply->deleteLater();
}

// GET
QNetworkReply* NetworkManager::get(const QUrl &url) {
    QUrl u = url;
    if (u.isRelative())
        u = QUrl(m_baseUrl + url.toString());
    QNetworkRequest req(u);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    return m_manager->get(req);
}

// POST JSON
QNetworkReply* NetworkManager::postJson(const QUrl &url, const QJsonObject &payload) {
    QUrl u = url;
    if (u.isRelative())
        u = QUrl(m_baseUrl + url.toString());
    QNetworkRequest req(u);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonDocument doc(payload);
    QByteArray data = doc.toJson(QJsonDocument::Compact);
    return m_manager->post(req, data);
}

// POST FORM
QNetworkReply* NetworkManager::postForm(const QUrl &url, const QUrlQuery &form) {
    QUrl u = url;
    if (u.isRelative())
        u = QUrl(m_baseUrl + url.toString());
    QNetworkRequest req(u);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
    return m_manager->post(req, form.toString(QUrl::FullyEncoded).toUtf8());
}

// DELETE 请求
QNetworkReply* NetworkManager::deleteRequest(const QUrl &url) {
    QUrl u = url;
    if (u.isRelative())
        u = QUrl(m_baseUrl + url.toString());
    QNetworkRequest req(u);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    return m_manager->deleteResource(req);
}
