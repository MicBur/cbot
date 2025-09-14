#include "tradestab.h"

TradesTab::TradesTab(QWidget *parent)
    : QWidget(parent)
{
    QVBoxLayout *layout = new QVBoxLayout(this);

    QLabel *title = new QLabel("Active Orders");
    title->setStyleSheet("color: #00ffff; font-size: 18px;");
    layout->addWidget(title);

    tableView = new QTableView;
    model = new QStandardItemModel(0, 4, this);
    model->setHeaderData(0, Qt::Horizontal, "Ticker");
    model->setHeaderData(1, Qt::Horizontal, "Side");
    model->setHeaderData(2, Qt::Horizontal, "Price");
    model->setHeaderData(3, Qt::Horizontal, "Status");

    tableView->setModel(model);
    tableView->setStyleSheet("QTableView { background-color: #0a0a0a; color: #00ffff; gridline-color: #00ffff; }"
                             "QHeaderView::section { background-color: #0a0a0a; color: #00ffff; border: 1px solid #00ffff; }");

    layout->addWidget(tableView);
}

void TradesTab::updateData()
{
    // Update from Alpaca API
    // Mock data
    model->insertRow(0);
    model->setData(model->index(0, 0), "AAPL");
    model->setData(model->index(0, 1), "Buy");
    model->setData(model->index(0, 2), "150.00");
    model->setData(model->index(0, 3), "Pending");
}