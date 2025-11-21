#include "mainwindow.h"

#include <QApplication>
#include <QLocale>
#include <QTranslator>
#include<QProcess>
#include <QTcpSocket>
#include <QTimer>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    // 设置全局字体支持中文
    QFont font;
    font.setFamily("Microsoft YaHei");
    a.setFont(font);

    // 确保输入法全局可用
    a.setAttribute(Qt::AA_EnableHighDpiScaling);
    a.setAttribute(Qt::AA_UseHighDpiPixmaps);

    // 启动 Go 服务
    QProcess *goServer = new QProcess();
    QString goServerPath = QCoreApplication::applicationDirPath() + "/smart_parking_server";

    // 启动命令行
    goServer->start(goServerPath);

    if (!goServer->waitForStarted(3000)) {
        qCritical() << "❌ 无法启动 Go 服务端！";
        return -1;
    }
    qDebug() << "✅ Go 服务端已启动";

    // 创建一个TCP Socket用于检测端口
    QTcpSocket *testSocket = new QTcpSocket();
    QTimer *timeoutTimer = new QTimer();
    timeoutTimer->setSingleShot(true);

    MainWindow w;
    // 连接成功：说明端口已开启，服务就绪
    QObject::connect(testSocket, &QTcpSocket::connected, [testSocket, timeoutTimer, &w]() {
        qDebug() << "🎉 Go 服务端端口已就绪，服务启动成功！";
        timeoutTimer->stop();
        testSocket->disconnectFromHost();
        testSocket->deleteLater();
        // 确保在这里再显示主窗口
        w.show();
    });

    // 连接失败（含超时）：说明服务启动可能有问题
    QObject::connect(timeoutTimer, &QTimer::timeout, [testSocket, goServer]() {
        qCritical() << "❌ Go 服务端端口在指定时间内未就绪，启动可能失败。";
        testSocket->abort();
        testSocket->deleteLater();
        // 可以考虑在这里终止Go服务进程 (goServer->kill())
    });

    // 开始检测（假设您的Go服务运行在8080端口）
    int servicePort = 8080; // 请修改为您的实际端口
    testSocket->connectToHost("127.0.0.1", servicePort);
    // 设置一个检测超时，例如5秒
    timeoutTimer->start(5000);

    QTranslator translator;
    const QStringList uiLanguages = QLocale::system().uiLanguages();
    for (const QString &locale : uiLanguages) {
        const QString baseName = "smartparking_" + QLocale(locale).name();
        if (translator.load(":/i18n/" + baseName)) {
            a.installTranslator(&translator);
            break;
        }
    }


    // 程序退出时关闭服务端
    QObject::connect(&a, &QCoreApplication::aboutToQuit, [goServer]() {
        qDebug() << "🛑 停止 Go 服务端";
        goServer->terminate();
        goServer->waitForFinished(2000);
    });

    return a.exec();
}


