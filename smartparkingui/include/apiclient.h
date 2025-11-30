#ifndef APICLIENT_H
#define APICLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include <QJsonDocument>
#include <QUrl>

class ApiClient : public QObject
{
    Q_OBJECT

public:
    explicit ApiClient(QObject *parent = nullptr);
    ~ApiClient();

    // Base URL configuration
    void setBaseUrl(const QString &url);
    QString baseUrl() const;

    // Authentication
    void setAuthToken(const QString &token);
    void clearAuthToken();

    // User APIs
    Q_INVOKABLE void registerUser(const QJsonObject &userData, const QJsonArray &vehicles);
    Q_INVOKABLE void sendLoginCode(const QString &phone);
    Q_INVOKABLE void login(const QString &phone, const QString &password = "", const QString &code = "");
    Q_INVOKABLE void adminLogin(const QString &phone, const QString &password);
    Q_INVOKABLE void getUserPaymentRecords(int page = 1, int pageSize = 10);

    // Parking APIs
    Q_INVOKABLE void getParkingLots();
    Q_INVOKABLE void getParkingLotById(int lotId);
    Q_INVOKABLE void getParkingSpaces(int lotId);
    Q_INVOKABLE void getParkingLotOccupancy(int lotId);
    Q_INVOKABLE void getUserActiveParkingRecords(int userId);
    Q_INVOKABLE void vehicleEntry(const QString &licensePlate, const QString &spaceType = "");
    Q_INVOKABLE void vehicleExit(const QString &licensePlate);

    // Booking APIs
    Q_INVOKABLE void createBooking(int userId, int vehicleId, int lotId, const QString &startTime, const QString &endTime);
    Q_INVOKABLE void cancelBooking(int orderId);
    Q_INVOKABLE void getUserBookings(int userId);
    Q_INVOKABLE void getBookingDetail(int orderId);

    // Violation APIs
    Q_INVOKABLE void getUserViolations(int userId, int status = -1);
    Q_INVOKABLE void payViolationFine(int violationId);

    // Payment APIs
    Q_INVOKABLE void createPayment(int orderId, const QString &type, const QString &method, double amount = 0.0);
    Q_INVOKABLE void notifyPayment(int paymentId, double amount, const QString &transactionNo, const QString &provider);

    // Admin APIs
    Q_INVOKABLE void getOccupancyAnalysis(const QString &startTime, const QString &endTime);
    Q_INVOKABLE void getViolationAnalysis(int year = 0, int month = 0);
    Q_INVOKABLE void generateReport(const QString &type, int year = 0, int month = 0);

signals:
    // Generic signals
    void requestFinished(const QJsonObject &response);
    void requestError(const QString &error);

    // Specific response signals
    void loginSuccess(const QJsonObject &userData, const QString &token);
    void registerSuccess(const QJsonObject &response);
    void parkingLotsReceived(const QJsonArray &lots);
    void activeParkingRecordsReceived(const QJsonArray &records);
    void paymentRecordsReceived(const QJsonObject &response);
    void bookingCreated(const QJsonObject &booking);
    void violationsReceived(const QJsonObject &response);
    void paymentCreated(const QJsonObject &payment);
    void paymentNotified(const QJsonObject &response);

private slots:
    void onRequestFinished(QNetworkReply *reply);

private:
    QNetworkAccessManager *m_networkManager;
    QString m_baseUrl;
    QString m_authToken;

    void makeRequest(const QString &method, const QString &endpoint, const QJsonObject &data = QJsonObject());
    QNetworkRequest createRequest(const QString &endpoint);
    QJsonObject parseResponse(QNetworkReply *reply);
};

#endif // APICLIENT_H

