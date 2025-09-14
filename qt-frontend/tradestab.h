#ifndef TRADESTAB_H
#define TRADESTAB_H

#include <QWidget>
#include <QTableView>
#include <QStandardItemModel>
#include <QVBoxLayout>
#include <QLabel>

class TradesTab : public QWidget
{
    Q_OBJECT

public:
    TradesTab(QWidget *parent = nullptr);
    void updateData();

private:
    QTableView *tableView;
    QStandardItemModel *model;
};

#endif // TRADESTAB_H