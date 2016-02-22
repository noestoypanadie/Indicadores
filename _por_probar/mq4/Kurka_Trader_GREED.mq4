//+------------------------------------------------------------------+
//|                                             KurkaTraderGREED.mq4 |
//|                                     Copyright © 2006, KurkaFund. |
//|                                         http://www.kurkafund.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, KurkaFund."
#property link      "http://www.kurkafund.com"
#include <stdlib.mqh>

extern int    MAGIC            = 0001;
extern int    STOPLOSS         = 200;
extern int    TAKEPROFIT       = 100;
extern int    SLIPPAGE         = 3;
extern int    SIGNALCANDLE     = 1;
extern int    LOTS             = 1;

extern int    PIPSTART         = 5;
extern int    PIPSTEP          = 3;

extern int    OSMATIME         = PERIOD_M15;
extern int    OSMAFast         = 5;
extern int    OSMASlow         = 30;
extern double OSMASignal       = 2;

extern int    ADXTIME          = PERIOD_M5;
extern int    ADXPERIOD        = 6;

extern bool   ProfitTrailing = True;  
extern int    TrailingStop   = 5;     
extern int    TrailingStep   = 2;     
extern bool   UseSound       = True;  
extern string NameFileSound  = "expert.wav";  

void start(){



double OSMAPrev     = iOsMA(NULL,OSMATIME,OSMASlow,OSMAFast,OSMASignal,PRICE_CLOSE,SIGNALCANDLE+1);
double OSMA         = iOsMA(NULL,OSMATIME,OSMASlow,OSMAFast,OSMASignal,PRICE_CLOSE,SIGNALCANDLE);
double ADXPLUS      = iADX(NULL,ADXTIME,ADXPERIOD,PRICE_MEDIAN,MODE_PLUSDI,SIGNALCANDLE);
double ADXMINUS     = iADX(NULL,ADXTIME,ADXPERIOD,PRICE_MEDIAN,MODE_MINUSDI,SIGNALCANDLE);
double PREVIOUSHIGH = iHigh(NULL,0,SIGNALCANDLE+1);
double PREVIOUSLOW  = iLow(NULL,0,SIGNALCANDLE+1);


          
if (OSMA > OSMAPrev && ADXPLUS > ADXMINUS){
   if (Ask == (PREVIOUSHIGH - PIPSTART * Point)){
      OrderSend(Symbol(),OP_BUY,LOTS,Ask,SLIPPAGE,Ask-STOPLOSS*Point,Ask+TAKEPROFIT*Point,"BUY PIPSTART",MAGIC,0,Green);
      return(0);
      }
   if (Ask == (PREVIOUSHIGH - (PIPSTART - PIPSTEP) * Point)){
      OrderSend(Symbol(),OP_BUY,LOTS,Ask,SLIPPAGE,Ask-STOPLOSS*Point,Ask+TAKEPROFIT*Point,"BUY PIPSTEP 1",MAGIC,0,Green);
      return (0);
      }
   if (Ask == (PREVIOUSHIGH - (PIPSTART - PIPSTEP - PIPSTEP) * Point)){
      OrderSend(Symbol(),OP_BUY,LOTS,Ask,SLIPPAGE,Ask-STOPLOSS*Point,Ask+TAKEPROFIT*Point,"BUY PIPSTEP 2",MAGIC,0,Green);
      return (0);
      }
   if (Ask == (PREVIOUSHIGH - (PIPSTART - PIPSTEP - PIPSTEP - PIPSTEP) * Point)){
      OrderSend(Symbol(),OP_BUY,LOTS,Ask,SLIPPAGE,Ask-STOPLOSS*Point,Ask+TAKEPROFIT*Point,"BUY PIPSTEP 3",MAGIC,0,Green);
      return (0);
      }
   if (Ask == (PREVIOUSHIGH - (PIPSTART - PIPSTEP - PIPSTEP - PIPSTEP - PIPSTEP) * Point)){
      OrderSend(Symbol(),OP_BUY,LOTS,Ask,SLIPPAGE,Ask-STOPLOSS*Point,Ask+TAKEPROFIT*Point,"BUY PIPSTEP 4",MAGIC,0,Green);
      return (0);
      }
    }

if (OSMA < OSMAPrev && ADXPLUS > ADXMINUS){
   if (Bid == (PREVIOUSLOW + PIPSTART * Point)){
      OrderSend(Symbol(),OP_SELL,LOTS,Bid,SLIPPAGE,Bid+STOPLOSS*Point,Bid-TAKEPROFIT*Point,"SELL PIPSTART",MAGIC,0,Green);
      return(0);
      }
   if (Bid == (PREVIOUSLOW + (PIPSTART + PIPSTEP) * Point)){
      OrderSend(Symbol(),OP_SELL,LOTS,Bid,SLIPPAGE,Bid+STOPLOSS*Point,Bid-TAKEPROFIT*Point,"SELL PIPSTEP 1",MAGIC,0,Green);
      return (0);
      }
   if (Bid == (PREVIOUSLOW + (PIPSTART + PIPSTEP + PIPSTEP) * Point)){
      OrderSend(Symbol(),OP_SELL,LOTS,Bid,SLIPPAGE,Bid+STOPLOSS*Point,Bid-TAKEPROFIT*Point,"SELL PIPSTEP 2",MAGIC,0,Green);
      return (0);
      }
   if (Bid == (PREVIOUSLOW + (PIPSTART + PIPSTEP + PIPSTEP + PIPSTEP) * Point)){
      OrderSend(Symbol(),OP_SELL,LOTS,Bid,SLIPPAGE,Bid+STOPLOSS*Point,Bid-TAKEPROFIT*Point,"SELL PIPSTEP 3",MAGIC,0,Green);
      return (0);
      }
   if (Bid == (PREVIOUSLOW + (PIPSTART + PIPSTEP + PIPSTEP + PIPSTEP + PIPSTEP) * Point)){
      OrderSend(Symbol(),OP_SELL,LOTS,Bid,SLIPPAGE,Bid+STOPLOSS*Point,Bid-TAKEPROFIT*Point,"SELL PIPSTEP 4",MAGIC,0,Green);
      return (0);
      }
    }

  for (int i=0; i<OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      TrailingPositions();
    }
  }
}

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

void ModifyStopLoss(double ldStopLoss) {
  bool fm;
  fm=OrderModify(OrderTicket(),OrderOpenPrice(),ldStopLoss,OrderTakeProfit(),0,CLR_NONE);
  if (fm && UseSound) PlaySound(NameFileSound);
}


