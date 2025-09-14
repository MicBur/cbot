#include "settingstab.h"
#include <QMessageBox>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>

SettingsTab::SettingsTab(QWidget *parent)
    : QWidget(parent)
{
    QVBoxLayout *layout = new QVBoxLayout(this);

    QLabel *title = new QLabel("API Settings");
    title->setStyleSheet("color: #00ffff; font-size: 18px;");
    layout->addWidget(title);

    QFormLayout *formLayout = new QFormLayout;

    // Backend Token
    QLabel *backendLabel = new QLabel("Backend API Token:");
    backendLabel->setStyleSheet("color: #00ffff;");
    backendTokenEdit = new QLineEdit;
    backendTokenEdit->setEchoMode(QLineEdit::Password);
    backendTokenEdit->setStyleSheet("background-color: #0a0a0a; color: #00ffff; border: 1px solid #00ffff; padding: 5px;");

    // Alpaca Keys
    QLabel *alpacaKeyLabel = new QLabel("Alpaca API Key:");
    alpacaKeyLabel->setStyleSheet("color: #00ffff;");
    alpacaKeyEdit = new QLineEdit;
    alpacaKeyEdit->setEchoMode(QLineEdit::Password);
    alpacaKeyEdit->setStyleSheet("background-color: #0a0a0a; color: #00ffff; border: 1px solid #00ffff; padding: 5px;");

    QLabel *alpacaSecretLabel = new QLabel("Alpaca Secret:");
    alpacaSecretLabel->setStyleSheet("color: #00ffff;");
    alpacaSecretEdit = new QLineEdit;
    alpacaSecretEdit->setEchoMode(QLineEdit::Password);
    alpacaSecretEdit->setStyleSheet("background-color: #0a0a0a; color: #00ffff; border: 1px solid #00ffff; padding: 5px;");

    QPushButton *validateBtn = new QPushButton("Validate Token");
    validateBtn->setStyleSheet("QPushButton { background-color: #00ffff; color: #0a0a0a; border: none; padding: 10px; }"
                               "QPushButton:hover { background-color: #0099cc; }");

    formLayout->addRow(backendLabel, backendTokenEdit);
    formLayout->addRow(alpacaKeyLabel, alpacaKeyEdit);
    formLayout->addRow(alpacaSecretLabel, alpacaSecretEdit);
    formLayout->addRow(validateBtn);

    layout->addLayout(formLayout);
    layout->addStretch();

    manager = new QNetworkAccessManager(this);
    connect(manager, &QNetworkAccessManager::finished, this, &SettingsTab::onReplyFinished);
    connect(validateBtn, &QPushButton::clicked, this, &SettingsTab::validateToken);
}

void SettingsTab::validateToken()
{
    // Validate API token
    QMessageBox::information(this, "Validation", "Token validation not implemented yet");
}

void SettingsTab::onReplyFinished(QNetworkReply *reply)
{
    // Handle validation response
}