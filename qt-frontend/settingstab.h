#ifndef SETTINGSTAB_H
#define SETTINGSTAB_H

#include <QWidget>
#include <QFormLayout>
#include <QLineEdit>
#include <QPushButton>
#include <QVBoxLayout>
#include <QLabel>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class SettingsTab : public QWidget
{
    Q_OBJECT

public:
    SettingsTab(QWidget *parent = nullptr);

private slots:
    void validateToken();
    void onReplyFinished(QNetworkReply *reply);

private:
    QLineEdit *backendTokenEdit;
    QLineEdit *alpacaKeyEdit;
    QLineEdit *alpacaSecretEdit;
    QNetworkAccessManager *manager;
};

#endif // SETTINGSTAB_H