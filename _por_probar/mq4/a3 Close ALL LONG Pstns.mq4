//+------------------------------------------------------------------+
//|                                      a3 Close ALL LONG Pstns.mq4 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Ronald Verwer, Forex MetaSoft"
#property link "www.forexmetasoft.com"
#property show_confirm
//+------------------------------------------------------------------+
//| script to close ALL LONG positions at market                     |
//+------------------------------------------------------------------+
int start()
  {
   int    i,type,err,Slippage=3;
   double price;
   bool   result;
//----
   for(i=OrdersTotal()-1;i>=0;i--)
      {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         {
         type=OrderType();
         if(type==OP_BUY)
            {
            while(true)
               {
               result=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),Slippage,CLR_NONE);
               if(result!=true) {err=GetLastError(); Print("LastError = ",err);}
               else err=0;
               if(err==135) RefreshRates();
               else break;
         }  }  }
      else Print( "When selecting a trade, error ",GetLastError()," occurred");
      }
   return(0);
   }
//+------------------------------------------------------------------+