//+------------------------------------------------------------------+
//|                                                e-5mSAR_v.0.2.mq4 |
//|                                           ��� ����� �. aka KimIV |
//|                                              http://www.kimiv.ru |
//|                                                                  |
//| 30.09.2005  5-�������� �������������� ����                       |
//| 02.10.2005  v.0.1 ������ ���� ���� �� ���� ���                   |
//| 03.10.2005  v.0.2 ����                                           |
//+------------------------------------------------------------------+
#property copyright "��� ����� �. aka KimIV"
#property link      "http://www.kimiv.ru"
#define   MAGIC     20050930

//------- ������� ��������� ��������� --------------------------------
extern string _Parameters_Trade = "---------- ��������� ��������";
extern double Lots           = 0.1;    // ������ ���������� ����
extern int    StopLoss       = 18;     // ������ �������������� �����
extern int    TakeProfit     = 60;     // ������ �������������� �����
extern bool   ProfitTrailing = True;   // ������� ������ ������
extern int    TrailingStop   = 15;     // ������������� ������ �����
extern int    TrailingStep   = 3;      // ��� �����
extern int    Slippage       = 5;      // ��������������� ����
extern bool   UseHourTrade   = True;   // ������������ ����� ��������
extern int    HourBegTrade   = 4;      // ����� ������ ��������
extern int    HourEndTrade   = 19;     // ����� ����� ��������
extern string _Parameters_Indicator = "---------- ��������� �����������";
extern double StepParabolic = 0.03;    // ��� ����������
extern double MaxParabolic  = 0.3;     // �������� ����������
extern string _Parameters_Expert = "---------- ��������� ���������";
extern bool   UseOneAccount = True;    // ��������� ������ �� ����� �����
extern int    NumberAccount = 71597;   // ����� ��������� �����
extern string Name_Expert   = "e-5mSAR_v.0.2";
extern bool   UseSound      = True;         // ������������ �������� ������
extern string NameFileSound = "expert.wav"; // ������������ ��������� �����
extern color  clOpenBuy     = LightBlue;    // ���� �������� �������
extern color  clOpenSell    = LightCoral;   // ���� �������� �������
extern color  clModifyBuy   = Aqua;         // ���� ����������� �������
extern color  clModifySell  = Tomato;       // ���� ����������� �������
extern color  clCloseBuy    = Blue;         // ���� �������� �������
extern color  clCloseSell   = Red;          // ���� �������� �������

//---- ���������� ���������� ��������� -------------------------------
int prevBar;    // ���������� ���������� �����

//------- ����������� ������� ������� --------------------------------

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
    Comment("�������� �� �����: "+AccountNumber()+" ���������!");
    return;
  } else Comment("");

  if (UseHourTrade && (Hour()<HourBegTrade || Hour()>=HourEndTrade)) {
    Comment("����� �������� ��� �� ���������!");
    return;
  } else Comment("");

  CheckForOpen();
  TrailingPositions();
}

//+------------------------------------------------------------------+
//| �������� ������� ��� �����                                       |
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
//| ���������� ���� ������������� ������ ��� �������                 |
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
//| ��������� ������                                                 |
//| ���������:                                                       |
//|   op     - ��������                                              |
//|   pp     - ����                                                  |
//|   ldStop - ������� ����                                          |
//|   ldTake - ������� ����                                          |
//+------------------------------------------------------------------+
void SetOrder(int op, double pp, double ldStop, double ldTake) {
  color  clOpen;
  string lsComm=GetCommentForOrder();
  if (op==OP_BUY) clOpen=clOpenBuy; else clOpen=clOpenSell;
  OrderSend(Symbol(),op,Lots,pp,Slippage,ldStop,ldTake,lsComm,MAGIC,0,clOpen);
  if (UseSound) PlaySound(NameFileSound);
}

//+------------------------------------------------------------------+
//| ���������� � ���������� ������ ���������� ��� ������ ��� ������� |
//+------------------------------------------------------------------+
string GetCommentForOrder() {
  return(Name_Expert);
}

//+------------------------------------------------------------------+
//| ������������� ������� ������� ������                             |
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
//| ������� ������ StopLoss                                          |
//| ���������:                                                       |
//|   ldStopLoss - ������� StopLoss                                  |
//|   clModify   - ���� �����������                                  |
//+------------------------------------------------------------------+
void ModifyStopLoss(double ldStop, color clModify) {
  bool   fm;
  double ldOpen=OrderOpenPrice();
  double ldTake=OrderTakeProfit();

  fm=OrderModify(OrderTicket(), ldOpen, ldStop, ldTake, 0, clModify);
  if (fm && UseSound) PlaySound(NameFileSound);
}
//+------------------------------------------------------------------+

