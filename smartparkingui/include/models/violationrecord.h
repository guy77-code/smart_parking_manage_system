#ifndef VIOLATIONRECORD_H
#define VIOLATIONRECORD_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QJsonObject>

class ViolationRecord : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int violationId READ violationId NOTIFY violationIdChanged)
    Q_PROPERTY(QString violationType READ violationType NOTIFY violationTypeChanged)
    Q_PROPERTY(QDateTime violationTime READ violationTime NOTIFY violationTimeChanged)
    Q_PROPERTY(double fineAmount READ fineAmount NOTIFY fineAmountChanged)
    Q_PROPERTY(int status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString description READ description NOTIFY descriptionChanged)

public:
    explicit ViolationRecord(QObject *parent = nullptr);

    int violationId() const { return m_violationId; }
    QString violationType() const { return m_violationType; }
    QDateTime violationTime() const { return m_violationTime; }
    double fineAmount() const { return m_fineAmount; }
    int status() const { return m_status; }
    QString description() const { return m_description; }

    static ViolationRecord* fromJson(const QJsonObject &json, QObject *parent = nullptr);

signals:
    void violationIdChanged();
    void violationTypeChanged();
    void violationTimeChanged();
    void fineAmountChanged();
    void statusChanged();
    void descriptionChanged();

private:
    int m_violationId;
    QString m_violationType;
    QDateTime m_violationTime;
    double m_fineAmount;
    int m_status;
    QString m_description;
};

#endif // VIOLATIONRECORD_H

