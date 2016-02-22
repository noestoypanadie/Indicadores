//+------------------------------------------------------------------+
//|                                                        Hans123MV |
//|                                     Copyright © 2005, Milan Volf |
//+------------------------------------------------------------------+

//---- input parameters
extern int       Start1=10;
extern int       Start2=14;
extern int       FirstSessionOnly=0;
extern int       Length=4;
extern int       EOD=24;
extern int       Pips=5;
extern int       StopLoss=50;
extern int       BreakEven=30;
extern int       TrailingStopStep=0;
extern int       TakeProfit=80;
extern double    Lots=1.0;

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   //---- 
   int i,Ticket,LastOrderTime,StartTime,StartTime1,StartTime2,EODTime,MN;
   
   //Settings
   if (!IsTesting()){
      if (Symbol()=="EURUSD"){
         Start1=10;
         Start2=14;
         Length=4;
         EOD=24;
         Pips=5;
         StopLoss=50;
         BreakEven=30;
         TakeProfit=80;
      }   
      else if (Symbol()=="GBPUSD"){
         Start1=10;
         Start2=14;
         Length=4;
         EOD=24;
         Pips=5;
         StopLoss=70;
         BreakEven=40;
         TakeProfit=120;
      }
      else {
         Start1=10;
         Start2=14;
         Length=4;
         EOD=24;
         Pips=5;
         StopLoss=50;
         BreakEven=30;
         TakeProfit=80;
      }
   }

   //Count time
   if(CurTime()>=StrToTime(Start1+":00")-60){
      StartTime1=StrToTime(Start1+":00");
      StartTime2=StrToTime(Start2+":00");
      if(DayOfWeek()==5)   EODTime=MathMin(StrToTime("22:55"),StrToTime(EOD+":00"));
      else if (EOD==24)    EODTime=StrToTime("23:59");
      else                 EODTime=StrToTime(EOD+":00")-60;
   }
   
   //Set orders
   if(CurTime()>=StartTime1 && CurTime()<StartTime1+300){
      MN=1;
      StartTime=StartTime1;
      SetOrders(MN,StartTime);
   }
   if(CurTime()>=StartTime2 && CurTime()<StartTime2+300 && FirstSessionOnly==0){
      MN=2;
      StartTime=StartTime2;
      SetOrders(MN,StartTime);
   }
   
   //Manage of open orders
   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
      if(CurTime()>=EODTime){     //close open positions at EOD
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)      OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)     OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)  OrderDelete(OrderTicket());
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP) OrderDelete(OrderTicket());
         GlobalVariableSet("LastOrderTime",CurTime());
      }   
      else {
         if(TrailingStopStep==0){    //move at BE if profit>BE
            if(OrderSymbol()==Symbol() && OrderType()==OP_BUY){
               if(High[0]-OrderOpenPrice()>=BreakEven*Point && OrderStopLoss()!=OrderOpenPrice()){
                  OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);
                  GlobalVariableSet("LastOrderTime",CurTime());
               }   
            }   
            if(OrderSymbol()==Symbol() && OrderType()==OP_SELL){
               if(OrderOpenPrice()-Low[0]>=BreakEven*Point && OrderStopLoss()!=OrderOpenPrice()){
                  OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);
                  GlobalVariableSet("LastOrderTime",CurTime());
               }
            }
         }
         else {                  //use trailing stop
            if(OrderSymbol()==Symbol() && OrderType()==OP_BUY){
               if(High[0]-OrderStopLoss()>=(StopLoss+TrailingStopStep)*Point){
                  OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss()+TrailingStopStep*Point,OrderTakeProfit(),0,Green);
                  GlobalVariableSet("LastOrderTime",CurTime());
               }   
            }   
            if(OrderSymbol()==Symbol() && OrderType()==OP_SELL){
               if(OrderStopLoss()-Low[0]>=(StopLoss+TrailingStopStep)*Point){
                  OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss()-TrailingStopStep*Point,OrderTakeProfit(),0,Green);
                  GlobalVariableSet("LastOrderTime",CurTime());
               }
            }
         }
      }
   }
   
   //Reset global variables at EOD
   if(CurTime()>=EODTime) GlobalVariablesDeleteAll();
   
   return(0);
  }
//+------------------------------------------------------------------+

int SetOrders(int MN,int StartTime){
   int i,Ticket,LastOrderTime,Bought=0,Sold=0,ShiftToStart,ShiftToBeginOfRange;
   double EntryLong,EntryShort,SLLong,SLShort,TPLong,TPShort;
   
   //Determine range
   ShiftToStart=iBarShift(NULL,0,StartTime)+1;
   ShiftToBeginOfRange=iBarShift(NULL,0,StartTime-Length*3600);
   EntryLong   =High[Highest(NULL,0,MODE_HIGH,ShiftToBeginOfRange,ShiftToStart)]+(Pips/*+MarketInfo(Symbol(),MODE_SPREAD)*/)*Point;
   EntryShort  =Low [Lowest (NULL,0,MODE_LOW, ShiftToBeginOfRange,ShiftToStart)]-Pips*Point;
   SLLong      =MathMax(EntryLong-StopLoss*Point,EntryShort);
   SLShort     =MathMin(EntryShort+StopLoss*Point,EntryLong);
   TPLong      =EntryLong+TakeProfit*Point;
   TPShort     =EntryShort-TakeProfit*Point;
   
   //Check Orders
   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && (OrderType()==OP_BUYSTOP || OrderType()==OP_BUY) && OrderMagicNumber()==MN) Bought++;
      if(Bought>1){ //more than 1 buy order
         if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)      OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)  OrderDelete(OrderTicket());
      }
      if(OrderSymbol()==Symbol() && (OrderType()==OP_SELLSTOP || OrderType()==OP_SELL) && OrderMagicNumber()==MN) Sold++;
      if(Sold>1){ //more than 1 sell order
         if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)     OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP) OrderDelete(OrderTicket());
      }
   }
   if(Bought==0){ //no buy order
      if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
      Ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,EntryLong,3,SLLong,TPLong,NULL,MN,0,Green);
      if(Ticket<0 && GetLastError()==130)
         Ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,SLLong,TPLong,NULL,MN,0,Green);
      GlobalVariableSet("LastOrderTime",OrderOpenTime()); 
   }
   if(Sold==0){ //no sell order
      if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
      Ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,EntryShort,3,SLShort,TPShort,NULL,MN,0,Green);
      if(Ticket<0 && GetLastError()==130)
         Ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,SLShort,TPShort,NULL,MN,0,Green);
      GlobalVariableSet("LastOrderTime",OrderOpenTime()); 
   }
}

