//+------------------------------------------------------------------+
//|                                              CloseOrDeleteAll.mq4|
//|                                                Paul Hampton-Smith| 
//+------------------------------------------------------------------+

// Cleans up all orders regardless of Symbol() or Magic

void init()
{
	// immediate execution
   while(OrdersTotal()>0)
   {
      OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
      switch (OrderType())
      {
      case OP_BUY: OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(),MODE_BID), 5, Purple); break;
      case OP_SELL: OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(),MODE_ASK), 5, Purple); break;
      case OP_BUYSTOP:
      case OP_SELLSTOP: 
      case OP_BUYLIMIT:
      case OP_SELLLIMIT: OrderDelete(OrderTicket());
      }
   }
}

void start()
{
	// nothing more to do
}