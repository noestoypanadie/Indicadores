//+------------------------------------------------------------------+
//|                                                  WaitToTrade.mq4 |
//|                                    Copyright © 2006, Robert Hill |
//|                                                                  |
//| Written by Robert Hill for Metaquites Yahoo Group                |
//|                                                                  |
//| Includes 2 functions                                             | 
//|                                                                  |
//| HandleOpenPositions                                              |
//| Useful for closing trade at desired profit amount.               |
//| Profit can even be less that the minimum amount allowed          |
//| by the broker. Set the TakeProfit that is sent to broker         |
//| for a higher value in case of disconnect from server             |
//|                                                                  |
//| LastTradeClosedForProfit                                         |
//| Checks if last trade closed for the desired profit or more       |
//| Then stops EA from placing new orders until the number of        |
//| minutes desired has elapsed                                      |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Robert Hill"
#include <stdlib.mqh>

#define MAGIC 9271533             // Unique identifier for this expert

extern int NoTradeMinutes = 30;   // Minutes to stop trading after last trade stopped out
extern int TakeProfit = 60;       // Profit amount hoping to achieve, can be 1 pip
extern int ServerTakeProfit = 60; // Actual amount to sent with the order to the server 
datetime WaitTime=0;                // Time to wait after a trade is stopped out


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
  }
  

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
//---- 
   
     
// You code here for modifying or closing positions

   HandleOpenPositions();
   
// Check if last trade closed for TakeProfit amount

   if ( WaitTime == 0) WaitTime = LastTradeClosedForProfit(TakeProfit, NoTradeMinutes);
   if  (CurTime() < WaitTime) return(0);
   WaitTime = 0;
   
   
// Your code here for opening new positions

}    
   
   

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Handle Open Positions                                            |
//| Check if any open positions need to be closed or modified        |
//+------------------------------------------------------------------+
void HandleOpenPositions()
{
   int cnt;

   for(cnt=OrdersTotal()-1;cnt>=0;cnt--)
   {
      OrderSelect (cnt, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol() != Symbol()) continue;
      if ( OrderMagicNumber() != MAGIC)  continue;
      
      if(OrderType() == OP_BUY )
      {
         if (Bid - OrderOpenPrice() >= TakeProfit*Point)
         {
           CloseOrder(OrderTicket(),OrderLots(),Bid);
         }
      }

      if(OrderType() == OP_SELL )
      {
         if (OrderOpenPrice() - 2* Bid  - Ask >= TakeProfit*Point)
         {
           CloseOrder(OrderTicket(),OrderLots(),Ask);
         }
      }
   }
}



//+------------------------------------------------------------------+
//| LastTradeClosedForProfit                                         |
//| Check History to see if last trade closed >= ProfitAmount        |
//| Return Time for next trade                                       |
//| Time returned will be MinutesToWait after order close time       |
//| if the last trade closed for TakeProfit amount                   |
//| return 0 otherwise                                               |
//+------------------------------------------------------------------+
  
datetime LastTradeClosedForProfit(int ProfitAmount, int MinutesToWait)
{
   int cnt;
   datetime NextTime;
   bool ClosedForProfit;
   
   NextTime = 0;
   
   for (cnt = HistoryTotal()-1; cnt >=0; cnt--)
   {
      OrderSelect (cnt, SELECT_BY_POS, MODE_HISTORY);
      
      if(OrderSymbol()==Symbol() && OrderMagicNumber() == MAGIC)
      {
        if (OrderType() == OP_BUY)
        {
          if (OrderClosePrice() - OrderOpenPrice() >= ProfitAmount*Point)
          {
             ClosedForProfit = true;
             NextTime = OrderCloseTime();
          }
          else
          {
             ClosedForProfit = false;
          }
        }
        if (OrderType() == OP_SELL)
        {
          if (OrderOpenPrice() - OrderClosePrice() >= ProfitAmount*Point)
          {
             ClosedForProfit = true;
             NextTime = OrderCloseTime();
          }
          else
          {
             ClosedForProfit = false;
          }
        }
      }
// Last trade was found so exit the loop
      break;
   }
   
   if (ClosedForProfit)
   {
      NextTime = NextTime + MinutesToWait*60;
   }
   
   return (NextTime);
}

void CloseOrder(int ticket,double numLots,double close_price)
{
   int CloseCnt, err;
   
   // try to close 3 Times
      
    CloseCnt = 0;
    while (CloseCnt < 3)
    {
       if (!OrderClose(ticket,numLots,close_price,3,Violet))
       {
         err=GetLastError();
         Print(CloseCnt," Error closing order : (", err , ") " + ErrorDescription(err));
         if (err > 0) CloseCnt++;
       }
       else
       {
         CloseCnt = 3;
       }
    }
}

