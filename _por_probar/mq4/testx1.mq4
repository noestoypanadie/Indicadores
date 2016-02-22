//+------------------------------------------------------------------+
//|                                                  MACD Sample.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+

extern double TakeProfit = 120;
extern double Lots = 0.1;
extern double TrailingStop = 30;
extern double MACDOpenLevel=3;
extern double MACDCloseLevel=2;
extern double MATrendPeriod=26;
double Points;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init ()
  {
   Points = MarketInfo (Symbol(), MODE_POINT);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
   double MacdCurrent=0, MacdPrevious=0, SignalCurrent=0;
   double SignalPrevious=0, MaCurrent=0, MaPrevious=0;
   int cnt=0, total;

   if(Bars<200)
     {
      Print("bars less than 200");
      return(0);  
     }

   if(TakeProfit<10)
     {
      Print("TakeProfit less than 10");
      return(0);
     }

   if(AccountFreeMargin()<(1000*Lots))
     {
      Print("We do not have money");
      return(0);  
     }


// to simplify the coding and speed up access
// data are put into internal variables
   MacdCurrent=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
   MacdPrevious=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
   SignalCurrent=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0);
   SignalPrevious=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
   MaCurrent=iMA(NULL,0,MATrendPeriod,MODE_EMA,0,PRICE_CLOSE,0);
   MaPrevious=iMA(NULL,0,MATrendPeriod,MODE_EMA,0,PRICE_CLOSE,1);
// check for opened orders()
   if(OrdersTotal()<1) 
     {

      // If((CurTime-LastTradeTime)<300) { Exit }
      // check for long position (BUY) possibility 
      if(MacdCurrent<0 && MacdCurrent>SignalCurrent && MacdPrevious<SignalPrevious &&
         MathAbs(MacdCurrent)>(MACDOpenLevel*Points) && MaCurrent>MaPrevious)
        {
         OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,Ask+TakeProfit*Points,
                   "macd sample",16384,0,Red);
         return(0);
        }
      // check for short position (SELL) possibility
      if(MacdCurrent>0 && MacdCurrent<SignalCurrent && MacdPrevious>SignalPrevious &&
         MacdCurrent>(MACDOpenLevel*Points) && MaCurrent<MaPrevious)
        {
         OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,Bid-TakeProfit*Points,
                   "macd sample",16384,0,Red); 
         return(0); 
        };
      return(0);
     };
   // it is important to enter the market correctly, 
   // but it is more important to exit it correctly...
   total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL && // check for opened position
         OrderSymbol()==Symbol())    
        {
         if(OrderType()==OP_BUY)   // long position is opened
           {
            if(MacdCurrent>0 && MacdCurrent<SignalCurrent && MacdPrevious>SignalPrevious &&
               MacdCurrent>(MACDCloseLevel*Points))
                {
                 OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); 
                 return(0); // exit
                };
            // check for trailing stop
            if(TrailingStop>0)  
              {                 
               if(Bid-OrderOpenPrice()>Points*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Points*TrailingStop)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Points*TrailingStop,
                                 OrderTakeProfit(),0,Red);
                     return(0);
                    }
                 }
              }
           }
         else // go to short position
           {
            if(MacdCurrent<0 && MacdCurrent>SignalCurrent &&
               MacdPrevious<SignalPrevious && MathAbs(MacdCurrent)>(MACDCloseLevel*Points))
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close position
               return(0); // exit
              }
            // check for trailing stop
            if(TrailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Points*TrailingStop))
                 {
                  if(OrderStopLoss()==0.0 || 
                     OrderStopLoss()>(Ask+Points*TrailingStop))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Points*TrailingStop,
                                 OrderTakeProfit(),0,Red);
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