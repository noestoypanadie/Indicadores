//+------------------------------------------------------------------+
//|                                               Heiken200.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#define MAGICMA  20050000

extern double Lots               = 0.1;
extern double MaximumRisk        = 0.5;
extern double TakeProfit = 2000;
extern double TrailingStop = 0;
extern double Stoploss = 60;
extern double risk = 10;
double lotMM;
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
// =================================================================================
// PYRAMIDING - LINEAR
// Money Management risk exposure compounding
// =================================================================================
   
  
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   int    res;
//---- sell conditions
   if (iCustom(NULL,0,"Heiken Ashi",2,0) > iCustom(NULL,0,"Heiken Ashi",3,0) && iCustom(NULL,0,"Heiken Ashi",1,0) < 
       iCustom(NULL,0,"Heiken Ashi",0,0) && Close[1] < iMA(NULL,0,200,0,MODE_EMA,PRICE_CLOSE,0) && iAO(NULL,0,0) < 0)
     {
      res=OrderSend(Symbol(),OP_SELL,MathCeil(AccountBalance() * risk / 100000),Bid,1,Bid+Stoploss*Point,Bid-TakeProfit*Point,"",MAGICMA,0,Red);
      return;
     }
//---- buy conditions
   if (iCustom(NULL,0,"Heiken Ashi",2,0) < iCustom(NULL,0,"Heiken Ashi",3,0) && iCustom(NULL,0,"Heiken Ashi",1,0) > 
       iCustom(NULL,0,"Heiken Ashi",0,0) && Close[1] > iMA(NULL,0,200,0,MODE_EMA,PRICE_CLOSE,0) && iAO(NULL,0,0) > 0)
     {
      res=OrderSend(Symbol(),OP_BUY,MathCeil(AccountBalance() * risk / 100000),Ask,1,Ask-Stoploss*Point,Ask+TakeProfit*Point,"",MAGICMA,0,Blue);
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
            // should it be closed?
            if(iCustom(NULL,0,"Heiken Ashi",2,0) > iCustom(NULL,0,"Heiken Ashi",3,0) && iCustom(NULL,0,"Heiken Ashi",1,0) < 
               iCustom(NULL,0,"Heiken Ashi",0,0))
                {
                 OrderClose(OrderTicket(),OrderLots(),Bid,1,Violet); // close position
                 return(0); // exit
                }
            // check for trailing stop
            if(TrailingStop>0)  
              {                 
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                     return(0);
                    }
                 }
              }
           }
         else // go to short position
           {
            // should it be closed?
            if (iCustom(NULL,0,"Heiken Ashi",2,0) < iCustom(NULL,0,"Heiken Ashi",3,0) && iCustom(NULL,0,"Heiken Ashi",1,0) > 
                iCustom(NULL,0,"Heiken Ashi",0,0))
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,1,Violet); // close position
               return(0); // exit
              }
            // check for trailing stop
            if(TrailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
                     return(0);
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