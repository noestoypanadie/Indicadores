//+------------------------------------------------------------------+
//|                                                   e-Trailing.mq4 |
//|                                           ��� ����� �. aka KimIV |
//|                                              http://www.kimiv.ru |
//|                                                                  |
//| 12.09.2005 �������������� Trailing Stop ���� �������� �������    |
//|            ������ ������ �� ���� ������                          |
//+------------------------------------------------------------------+
#property copyright "��� ����� �. aka KimIV"
#property link      "http://www.kimiv.ru"

//------- ������� ��������� ------------------------------------------
extern bool   ProfitTrailing = True;  // ������� ������ ������
extern int    TrailingStop   = 8;     // ������������� ������ �����
extern int    TrailingStep   = 2;     // ��� �����
extern bool   UseSound       = True;  // ������������ �������� ������
extern string NameFileSound  = "expert.wav";  // ������������ ��������� �����

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void start() {
  for (int i=0; i<OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      TrailingPositions();
    }
  }
}

//+------------------------------------------------------------------+
//| ������������� ������� ������� ������                             |
//+------------------------------------------------------------------+
void TrailingPositions() {
  double pBid, pAsk, pp;

  pp = MarketInfo(OrderSymbol(), MODE_POINT);
  if (OrderType()==OP_BUY) {
    pBid = MarketInfo(OrderSymbol(), MODE_BID);
    if (!ProfitTrailing || (pBid-OrderOpenPrice())>TrailingStop*pp) {
      if (OrderStopLoss()<pBid-(TrailingStop+TrailingStep-1)*pp) {
        ModifyStopLoss(pBid-TrailingStop*pp);
        return;
      }
    }
  }
  if (OrderType()==OP_SELL) {
    pAsk = MarketInfo(OrderSymbol(), MODE_ASK);
    if (!ProfitTrailing || OrderOpenPrice()-pAsk>TrailingStop*pp) {
      if (OrderStopLoss()>pAsk+(TrailingStop+TrailingStep-1)*pp || OrderStopLoss()==0) {
        ModifyStopLoss(pAsk+TrailingStop*pp);
        return;
      }
    }
  }
}

//+------------------------------------------------------------------+
//| ������� ������ StopLoss                                          |
//| ���������:                                                       |
//|   ldStopLoss - ������� StopLoss                                  |
//+------------------------------------------------------------------+
void ModifyStopLoss(double ldStopLoss) {
  bool fm;

  fm=OrderModify(OrderTicket(),OrderOpenPrice(),ldStopLoss,OrderTakeProfit(),0,CLR_NONE);
  if (fm && UseSound) PlaySound(NameFileSound);
}
//+------------------------------------------------------------------+

