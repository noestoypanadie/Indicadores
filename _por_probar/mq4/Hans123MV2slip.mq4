//+------------------------------------------------------------------+
//|                                                       Hans123MV2 |
//|                                     Copyright © 2006, Milan Volf |
//|                                                 milan@mmtop.info |
//+------------------------------------------------------------------+

//---- input parameters
extern int       Start1=10;           //begin of the first session; time adjust by your broker time
extern int       Start2=14;           //begin of the second session
extern int       EOD=24;              //time for closing orders at end of day
extern int       FridayClosing=23;    //broker friday closing time
extern bool      FirstSessionOnly=0;  //if it equals 0, it trades the first range only
extern int       Length=4;            //length of range for determining high/low
extern int       Pips=5;              //trigger above/bellow range
extern int       StopLoss=50;
extern int       BreakEven=30;
extern int       TrailingStop=0;      //if equals 0, it uses breakeven
extern int       TakeProfit=80;
extern double    Lots=1;
extern int       Slippage=3;

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
   
   //Manage open orders
   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderComment()==Text){
         //close open positions at EOD
         if(Hour()==EOD || (DayOfWeek()>=5 && Hour()==FridayClosing-1 && Minute()>=50)){ 
            switch (OrderType()){
               case OP_BUY: OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,Red);
               break;
               case OP_SELL: OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Red);
               break;
               default: OrderDelete(OrderTicket());
               break;
            }
            Sleep(10000);
         }
         else {
            //move at BE if profit>BE
            if(TrailingStop==0){ 
               if(OrderType()==OP_BUY){
                  if(High[0]-OrderOpenPrice()>=BreakEven*Point && OrderStopLoss()<OrderOpenPrice()){
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);
                     Sleep(10000);
                  }   
               }   
               if(OrderType()==OP_SELL){
                  if(OrderOpenPrice()-Low[0]>=BreakEven*Point && OrderStopLoss()>OrderOpenPrice()){
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);
                     Sleep(10000);
                  }
               }
            }
            //use trailing stop
            else {                  
               if(OrderType()==OP_BUY){
                  if(High[0]-OrderStopLoss()>=(StopLoss+TrailingStop)*Point){
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss()+TrailingStop*Point,OrderTakeProfit(),0,Green);
                     Sleep(10000);
                  }   
               }   
               if(OrderType()==OP_SELL){
                  if(OrderStopLoss()-Low[0]>=(StopLoss+TrailingStop)*Point){
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss()-TrailingStop*Point,OrderTakeProfit(),0,Green);
                     Sleep(10000);
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
   
   //Check Orders
   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderComment()==Text && OrderMagicNumber()==MN){
         if(OrderType()==OP_BUYSTOP || OrderType()==OP_BUY) Bought++;
         if(OrderType()==OP_SELLSTOP || OrderType()==OP_SELL) Sold++;
      }
   }
   if(Bought==0){ //no buy order
      Ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,EntryLong,Slippage,SLLong,TPLong,Text,MN,0,Green);
      if(Ticket<0 && GetLastError()==130)
         Ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,SLLong,TPLong,Text,MN,0,Green);
         Sleep(10000); 
   }
   if(Sold==0){ //no sell order
      Ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,EntryShort,Slippage,SLShort,TPShort,Text,MN,0,Green);
      if(Ticket<0 && GetLastError()==130)
         Ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,SLShort,TPShort,Text,MN,0,Green);
         Sleep(10000); 
   }
}

