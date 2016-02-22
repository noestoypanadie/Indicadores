//+------------------------------------------------------------------+
//|                                      Manual Trendline Trader.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                      Copyright © 2005, tageiger as fxid10t       |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright  "steve.cartwright@homecall.co.uk"//originator
#property copyright  "tageiger fxid10t@yahoo.com" //modifier
#property link       "http://www.metaquotes.net"
#property link       "http://finance.groups.yahoo.com/group/MetaTrader_Experts_and_Indicators/"
#property link       "http://www.forexnews.com"

extern double  Lots              =0.1;
extern double  MaximumRisk       =0.02;
extern double  DecreaseFactor    =3;
extern double  Slippage          =3;
extern int     UseTrailingStop   =0;//>0 enables trailing stop
extern double  TrailingStop      =20;
extern int     OneTradePerDay    =0;//>0 LIMITS(restricts) trades to ONE PER DAY



//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//---- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//---- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         //----
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//---- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
   }