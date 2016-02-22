//+------------------------------------------------------------------+
//|                                                Cancel Orders.mq4 |
//|                 Copyright © 2006, tageiger aka fxid10t@yahoo.com |
//|                                        http://www.metatrader.org |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, tageiger aka fxid10t@yahoo.com"
#property link      "http://www.metatrader.org"
#property show_inputs
extern string Symbol.to.delete="enter pair Symbol, e.g., EURUSDm";

int init()  {return(0);}
int deinit()   {return(0);}
int start() {
   for(int i=0;i<OrdersTotal(); i++)   {
   OrderSelect(i,SELECT_BY_POS);
   if(Symbol()==Symbol.to.delete && OrderType()>1) {
      OrderDelete(OrderTicket());   }  }

return(0);
  }
//+------------------------------------------------------------------+