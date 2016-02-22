//+------------------------------------------------------------------+
//|                                            close-all-orders.mq4  |
//|                                  Copyright © 2005, Matias Romeo. |
//|                                       Custom Metatrader Systems. |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2005, Matias Romeo."
#property link      "mailto:matiasDOTromeoATgmail.com"

int start()
{
    for( int count = OrdersTotal(); count > 0; count-- ) {
    OrderSelect(count, SELECT_BY_POS);
    if(OrderSymbol()==Symbol()){
      int type   = OrderType();

      bool result = false;
    
      switch(type)
      {
         //Close opened long positions
         case OP_BUY       : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
                             break;
      
         //Close opened short positions
         case OP_SELL      : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
                             break;

         //Close pending orders
         case OP_BUYLIMIT  :
         case OP_BUYSTOP   :
         case OP_SELLLIMIT :
         case OP_SELLSTOP  : result = OrderDelete( OrderTicket() );
      }
    
      if(result == false)
      {
         Alert("Order " , OrderTicket() , " failed to close. Error:" , GetLastError() );
         Sleep(3000);
      }  
   }
}  
  return(0);
}




