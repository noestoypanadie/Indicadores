//+------------------------------------------------------------------+
//|                                             e-PassLevCCI-EMA.mq4 |
//|                              ���� Gentor, ���������� � ��4 KimIV |
//|                                              http://www.kimiv.ru |
//| �������� ������� � ������� ����������:                           |
//| 1. TrailingStop                                                  |
//| 2. TakeProfit                                                    |
//| 3. �� ������� ������                                             |
//| ������ EMA                                                       |
//+------------------------------------------------------------------+
#property copyright "Gentor, KimIV"
#property link      "http://www.kimiv.ru"
#define   MAGIC     20050822

//------- ������� ��������� ------------------------------------------
extern double Lots          = 0.1;    // ������ ���������� ����
extern int    StopLoss      = 27;     // ������ �������������� �����
extern bool   UseTakeProfit = True;   // ������������ ����
extern int    TakeProfit    = 70;     // ������ �������������� �����
extern bool   UseTrailing   = False;  // ������������ ����
extern int    TrailingStop  = 50;     // ������ �����
extern int    CCI_Period    = 18;     // ������ CCI
extern int    EMA_Period    = 34;     // ������ EMA
extern int    BarsForCheck  = 4;      // ���������� ����� ��� ��������

//------- ���������� ���������� --------------------------------------
datetime OldBar;

//+------------------------------------------------------------------+
//| �������� ������� �������� �������                                |
//+------------------------------------------------------------------+
void CheckForOpen() {
  bool   PosExist=False;     // ���� �������� ������� �� �������� �����������
  double cci1, cci2, ema;
  double take;

  // ����� ������� �� �������� �����������, �������� ������ ���� ����������
  for (int i=0; i<OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC) {
        PosExist=True;
      }
    }
  }

  // ��� �������� �������.
  if (!PosExist) {
    // ��������� �������� ���.
    cci1 = iCCI(NULL, 0, CCI_Period, PRICE_TYPICAL, 1);
    cci2 = iCCI(NULL, 0, CCI_Period, PRICE_TYPICAL, BarsForCheck);
    ema  = iMA (NULL, 0, EMA_Period, 0, MODE_EMA, PRICE_TYPICAL, 1);
    // ������ �� �������.
    if (cci1>100 && cci2<-100 && ema>Close[1]) {
      if (UseTakeProfit) take = Ask+TakeProfit*Point;
      else take = 0;
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,take,"e-PassLevCCI",MAGIC,0,Blue);
      OldBar = Time[1];
      return;
    }
    // ������ �� �������.
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
//| �������� ������� �������� �������                                |
//+------------------------------------------------------------------+
void CheckForClose() {
  bool fs=False;        // ���� ������� ������� ��������
  int  cci1, cci2;

  // ��������� �������� ���.
  cci1 = iCCI(NULL, 0, CCI_Period, PRICE_TYPICAL, 1);
  cci2 = iCCI(NULL, 0, CCI_Period, PRICE_TYPICAL, 2);
  // ������ �� �������� �������.
  if (cci1*cci2<0 && OldBar!=Time[1]) fs = True;

  // ����� ������� �� �������� �����������, �������� ������ ���� ����������
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
//| ������������� �������                                            |
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

