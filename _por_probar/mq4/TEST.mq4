#define MAGICMA  2

extern double Lots               = 0.1;
extern double TakeProfit = 8;
extern double TrailingStop = 6;
extern double Stoploss = 37;
extern double risk = 0.1;


//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//----
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//---- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }

  
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   int    res;
   double sema,lema,sema1,lema1;
   sema=iMA(Symbol(),0,2,0,MODE_EMA,PRICE_CLOSE,0);
   lema=iMA(Symbol(),0,40,0,MODE_EMA,PRICE_CLOSE,0);
   sema1=iMA(Symbol(),0,2,0,MODE_EMA,PRICE_CLOSE,1);
   lema1=iMA(Symbol(),0,40,0,MODE_EMA,PRICE_CLOSE,1);
//---- sell conditions
   if (sema>lema && sema1<lema1 && sema>sema1 && lema>lema1)  
     {
      res=OrderSend(Symbol(),OP_SELL,(MathCeil(AccountBalance() * risk / 12000)/10),Bid,3,Bid+Stoploss*Point,Bid-TakeProfit*Point,"",MAGICMA,0,Red);
      return;
     }

//---- buy conditions
   if (sema<lema && sema1>lema1 && sema<sema1 && lema<lema1) 
   
     {
      res=OrderSend(Symbol(),OP_BUY,(MathCeil(AccountBalance() * risk / 12000)/10),Ask,3,Ask-Stoploss*Point,Ask+TakeProfit*Point,"",MAGICMA,0,Blue);
      return;
     }  
//----
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
//----
   for(int i=0;i<OrdersTotal();i++)
     {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL &&   // check for opened position 
         OrderSymbol()==Symbol())  // check for symbol
        {
         if(OrderType()==OP_BUY)   // long position is opened
           {
            // check for trailing stop
            if(TrailingStop>0)  
              {                 
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
		                RefreshRates();
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                     //return(0);
                    }
                 }
              }
           }
         else // go to short position
           {
            if(TrailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
		                RefreshRates();
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
                     //return(0);
                    }
                 }
              }
           }
        }
     }
   return(0);
  }
// the end.
//----

//+------------------------------------------------------------------+
//| Start function                                                   |
//+------------------------------------------------------------------+
void start()
  {
//---- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false) return;
//---- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
//----
  }
//+--------------------------------------------------------------




