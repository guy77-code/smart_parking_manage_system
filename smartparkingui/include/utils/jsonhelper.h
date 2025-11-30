#ifndef JSONHELPER_H
#define JSONHELPER_H

#include <QString>
#include <QJsonObject>
#include <QJsonArray>

class JsonHelper
{
public:
    static QString getString(const QJsonObject &obj, const QString &key, const QString &defaultValue = "");
    static int getInt(const QJsonObject &obj, const QString &key, int defaultValue = 0);
    static double getDouble(const QJsonObject &obj, const QString &key, double defaultValue = 0.0);
    static bool getBool(const QJsonObject &obj, const QString &key, bool defaultValue = false);
    static QJsonArray getArray(const QJsonObject &obj, const QString &key);
    static QJsonObject getObject(const QJsonObject &obj, const QString &key);
};

#endif // JSONHELPER_H

