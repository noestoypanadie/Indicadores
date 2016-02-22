//+------------------------------------------------------------------+
//|                                                   5M_Scalper.mq4 |
//|                                                                  |
//| 
//+------------------------------------------------------------------+
#property copyright "borrowed some code from mpfx"
#property link ""

#include <stdlib.mqh>

extern double Lots = 1.0;
extern double TakeProfit = 10;
extern double Stoploss = 17;
extern double TrailingStop = 9;
extern double Slippage = 2;
extern double risk = 5.0;
extern double Pips = 16;
extern double Perc = 5;
double Points;
//int color arrow_color=CLR_NONE;

int init ()
{
  Points = MarketInfo (Symbol(), MODE_POINT);
  //----
  return(0);
}
//+------------------------------------------------------------------+
//| |
//+------------------------------------------------------------------+
int deinit()
{
  return(0);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| expert start function |
//+------------------------------------------------------------------+
int start()
{
  double Levv=0;
  int cnt=0, total;

  if(Bars<10)
  {
    Print("bars less than 100");
    return(0);
  }  
  if(OrdersTotal()<1)
  {
    if(AccountFreeMargin()<(1*Lots))
    {
      Print("BrokeAsAJoke");
      return(0);
    }
    Levv= (MathCeil(AccountEquity() * risk / 10000)/10);
    

    // (BUY)
    if (Close[1]>Close[2])
    {
      OrderSend(Symbol(),OP_BUY,Levv,Bid,Slippage,Bid-Stoploss*Points,Ask+TakeProfit*Points,0,0,Red);
      return(0);
    }
   
    // (SELL)
    if (Close[1]<Close[2])
    {
      OrderSend(Symbol(),OP_SELL,Levv,Ask,Slippage,Ask+Stoploss*Points,Bid-TakeProfit*Points,0,0,Red);
      return(0);
    }
  }

  total=OrdersTotal();
  for(cnt=0;cnt<OrdersTotal();cnt++)
  {
    OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
    if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())
    {
      if(OrderType()==OP_BUY)
      {
        //if((OrderOpenTime() - (CurTime() >= 300))|| (AccountProfit() >2))
        if((CurTime() - (OrderOpenTime() >= 300)) || (AccountProfit() >2))
        {
          OrderClose(OrderTicket(),OrderLots(),Ask,0,Violet);
          return(0);
        }
      }
    }
  }

  total=OrdersTotal();
  for(cnt=0;cnt<OrdersTotal();cnt++)
  {
    OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
    if(OrderType()<=OP_BUY && OrderSymbol()==Symbol())
    {
      if(OrderType()==OP_SELL)
      {
        //if ((OrderOpenTime() - (CurTime() >= 300))|| (AccountProfit() >2))//1 Day//
        if((CurTime() - (OrderOpenTime() >= 300)) || (AccountProfit() >2))
        {
          OrderClose(OrderTicket(),OrderLots(),Bid,0,Violet);
          return(0);
        }
      }
    }
  }
}