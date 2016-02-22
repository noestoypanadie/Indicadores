//+------------------------------------------------------------------+
//|                                         Close_Basket_Profit.mq4  |
//|                                  Copyright © 2006, Robert Hill . |
//|                                       Custom Metatrader Systems. |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2006, Robert Hill."

extern int ProfitTarget = 10; // Profit target in dollars

int start()
{
  double TotalProfit = 0.0;
  
  int total, i;
  bool result = false;

// Calculate total profit on all trades

  total = OrdersTotal();
  for(i=total-1;i>=0;i--)
  {
    OrderSelect(i, SELECT_BY_POS);
    TotalProfit += OrderProfit();
  }
  
  if (TotalProfit >= ProfitTarget)
  {
    
  // First close losing trades
  
    total = OrdersTotal();
  
    for(i=total-1;i>=0;i--)
    {
      OrderSelect(i, SELECT_BY_POS);

      result = false;
    
      switch(OrderType())
      {
      //Close opened long positions
        case OP_BUY       : if ( OrderProfit() < 0) result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
                            break;
      
      //Close opened short positions
        case OP_SELL      : if ( OrderProfit() < 0) result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
                          
      }
    
      if(result == false)
      {
        Alert("Order " , OrderTicket() , " failed to close. Error:" , GetLastError() );
        Sleep(3000);
      }  
    }
  
// Now close remaining trades

    total = OrdersTotal();

    for(i=total-1;i>=0;i--)
    {
      OrderSelect(i, SELECT_BY_POS);

      result = false;
    
      switch(OrderType())
      {
      //Close opened long positions
        case OP_BUY       : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
                            break;
      
      //Close opened short positions
        case OP_SELL      : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
                            
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