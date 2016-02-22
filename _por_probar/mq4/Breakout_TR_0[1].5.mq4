//+------------------------------------------------------------------+
//|                                      Hans123 testing version.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+

#property copyright "If AdjustDSTwhenBacktesting is true, expert assumes when backtesting that times are non-DST and adjusts by -1 for Apr-Oct."

//---- input parameters
extern bool      UseSymbolSettingsInCode?=true;
extern int       TradeOpenTime=10;
extern int       LookBackHrs=4;
extern int       EOD=24;
extern bool      CloseAtEOD?=true;
extern int       PipsAddedToRange=5;
extern int       Lots=1;
extern int       StopLossMax=50;
extern int       BreakEven=30;
extern int       TakeProfit=80;
extern bool      AdjustDSTwhenBacktesting?=true;
extern bool      Skip1stFriOfMonthIfBacktesting?=true;

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   //---- 
   int i,Ticket,LastOrderTime,StartTime,EODTime,Bought=0,Sold=0,PeriodToReference=0,ErrTemp=0;
   double EntryLong,EntryShort,SLLong,SLShort,TPLong,TPShort,CurrH1BarTime,LookbackBars;
   
   //Settings
   if (UseSymbolSettingsInCode?){
      if (Symbol()=="EURUSD"){
         TradeOpenTime=10;
         LookBackHrs=4;
         EOD=24;
         CloseAtEOD?=true;
         PipsAddedToRange=5;
         StopLossMax=50;
         BreakEven=30;
         TakeProfit=80;
      }   
      else if (Symbol()=="GBPUSD"){
         TradeOpenTime=10;
         LookBackHrs=4;
         EOD=24;
         CloseAtEOD?=true;
         PipsAddedToRange=5;
         StopLossMax=70;
         BreakEven=40;
         TakeProfit=120;
      }
      else {
         TradeOpenTime=10;
         LookBackHrs=4;
         EOD=24;
         CloseAtEOD?=true;
         PipsAddedToRange=5;
         StopLossMax=50;
         BreakEven=30;
         TakeProfit=80;
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
      if(DayOfWeek()==5)   EODTime  = MathMin(StrToTime("22:00"),StrToTime(EOD-1+":00"));
         else              EODTime  = StrToTime(EOD-1+":00");
      }
      else
      {
      StartTime= StrToTime(TradeOpenTime+":00");
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
      
      if (! (IsTesting() && Skip1stFriOfMonthIfBacktesting? &&  DayOfWeek()==5 && Day()<8)) {
         if(Bought==0){ //no buy order
            //if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
            ErrTemp=GetLastError(); //In order to clear any previous error
            Ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,EntryLong,3,SLLong,TPLong,NULL,0,0,Green);
            /*
            ErrTemp=GetLastError();
            if(Ticket<0 && ErrTemp==130)
               Print("INVALID STOPS???   EntryLong:",EntryLong, "    SLLong:",SLLong,  "     TPLong:",TPLong); 
               Ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,SLLong,TPLong,NULL,0,0,Green);
            */   
            //GlobalVariableSet("LastOrderTime",OrderOpenTime()); 
         }
         if(Sold==0){ //no sell order
            //if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
            ErrTemp=GetLastError(); //In order to clear any previous error
            Ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,EntryShort,3,SLShort,TPShort,NULL,0,0,Green);
            /*
            ErrTemp=GetLastError();
            if(Ticket<0 && ErrTemp==130)
               Print("INVALID STOPS???   EntryShort:",EntryShort, "    SLShort:",SLShort,  "     TPShort:",TPShort); 
               Ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,SLShort,TPShort,NULL,0,0,Green);
            */   
            //GlobalVariableSet("LastOrderTime",OrderOpenTime()); 
         }
      }
   }
   
   //Manage opened orders
   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      //if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
      //uzavøení otevøených pozic na konci dne
      if(CloseAtEOD? && CurrH1BarTime>=EODTime){
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)      OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)     OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)  OrderDelete(OrderTicket());
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP) OrderDelete(OrderTicket());
         //GlobalVariableSet("LastOrderTime",CurTime());
      }   
      //move at BE if profit>BE
      else {
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY){
            if(OrderStopLoss()!=OrderOpenPrice() && iHigh(NULL,PeriodToReference,1)-OrderOpenPrice() >= BreakEven*Point){
               OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);
               //GlobalVariableSet("LastOrderTime",CurTime());
            }   
         }   
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL){
            if(OrderStopLoss()!=OrderOpenPrice() && OrderOpenPrice()-(iLow(NULL,PeriodToReference,1)+MarketInfo(Symbol(),MODE_SPREAD)*Point) >= BreakEven*Point){
               OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);
               //GlobalVariableSet("LastOrderTime",CurTime());
            }
         }
      }
   }
   
   //Reset global variables at EOD
   //if(CurTime()>=EODTime) GlobalVariablesDeleteAll();
   
   return(0);
  }
//+------------------------------------------------------------------+