// ForexOFFTrend v1 Expert Test


// generic user input

extern double Lots=1;
extern int    TakeProfit=150;
extern int    StopLoss=20;
extern int    TrailingStop=15;
extern bool   TP=false;
extern bool   TS=true;
extern double Shave=5;
extern int    Slippage=2;
extern int    ProfitMade=7;


//+------------------------------------+
//| Custom init (usually empty on EAs) |
//|------------------------------------|
// Called ONCE when EA is added to chart
int init()
  {
   return(0);
  }


//+------------------------------------+
//| Custom deinit(usually empty on EAs)|
//+------------------------------------+
// Called ONCE when EA is removed from chart
int deinit()
  {
   return(0);
  }


//+------------------------------------+
//| EA main code                       |
//+------------------------------------+
// Called EACH TICK and possibly every Minute
// in the case that there have been no ticks

int start()
  {

   double p=Point();
   int      cnt=0;
  
   int      OrdersPerSymbol=0;


   double  Blimit=0,Slimit=0;
   double FM=AccountFreeMargin();
   double LRS=0;
   double slBUY=0, tpBUY=0, slSEL=0, tpSEL=0, sl=0, ma=0, cci=0, ma1=0, val1=0, val2=0;

   if (FM > 50000 && FM <= 100000) { 
      Lots = 2;
   }
   else if (FM > 100000 && FM <= 200000)
   {
      Lots=3;
   }
   else if (FM > 200000 && FM <= 400000)
   {
      Lots=4;
   }
   else if (FM > 400000 && FM <= 800000)
   {  
      Lots=5;
   }
   else if (FM > 800000 )
   {  
      Lots=6;
   }

   // Error checking
   
   if(FM<(100*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)              {Print("-----NO BARS "); return(0);}
   
   
   // Set number of lots according to how much is in account
   //if(FM > 10000) {Lots=2;}
   
    
   OrdersPerSymbol=0;
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() )
        {
         OrdersPerSymbol++;
        }
     }
  val1=iCustom(NULL, 0, "ForexOFFTrend v1", 1, 0);
  val2=iCustom(NULL, 0, "ForexOFFTrend v1", 2, 0);
  
  Blimit=Ask;
  Slimit=Bid;
  
 // Print("ma= ", DoubleToStr(ma,10), " bid= ", DoubleToStr(Bid,10), " ask= ", DoubleToStr(Ask,10));
 
  slBUY=Blimit-(StopLoss*p);
  tpBUY=Blimit+(TakeProfit*p);
      //Bid (sell, short)
  slSEL=Slimit+(StopLoss*p);
  tpSEL=Slimit-(TakeProfit*p);
  

  if (OrdersPerSymbol < 1 )
  {
 //     if (Ask > (valh) && Ask > ma) {
   if (val1>val2)
   {
        OrderSend(Symbol(),OP_BUY,Lots,Blimit,Slippage,slBUY,tpBUY,"ZJMQCIDFG",11123,0,White);
   }
   else if (val2>val1 )
   {
         OrderSend(Symbol(),OP_SELL,Lots,Slimit,Slippage,slSEL,tpSEL,"ZJMQCIDFG",11321,0,Red);
   }     
  } 
   
     // CLOSE order if profit target made
    
   for (cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() )
        {
        if(OrderType()==OP_BUY)
      {
          // did we make our desired BUY profit?
          if( TP )
          {
            if ((Bid-OrderOpenPrice()) > (ProfitMade*p)  )
            {
               OrderClose(OrderTicket(),Lots,Bid,0,White);
               return(0);
            }
          }
          else if ( TS )
          {
                if ( Bid-OrderOpenPrice()>(TrailingStop*p) ) 
                {    
                   slBUY=OrderStopLoss();        
                   sl = Bid-(TrailingStop*p);
                   if (slBUY < sl)
                   {
                     Print ("TSD trailstop Buy: ", Symbol(), " ", sl, ", ", Bid);
                     OrderModify (OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), 0); 
                   }
                } // if BUY
          }
      }
      else if(OrderType()==OP_SELL)
      {
           // did we make our desired SELL profit?
           if( TP )
           {
               if ((Ask-OrderOpenPrice()) > (ProfitMade*p))
               {
                  OrderClose(OrderTicket(),Lots,Ask,0,Red);
                  return(0);
               }
          }
          else if ( TS )
          {
             if ( OrderOpenPrice()-Ask > (TrailingStop*p) ) 
             { 
                  slSEL=OrderStopLoss();
                  sl = Ask+(TrailingStop*p);
                  if (slSEL > sl) {
                     Print ("TSD trailstop Sell: ", Symbol(), " ", sl, ", ", Ask);
                     OrderModify (OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), 0);
                  }
              }
          }
       } //if SELL      
     } // if(OrderSymbol)
   } // for

   return(0);
  } // start()

//+------------------------------------------------------------------+
bool TrailStop () {
   double StopLoss;
   string TradeSymbol=Symbol();

   if ( OrderType() == OP_BUY ) {
      if ( MarketInfo (TradeSymbol, MODE_BID) < OrderOpenPrice()+(TrailingStop*Point) )  return(false);
  //    StopLoss = iLow(TradeSymbol, PeriodTrailing, Lowest (TradeSymbol, PeriodTrailing, MODE_LOW, CandlesTrailing+1, 0)) - 1*SPoint;
  //    StopLoss = MathMin (MarketInfo (TradeSymbol, MODE_BID)-TrailingStop, StopLoss);
      StopLoss = MarketInfo (TradeSymbol, MODE_BID)-(TrailingStop*Point);
      Print ("TSD trailstop Buy: ", TradeSymbol, " ", StopLoss, ", ", MarketInfo(TradeSymbol, MODE_ASK));
      OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0);
      return(true);
   }
   
   if ( OrderType() == OP_SELL ) {
      if ( MarketInfo (TradeSymbol, MODE_ASK) > OrderOpenPrice()-(TrailingStop*Point) )  return(false);
//      StopLoss = iHigh(TradeSymbol, PeriodTrailing, Highest (TradeSymbol, PeriodTrailing, MODE_HIGH, CandlesTrailing+1, 0)) + 1*SPoint
//                 + Spread;
//      StopLoss = MathMax (MarketInfo (TradeSymbol, MODE_ASK)+TrailingStop, StopLoss);
      StopLoss = MarketInfo (TradeSymbol, MODE_ASK)+(TrailingStop*Point);
      Print ("TSD trailstop Sell: ", TradeSymbol, " ", StopLoss, ", ", MarketInfo(TradeSymbol, MODE_BID));
      OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0);
      return(true);
   }
   
   return(false);
}

int CloseOrders()
{

   int total, cnt;
   //########################################################################################
//##################     ORDER CLOSURE  ###################################################
// If Orders are in force then check for closure against Technicals LONG & SHORT
//CLOSE LONG Entries
  total=OrdersTotal();
  if(total>0)
   { 
   for(cnt=0;cnt<total;cnt++)
   {
    OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
    if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
     {                    
       OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // close LONG position
     }

//CLOSE SHORT ENTRIES: 
    OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES); 
    if(OrderType()==OP_SELL && OrderSymbol()==Symbol()) // check for symbol
     {
       OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close SHORT position
     }
    }  // for loop return
    }   // close 1st if 
}
int DeletePending()
{
   int total, cnt;
  total=OrdersTotal();
  if(total>0)
   { 
   for(cnt=0;cnt<total;cnt++)
   {
    OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
    if(OrderSymbol()==Symbol())
     {                    
       OrderDelete(OrderTicket());
     }
   }
   }
}

int TakeProfit() {
 
 
      if(OrderType()==OP_BUY)
      {
            // did we make our desired BUY profit?
            if(  Bid-OrderOpenPrice() > ProfitMade*Point()  )
              {
               OrderClose(OrderTicket(),Lots,Bid,0,White);
               return(0);
              }
           } // if BUY

         if(OrderType()==OP_SELL)
          {
            // did we make our desired SELL profit?
            if(  OrderOpenPrice()-Ask > (ProfitMade*Point())   )
              {
               OrderClose(OrderTicket(),Lots,Ask,0,Red);
               return(0);
              }
           } //if SELL
}


