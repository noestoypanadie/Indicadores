//+------------------------------------------------------------------+
//|                                                   Modify All.mq4 |
//|                              transport_david , David W Honeywell |
//|                                        transport.david@gmail.com |
//+------------------------------------------------------------------+
#property copyright "transport_david , David W Honeywell"
#property link      "transport.david@gmail.com"

extern int stploss = 100;
extern int tkprft = 100;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
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
//----
 int i;
  for (i = OrdersTotal()-1; i >=0 ; i--)
  {
      if ((OrderStopLoss()==0 || OrderTakeProfit() == 0)&&(OrderSymbol()==OrderSymbol()))
      {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if ((OrderType() == OP_BUY)&&(OrderTakeProfit() == 0))
      {
         OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice()-(stploss*Point), OrderOpenPrice()+(tkprft*Point),0, White);
      }
      if ((OrderType() == OP_SELL)&&(OrderTakeProfit() == 0))
      {
         OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice()+(stploss*Point), OrderOpenPrice()-(tkprft*Point),0, White);
      }
      }
  }

  
//----
   return(0);
  }
//+------------------------------------------------------------------+