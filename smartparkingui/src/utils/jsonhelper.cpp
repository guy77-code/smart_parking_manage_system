#include "utils/jsonhelper.h"
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QDebug>

QString JsonHelper::getString(const QJsonObject &obj, const QString &key, const QString &defaultValue)
{
    if (obj.contains(key) && obj[key].isString()) {
        return obj[key].toString();
    }
    return defaultValue;
}

int JsonHelper::getInt(const QJsonObject &obj, const QString &key, int defaultValue)
{
    if (obj.contains(key) && obj[key].isDouble()) {
        return obj[key].toInt();
    }
    return defaultValue;
}

double JsonHelper::getDouble(const QJsonObject &obj, const QString &key, double defaultValue)
{
    if (obj.contains(key) && obj[key].isDouble()) {
        return obj[key].toDouble();
    }
    return defaultValue;
}

bool JsonHelper::getBool(const QJsonObject &obj, const QString &key, bool defaultValue)
{
    if (obj.contains(key) && obj[key].isBool()) {
        return obj[key].toBool();
    }
    return defaultValue;
}

QJsonArray JsonHelper::getArray(const QJsonObject &obj, const QString &key)
{
    if (obj.contains(key) && obj[key].isArray()) {
        return obj[key].toArray();
    }
    return QJsonArray();
}

QJsonObject JsonHelper::getObject(const QJsonObject &obj, const QString &key)
{
    if (obj.contains(key) && obj[key].isObject()) {
        return obj[key].toObject();
    }
    return QJsonObject();
}

