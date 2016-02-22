//+------------------------------------------------------------------+
//|                                                  CloseOnTime.mq4 |
//|                                           ��� ����� �. aka KimIV |
//|                                              http://www.kimiv.ru |
//|                                                                  |
//| �������� � ������ ����� ��������� ��� �������.                   |
//+------------------------------------------------------------------+
#property copyright "��� ����� �. aka KimIV"
#property link      "http://www.kimiv.ru"

//---- input parameters
extern int   CloseHour     = 7;      // ����� ��������, ����
extern int   CloseMinute   = 0;      // ����� ��������, ������
extern bool  UseCurrSymbol = False;  // ������������ ������ ���� ����������
extern bool  UseOneAccount = False;  // ������������ ������ ���� ����
extern int   NumberAccount = 11111;  // ����� ��������� �����
extern int   Slippage      = 3;      // ��������������� ����
extern color clCloseBuy    = Blue;   // ���� �������� �������
extern color clCloseSell   = Red;    // ���� �������� �������

void start() {
  double pBid, pAsk;

  if (UseOneAccount && AccountNumber()!=NumberAccount) {
    Comment("������ �� �����: "+AccountNumber()+" ���������!");
    return;
  } else Comment("");

  if (Hour()==CloseHour && Minute()>=CloseMinute) {
    for (int i=OrdersTotal()-1; i>=0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
        if (!UseCurrSymbol || OrderSymbol()==Symbol()) {
          if (OrderType()==OP_BUY) {
            pBid=MarketInfo(OrderSymbol(), MODE_BID);
            OrderClose(OrderTicket(), OrderLots(), pBid, Slippage, clCloseBuy);
          }
          if (OrderType()==OP_SELL) {
            pAsk=MarketInfo(OrderSymbol(), MODE_ASK);
            OrderClose(OrderTicket(), OrderLots(), pAsk, Slippage, clCloseSell);
          }
        }
      }
    }
  }
}
//+------------------------------------------------------------------+