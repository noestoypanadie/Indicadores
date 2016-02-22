//+-------------------------------------------------------------------------+
//|                        Close_Delete_Everything_ASAP_Now_Profit_Hour.mq4 |
//|                                       Copyright © 2006, transport_david |
//|http://finance.groups.yahoo.com/group/MetaTrader_Experts_and_Indicators/ |
//+-------------------------------------------------------------------------+



//---------------------------------------------------------------------------

//   When This Runs It Closes And Deletes Every Trade On All Symbols ,
//   Will Not Stop Untill There Are No Current Trades Or Orders .

//---------------------------------------------------------------------------



#property copyright "Copyright © 2006, transport_david"
#property link      "http://finance.groups.yahoo.com/group/MetaTrader_Experts_and_Indicators/"


extern int CloseNow     =     0;  // Any value other than 0 == CloseMAll True

//----------------------------------------------------------------------------------------------
// Re-Set CloseProfit value AFTER you have attached this expert to the Chart(s) .
// Use the Properties Window

extern int CloseProfit  =  500000000;  // ( (Equity - Balance) > CloseProfit ) == CloseMAll True

// Use the Properties Window
// Re-Set CloseProfit value AFTER you have attached this expert to the Chart(s) .
//----------------------------------------------------------------------------------------------

extern int CloseHour    =    24;  // > 23 == disabled


int    i;
bool   CloseMAll;

int start()
{

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

  ////////////////////////////////
  // data checks
  ////////////////////////////////

  if ((Hour()!=CloseHour) && (CloseNow==0) && ((AccountEquity()-AccountBalance()) < CloseProfit)) { CloseMAll = false;  }
  if ((Hour()==CloseHour) || (CloseNow!=0) || ((AccountEquity()-AccountBalance()) > CloseProfit)) { CloseMAll = true;   }

 return(0);
}
