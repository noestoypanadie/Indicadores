//+------------------------------------------------------------------+
//|                                             e-PassLevCCI-EMA.mq4 |
//|                              Идея Gentor, реализация в МТ4 KimIV |
//|                                              http://www.kimiv.ru |
//| Фиксация прибыли в порядке приоритета:                           |
//| 1. TrailingStop                                                  |
//| 2. TakeProfit                                                    |
//| 3. По сигналу выхода                                             |
//| Фильтр EMA                                                       |
//+------------------------------------------------------------------+
#property copyright "Gentor, KimIV"
#property link      "http://www.kimiv.ru"
#define   MAGIC     20050822

//------- Внешние параметры ------------------------------------------
extern double Lots          = 0.1;    // Размер торгуемого лота
extern int    StopLoss      = 27;     // Размер фиксированного стопа
extern bool   UseTakeProfit = True;   // Использовать тэйк
extern int    TakeProfit    = 70;     // Размер фиксированного тэйка
extern bool   UseTrailing   = False;  // Использовать трал
extern int    TrailingStop  = 50;     // Размер трала
extern int    CCI_Period    = 18;     // Период CCI
extern int    EMA_Period    = 34;     // Период EMA
extern int    BarsForCheck  = 4;      // Количество баров для проверки

//------- Глобальные переменные --------------------------------------
datetime OldBar;

//+------------------------------------------------------------------+
//| Проверка условий открытия позиции                                |
//+------------------------------------------------------------------+
void CheckForOpen() {
  bool   PosExist=False;     // Есть открытая позиция по текущему инструменту
  double cci1, cci2, ema;
  double take;

  // Поиск позиций по текущему инструменту, открытых именно этим советником
  for (int i=0; i<OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC) {
        PosExist=True;
      }
    }
  }

  // Нет открытых позиций.
  if (!PosExist) {
    // Фиксируем значения ССИ.
    cci1 = iCCI(NULL, 0, CCI_Period, PRICE_TYPICAL, 1);
    cci2 = iCCI(NULL, 0, CCI_Period, PRICE_TYPICAL, BarsForCheck);
    ema  = iMA (NULL, 0, EMA_Period, 0, MODE_EMA, PRICE_TYPICAL, 1);
    // Сигнал на покупку.
    if (cci1>100 && cci2<-100 && ema>Close[1]) {
      if (UseTakeProfit) take = Ask+TakeProfit*Point;
      else take = 0;
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,take,"e-PassLevCCI",MAGIC,0,Blue);
      OldBar = Time[1];
      return;
    }
    // Сигнал на продажу.
    if (cci1<-100 && cci2>100 && ema<Close[1]) {
      if (UseTakeProfit) take = Bid-TakeProfit*Point;
      else take = 0;
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+StopLoss*Point,take,"e-PassLevCCI",MAGIC,0,Red);
      OldBar = Time[1];
      return;
    }
  }
}

//+------------------------------------------------------------------+
//| Проверка условий закрытия позиции                                |
//+------------------------------------------------------------------+
void CheckForClose() {
  bool fs=False;        // Флаг наличия сигнала закрытия
  int  cci1, cci2;

  // Фиксируем значения ССИ.
  cci1 = iCCI(NULL, 0, CCI_Period, PRICE_TYPICAL, 1);
  cci2 = iCCI(NULL, 0, CCI_Period, PRICE_TYPICAL, 2);
  // Сигнал на закрытие позиции.
  if (cci1*cci2<0 && OldBar!=Time[1]) fs = True;

  // Поиск позиций по текущему инструменту, открытых именно этим советником
  for (int i=0; i<OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC) {
        if (OrderType()==OP_BUY && fs) {
          OrderClose(OrderTicket(), Lots, Bid, 3, Aqua);
          return;
        }
        if (OrderType()==OP_SELL && fs) {
          OrderClose(OrderTicket(), Lots, Ask, 3, Violet);
          return;
        }
      }
    }
  }
}

//+------------------------------------------------------------------+
//| Сопровождение позиции                                            |
//+------------------------------------------------------------------+
void TrailingPosition() {
  for (int i=0; i<OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC) {
        if (OrderType()==OP_BUY) {
          if ((Bid-OrderOpenPrice())>TrailingStop*Point) {
            if (OrderStopLoss()<Bid-TrailingStop*Point) {
              OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailingStop*Point,OrderTakeProfit(),Blue);
              return;
            }
          }
        }
        if (OrderType()==OP_SELL) {
          if ((OrderOpenPrice()-Ask)>TrailingStop*Point) {
            if (OrderStopLoss()>Ask+TrailingStop*Point) {
              OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailingStop*Point,OrderTakeProfit(),Red);
              return;
            }
          }
        }
      }
    }
  }
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void start() {
  CheckForOpen();
  if (UseTrailing) TrailingPosition();
  else if (!UseTakeProfit) CheckForClose();
}
//+------------------------------------------------------------------+

