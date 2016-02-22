//+------------------------------------------------------------------+
//|                                                e-5mSAR_v.0.2.mq4 |
//|                                           Ким Игорь В. aka KimIV |
//|                                              http://www.kimiv.ru |
//|                                                                  |
//| 30.09.2005  5-минутный параболический вход                       |
//| 02.10.2005  v.0.1 Сделал один вход на один бар                   |
//| 03.10.2005  v.0.2 Трал                                           |
//+------------------------------------------------------------------+
#property copyright "Ким Игорь В. aka KimIV"
#property link      "http://www.kimiv.ru"
#define   MAGIC     20050930

//------- Внешние параметры советника --------------------------------
extern string _Parameters_Trade = "---------- Параметры торговли";
extern double Lots           = 0.1;    // Размер торгуемого лота
extern int    StopLoss       = 18;     // Размер фиксированного стопа
extern int    TakeProfit     = 60;     // Размер фиксированного тэйка
extern bool   ProfitTrailing = True;   // Тралить только профит
extern int    TrailingStop   = 15;     // Фиксированный размер трала
extern int    TrailingStep   = 3;      // Шаг трала
extern int    Slippage       = 5;      // Проскальзывание цены
extern bool   UseHourTrade   = True;   // Использовать время торговли
extern int    HourBegTrade   = 4;      // Время начала торговли
extern int    HourEndTrade   = 19;     // Время конца торговли
extern string _Parameters_Indicator = "---------- Параметры индикаторов";
extern double StepParabolic = 0.03;    // Шаг параболика
extern double MaxParabolic  = 0.3;     // Максимум параболика
extern string _Parameters_Expert = "---------- Параметры советника";
extern bool   UseOneAccount = True;    // Торговать только на одном счёте
extern int    NumberAccount = 71597;   // Номер торгового счёта
extern string Name_Expert   = "e-5mSAR_v.0.2";
extern bool   UseSound      = True;         // Использовать звуковой сигнал
extern string NameFileSound = "expert.wav"; // Наименование звукового файла
extern color  clOpenBuy     = LightBlue;    // Цвет открытия покупки
extern color  clOpenSell    = LightCoral;   // Цвет открытия продажи
extern color  clModifyBuy   = Aqua;         // Цвет модификации покупки
extern color  clModifySell  = Tomato;       // Цвет модификации продажи
extern color  clCloseBuy    = Blue;         // Цвет закрытия покупки
extern color  clCloseSell   = Red;          // Цвет закрытия продажи

//---- Глобальные переменные советника -------------------------------
int prevBar;    // Предыдущее количество баров

//------- Подключение внешних модулей --------------------------------

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
void deinit() {
  Comment("");
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void start() {
  if (UseOneAccount && AccountNumber()!=NumberAccount) {
    Comment("Торговля на счёте: "+AccountNumber()+" ЗАПРЕЩЕНА!");
    return;
  } else Comment("");

  if (UseHourTrade && (Hour()<HourBegTrade || Hour()>=HourEndTrade)) {
    Comment("Время торговли ещё не наступило!");
    return;
  } else Comment("");

  CheckForOpen();
  TrailingPositions();
}

//+------------------------------------------------------------------+
//| Проверка условий для входа                                       |
//+------------------------------------------------------------------+
void CheckForOpen() {
  double ldStop=0, ldTake=0;
  double sar0=iSAR(NULL, 0, StepParabolic, MaxParabolic, 0);
  double sar1=iSAR(NULL, 0, StepParabolic, MaxParabolic, 1);

  if (!ExistPosition() && prevBar!=Bars) {
    if (sar1>Open[1] && sar0<Bid) {
      if (StopLoss!=0) ldStop=Ask-StopLoss*Point;
      if (TakeProfit!=0) ldTake=Ask+TakeProfit*Point;
      SetOrder(OP_BUY, Ask, ldStop, ldTake);
      prevBar=Bars;
    }
    if (sar1<Open[1] && sar0>Ask) {
      if (StopLoss!=0) ldStop=Bid+StopLoss*Point;
      if (TakeProfit!=0) ldTake=Bid-TakeProfit*Point;
      SetOrder(OP_SELL, Bid, ldStop, ldTake);
      prevBar=Bars;
    }
  }
}

//+------------------------------------------------------------------+
//| Возвращает флаг существования ордера или позиции                 |
//+------------------------------------------------------------------+
bool ExistPosition() {
  bool Exist=False;
  for (int i=0; i<OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC) Exist=True;
    }
  }
  return(Exist);
}

//+------------------------------------------------------------------+
//| Установка ордера                                                 |
//| Параметры:                                                       |
//|   op     - операция                                              |
//|   pp     - цена                                                  |
//|   ldStop - уровень стоп                                          |
//|   ldTake - уровень тейк                                          |
//+------------------------------------------------------------------+
void SetOrder(int op, double pp, double ldStop, double ldTake) {
  color  clOpen;
  string lsComm=GetCommentForOrder();
  if (op==OP_BUY) clOpen=clOpenBuy; else clOpen=clOpenSell;
  OrderSend(Symbol(),op,Lots,pp,Slippage,ldStop,ldTake,lsComm,MAGIC,0,clOpen);
  if (UseSound) PlaySound(NameFileSound);
}

//+------------------------------------------------------------------+
//| Генерирует и возвращает строку коментария для ордера или позиции |
//+------------------------------------------------------------------+
string GetCommentForOrder() {
  return(Name_Expert);
}

//+------------------------------------------------------------------+
//| Сопровождение позиции простым тралом                             |
//+------------------------------------------------------------------+
void TrailingPositions() {
  for (int i=0; i<OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderMagicNumber()>MAGIC && OrderMagicNumber()<=MAGIC+5) {
        if (OrderSymbol()==Symbol()) {
          if (OrderType()==OP_BUY) {
            if (!ProfitTrailing || (Bid-OrderOpenPrice())>TrailingStop*Point) {
              if (OrderStopLoss()<Bid-(TrailingStop+TrailingStep-1)*Point) {
                ModifyStopLoss(Bid-TrailingStop*Point, clModifyBuy);
              }
            }
          }
          if (OrderType()==OP_SELL) {
            if (!ProfitTrailing || OrderOpenPrice()-Ask>TrailingStop*Point) {
              if (OrderStopLoss()>Ask+(TrailingStop+TrailingStep-1)*Point || OrderStopLoss()==0) {
                ModifyStopLoss(Ask+TrailingStop*Point, clModifySell);
              }
            }
          }
        }
      }
    }
  }
}

//+------------------------------------------------------------------+
//| Перенос уровня StopLoss                                          |
//| Параметры:                                                       |
//|   ldStopLoss - уровень StopLoss                                  |
//|   clModify   - цвет модификации                                  |
//+------------------------------------------------------------------+
void ModifyStopLoss(double ldStop, color clModify) {
  bool   fm;
  double ldOpen=OrderOpenPrice();
  double ldTake=OrderTakeProfit();

  fm=OrderModify(OrderTicket(), ldOpen, ldStop, ldTake, 0, clModify);
  if (fm && UseSound) PlaySound(NameFileSound);
}
//+------------------------------------------------------------------+

