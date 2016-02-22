//+------------------------------------------------------------------+
//|                                                        Buy.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#include <stdlib.mqh>
#property copyright "Copyright © 2004, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"
//+------------------------------------------------------------------+
//| script "trading for all money"                                   |
//+------------------------------------------------------------------+
int start()
  {
   int ticket;
//----
   while(true)
     {
      ticket=OrderSend(Symbol(),OP_BUY,1.0,Ask,2,Ask-11*Point,0,"expert comment",255,0,CLR_NONE);
      if(ticket<=0)
        {
         int error=GetLastError();
         Print("Error = ",ErrorDescription(error));
         if(error==134) break;            // not enough money
         if(error==135) RefreshRates();   // prices changed
         break;
        }
      //---- remove break statement below and take trading for all money
      else { OrderPrint(); break; }
      //---- 10 seconds wait
      Sleep(10000);
     }
//----
   return(0);
  }
//+------------------------------------------------------------------+