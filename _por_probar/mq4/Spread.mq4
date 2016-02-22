#include <stdlib.mqh>
//+------------------------------------------------------------------+
//|                                                       Spread.mq4 |
//|                                                                  |
//|                                                                  |
//|                                        Converted by Mql2Mq4 v0.7 |
//|                                            http://yousky.free.fr |
//|                                    Copyright © 2006, Yousky Soft |
//+------------------------------------------------------------------+

#property copyright " Copyright © 2006, Nick Bilak, beluck[AT]gmail.com"
#property link      " http://metatrader.50webs.com "


//+------------------------------------------------------------------+
//| Common External variables                                        |
//+------------------------------------------------------------------+
extern double Lots = 1.00;
extern double StopLoss = 20.00;
extern double TakeProfit = 10.00;
extern double TrailingStop = 0.00;

//+------------------------------------------------------------------+
//| External variables                                               |
//+------------------------------------------------------------------+
extern double slippage = 0;
extern double risk = 50;
extern double mm = 1;

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

int OrderValueTicket(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderTicket());
}

int OrderValueType(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderType());
}

double OrderValueLots(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderLots());
}

string OrderValueSymbol(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderSymbol());
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
int i = 0;
double cnt = 0;
double lotsi = 0;
bool sell = false;
bool buy = false;
double ptime = 0;
double orders = 0;
double sym = 0;

/*[[
 Name := mio trader
 Author := Copyright © 2006, Nick Bilak, beluck[AT]gmail.com
 Link := http://metatrader.50webs.com 
 Notes := 
 Lots := 1
 Stop Loss := 20
 Take Profit := 10
 Trailing Stop := 0
]]*/


 

if( AccountFreeMargin()<200 ) return(0);  
if( ((CurTime()-LastTradeTime)<30) ) return(0);
if( mm != 0 ) 
 lotsi=MathCeil(AccountBalance()*risk/10000)/10
; else 
 lotsi=Lots;

orders=0;
sym=0;
for(i=1;i<=OrdersTotal();i++) {
 if( OrderValueSymbol(i) == Symbol() ) {
  sym=i;
  orders=1;
 }
}


sell=false;
buy=false;
if( Close[1]>Open[1] ) { buy=true; sell=false; }
if( Close[1]<Open[1]  ) { sell=true; buy=false; }

if( orders>0 ) {
 if( OrderValueType(sym) == OP_SELL ) {
     OrderClose(OrderValueTicket(sym),OrderValueLots(sym),Bid,slippage,Blue);
     return(0); 
 }
 if( OrderValueType(sym) == OP_BUY ) {
     OrderClose(OrderValueTicket(sym),OrderValueLots(sym),Ask,slippage,Red); 
     return(0); 
 }
}
if( ptime != Time[0] && buy ) {
   if( orders == 0 ) {
  ptime=Time[0];
        MOrderSend(Symbol(),OP_BUY,lotsi,Bid,slippage,Bid-StopLoss*Point,Ask+TakeProfit*Point,"",16384,0,Red);
        return(0); 
   }
}
if( ptime != Time[0] && sell ) {
   if( orders == 0 ) {
  ptime=Time[0];
        MOrderSend(Symbol(),OP_SELL,lotsi,Ask,slippage,Ask+StopLoss*Point,Bid-TakeProfit*Point,"",16384,0,Blue);
        return(0);
    } 
}
  return(0);
}