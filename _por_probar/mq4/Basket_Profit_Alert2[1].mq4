//+------------------------------------------------------------------+
//|                                         Basket_Profit_Alert.mq4  |
//|                                                    Robert Hill . |
//|                                                    &  Kirk Sloan |
//|                                                   ksfx@kc.rr.com |
//|                                       Custom Metatrader Systems. |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2006, Robert Hill, Kirk Sloan, Ross Todd & whoever else works on this :-)"
//---- input parameters
extern bool      Run=true;
double Balance;
double Equity;
string Message;

datetime Bartime;
int Bartick=0;
bool Tradeallowed=true;
string Orders;

extern int ProfitTarget1 = 300; // Profit target in dollars
extern int ProfitTarget2 = 100; // Profit target in dollars for alert

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+ 
int deinit()
  {
  
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
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
  
  if (TotalProfit >= ProfitTarget1) ||
  if (TotalProfit >= ProfitTarget2)
  
//----
if(Bartime!=Time[0]){
   Bartime=Time[0]; 
   Tradeallowed=true;
   }  


   if(Tradeallowed && Run == true) {
   Tradeallowed = false;
   Orders=NULL;
   Message = NULL;
   OrderInfo();
   Message = StringConcatenate (" Current Balance is ", AccountBalance(), " Current Equity is ", AccountEquity(), Orders) ;
   SendMail("Account Update", Message);
   PlaySound
   }
   
   
//----
   return(0);
  }
//+------------------------------------------------------------------+

  }
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