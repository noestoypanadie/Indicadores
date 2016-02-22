//+------------------------------------------------------------------+
//|                                                  CloseOnTime.mq4 |
//|                                           Ким Игорь В. aka KimIV |
//|                                              http://www.kimiv.ru |
//|                                                                  |
//| Советник в нужное время закрывает все позиции.                   |
//+------------------------------------------------------------------+
#property copyright "Ким Игорь В. aka KimIV"
#property link      "http://www.kimiv.ru"

//---- input parameters
extern int   CloseHour     = 7;      // Время закрытия, часы
extern int   CloseMinute   = 0;      // Время закрытия, минуты
extern bool  UseCurrSymbol = False;  // Использовать только один инструмент
extern bool  UseOneAccount = False;  // Использовать только один счёт
extern int   NumberAccount = 11111;  // Номер торгового счёта
extern int   Slippage      = 3;      // Проскальзывание цены
extern color clCloseBuy    = Blue;   // Цвет закрытия покупки
extern color clCloseSell   = Red;    // Цвет закрытия продажи

void start() {
  double pBid, pAsk;

  if (UseOneAccount && AccountNumber()!=NumberAccount) {
    Comment("Работа на счёте: "+AccountNumber()+" ЗАПРЕЩЕНА!");
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