//+------------------------------------------------------------------+
//|                                   TSD_MR_Trade_OsMA_WPR_0_32.mq4 |
//|                                       Copyright ® 2005 Mindaugas |
//|                                           TSD Trade version 0.32 |
//|                                                                  |
//|             o TSD idea and realization by Bob O'Brien / Barcode  |
//|               o TSD rewritten to MQL4 and enhanced by Mindaugas  |
//|                            o Enhanced comments by Mike aka FxMt  |
//|                    o Trailing Stop based on ATR by Loren Gordon  |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2005 Mindaugas"

#include <stdlib.mqh>

#define  DIRECTION_MACD 1
#define  DIRECTION_OSMA 2

#define  FILTER_WPR     1
#define  FILTER_FORCE   2

#define  BROKER_ALPARI        1
#define  BROKER_IBFX          2
#define  BROKER_IBFX_MINI     3
#define  BROKER_FXDD          4
#define  BROKER_FXDD_MINI     5
#define  BROKER_METAQUOTES    6
#define  BROKER_NEUREX        7
#define  BROKER_NEUREX_MINI   8
#define  BROKER_NEUREX_MICRO  9

// Whether to put new orders or only track old ones
extern bool NewTrades = true;

// which indicators to use
int DirectionMode = DIRECTION_OSMA, FilterMode = FILTER_WPR;
// trading periods
int PeriodDirection = PERIOD_W1, PeriodTrade = PERIOD_D1, PeriodTrailing = PERIOD_H4, CandlesTrailing = 3;
// currency pairs to trade
string pairs[] = { "AUDUSD", "EURCHF", "EURGBP", "EURJPY", "EURUSD", "GBPCHF", "GBPJPY", "GBPUSD",
                   "USDCAD", "USDCHF", "USDJPY" };

// MM and broker parameters
int Broker = BROKER_ALPARI;
double Risk = 0.00, Lots = 0.1;

// parameters for MACD and OsMA
int DirectionFastEMA = 12, DirectionSlowEMA = 26, DirectionSignal = 9;
// parameters for iWPR and iForce indicators
int WilliamsP = 24, WilliamsL = -75, WilliamsH = -25;
int ForceP = 2;

int MagicNumber = 2005072001;

bool TrailingStop = true;
int TakeProfit = 100, Slippage = 5;

string TradeSymbol, CommentHeader, CommentsPairs[];
int Pair = -1, SDigits;
double Spread, SPoint, STS, StopLevel;
datetime LastTrade = 0;

//+------------------------------------------------------------------+
int init() {
   string DirInd, FilterInd;

   if ( IsTesting() ) { if ( ArrayResize(pairs,1) != 0 )  pairs[0] = Symbol(); }
   else {
      if ( DirectionMode == DIRECTION_MACD )       DirInd = "MACD";
      else if ( DirectionMode == DIRECTION_OSMA )  DirInd = "OsMA";
      
      if ( FilterMode == FILTER_WPR )         FilterInd = "WPR("+WilliamsP+","+WilliamsL+","+WilliamsH+")";
      else if ( FilterMode == FILTER_FORCE )  FilterInd = "Force("+ForceP+")";
      
      CommentHeader = ("\nTSD Trade P("+PeriodDirection+","+PeriodTrade+","+PeriodTrailing+","+CandlesTrailing+")"+
                       " "+DirInd+"("+DirectionFastEMA+","+DirectionSlowEMA+","+DirectionSignal+")"+
                       " "+FilterInd+"\n");
   }
   ArrayCopy (CommentsPairs, pairs);
   return(0);
}
//+------------------------------------------------------------------+
int deinit() { return(0); }
//+------------------------------------------------------------------+

int start() {
   int TradesThisSymbol, Direction;
   int i, ticket;
   
   bool okSell, okBuy;
   
   double PriceOpen, Buy_Sl, Buy_Tp, LotMM;
   string ValueComment;
   
   Pair = (Pair+1) % ArraySize(pairs);
   TradeSymbol = pairs[Pair];

   if ( MarketInfo (TradeSymbol, MODE_SPREAD) < 1 ) {
      Alert ("No data for the pair: ", TradeSymbol, ". Please review and fix pairs variable.");
      return(0);
   }

   TradesThisSymbol = TotalTradesThisSymbol (TradeSymbol);

   SPoint    = MarketInfo (TradeSymbol, MODE_POINT);
   Spread    = MarketInfo (TradeSymbol, MODE_SPREAD) * SPoint;
   SDigits   = MarketInfo (TradeSymbol, MODE_DIGITS);
   StopLevel = MarketInfo (TradeSymbol, MODE_STOPLEVEL) * SPoint + 1*SPoint;
   STS = iATR (TradeSymbol, PeriodTrailing, PeriodDirection*3/PeriodTrailing, 1) + Spread + 1*SPoint;
  
   Direction = Direction (TradeSymbol, PeriodDirection, DirectionMode);
   ValueComment = Filter(TradeSymbol, PeriodTrade, FilterMode, okBuy, okSell);
   
   CommentAll (Direction, ValueComment);

   if ( ! IsTradeAllowed() )  return(0);

   ///////////////////////////////////////////////////////////////////////////////
   //  Place new orders and modify pending ones only on the beginning of new bar
   ///////////////////////////////////////////////////////////////////////////////
   if ( NewBar() ) {
      /////////////////////////////////////////////////
      //  Place new order
      /////////////////////////////////////////////////
      if ( TradesThisSymbol < 1 && NewTrades ) {

         ticket = 0;
         LotMM = CalcMM_TSDTrade (Direction);
         if ( LotMM < 0 )  return(0);

         if ( Direction == 1 && okBuy ) {
            MarkTrade();
	         Print ("TSD BuyStop: ", TradeSymbol, " ", LotMM, " ", CalcOpenBuy(), " ", CalcSlBuy(), " ", CalcTpBuy(),
	                ", ", MarketInfo(TradeSymbol, MODE_ASK), " ", ValueComment);
            ticket = OrderSend (TradeSymbol, OP_BUYSTOP, LotMM, CalcOpenBuy(), Slippage, CalcSlBuy(), CalcTpBuy(),
		                       "TSD BuyStop", MagicNumber, 0);
         } 
		   
         if ( Direction == -1 && okSell ) {
            MarkTrade();
	         Print ("TSD SellStop: ", TradeSymbol, " ", LotMM, " ", CalcOpenSell(), " ", CalcSlSell(), " ", CalcTpSell(),
	                ", ", MarketInfo(TradeSymbol, MODE_BID), " ", ValueComment);
	         ticket = OrderSend (TradeSymbol, OP_SELLSTOP, LotMM, CalcOpenSell(), Slippage, CalcSlSell(), CalcTpSell(),
	                             "TSD SellStop", MagicNumber, 0);
   	   }
 
   	   if ( ticket == -1 )  ReportError ();
	      if ( ticket != 0 )   return(0);
   	} // End of TradesThisSymbol < 1 && NewTrades

      /////////////////////////////////////////////////
      //  Pending Order Management
      /////////////////////////////////////////////////
      for (i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != TradeSymbol || OrderMagicNumber() != MagicNumber)  continue;
         if ( OrderOpenTime() > iTime(TradeSymbol, PeriodTrade, 0) ) continue;

         if ( OrderType () == OP_BUYSTOP ) {
            if ( Direction != 1 || ComparePrices (CalcOpenBuy(), OrderOpenPrice()) != 0 ||
                                   ComparePrices (CalcSlBuy(), OrderStopLoss()) != 0 ) {
               MarkTrade();
   	         Print ("TSD delete BuyStop: ", TradeSymbol);
               OrderDelete ( OrderTicket() );
               return(0);
            }
         }

         if ( OrderType () == OP_SELLSTOP ) {
            if ( Direction != -1 || ComparePrices (CalcOpenSell(), OrderOpenPrice()) != 0 ||
                                    ComparePrices (CalcSlSell(), OrderStopLoss()) != 0 ) {
               MarkTrade();
   	         Print ("TSD delete SellStop: ", TradeSymbol);
               OrderDelete ( OrderTicket() );
               return(0);
            }
         }
      } // End of Pending Order Management
   } // End of NewBar()

   /////////////////////////////////////////////////
   //  Stop Loss Management
   /////////////////////////////////////////////////
   if ( TrailingStop ) {
      for (i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != TradeSymbol || OrderMagicNumber() != MagicNumber)  continue;
         if ( TrailStop (i, STS) )  return(0);
      }
   }

   return(0);
}
//+------------------------------------------------------------------+
double CalcOpenBuy  () { return (MathMax (iHigh(TradeSymbol, PeriodTrade, 1) + 1*SPoint + Spread,
                                          MarketInfo(TradeSymbol, MODE_ASK) + StopLevel)); }
double CalcOpenSell () { return (MathMin (iLow(TradeSymbol, PeriodTrade, 1) - 1*SPoint,
                                          MarketInfo(TradeSymbol, MODE_BID) - StopLevel)); }
double CalcSlBuy  () { return (iLow (TradeSymbol, PeriodTrade, 1) - 1*SPoint); }
double CalcSlSell () { return (iHigh(TradeSymbol, PeriodTrade, 1) + 1*SPoint + Spread); }
double CalcTpBuy  () {
   double PriceOpen = CalcOpenBuy(), SL = CalcSlBuy();
   if ( TakeProfit == 0 )  return(0);
   return (PriceOpen + MathMax(TakeProfit*SPoint, (PriceOpen - SL)*2));
}
double CalcTpSell () {
   double PriceOpen = CalcOpenSell(), SL = CalcSlSell();
   if ( TakeProfit == 0 )  return(0);
   return (PriceOpen - MathMax(TakeProfit*SPoint, (SL - PriceOpen)*2));
}
//+------------------------------------------------------------------+
bool TrailStop (int i, double TrailingStop) {
   double StopLoss;

   if ( OrderType() == OP_BUY ) {
      if ( MarketInfo (TradeSymbol, MODE_BID) < OrderOpenPrice()+TrailingStop )  return(false);
      StopLoss = iLow(TradeSymbol, PeriodTrailing, Lowest (TradeSymbol, PeriodTrailing, MODE_LOW, CandlesTrailing+1, 0)) - 1*SPoint;
      StopLoss = MathMin (MarketInfo (TradeSymbol, MODE_BID)-TrailingStop, StopLoss);
      if ( ComparePrices (StopLoss, OrderStopLoss() + 2*SPoint) == 1 ) {
         MarkTrade();
         Print ("TSD trailstop Buy: ", TradeSymbol, " ", StopLoss, ", ", MarketInfo(TradeSymbol, MODE_ASK));
         OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0);
         return(true);
      }
   }
   
   if ( OrderType() == OP_SELL ) {
      if ( MarketInfo (TradeSymbol, MODE_ASK) > OrderOpenPrice()-TrailingStop )  return(false);
      StopLoss = iHigh(TradeSymbol, PeriodTrailing, Highest (TradeSymbol, PeriodTrailing, MODE_HIGH, CandlesTrailing+1, 0)) + 1*SPoint
                 + Spread;
      StopLoss = MathMax (MarketInfo (TradeSymbol, MODE_ASK)+TrailingStop, StopLoss);
      if ( ComparePrices (StopLoss, OrderStopLoss() - 2*SPoint) == -1 ) {
         MarkTrade();
         Print ("TSD trailstop Sell: ", TradeSymbol, " ", StopLoss, ", ", MarketInfo(TradeSymbol, MODE_BID));
         OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0);
         return(true);
      }
   }
   
   return(false);
}
//+------------------------------------------------------------------+
int Direction (string TradeSymbol, int PeriodDirection, int Mode) {
   double Previous, Previous2;

   if (Mode == DIRECTION_MACD ) {
	   Previous  = iMACD (TradeSymbol, PeriodDirection, DirectionFastEMA, DirectionSlowEMA, DirectionSignal,
	                      PRICE_CLOSE, MODE_MAIN, 1);
	   Previous2 = iMACD (TradeSymbol, PeriodDirection, DirectionFastEMA, DirectionSlowEMA, DirectionSignal,
	                      PRICE_CLOSE, MODE_MAIN, 2);
	}
	else if (Mode == DIRECTION_OSMA) {
	   Previous  = iOsMA (TradeSymbol, PeriodDirection, DirectionFastEMA, DirectionSlowEMA, DirectionSignal,
	                      PRICE_CLOSE, 1);
	   Previous2 = iOsMA (TradeSymbol, PeriodDirection, DirectionFastEMA, DirectionSlowEMA, DirectionSignal,
	                      PRICE_CLOSE, 2);
	}

   if ( Previous > Previous2 )
      return(1);
   if ( Previous < Previous2 )
      return(-1);
   return(0);
}
//+------------------------------------------------------------------+
string Filter (string TradeSymbol, int PeriodTrade, int Mode, bool &okBuy, bool &okSell) {
   double Value;
   
   okBuy = false; okSell = false;
   
   if (Mode == FILTER_WPR) {
      Value = iWPR(TradeSymbol, PeriodTrade, WilliamsP, 1);
	   if (Value < WilliamsH)  okBuy = true;
   	if (Value > WilliamsL)  okSell = true;
   	return ("iWPR: " + DoubleToStr(Value, 2));
   }
   else if (Mode == FILTER_FORCE) {
      Value = iForce (TradeSymbol, PeriodTrade, ForceP, MODE_EMA, PRICE_CLOSE, 1);
      if (Value < 0)  okBuy = true;
      if (Value > 0)  okSell = true;
   	return ("iForce: " + DoubleToStr(Value, 2));
   }
}
//+------------------------------------------------------------------+
double CalcMM_TSDTrade (int Direction) {
   if ( Direction == 1 ) 
      return ( CalcMM (TradeSymbol, (CalcOpenBuy()-CalcSlBuy())/SPoint) );
   else if ( Direction == -1 ) 
      return ( CalcMM (TradeSymbol, (CalcSlSell()-CalcOpenSell())/SPoint) );
}
//+------------------------------------------------------------------+
double CalcMM (string TradeSymbol, int StopLoss) {

   static double MinimalLot = 1;
   static int LotDigits = 0, LotSize = 0;

   double LotsMM = Lots;

   if ( LotSize == 0 ) {
      if ( Broker == BROKER_IBFX_MINI ) LotSize = 10000;
      else                              LotSize = 100000;
      
      switch (Broker) {
         case BROKER_NEUREX_MICRO:  MinimalLot = 0.01; LotDigits = 2; break;
         case BROKER_ALPARI:
         case BROKER_FXDD_MINI:
         case BROKER_METAQUOTES:
         case BROKER_NEUREX_MINI:   MinimalLot = 0.1;  LotDigits = 1; break;
      }
   }

   if ( Risk > 0 )
      LotsMM = MathMax ( MinimalLot, AccountBalance() * Risk / (StopLoss * PipCost(TradeSymbol)) );
      
   if ( AccountFreeMargin() < LotsMM * LotSize/AccountLeverage() ) {
      Alert("Not enough money to open trade. Free Margin = ", AccountFreeMargin(),
            ". Number of Lots in trade = ", LotsMM);
      return(-1); 
   }

   return (NormalizeDouble (LotsMM, LotDigits));
}
//+------------------------------------------------------------------+
double PipCost (string TradeSymbol) {
   double Cost;

   if      ( TradeSymbol == "EURCHF" || 
             TradeSymbol == "USDCHF" )  Cost = 10/  MarketInfo("USDCHF",MODE_BID);
   else if ( TradeSymbol == "EURGBP" )  Cost = 10*  MarketInfo("GBPUSD",MODE_BID);
   else if ( TradeSymbol == "CHFJPY" ||
             TradeSymbol == "EURJPY" ||
             TradeSymbol == "USDJPY" )  Cost = 1000/MarketInfo("USDJPY",MODE_BID);
   else if ( TradeSymbol == "AUDUSD" ||
             TradeSymbol == "EURUSD" ||
             TradeSymbol == "GBPUSD" ||
             TradeSymbol == "NZDUSD" )  Cost = 10;
   else if ( TradeSymbol == "GBPCHF" )  Cost = PipCost("GBPUSD")     / MarketInfo("USDCHF",MODE_BID);
   else if ( TradeSymbol == "GBPJPY" )  Cost = PipCost("GBPUSD")*100 / MarketInfo("USDJPY",MODE_BID);
   else if ( TradeSymbol == "EURCAD" ||
             TradeSymbol == "USDCAD" )  Cost = 10/  MarketInfo("USDCAD",MODE_BID);
   else                                 Cost = 10;

   if ( Broker == BROKER_ALPARI || Broker == BROKER_METAQUOTES ||
        Broker == BROKER_NEUREX || Broker == BROKER_NEUREX_MINI || Broker == BROKER_NEUREX_MICRO ) {
      if      ( TradeSymbol == "AUDUSD" )  Cost = 20;
      else if ( TradeSymbol == "GBPUSD" )  Cost = 7;
   }

   if ( Broker == BROKER_IBFX_MINI )  Cost = Cost / 10;

   return(Cost);
}
//+------------------------------------------------------------------+
int TotalTradesThisSymbol (string TradeSymbol) {
   int i, TradesThisSymbol = 0;
   
   for (i = 0; i < OrdersTotal(); i++)
      if ( OrderSelect (i, SELECT_BY_POS) )
         if ( OrderSymbol() == TradeSymbol && OrderMagicNumber() == MagicNumber )
            TradesThisSymbol++;

   return (TradesThisSymbol);
}
//+------------------------------------------------------------------+
void ReportError () {
   int err = GetLastError();
   Print("Error(",err,"): ", ErrorDescription(err));
}
//+------------------------------------------------------------------+
void MarkTrade () {
   LastTrade = CurTime();
}
//+------------------------------------------------------------------+
int ComparePrices (double Price1, double Price2) {
   double p1 = NormalizeDouble (Price1, SDigits), p2 = NormalizeDouble (Price2, SDigits);
   if ( p1 > p2 )  return(1);
   if ( p1 < p2 )  return(-1);
   return(0);
}
//+------------------------------------------------------------------+
bool NewBar () {
   static datetime PairTime[0];
   static int PairNewBar[0];
   
   if ( ArraySize(PairTime) != ArraySize(pairs) ) {
      ArrayResize (PairTime, ArraySize(pairs) );    ArrayInitialize (PairTime, 0);
      ArrayResize (PairNewBar, ArraySize(pairs) );  ArrayInitialize (PairNewBar, 0);
   }
   
   if ( PairNewBar[Pair] < 3 ) {
      PairNewBar[Pair]++;
      return(true);
   }
   
   if ( PairTime[Pair] != iTime (TradeSymbol, PeriodTrade, 0 ) ) {
      PairTime[Pair] = iTime (TradeSymbol, PeriodTrade, 0 );
      PairNewBar[Pair] = 0;
   }

   return(false);
}
//+------------------------------------------------------------------+
void CommentAll (int Direction, string ValueComment) {
   string Comments = "";
   int i, next = (Pair+1) % ArraySize(pairs);
   
   CommentsPairs[Pair] = TradeSymbol + ": " + " Dir("+Direction+") " + ValueComment + 
                         " TS(" + DoubleToStr (STS/SPoint, 0) + ")";
   CommentsPairs[next] = ">" + CommentsPairs[next];
   for (i=0; i < ArraySize(CommentsPairs); i++)
      Comments = Comments + "\n" + CommentsPairs[i];
   Comment (CommentHeader, Comments);
}

