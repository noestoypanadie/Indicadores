
//+-------------------------------------------------------------------------+
//|                                            Clear The Board Bee-otch.mq4 |
//|                                       Copyright © 2006, transport_david |
//|http://finance.groups.yahoo.com/group/MetaTrader_Experts_and_Indicators/ |
//+-------------------------------------------------------------------------+

#property copyright "Copyright © 2006, transport_david"
#property link      "http://finance.groups.yahoo.com/group/MetaTrader_Experts_and_Indicators/"

extern int CloseHour   =    23;
extern int CloseNow    =     1;
int    i;
bool   CloseMAll;

int start()
{

  ////////////////////////////////
  // initial data checks
  ////////////////////////////////

  if ((Hour()!=CloseHour) && (CloseNow==0))   { CloseMAll = false;  }
  if ((Hour()==CloseHour) || (CloseNow==1))   { CloseMAll = true;   }

  ///////////////////////////////////
  // close/delete all trades/orders
  ///////////////////////////////////

  if (CloseMAll == true)
   {
    for(i = OrdersTotal()-1; i >=0 ; i--)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
       if (OrdersTotal() != 0)
        {
         OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,White);
         OrderDelete( OrderTicket() );
         CloseMAll = true;
        }
     }
   }
 return(0);
}