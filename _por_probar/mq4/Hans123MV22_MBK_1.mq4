//+------------------------------------------------------------------+
//|                                                 Hans123MV22_MBK1 |
//|                                     Copyright © 2006, Milan Volf |
//|                                                                  |
//+------------------------------------------------------------------+
//|
//| Milan Volf's implementation of hans123 system.
//|
//| Modifications & Notes, 2006-06-06 by by Matt Kennel,
//|
//|     * Uses OrderReliable.mqh library and corresponding function
//|       calls have been changed here, and all manual Sleep() statements
//|       have been commented out, in order to test new order handling
//|       code
//| 
//|     * You must separately download the appropriate OrderReliable*.mqh
//|       include file and put in the same 'experts' directory as this one.
//|       Make sure the #include line below points to the same file name.
//|
//|     * init() statement has been added to automatically put SilverRex's 
//|       parameters for EUR/USD and GPB/USD.
//| 
//|     * Put on EUR/USD and GBP/USD, timeframe is not critical, but try M5
//|
//|     * You MUST check the server time zone.  Currently below it is set for CET.
//|
//+------------------------------------------------------------------+

#property copyright "Copyright © 2006, Milan Volf"

//---- input parameters
//
// THE HOURS BELOW ASSUME THAT THE TIME ZONE OF THE SERVER IS CET (Central European Time)
// WHICH IS ONE HOUR LATER THAN LONDON TIME.  I.e. during daylight savings (N. Hemisphere summer)
// CET = GMT+2, and during winter, CET=GMT+1. 
//
//  CET default parameters:
// extern int       Start1=10;           //begin of the first session; time adjust by your broker time
// extern int       Start2=14;           //begin of the second session
// extern int       EOD=23;              //time for closing orders at end of day Modified mbk.
// extern int       FridayClosing=21;    //broker friday closing time            Modified MBK


// These must be adjusted for time zone of server.
// I.e. if server is GMT, then subtract 2 during daylight savings time months (defined in U.K.)
// and 1 during winter months.

extern int       Start1=10;           //begin of the first session; time adjust by your broker time
extern int       Start2=14;           //begin of the second session
extern int       EOD=23;              //time for closing orders at end of day Modified mbk.
extern int       FridayClosing=21;    //broker friday closing time            Modified MBK


extern bool      FirstSessionOnly=0;  //if it equals 1, it trades the first range only (for testing)
extern int       Length=4;            //length of range for determining high/low
extern int       Pips=5;              //trigger above/bellow range
extern int       StopLoss=50;
extern int       BreakEven=30;
extern int       TrailingStop=0;      //if equals 0, it uses breakeven
extern int       TakeProfit=80;
extern double    Lots=1;

#include "OrderReliable_V2_0_0.mqh"

int init() {
   // Added by MBK to put in silverrex's parameters).
   if (Symbol() == "GBPUSD") {
      Pips = 10;
      BreakEven = 35;
      TakeProfit = 115;
   } else if (Symbol() == "EURUSD") {
      Pips = 10;
      BreakEven = 25;
      TakeProfit = 75;
   }
   return(0); 
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+



int start()
  {
   //---- 
   int i,Ticket,MN;
   
   //Normalize times
   if(EOD==24) EOD=0;
   if(FridayClosing==0) FridayClosing=24;
   
   //Setup comment
   string Text="Hans123"+Symbol();

   //Setup orders
   if(Hour()==Start1 && Minute()<10){
      MN=1;
      SetOrders(Text,MN);
   }
   if(Hour()==Start2 && Minute()<10 && FirstSessionOnly==0){
      MN=2;
      SetOrders(Text,MN);
   }
   
   //Manage opened orders
   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderComment()==Text){
         //close open positions at EOD
         if(Hour()==EOD || (DayOfWeek()>=5 && Hour()==FridayClosing-1 && Minute()>=50)){ 
            switch (OrderType()){
               case OP_BUY: OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
               break;
               case OP_SELL: OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
               break;
               default: OrderDelete(OrderTicket());
               break;
            }
          //  Sleep(10000);
         }
         else {
            //move at BE if profit>BE
            if(TrailingStop==0){ 
               if(OrderType()==OP_BUY){
                  if(High[0]-OrderOpenPrice()>=BreakEven*Point && OrderStopLoss()<OrderOpenPrice()){
                     OrderModifyReliable(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);
                     // Sleep(10000);
                  }   
               }   
               if(OrderType()==OP_SELL){
                  if(OrderOpenPrice()-Low[0]>=BreakEven*Point && OrderStopLoss()>OrderOpenPrice()){
                     OrderModifyReliable(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);
                     // Sleep(10000);
                  }
               }
            }
            //use trailing stop
            else {                  
               if(OrderType()==OP_BUY){
                  if(High[0]-OrderStopLoss()>TrailingStop*Point){
                     OrderModifyReliable(OrderTicket(),OrderOpenPrice(),High[0]-TrailingStop*Point,OrderTakeProfit(),0,Green);
                     //Sleep(10000);
                  }   
               }   
               if(OrderType()==OP_SELL){
                  if(OrderStopLoss()-Low[0]>TrailingStop*Point){
                     OrderModifyReliable(OrderTicket(),OrderOpenPrice(),Low[0]+TrailingStop*Point,OrderTakeProfit(),0,Green);
                     //Sleep(10000);
                  }
               }
            }
         }
      }
   }
   
   return(0);
   }
//+------------------------------------------------------------------+

void SetOrders(string Text,int MN){
   int i,Ticket,Bought,Sold;
   double EntryLong,EntryShort,SLLong,SLShort,TPLong,TPShort;

   //Determine range
   EntryLong   =iHigh(NULL,60,Highest(NULL,60,MODE_HIGH,Length,1))+(Pips/*+MarketInfo(Symbol(),MODE_SPREAD)*/)*Point;
   EntryShort  =iLow (NULL,60,Lowest (NULL,60,MODE_LOW, Length,1))-Pips*Point;
   SLLong      =MathMax(EntryLong-StopLoss*Point,EntryShort);
   SLShort     =MathMin(EntryShort+StopLoss*Point,EntryLong);
   TPLong      =EntryLong+TakeProfit*Point;
   TPShort     =EntryShort-TakeProfit*Point;
   
   //Send orders
   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderComment()==Text && OrderMagicNumber()==MN){
         if(OrderType()==OP_BUYSTOP || OrderType()==OP_BUY) Bought++;
         if(OrderType()==OP_SELLSTOP || OrderType()==OP_SELL) Sold++;
      }
   }
   if(Bought==0){ //no buy order
//      Ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,EntryLong,3,SLLong,TPLong,Text,MN,0,Blue);
      Ticket=OrderSendReliable(Symbol(),OP_BUYSTOP,Lots,EntryLong,3,SLLong,TPLong,Text,MN,0,Blue);
      
      if(Ticket<0 && High[0]>=EntryLong)
         Ticket=OrderSendReliable(Symbol(),OP_BUY,Lots,Ask,3,SLLong,TPLong,Text,MN,0,Blue);
      //   Sleep(10000); 
   }
   if(Sold==0){ //no sell order
      Ticket=OrderSendReliable(Symbol(),OP_SELLSTOP,Lots,EntryShort,3,SLShort,TPShort,Text,MN,0,Magenta);
      if(Ticket<0 && Low[0]<=EntryShort)
         Ticket=OrderSendReliable(Symbol(),OP_SELL,Lots,Bid,3,SLShort,TPShort,Text,MN,0,Magenta);
        // Sleep(10000); 
   }
   //Check orders
   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderComment()==Text && OrderMagicNumber()==MN){
         if(OrderType()==OP_BUYSTOP && (MathAbs(OrderOpenPrice()-EntryLong)>Point 
         || MathAbs(OrderStopLoss()-SLLong)>Point || MathAbs(OrderTakeProfit()-TPLong)>Point))
            OrderModifyReliable(OrderTicket(),EntryLong,SLLong,TPLong,0,Blue);
         if(OrderType()==OP_SELLSTOP && (MathAbs(OrderOpenPrice()-EntryShort)>Point 
         || MathAbs(OrderStopLoss()-SLShort)>Point || MathAbs(OrderTakeProfit()-TPShort)>Point))
            OrderModifyReliable(OrderTicket(),EntryShort,SLShort,TPShort,0,Magenta);
      }
   }
}




