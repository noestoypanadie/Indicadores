//+------------------------------------------------------------------+
//|                                      Hans123 testing version.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+

#property copyright "If AdjustDSTwhenBacktesting is true, expert assumes when backtesting that times are non-DST and adjusts by -1 for Apr-Oct."

//---- input parameters
extern double    Lots=2;
extern int       blOneTradeOnly=1;
extern bool      AdjustDSTwhenBacktesting?=true;
extern bool      Skip1stFriOfMonthIfBacktesting?=true;
extern int       ClosedBarLowTrailAfterBE=0;
extern int       Multiplier15mATR3TrailAfterBE=0;
extern int       MultiplierH1ATR4TrailAfterBE=4;
extern int       OrderHoursExpiry=0;
//extern int       blTakePartialProfitAtBEtime=0; //Disabled since the code is only backtest-safe and it doesn't help anyway
extern bool      TakeRemainingSettingsFromCode?=false;
extern int       TradeOpenTime=10;
extern int       LookBackHrs=2;
extern int       EOD=21;
extern int       blCloseAtEOD=0;
extern int       PipsAddedToRange=0;
extern int       StopLossMax=60;
extern int       BreakEven=20;
extern int       TakeProfit=999;
extern int       RangeMax=60;
extern int       blIfRangeMaxStillOpenFarTrade=1;

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   //---- 
   int i,Ticket,LastOrderTime,StartTime,EODTime,CloseUnhitOrdersTime,Bought=0,Sold=0,PeriodToReference=0,ErrTemp=0;
   int PendingTicket,OpenTicket,Last15mATRTrailBarTime,LastH1ATRTrailBarTime;

   double EntryLong,EntryShort,SLLong,SLShort,TPLong,TPShort,CurrH1BarTime,LookbackBars,ATRtrail;
   
   
   if ( ! IsTesting() ) Comment(" Tick no. ", iVolume(NULL,0,0));
   
   //Settings
   if (TakeRemainingSettingsFromCode?){
      if (Symbol()=="EURUSD"){
         TradeOpenTime=10;
         LookBackHrs=4;
         EOD=24;
         blCloseAtEOD=1;
         PipsAddedToRange=5;
         StopLossMax=50;
         BreakEven=30;
         TakeProfit=80;
         RangeMax=70;
         blIfRangeMaxStillOpenFarTrade=0;
      }   
      else if (Symbol()=="GBPUSD"){
         TradeOpenTime=10;
         LookBackHrs=4;
         EOD=24;
         blCloseAtEOD=1;
         PipsAddedToRange=5;
         StopLossMax=70;
         BreakEven=40;
         TakeProfit=120;
         RangeMax=0;
         blIfRangeMaxStillOpenFarTrade=0;
      }
      else {
         TradeOpenTime=10;
         LookBackHrs=4;
         EOD=24;
         blCloseAtEOD=1;
         PipsAddedToRange=5;
         StopLossMax=50;
         BreakEven=30;
         TakeProfit=80;
         RangeMax=999;
         blIfRangeMaxStillOpenFarTrade=0;

      }
   }
   
   /*
   if (IsTesting()) PeriodToReference=0; 
      else PeriodToReference=PERIOD_M1;
   */  
   
   PeriodToReference=0; //I.e. whatever timeframe the chart/backtest is in
      
   CurrH1BarTime=iTime(NULL,PERIOD_H1,0);
   
   //Count time
   //if(TimeHour(CurrH1BarTime)>=TradeOpenTime-1)
   if(IsTesting() && AdjustDSTwhenBacktesting? && TimeMonth(CurrH1BarTime)>=4 && TimeMonth(CurrH1BarTime)<=10)
      {
      StartTime= StrToTime(TradeOpenTime-1+":00");
      CloseUnhitOrdersTime= StrToTime(TradeOpenTime+OrderHoursExpiry-1+":00");
      if(DayOfWeek()==5)   EODTime  = MathMin(StrToTime("22:00"),StrToTime(EOD-1+":00"));
         else              EODTime  = StrToTime(EOD-1+":00");
      }
      else
      {
      StartTime= StrToTime(TradeOpenTime+":00");
      CloseUnhitOrdersTime= StrToTime(TradeOpenTime+OrderHoursExpiry+":00");
      if(DayOfWeek()==5)   EODTime  = MathMin(StrToTime("22:00"),StrToTime(EOD+":00"));
         else              EODTime  = StrToTime(EOD+":00");
      }

   
   //Set orders
   if(CurrH1BarTime>= StartTime && CurrH1BarTime<StartTime+60*60){
   //if(CurrH1BarTime>= StartTime && CurTime()<StartTime+5*60){
      //Determine range

      LookbackBars=0;
      
      for (i=0;i<Bars;i++){
         if (iTime(NULL,PeriodToReference,i) < CurrH1BarTime-(LookBackHrs*60*60)) {
            LookbackBars=i+1;
            break;
            }
      
         }
      
      if (LookbackBars==0) return(0); //exit if not enough bars on current timeframe

      EntryLong   =iHigh(NULL,PeriodToReference,Highest(NULL,PeriodToReference,MODE_HIGH,LookbackBars,1))+(PipsAddedToRange+MarketInfo(Symbol(),MODE_SPREAD))*Point;
      EntryShort  =iLow (NULL,PeriodToReference,Lowest (NULL,PeriodToReference,MODE_LOW, LookbackBars,1))-PipsAddedToRange*Point;
      
      SLLong      =MathMax(EntryLong-StopLossMax*Point,EntryShort);
      SLShort     =MathMin(EntryShort+StopLossMax*Point,EntryLong);
      TPLong      =EntryLong+TakeProfit*Point;
      TPShort     =EntryShort-TakeProfit*Point;
      
      //Check Orders
      for (i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && (OrderType()==OP_BUYSTOP || OrderType()==OP_BUY)) Bought++;
         if(Bought>1){ //more than 1 buy order
            //if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
            if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)      OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
            if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)  OrderDelete(OrderTicket());
         }

         if(OrderSymbol()==Symbol() && (OrderType()==OP_SELLSTOP || OrderType()==OP_SELL)) Sold++;
         if(Sold>1){ //more than 1 sell order
            //if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
            if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)     OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
            if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP) OrderDelete(OrderTicket());
         }
      }
      
      if (RangeMax != 0 && EntryLong-EntryShort>=RangeMax*Point) { //So we can filter out large ranges
         if (blIfRangeMaxStillOpenFarTrade==1) {
            //Ensures that only the trigger furthest from the current price will be set. If price moves back to the other side of the range within the hour, the second trade will also be set.
            if (iClose(NULL,PeriodToReference,1)-EntryShort < EntryLong-iClose(NULL,PeriodToReference,1)) {
                Sold=1;
                //Print("HERE");
            }
            else
            {
            Bought=1;
            }
         }
         else
         {
         // Ensures that no trades will be opened
         Bought=1;
         Sold=1;
         }
      }
      
      if (! (IsTesting() && Skip1stFriOfMonthIfBacktesting? &&  DayOfWeek()==5 && Day()<8)) {
         if(Bought==0 && EntryLong>Ask+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point){ //no buy order and price not right at the top of the range
            //if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
            ErrTemp=GetLastError(); //In order to clear any previous error
            Ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,EntryLong,3,SLLong,TPLong,NULL,0,0,Green);
            /*
            ErrTemp=GetLastError();
            if(Ticket<0 && ErrTemp==130)
               Print("INVALID STOPS???   EntryLong:",EntryLong, "    SLLong:",SLLong,  "     TPLong:",TPLong); 
               Ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,SLLong,TPLong,NULL,0,0,Green);
            */   
         }
         if(Sold==0 && EntryShort<Bid-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point){ //no sell order and price not right at the bottom of the range
            //if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
            ErrTemp=GetLastError(); //In order to clear any previous error
            Ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,EntryShort,3,SLShort,TPShort,NULL,0,0,Green);
            /*
            ErrTemp=GetLastError();
            if(Ticket<0 && ErrTemp==130)
               Print("INVALID STOPS???   EntryShort:",EntryShort, "    SLShort:",SLShort,  "     TPShort:",TPShort); 
               Ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,SLShort,TPShort,NULL,0,0,Green);
            */   
         }
      }
   }
   
   //Manage opened orders

   if (blOneTradeOnly==1  && CurrH1BarTime>=StartTime+60*60) //Delete the second pending trade if the other has been hit and new orders are no longer being placed
      {
      OpenTicket=0;
      PendingTicket=0;
      for (i=0;i<OrdersTotal();i++)
         {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && (OrderType()==OP_BUY || OrderType()==OP_SELL)) {OpenTicket=OrderTicket();}
         if(OrderSymbol()==Symbol() && (OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP)) {PendingTicket=OrderTicket();}
         }
      if (OpenTicket != 0 && PendingTicket != 0) //This assumes that there will only be two trades set at any given time
         {
         OrderDelete(PendingTicket);
         }   
      }


   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      //if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
      //uzavøení otevøených pozic na konci dne
      if(OrderHoursExpiry>0 && CurrH1BarTime>=CloseUnhitOrdersTime){
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)  OrderDelete(OrderTicket());
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP) OrderDelete(OrderTicket());
      }   
      
      if(blCloseAtEOD==1 && CurrH1BarTime>=EODTime){
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)      OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)     OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)  OrderDelete(OrderTicket());
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP) OrderDelete(OrderTicket());
      }   
      //move at BE if profit>BE
      else {
         if(BreakEven>0 && OrderSymbol()==Symbol() && OrderType()==OP_BUY){
            if(OrderStopLoss()<OrderOpenPrice() && iHigh(NULL,PeriodToReference,1)-OrderOpenPrice() >= BreakEven*Point){
               OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);
               //if (blTakePartialProfitAtBEtime==1) OrderClose(OrderTicket(),OrderLots()/2,Bid,3,Green); //Disabled since the code is only backtest-safe and it doesn't help anyway
            }   
         }   
         if(BreakEven>0 && OrderSymbol()==Symbol() && OrderType()==OP_SELL){
            if(OrderStopLoss()>OrderOpenPrice() && OrderOpenPrice()-(iLow(NULL,PeriodToReference,1)+MarketInfo(Symbol(),MODE_SPREAD)*Point) >= BreakEven*Point){
               OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);
               //if (blTakePartialProfitAtBEtime==1) OrderClose(OrderTicket(),OrderLots()/2,Ask,3,Green); //Disabled since the code is only backtest-safe and it doesn't help anyway
            }
         }
      }
   }
   
   if (ClosedBarLowTrailAfterBE>0) {  
      for (i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY){
            if(OrderStopLoss()>=OrderOpenPrice() && iLow(NULL,PeriodToReference,1)-OrderStopLoss() > ClosedBarLowTrailAfterBE*Point){
               OrderModify(OrderTicket(),OrderOpenPrice(),iLow(NULL,PeriodToReference,1)-ClosedBarLowTrailAfterBE*Point,OrderTakeProfit(),0,Green);
            }   
         }   
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL){
            if(OrderStopLoss()<=OrderOpenPrice() && OrderStopLoss()-((iHigh(NULL,PeriodToReference,1)+MarketInfo(Symbol(),MODE_SPREAD)*Point)) > ClosedBarLowTrailAfterBE*Point){
               OrderModify(OrderTicket(),OrderOpenPrice(),((iHigh(NULL,PeriodToReference,1)+MarketInfo(Symbol(),MODE_SPREAD)*Point))+ClosedBarLowTrailAfterBE*Point,OrderTakeProfit(),0,Green);
            }
         }
      }
   }
   
   if (Multiplier15mATR3TrailAfterBE>0 && iTime(Symbol(),PERIOD_M15,0)> Last15mATRTrailBarTime) {
      Last15mATRTrailBarTime=iTime(Symbol(),PERIOD_M15,0);
      for (i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY){
            ATRtrail=iATR(Symbol(),PERIOD_M15,3,1)*Multiplier15mATR3TrailAfterBE;
            if(OrderStopLoss()>=OrderOpenPrice() && iOpen(NULL,PeriodToReference,1)-OrderStopLoss() > ATRtrail){
               OrderModify(OrderTicket(),OrderOpenPrice(),iOpen(NULL,PeriodToReference,1)-ATRtrail,OrderTakeProfit(),0,Green);
            }   
         }   
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL){
            ATRtrail=iATR(Symbol(),PERIOD_M15,3,1)*Multiplier15mATR3TrailAfterBE;
            if(OrderStopLoss()<=OrderOpenPrice() && OrderStopLoss()-((iOpen(NULL,PeriodToReference,1)+MarketInfo(Symbol(),MODE_SPREAD)*Point)) > ATRtrail){
               OrderModify(OrderTicket(),OrderOpenPrice(),((iOpen(NULL,PeriodToReference,1)+MarketInfo(Symbol(),MODE_SPREAD)*Point))+ATRtrail,OrderTakeProfit(),0,Green);
            }
         }
      }
   }
   
   if (MultiplierH1ATR4TrailAfterBE>0 && iTime(Symbol(),PERIOD_H1,0)> LastH1ATRTrailBarTime) {
      LastH1ATRTrailBarTime=iTime(Symbol(),PERIOD_H1,0);
      for (i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY){
            ATRtrail=iATR(Symbol(),PERIOD_H1,4,1)*MultiplierH1ATR4TrailAfterBE;
            if(OrderStopLoss()>=OrderOpenPrice() && iOpen(NULL,PeriodToReference,1)-OrderStopLoss() > ATRtrail){
               OrderModify(OrderTicket(),OrderOpenPrice(),iOpen(NULL,PeriodToReference,1)-ATRtrail,OrderTakeProfit(),0,Green);
            }   
         }   
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL){
            ATRtrail=iATR(Symbol(),PERIOD_H1,4,1)*MultiplierH1ATR4TrailAfterBE;
            if(OrderStopLoss()<=OrderOpenPrice() && OrderStopLoss()-((iOpen(NULL,PeriodToReference,1)+MarketInfo(Symbol(),MODE_SPREAD)*Point)) > ATRtrail){
               OrderModify(OrderTicket(),OrderOpenPrice(),((iOpen(NULL,PeriodToReference,1)+MarketInfo(Symbol(),MODE_SPREAD)*Point))+ATRtrail,OrderTakeProfit(),0,Green);
            }
         }
      }
   }
   
   return(0);
  }
//+------------------------------------------------------------------+