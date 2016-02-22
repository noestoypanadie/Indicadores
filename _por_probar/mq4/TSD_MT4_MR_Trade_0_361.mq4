//+------------------------------------------------------------------+
//|                                   TSD_MR_Trade_OsMA_WPR_0_36.mq4 |
//|                                       Copyright © 2006 Mindaugas |
//|                                           TSD Trade version 0.36 |
//|                                                                  |
//|             o TSD idea and realization by Bob O'Brien / Barcode  |
//|               o TSD rewritten to MQL4 and enhanced by Mindaugas  |
//|                            o Enhanced comments by Mike aka FxMt  |
//|                    o Trailing Stop based on ATR by Loren Gordon  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006 Mindaugas"

#include <stdlib.mqh>

#define  DIRECTION_MACD 1
#define  DIRECTION_OSMA 2

#define  FILTER_WPR     1
#define  FILTER_FORCE   2

// Put new trades only on new bar or also on expert initialization. Default is to trade only on new bar.
extern bool TradeOnInit = false;
// Whether to put new orders or only track old ones. Default is to put new orders.
extern bool NewTrades = true;

// which indicators to use
int DirectionMode = DIRECTION_OSMA, FilterMode = FILTER_WPR;
// trading periods
int PeriodDirection = PERIOD_W1, PeriodTrade = PERIOD_D1, PeriodTrailing = PERIOD_H4, CandlesTrailing = 0;
// currency pairs to trade
//string pairs[] = { "AUDUSD", "EURCHF", "EURGBP", "EURJPY", "EURUSD",
//                   "GBPCHF", "GBPJPY", "GBPUSD", "USDCAD", "USDCHF", "USDJPY" };
string pairs[] = { "EURUSD" };
// MM and broker parameters
double Risk = 0.00, Lots = 0.1;

// parameters for MACD and OsMA
int DirectionFastEMA = 12, DirectionSlowEMA = 26, DirectionSignal = 9;
// parameters for iWPR and iForce indicators
int WilliamsP = 24, WilliamsL = -75, WilliamsH = -25;
int ForceP = 2;

int MagicNumber = 2005072001;

bool TrailingStop = true;
int TakeProfit = 60, Slippage = 2, TrailingStopStep = 2;

string TradeSymbol, CommentHeader, CommentsPairs[];
int Pair = -1, SDigits;
double Spread, SPoint, STS, StopLevel;

//+------------------------------------------------------------------+
int init() {
   string DirInd, FilterInd;
   
   if ( ! TradeOnInit )  Print ("WARNING!!! Expert will place new orders only on the beginning of the new bar.");

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
   static bool Alerted = false;

   int TradesThisSymbol, Direction;
   int i, ticket;
   
   bool okSell, okBuy, Deleted;
   
   double PriceOpen, Buy_Sl, Buy_Tp, LotMM;
   string ValueComment;
   
   Pair = (Pair+1) % ArraySize(pairs);
   TradeSymbol = pairs[Pair];

   if ( ! PairExists(TradeSymbol) ) {
      if ( ! Alerted )  Alert ("No data for the pair: ", TradeSymbol, ". Please review and fix pairs variable.");
      Alerted = true;
      return(0);
   }

   TradesThisSymbol = TotalTradesThisSymbol (TradeSymbol);

   SPoint    = MarketInfo (TradeSymbol, MODE_POINT);
   Spread    = MarketInfo (TradeSymbol, MODE_ASK) - MarketInfo (TradeSymbol, MODE_BID);
   SDigits   = MarketInfo (TradeSymbol, MODE_DIGITS);
   StopLevel = MarketInfo (TradeSymbol, MODE_STOPLEVEL) * SPoint + 1*SPoint;
   STS = iATR (TradeSymbol, PeriodTrailing, PeriodDirection*3/PeriodTrailing, 1) + Spread + 1*SPoint;
  
   Direction = Direction (TradeSymbol, PeriodDirection, DirectionMode);
   ValueComment = Filter(TradeSymbol, PeriodTrade, FilterMode, okBuy, okSell);
   
   CommentAll (Direction, ValueComment);

   if ( ! IsTradeAllowed() || MarketInfo(TradeSymbol, MODE_TRADEALLOWED) == 0 ) return(0);

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
         if ( LotMM <= 0 )  return(0);

         if ( Direction == 1 && okBuy ) {
	         Print ("TSD BuyStop: ", TradeSymbol, " ", LotMM, " ", CalcOpenBuy(), " ", CalcSlBuy(), " ", CalcTpBuy(),
	                ", ", MarketInfo(TradeSymbol, MODE_ASK), " ", ValueComment);
            ticket = OrderSend (TradeSymbol, OP_BUYSTOP, LotMM, CalcOpenBuy(), Slippage, CalcSlBuy(), CalcTpBuy(),
		                       "TSD BuyStop", MagicNumber, 0);
         } 
		   
         if ( Direction == -1 && okSell ) {
	         Print ("TSD SellStop: ", TradeSymbol, " ", LotMM, " ", CalcOpenSell(), " ", CalcSlSell(), " ", CalcTpSell(),
	                ", ", MarketInfo(TradeSymbol, MODE_BID), " ", ValueComment);
	         ticket = OrderSend (TradeSymbol, OP_SELLSTOP, LotMM, CalcOpenSell(), Slippage, CalcSlSell(), CalcTpSell(),
	                             "TSD SellStop", MagicNumber, 0);
   	   }
 
   	   OrderError(ticket >= 0);
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
   	         Print ("TSD delete BuyStop: ", TradeSymbol);
               Deleted = OrderDelete ( OrderTicket() );
               OrderError(Deleted);
               return(0);
            }
         }

         if ( OrderType () == OP_SELLSTOP ) {
            if ( Direction != -1 || ComparePrices (CalcOpenSell(), OrderOpenPrice()) != 0 ||
                                    ComparePrices (CalcSlSell(), OrderStopLoss()) != 0 ) {
   	         Print ("TSD delete SellStop: ", TradeSymbol);
               Deleted = OrderDelete ( OrderTicket() );
               OrderError(Deleted);
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
         if ( TrailStop (STS) )  return(0);
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
   return (PriceOpen + MathMax( MathMax(TakeProfit*SPoint, STS*3), (PriceOpen - SL)*2) );
}
double CalcTpSell () {
   double PriceOpen = CalcOpenSell(), SL = CalcSlSell();
   if ( TakeProfit == 0 )  return(0);
   return (PriceOpen - MathMax( MathMax(TakeProfit*SPoint, STS*3), (SL - PriceOpen)*2));
}
//+------------------------------------------------------------------+
bool TrailStop (double TrailingStop) {
   double StopLoss;
   bool Modified;

   if ( OrderType() == OP_BUY ) {
      if ( MarketInfo (TradeSymbol, MODE_BID) < OrderOpenPrice()+TrailingStop )  return(false);
      StopLoss = iLow(TradeSymbol, PeriodTrailing, Lowest (TradeSymbol, PeriodTrailing, MODE_LOW, CandlesTrailing+1, 0)) - 1*SPoint;
      StopLoss = MathMin (MarketInfo (TradeSymbol, MODE_BID)-TrailingStop, StopLoss);
      if ( ComparePrices (StopLoss, OrderStopLoss() + TrailingStopStep*SPoint) == 1 ) {
         Print ("TSD trailstop Buy: ", TradeSymbol, " ", StopLoss, ", ", MarketInfo(TradeSymbol, MODE_ASK));
         Modified = OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0);
         OrderError(Modified, false);
         return(true);
      }
   }
   
   if ( OrderType() == OP_SELL ) {
      if ( MarketInfo (TradeSymbol, MODE_ASK) > OrderOpenPrice()-TrailingStop )  return(false);
      StopLoss = iHigh(TradeSymbol, PeriodTrailing, Highest (TradeSymbol, PeriodTrailing, MODE_HIGH, CandlesTrailing+1, 0)) + 1*SPoint
                 + Spread;
      StopLoss = MathMax (MarketInfo (TradeSymbol, MODE_ASK)+TrailingStop, StopLoss);
      if ( ComparePrices (StopLoss, OrderStopLoss() - TrailingStopStep*SPoint) == -1 ) {
         Print ("TSD trailstop Sell: ", TradeSymbol, " ", StopLoss, ", ", MarketInfo(TradeSymbol, MODE_BID));
         Modified = OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0);
         OrderError(Modified, false);
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

   double MinLot  = MarketInfo(TradeSymbol, MODE_MINLOT);
   double LotStep = MarketInfo(TradeSymbol, MODE_LOTSTEP);
   double LotsToTrade, LotsMM = Lots;

   if ( Risk > 0 ) {
      LotsToTrade = AccountBalance() * Risk / (StopLoss * PipCost(TradeSymbol));
      for (LotsMM = MinLot; NormalizeDouble(LotsToTrade-LotsMM, 8) >= 0; LotsMM += LotStep ) {}
      LotsMM = MathMax (MinLot, LotsMM - LotStep);
   }

   if ( AccountFreeMargin() < LotsMM * LotMarginSize(TradeSymbol) ) {
      Alert("Not enough money to open trade. Free Margin = ", AccountFreeMargin(),
            ". Number of Lots to trade = ", LotsMM);
      return(-1); 
   }

   return (LotsMM);
}
//+------------------------------------------------------------------+
double PipCost (string TradeSymbol) {
   double Base, Cost;
   string TS_13, TS_46, TS_4L;

   TS_13 = StringSubstr (TradeSymbol, 0, 3);
   TS_46 = StringSubstr (TradeSymbol, 3, 3);
   TS_4L = StringSubstr (TradeSymbol, 3, StringLen(TradeSymbol)-3);
   
   Base = MarketInfo (TradeSymbol, MODE_LOTSIZE) * MarketInfo (TradeSymbol, MODE_POINT);
   if ( TS_46 == "USD" )
      Cost = Base;
   else if ( TS_13 == "USD" )
           Cost = Base / MarketInfo (TradeSymbol, MODE_BID);
        else if ( PairExists ("USD"+TS_4L) )
                Cost = Base / MarketInfo ("USD"+TS_4L, MODE_BID);
             else
                Cost = Base * MarketInfo (TS_46+"USD", MODE_BID);

   return(Cost);
}
//+------------------------------------------------------------------+
double LotMarginSize (string TradeSymbol) {
   double Margin, MarginSize = MarketInfo (TradeSymbol, MODE_LOTSIZE) / AccountLeverage();
   string TS_13, TS_7L;

   TS_13 = StringSubstr (TradeSymbol, 0, 3);
   TS_7L = StringSubstr (TradeSymbol, 6, StringLen(TradeSymbol)-6);
   
   if ( TS_13 == "USD" )
      Margin = MarginSize;
   else if ( PairExists (TS_13+"USD"+TS_7L) )
           Margin = MarginSize * MarketInfo (TS_13+"USD"+TS_7L, MODE_BID);
        else
           Margin = MarginSize / MarketInfo ("USD"+TS_13+TS_7L, MODE_BID);

   return(Margin);
}
//+------------------------------------------------------------------+
bool PairExists (string TradeSymbol) {
   return ( MarketInfo (TradeSymbol, MODE_LOTSIZE) > 0 );
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
void OrderError (bool OK, bool ResetNewBar=true) {
   if ( ! OK ) {
      if ( ResetNewBar )  NewBar(-1);
      ReportError();
   }
}
//+------------------------------------------------------------------+
void ReportError () {
   int err = GetLastError();
   Print("Error(",err,"): ", ErrorDescription(err));
}
//+------------------------------------------------------------------+
int ComparePrices (double Price1, double Price2) {
   double p1 = NormalizeDouble (Price1, SDigits), p2 = NormalizeDouble (Price2, SDigits);
   if ( p1 > p2 )  return(1);
   if ( p1 < p2 )  return(-1);
   return(0);
}
//+------------------------------------------------------------------+
bool NewBar (int how=1) {
   static int ProcessNumber = 2;
   static datetime PairTime[0];
   static int PairNewBar[0];
   
   if ( ArraySize(PairTime) != ArraySize(pairs) ) {
      ArrayResize (PairTime, ArraySize(pairs) );
      ArrayResize (PairNewBar, ArraySize(pairs) );  ArrayInitialize (PairNewBar, 100);

      if ( TradeOnInit )  ArrayInitialize (PairTime, 0);
      else                ArrayInitialize (PairTime, iTime (TradeSymbol, PeriodTrade, 0 ));
   }

   if ( how == -1 ) {
      PairNewBar[Pair] = MathMax ( 0, PairNewBar[Pair]-1 );
      return(true);
   }
   
   if ( PairNewBar[Pair] <= ProcessNumber ) {
      if ( how == 1 )
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
   if ( ! IsTesting() )  Comment (CommentHeader, Comments);
}

