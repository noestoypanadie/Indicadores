//+------------------------------------------------------------------+
//|                                                   Hi_Buy_Lo_Sell |
//|This EA will take the previous bar hi and low, set a stop buy on  |
//|the high price, set a stop sell at the low price, and close       |
//|pending trades at EOD.                                            |
//+------------------------------------------------------------------+

//---- input parameters
extern int       EOD=24;   
extern int       BreakEven=10;
extern int       StopLoss=50;
extern int       TrailingStopStep=20;
extern int       TakeProfit=15;
extern double    Lots=0.1;
extern int       Pips=5;
extern double    StartingBalance=5000;
extern int       timeframe=0;

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   //---- 
   int i,Ticket,LastOrderTime,StartTime,StartTime1,EODTime,MN;
   
   //Settings for each currency pair.  Copy "else if" to create more.
   if (!IsTesting()){
      if (Symbol()=="EURUSD"){
         StopLoss=20;
         BreakEven=0;
         TakeProfit=0;
      }   
      else if (Symbol()=="GBPUSD"){
         StopLoss=20;
         BreakEven=0;
         TakeProfit=0;
      }
      else {   //default
         StopLoss=20;
         BreakEven=0;
         TakeProfit=0;
      }
   }

   // Ron's mod for lot increasement based on StartingBalance
   // this will trade 1.0, then 1.1, then 1.2 etc as balance grows
   // or 0.9 then 0.8 then 0.7 as balance shrinks 
   Lots=NormalizeDouble(AccountBalance()/StartingBalance,1);  
   Lots=Lots/10;     //allow for mini account. 
   if (Lots>50) Lots=50;  

   
    //Count time
   if(CurTime()==StrToTime("00:00")) { 
      StartTime1=StrToTime("00:00");
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
/*     
   //Manage of open orders
   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(CurTime()<=GlobalVariableGet("LastOrderTime")+10) Sleep(10000);
      if(CurTime()>=EODTime){     
         //if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)      OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
         //if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)     OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)  OrderDelete(OrderTicket());
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP) OrderDelete(OrderTicket());
         GlobalVariableSet("LastOrderTime",CurTime());
      }   
      else {
         if(TrailingStopStep==0){    //move at break even ("BE") if profit>BE
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
*/
   //Reset global variables at EOD
   if(CurTime()>=EODTime) GlobalVariablesDeleteAll();
   
   return(0);
  }
//+------------------------------------------------------------------+

int SetOrders(int MN,int StartTime){
   int i,Ticket,LastOrderTime,Bought=0,Sold=0,ShiftToStart,ShiftToBeginOfRange,timeframe;
   double EntryLong,EntryShort,SLLong,SLShort,TPLong=0,TPShort=0;
   
   if(timeframe==0) {timeframe=Period();}
   //Determine entry and stop.
   EntryLong   =High[1];
   EntryShort  =Low[1];
   SLLong      =MathMax(EntryLong-StopLoss*Point,EntryShort);
   SLShort     =MathMin(EntryShort+StopLoss*Point,EntryLong);

   if (TakeProfit>0)
   {
   TPLong      =EntryLong+TakeProfit*Point;
   TPShort     =EntryShort-TakeProfit*Point;
   }
   
   //Check Orders 
   for (i=0;i<OrdersTotal();i++)
   {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && (OrderType()==OP_BUYSTOP) && OrderMagicNumber()==MN) OrderDelete(OrderTicket());
      if(OrderSymbol()==Symbol() && (OrderType()==OP_SELLSTOP) && OrderMagicNumber()==MN) OrderDelete(OrderTicket());
   }
//   if(Bought==0)
//   { //no buy order
      Ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,EntryLong,3,SLLong,TPLong,"Hi_Buy_Lo_Sell",MN,0,Green);
      if(Ticket<0 && GetLastError()==130)
         Ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,SLLong,TPLong,"Hi_Buy_Lo_Sell",MN,0,Green);
         GlobalVariableSet("LastOrderTime",OrderOpenTime()); 
//   }
//   if(Sold==0)
//   { //no sell order
      Ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,EntryShort,3,SLShort,TPShort,"Hi_Buy_Lo_Sell",MN,0,Green);
      if(Ticket<0 && GetLastError()==130)
         Ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,SLShort,TPShort,"Hi_Buy_Lo_Sell",MN,0,Green);
         GlobalVariableSet("LastOrderTime",OrderOpenTime()); 
//   }
}