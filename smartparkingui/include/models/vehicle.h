#ifndef VEHICLE_H
#define VEHICLE_H

#include <QObject>
#include <QString>
#include <QJsonObject>

class Vehicle : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int vehicleId READ vehicleId NOTIFY vehicleIdChanged)
    Q_PROPERTY(QString licensePlate READ licensePlate NOTIFY licensePlateChanged)
    Q_PROPERTY(QString brand READ brand NOTIFY brandChanged)
    Q_PROPERTY(QString model READ model NOTIFY modelChanged)
    Q_PROPERTY(QString color READ color NOTIFY colorChanged)

public:
    explicit Vehicle(QObject *parent = nullptr);

    int vehicleId() const { return m_vehicleId; }
    QString licensePlate() const { return m_licensePlate; }
    QString brand() const { return m_brand; }
    QString model() const { return m_model; }
    QString color() const { return m_color; }

    static Vehicle* fromJson(const QJsonObject &json, QObject *parent = nullptr);

signals:
    void vehicleIdChanged();
    void licensePlateChanged();
    void brandChanged();
    void modelChanged();
    void colorChanged();

private:
    int m_vehicleId;
    QString m_licensePlate;
    QString m_brand;
    QString m_model;
    QString m_color;
};

#endif // VEHICLE_H

