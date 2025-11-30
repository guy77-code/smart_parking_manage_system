#include "apiclient.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QHttpMultiPart>
#include <QDebug>
#include <QUrlQuery>

ApiClient::ApiClient(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_baseUrl("http://127.0.0.1:8080")
{
    connect(m_networkManager, &QNetworkAccessManager::finished,
            this, &ApiClient::onRequestFinished);
}

ApiClient::~ApiClient()
{
}

void ApiClient::setBaseUrl(const QString &url)
{
    m_baseUrl = url;
}

QString ApiClient::baseUrl() const
{
    return m_baseUrl;
}

void ApiClient::setAuthToken(const QString &token)
{
    m_authToken = token;
}

void ApiClient::clearAuthToken()
{
    m_authToken.clear();
}

QNetworkRequest ApiClient::createRequest(const QString &endpoint)
{
    QUrl url(m_baseUrl + endpoint);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    if (!m_authToken.isEmpty()) {
        request.setRawHeader("Authorization", ("Bearer " + m_authToken).toUtf8());
    }
    
    return request;
}

void ApiClient::makeRequest(const QString &method, const QString &endpoint, const QJsonObject &data)
{
    QNetworkRequest request = createRequest(endpoint);
    QByteArray jsonData = QJsonDocument(data).toJson();

    if (method == "GET") {
        m_networkManager->get(request);
    } else if (method == "POST") {
        m_networkManager->post(request, jsonData);
    } else if (method == "PATCH") {
        m_networkManager->sendCustomRequest(request, "PATCH", jsonData);
    } else if (method == "DELETE") {
        m_networkManager->deleteResource(request);
    }
}

QJsonObject ApiClient::parseResponse(QNetworkReply *reply)
{
    QJsonObject result;
    
    int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    result["http_status"] = httpStatus;
    
    if (reply->error() != QNetworkReply::NoError) {
        result["error"] = reply->errorString();
        return result;
    }

    QByteArray data = reply->readAll();
    if (data.isEmpty()) {
        return result;
    }
    
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);

    if (error.error != QJsonParseError::NoError) {
        result["error"] = "JSON parse error: " + error.errorString();
        return result;
    }

    if (doc.isObject()) {
        result = doc.object();
        result["http_status"] = httpStatus;
    } else if (doc.isArray()) {
        result["data"] = doc.array();
        result["http_status"] = httpStatus;
    }

    return result;
}

void ApiClient::onRequestFinished(QNetworkReply *reply)
{
    // Store URL before reading data
    QString url = reply->url().toString();
    
    QJsonObject response = parseResponse(reply);
    int httpStatus = response.value("http_status").toInt();
    
    // Store URL in response for QML to identify request type
    response["url"] = url;
    
    if (httpStatus >= 200 && httpStatus < 300) {
        // Parse response and emit specific signals
        if (url.contains("/api/v1/login") || url.contains("/admin/login")) {
            QString token = response.value("token").toString();
            QJsonObject userData = response.value("user").toObject();
            if (userData.isEmpty()) {
                userData = response.value("admin_info").toObject();
            }
            emit loginSuccess(userData, token);
        } else if (url.contains("/api/v1/register")) {
            emit registerSuccess(response);
        } else if (url.contains("/api/v2/getparkinglots")) {
            QJsonArray lots;
            if (response.contains("data")) {
                if (response["data"].isArray()) {
                    lots = response["data"].toArray();
                } else if (response["data"].isObject()) {
                    QJsonObject dataObj = response["data"].toObject();
                    if (dataObj.contains("data") && dataObj["data"].isArray()) {
                        lots = dataObj["data"].toArray();
                    }
                }
            }
            emit parkingLotsReceived(lots);
        } else if (url.contains("/active-parking")) {
            QJsonArray records;
            if (response.contains("data") && response["data"].isArray()) {
                records = response["data"].toArray();
            }
            emit activeParkingRecordsReceived(records);
        } else if (url.contains("/getpaymentinfo")) {
            emit paymentRecordsReceived(response);
        } else if (url.contains("/booking/create")) {
            QJsonObject booking = response.value("data").toObject();
            emit bookingCreated(booking);
        } else if (url.contains("/violations/checkmyself")) {
            emit violationsReceived(response);
        } else if (url.contains("/payment/create")) {
            emit paymentCreated(response);
        } else if (url.contains("/payment/notify")) {
            emit paymentNotified(response);
        }
    } else {
        QString error = response.value("error").toString();
        if (error.isEmpty()) {
            error = response.value("message").toString();
        }
        if (!error.isEmpty()) {
            emit requestError(error);
        }
    }
    
    emit requestFinished(response);
    reply->deleteLater();
}

// User APIs
void ApiClient::registerUser(const QJsonObject &userData, const QJsonArray &vehicles)
{
    QJsonObject data;
    data["users_list"] = userData;
    data["vehicles"] = vehicles;
    makeRequest("POST", "/api/v1/register", data);
}

void ApiClient::sendLoginCode(const QString &phone)
{
    QJsonObject data;
    data["phone"] = phone;
    makeRequest("POST", "/api/v1/send_code", data);
}

void ApiClient::login(const QString &phone, const QString &password, const QString &code)
{
    QJsonObject data;
    data["phone"] = phone;
    if (!password.isEmpty()) {
        data["password"] = password;
    }
    if (!code.isEmpty()) {
        data["code"] = code;
    }
    makeRequest("POST", "/api/v1/login", data);
}

void ApiClient::adminLogin(const QString &phone, const QString &password)
{
    QJsonObject data;
    data["phone"] = phone;
    data["password"] = password;
    makeRequest("POST", "/admin/login", data);
}

void ApiClient::getUserPaymentRecords(int page, int pageSize)
{
    QString endpoint = QString("/api/v1/getpaymentinfo?page=%1&page_size=%2").arg(page).arg(pageSize);
    makeRequest("GET", endpoint);
}

// Parking APIs
void ApiClient::getParkingLots()
{
    makeRequest("GET", "/api/v2/getparkinglots");
}

void ApiClient::getParkingLotById(int lotId)
{
    makeRequest("GET", QString("/api/v2/getparkinglot/%1").arg(lotId));
}

void ApiClient::getParkingSpaces(int lotId)
{
    makeRequest("GET", QString("/api/parking/lots/%1/spaces").arg(lotId));
}

void ApiClient::getParkingLotOccupancy(int lotId)
{
    makeRequest("GET", QString("/api/parking/getparkinglotoccupancy/%1").arg(lotId));
}

void ApiClient::getUserActiveParkingRecords(int userId)
{
    makeRequest("GET", QString("/api/parking/%1/active-parking").arg(userId));
}

void ApiClient::vehicleEntry(const QString &licensePlate, const QString &spaceType)
{
    QJsonObject data;
    data["license_plate"] = licensePlate;
    if (!spaceType.isEmpty()) {
        data["space_type"] = spaceType;
    }
    makeRequest("POST", "/api/parking/entry", data);
}

void ApiClient::vehicleExit(const QString &licensePlate)
{
    QJsonObject data;
    data["license_plate"] = licensePlate;
    makeRequest("POST", "/api/parking/exit", data);
}

// Booking APIs
void ApiClient::createBooking(int userId, int vehicleId, int lotId, const QString &startTime, const QString &endTime)
{
    QJsonObject data;
    data["user_id"] = userId;
    data["vehicle_id"] = vehicleId;
    data["lot_id"] = lotId;
    data["start_time"] = startTime;
    data["end_time"] = endTime;
    makeRequest("POST", "/api/v4/booking/create", data);
}

void ApiClient::cancelBooking(int orderId)
{
    makeRequest("DELETE", QString("/api/v4/booking/cancel/%1").arg(orderId));
}

void ApiClient::getUserBookings(int userId)
{
    makeRequest("GET", QString("/api/v4/booking/user?user_id=%1").arg(userId));
}

void ApiClient::getBookingDetail(int orderId)
{
    makeRequest("GET", QString("/api/v4/booking/detail/%1").arg(orderId));
}

// Violation APIs
void ApiClient::getUserViolations(int userId, int status)
{
    QString endpoint = QString("/api/violations/checkmyself/%1").arg(userId);
    if (status >= 0) {
        endpoint += QString("?status=%1").arg(status);
    }
    makeRequest("GET", endpoint);
}

void ApiClient::payViolationFine(int violationId)
{
    makeRequest("POST", QString("/api/violations/%1/pay").arg(violationId));
}

// Payment APIs
void ApiClient::createPayment(int orderId, const QString &type, const QString &method, double amount)
{
    QJsonObject data;
    data["order_id"] = orderId;
    data["type"] = type;
    data["method"] = method;
    if (amount > 0) {
        data["amount"] = amount;
    }
    makeRequest("POST", "/api/payment/create", data);
}

void ApiClient::notifyPayment(int paymentId, double amount, const QString &transactionNo, const QString &provider)
{
    QJsonObject data;
    data["payment_id"] = paymentId;
    data["amount"] = amount;
    data["transaction_no"] = transactionNo;
    data["provider"] = provider;
    makeRequest("POST", "/api/payment/notify", data);
}

// Admin APIs
void ApiClient::getOccupancyAnalysis(const QString &startTime, const QString &endTime)
{
    QString endpoint = QString("/admin/occupancy?start_time=%1&end_time=%2")
                       .arg(QString::fromUtf8(QUrl::toPercentEncoding(startTime)))
                       .arg(QString::fromUtf8(QUrl::toPercentEncoding(endTime)));
    makeRequest("GET", endpoint);
}

void ApiClient::getViolationAnalysis(int year, int month)
{
    QString endpoint = "/admin/violations";
    if (year > 0) {
        endpoint += QString("?year=%1").arg(year);
        if (month > 0) {
            endpoint += QString("&month=%1").arg(month);
        }
    }
    makeRequest("GET", endpoint);
}

void ApiClient::generateReport(const QString &type, int year, int month)
{
    QString endpoint = QString("/admin/report?type=%1").arg(type);
    if (year > 0) {
        endpoint += QString("&year=%1").arg(year);
        if (type == "monthly" && month > 0) {
            endpoint += QString("&month=%1").arg(month);
        }
    }
    makeRequest("GET", endpoint);
}

