//+------------------------------------------------------------------+
//|                                         CloseMall_Hour_Input.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern int CloseHour   =    23;
int    i;
bool   CloseMAll;

int start()
{

  ////////////////////////////////
  // initial data checks
  ////////////////////////////////

  if (Hour()!=CloseHour)   { CloseMAll = false;  }
  if (Hour()==CloseHour)   { CloseMAll = true;   }

  ///////////////////////////////////
  // Determine trades/orders and close/delete all trades/orders
  ///////////////////////////////////

  if (CloseMAll == true)
   {
    for(i = OrdersTotal()-1; i >=0 ; i--)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
       if (OrderSymbol() == Symbol())
        {
         OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,White);
         OrderDelete( OrderTicket() );
         CloseMAll = true;
        }
     }
   }
 return(0);
}