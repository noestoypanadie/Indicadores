//+------------------------------------------------------------------+
//|                                                     TSD v1-1.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""

//---
extern double Lots = 1;
//extern int StopLoss = 0;
extern int TakeProfit = 999;
extern int TrailingStop = 60;
int Slippage = 0;

//---Money Management Parameters
extern int Risk=5;
extern int mm=0;
extern int LiveTrading=0;
extern int AccountIsMini=0;
extern int maxTradesPerPair=1;


datetime NewWeeklyBar;
bool RunOnce=false;
double lotMM=0;
int LotSize=10000,LotMax=50,MarginChoke=500;
int WeeklyDirection;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//---- 
   // Run checks 
   if(RunOnce && MathMod(TimeMinute(CurTime()),5)!=0)return(0); //after the first run of the EA, it only runs every 5 mins
   
   // This function determines the weekly trend
   SetWeeklyTrend();
   
   // Manage current open orders and trades
   RunPendingOrderManagement(Symbol(),"TSD");
   RunTrailingStop(Symbol(),"TSD");
   
   // Open New Orders
   if(!SetLotsMM())return(0);
   RunNewOrderManagement(Symbol(),"TSD");
   
   RunOnce=true;
//----
   return(0);
  }
//+------------------------------------------------------------------+


/////////////////////////////////////////////////
//  WeeklyTrend
/////////////////////////////////////////////////
bool SetWeeklyTrend(){
   double MACD_0,MACD_1,MACD_2;   
   MACD_0   = iMACD(Symbol(),PERIOD_W1,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
   MACD_1   = iMACD(Symbol(),PERIOD_W1,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
   MACD_2   = iMACD(Symbol(),PERIOD_W1,12,26,9,PRICE_CLOSE,MODE_MAIN,2);
   if(MACD_1 > MACD_2)  WeeklyDirection = 1;
   if(MACD_1 < MACD_2)  WeeklyDirection = -1;
   if(MACD_1 == MACD_2) WeeklyDirection = 0;

   if(WeeklyDirection==1)  Comment("\nWeekly Trend for "+Symbol()+" = UP TREND");
   if(WeeklyDirection==-1) Comment("\nWeekly Trend for "+Symbol()+" = DOWN TREND");
   if(WeeklyDirection==0)  Comment("\nWeekly Trend for "+Symbol()+" = NEUTRAL TREND");
   
   return(true);
   }
   
/////////////////////////////////////////////////
//  LastOrderCloseTime
/////////////////////////////////////////////////
datetime LastOrderCloseTimeAll(){
   datetime loct;
   for(int x=0;x<HistoryTotal();x++){
      OrderSelect(x, SELECT_BY_POS, MODE_HISTORY);
      if(OrderCloseTime()>loct){
         loct=OrderCloseTime();
         }
      }
   return(loct);
   }
datetime LastOrderCloseTimeBySymbol(string sym){
   datetime loct;
   for(int x=0;x<HistoryTotal();x++){
      OrderSelect(x, SELECT_BY_POS, MODE_HISTORY);
      if(OrderSymbol()==sym){
         if(OrderCloseTime()>loct){
            loct=OrderCloseTime();
            }
         }
      }
   return(loct);
   }


/////////////////////////////////////////////////
//  OpenOrdersBySymbolAndComment
/////////////////////////////////////////////////
int OpenOrdersBySymbolAndComment(string sym, string comm){
   int ofts=0;
   for(int x=0;x<OrdersTotal();x++){
      OrderSelect(x, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && StringSubstr(OrderComment(),0,StringLen(comm))==comm){
         ofts++;
         }
      }
   return(ofts);
   }

/////////////////////////////////////////////////
//  SetLotsMM
/////////////////////////////////////////////////
bool SetLotsMM(){
   double MarginCutoff;

   if(AccountIsMini == 0) MarginCutoff = 1000;
   if(AccountIsMini == 1) MarginCutoff = 100;

   if(AccountFreeMargin() < MarginCutoff)return(false);

   if(mm != 0){
     lotMM = MathCeil(AccountBalance() * Risk / 10000) / 10;

     if(lotMM < 0.1) lotMM = Lots;
     if(lotMM > 1.0) lotMM = MathCeil(lotMM);

     // Enforce lot size boundaries

     if(LiveTrading == 1){
         if(AccountIsMini == 1 )               lotMM = lotMM * 10;
         if(AccountIsMini == 0 && lotMM < 1.0) lotMM = 1.0;
         }

     if(lotMM > 100) lotMM = 100;
   }
   else{
     lotMM = Lots; // Change mm to 0 if you want the Lots parameter to be in effect
     }
   
   return(true);
   }
   
/////////////////////////////////////////////////
//  RunPendingOrderManagement
/////////////////////////////////////////////////
bool RunPendingOrderManagement(string sym, string comm){
   if( OpenOrdersBySymbolAndComment(sym,comm) > 0 ){
      for ( int i = 0; i < OrdersTotal(); i++){
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         //--- LONG TRADES
         if(OrderType() == OP_BUYSTOP && OrderSymbol() == sym && StringSubstr(OrderComment(),0,StringLen(comm))==comm){
            if(WeeklyDirection==-1){
               OrderDelete(OrderTicket());
               continue;
               }
            if( iHigh(Symbol(),PERIOD_D1,1) < iHigh(Symbol(),PERIOD_D1,2) ){
	            if( iHigh(Symbol(),PERIOD_D1,1) > (Ask + 16*Point) ){
	               OrderModify(OrderTicket(),iHigh(Symbol(),PERIOD_D1,1) + 1*Point,iLow(Symbol(),PERIOD_D1,1) - 1*Point,OrderTakeProfit(),OrderExpiration(),Green);
	               continue;
	               }
               }
            }
         //--- SHORT TRADES
         if(OrderType() == OP_SELLSTOP && OrderSymbol() == sym && StringSubstr(OrderComment(),0,StringLen(comm))==comm){
            if(WeeklyDirection==1){
               OrderDelete(OrderTicket());
               continue;
               }
            if( iLow(Symbol(),PERIOD_D1,1) > iLow(Symbol(),PERIOD_D1,2) ){ 
	            if( iLow(Symbol(),PERIOD_D1,1) < (Bid - 16*Point) ){
	               OrderModify(OrderTicket(),iLow(Symbol(),PERIOD_D1,1) - 1*Point,iHigh(Symbol(),PERIOD_D1,1) + 1*Point,OrderTakeProfit(),OrderExpiration(),Blue);
	               continue;
		            }
               }
            }
         }
      }
   }
   
/////////////////////////////////////////////////
//  RunTrailingStop
/////////////////////////////////////////////////
bool RunTrailingStop(string sym, string comm){
   if( OpenOrdersBySymbolAndComment(sym,comm) > 0 ){
      double Buy_Tp,Sell_Tp;
      for ( int i = 0; i < OrdersTotal(); i++){
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         //--- LONG TRADES
         if(OrderType() == OP_BUY && OrderSymbol() == sym && StringSubstr(OrderComment(),0,StringLen(comm))==comm){
            if (Bid - OrderOpenPrice() >= TrailingStop * Point){
               if (OrderStopLoss() < Bid - TrailingStop * Point || OrderStopLoss() == 0){
                  OrderModify(OrderTicket(), OrderOpenPrice(), Bid - TrailingStop * Point, OrderTakeProfit(), Red);
                  }
               }
            }
         //--- SHORT TRADES
         if(OrderType() == OP_SELL && OrderSymbol() == sym && StringSubstr(OrderComment(),0,StringLen(comm))==comm){
            if(OrderOpenPrice() - Ask >= TrailingStop * Point){
               if((OrderStopLoss() > Ask + TrailingStop * Point) || OrderStopLoss() == 0){
                  OrderModify(OrderTicket(), OrderOpenPrice(),Ask + TrailingStop * Point, OrderTakeProfit(), Blue);
                  }
               }
            }
         }
      }
   }

/////////////////////////////////////////////////
//  RunNewOrderManagement
/////////////////////////////////////////////////
bool RunNewOrderManagement(string sym, string comm){
   if( OpenOrdersBySymbolAndComment(sym,comm) <= 0 ){
      double Buy_Tp,Sell_Tp,PriceOpen,NewPrice;
      bool ForcePos = iForce(Symbol(),PERIOD_D1,2,MODE_EMA,PRICE_CLOSE,1)  > 0;
      bool ForceNeg  = iForce(Symbol(),PERIOD_D1,2,MODE_EMA,PRICE_CLOSE,1) < 0;
      
      if( WeeklyDirection == 1 && ForceNeg ){
         PriceOpen = iHigh(Symbol(),PERIOD_D1,1) + 1 * Point;		         // Buy 1 point above high of previous candle
			if( PriceOpen > (Ask + 16 * Point) ){                             // Check If buy price is a least 16 points > Ask
			   if( TakeProfit >= 5 )   Buy_Tp = PriceOpen + TakeProfit * Point;
				if( TakeProfit <  5 )   Buy_Tp = 0;
				OrderSend(sym,OP_BUYSTOP,lotMM,PriceOpen,Slippage,iLow(Symbol(),PERIOD_D1,1) - 1*Point,Buy_Tp,"TSD - "+Symbol()+" Long",0,0,Green);
				return(true);
			   }
			if( PriceOpen <= (Ask + 16 * Point) ){
				NewPrice = Ask + 16 * Point;
				if( TakeProfit >= 5 )   Buy_Tp = NewPrice + TakeProfit * Point;
				if( TakeProfit <  5 )   Buy_Tp = 0;
				OrderSend(sym,OP_BUYSTOP,lotMM,NewPrice,Slippage,iLow(Symbol(),PERIOD_D1,1) - 1*Point,Buy_Tp,"TSD - "+Symbol()+" Long",0,0,Green);
				return(true);
			   }
         }
      if( WeeklyDirection == -1 && ForcePos ){
         PriceOpen = iLow(Symbol(),PERIOD_D1,1) - 1 * Point;		         // Sell 1 point below low of previous candle
			if( PriceOpen < (Bid - 16 * Point) ){                             // Check If sell price is a least 16 points < Bid
			   if( TakeProfit >= 5 )   Sell_Tp = PriceOpen - TakeProfit * Point;
				if( TakeProfit <  5 )   Sell_Tp = 0;
				OrderSend(sym,OP_SELLSTOP,lotMM,PriceOpen,Slippage,iHigh(Symbol(),PERIOD_D1,1) + 1 * Point,Sell_Tp,"TSD - "+Symbol()+" Short",0,0,Red);
				return(true);
			   }
			if( PriceOpen >= (Bid - 16 * Point) ){
				NewPrice = Bid - 16 * Point;
				if( TakeProfit >= 5 )   Sell_Tp = NewPrice - TakeProfit * Point;
				if( TakeProfit <  5 )   Sell_Tp = 0;
				OrderSend(sym,OP_SELLSTOP,lotMM,NewPrice,Slippage,iHigh(Symbol(),PERIOD_D1,1) + 1 * Point,Sell_Tp,"TSD - "+Symbol()+" Short",0,0,Red);
				return(true);
			   }
         }
      }
   return(true);
   }