//+------------------------------------------------------------------+
//|                                               Terminator_MQ4.mq4 |
//|                     Copyright © 2006, 9/4/2006 David W Honeywell |
//|                                        transport.david@gmail.com |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2006, 9/4/2006 David W Honeywell"
#property link      "transport.david@gmail.com"


//---------------------------------------------------------------------------

//   When This Runs It Closes And Deletes Every Trade And Order On All Symbols ,
//   Will Not Stop Untill There Are No Current Trades Or Orders .

//---------------------------------------------------------------------------



#property copyright "Copyright © 2006, 9/4/2006 David W or Renee A Honeywell"
#property link      "DavidHoneywell800@msn.com  RenHon@msn.com"


extern int CloseNow     =     0;  // Any value other than 0 == CloseMAll 10 and trades will start closing and or cancelling after the price has moved .

//----------------------------------------------------------------------------------------------
// Re-Set CloseAtEquity value AFTER you have attached this expert to the Chart(s) .
// Use the Properties Window

extern int CloseAtEquity  =  500000000;  // ( (Equity - Balance) > CloseProfit ) == CloseMAll True

// Use the Properties Window
// Re-Set CloseAtEquity value AFTER you have attached this expert to the Chart(s) .
//----------------------------------------------------------------------------------------------

extern int CloseAtHour    =    24;  // 24 or greater and the CloseAtHour is "disabled" .


int    i;
double CloseMAll = 0;
double prevtime = 0;
int start()
 {
  if ( (Hour()!=CloseAtHour) && (CloseNow==0) && ((AccountEquity()-AccountBalance()) < CloseAtEquity) ) { CloseMAll = -10;  }
  if ( (Hour()==CloseAtHour) || (CloseNow!=0) || ((AccountEquity()-AccountBalance()) > CloseAtEquity) ) { CloseMAll =  10;   }
  
  if (CloseMAll > 0)
   {
    for(i = OrdersTotal()-1; i >=0 ; i--)
     { OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if ( (OrderType() == OP_BUY) || (OrderType() == OP_SELL) )
       {
         OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,White);
         CloseMAll = 10;
       }
      if ( (OrderType() == OP_BUYSTOP) || (OrderType() == OP_SELLSTOP) || (OrderType() == OP_BUYLIMIT) || (OrderType() == OP_SELLLIMIT) )
       {
         OrderDelete( OrderTicket() );
         CloseMAll = 10;
       }
     }
   }
  if ( (prevtime != Time[0]) && (OrdersTotal() <= 0) && (CloseMAll >= 0) )
   {
     Alert("Remove Expert");
     prevtime = Time[0];
     CloseMAll = -10;
   }
  return(0);
 }