//+------------------------------------------------------------------+
//|                                             The Reversal Bar.mq4 |
//|                                                                  |
//|                                                                  |
//|                                          Converted by Dr. Gaines |
//|                                      dr_richard_gaines@yahoo.com |
//|                                     
//+------------------------------------------------------------------+

#property copyright " Copyright © 2002, MetaQuotes Software Corp."
#property link      " http://www.metaquotes.ru"
#include <stdlib.mqh>

//+------------------------------------------------------------------+
//| Common External variables                                        |
//+------------------------------------------------------------------+
extern double Lots = 0.01;
extern double StopLoss = 0.00;
extern double TakeProfit = 40.00;
extern double TrailingStop = 0.00;

//+------------------------------------------------------------------+
//| External variables                                               |
//+------------------------------------------------------------------+
extern double Slippage = 2;
extern double MATrendPeriod = 60;

//+------------------------------------------------------------------+
//| Special Convertion Functions                                     |
//+------------------------------------------------------------------+

int LastTradeTime;

int MOrderSend( string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment="", int magic=0, datetime expiration=0, color arrow_color=CLR_NONE)
{
  LastTradeTime = CurTime();
  price = MathRound(price*10000)/10000;
  stoploss = MathRound(stoploss*10000)/10000;
  takeprofit = MathRound(takeprofit*10000)/10000;
  return ( OrderSend( symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic, expiration, arrow_color ) );
}

bool IsIndirect(string symbol)
{
}

//+------------------------------------------------------------------+
//| End                                                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+

int init()
{
   return(0);
}
int start()
{
//+------------------------------------------------------------------+
//| Local variables                                                  |
//+------------------------------------------------------------------+
double cnt = 0;
double pos = 0;
double sl = 0;
double tp = 0;
double MACurrent = 0;
double MAPrevious = 0;

/*[[
	Name := The Reversal Bar
	Author := Copyright © 2002, MetaQuotes Software Corp.
	Link := http://www.metaquotes.ru
	Notes := 
	Lots := 1
	Stop Loss := 0
	Take Profit := 40
	Trailing Stop := 0
]]*/




if( Bars<100 || TakeProfit<10 ) return(0);
if( IsIndirect(Symbol()) == TRUE ) return(0);

MACurrent=iMA(NULL, 0, MATrendPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
MAPrevious=iMA(NULL, 0, MATrendPeriod, 0, MODE_EMA, PRICE_CLOSE, 3);

if( OrdersTotal()<1 ) 
  {
   if( AccountFreeMargin()<1000 ) return(0);  // not enough money
   if( Low[2]<Low[3] && High[2]<High[3] &&
      Low[1]<Low[2] && High[1]<High[2] && 
      Close[1]>Open[1] && MACurrent>MAPrevious ) 
     {
      // calculate Stop Loss
      sl=Low[Lowest(NULL, 0, MODE_LOW,10,10)];  
      tp=High[Highest(NULL, 0, MODE_HIGH,10,10)];
      if( (tp-Ask)<15 ) tp=Ask+15*Point;
      if( (Bid-sl)<15 ) sl=Bid-15*Point;
      MOrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,sl,Ask+TakeProfit*Point,"",16384,0,Red);
      return(0);
     }
   if( Low[2]>Low[3] && High[2]>High[3] && 
      Low[1]>Low[2] && High[1]>High[2] && 
      Close[1]<Open[1] && MACurrent<MAPrevious ) 
     {
      // calculate Stop Loss
      sl=High[Highest(NULL, 0, MODE_HIGH,10,10)];
      tp=Low[Lowest(NULL, 0, MODE_LOW,10,10)];
      if( (Bid-tp)<15 ) tp=Bid-15*Point;
      if( (sl-Bid)<15 ) sl=Bid+15*Point;
      MOrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,sl,Bid-TakeProfit*Point,"",16384,0,Red);
      return(0);
     }
  }
  return(0);
}