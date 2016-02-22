//+------------------------------------------------------------------+
//|                                   TSD_MR_Trade_MACD_WPR_0_15.mq4 |
//|                           Copyright ® 2005 Bob O'Brien / Barcode |
//|             TSD v1.2 rewritten to MQL4 and enhanced by Mindaugas |
//|                                           TSD Trade version 0.15 |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2005 Bob O'Brien / Barcode"

#include <stdlib.mqh>

#define  DIRECTION_MACD 1
#define  DIRECTION_OSMA 2

#define  FILTER_WPR     1
#define  FILTER_FORCE   2

// which indicators to use
int DirectionMode = DIRECTION_MACD, FilterMode = FILTER_WPR;
// trading periods
int PeriodDirection = PERIOD_W1, PeriodTrade = PERIOD_D1, PeriodTrailing = PERIOD_H4, CandlesTrailing = 3;
// currency pairs to trade
string pairs[] = { "AUDUSD", "EURCHF", "EURGBP", "EURJPY", "EURUSD", "GBPCHF", "GBPJPY", "GBPUSD",
                   "USDCAD", "USDCHF", "USDJPY" };

// parameters for MACD and OsMA
int DirectionFastEMA = 5, DirectionSlowEMA = 34, DirectionSignal = 5;
// parameters for iWPR and iForce indicators
int WilliamsP = 24, WilliamsL = -75, WilliamsH = -25;
int ForceP = 2;

int MagicNumber = 2005072001;

int TakeProfit = 100, TrailingStop = 60;
int Slippage = 5, LotsMax = 50;
double Lots = 0.1;
int MM = 0, Leverage = 1, MarginChoke = 200;

string TradeSymbol;
int Pair = 0, SDigits;
datetime LastTrade = 0;
double Spread, SPoint;

//+------------------------------------------------------------------+

int init()   { return(0); }
int deinit() { return(0); }

//+------------------------------------------------------------------+

int start() {
   int TradesThisSymbol, Direction;
   int i, ticket;
   
   bool okSell, okBuy, NewBarTrade;
   
   double PriceOpen, Buy_Sl, Buy_Tp, LotMM, WilliamsValue;
   string ValueComment;
   
   if ( (LastTrade + 15) > CurTime() )  return(0);
   
   Pair = (Pair+1) % ArraySize(pairs);
   TradeSymbol = pairs[Pair];
   
   NewBarTrade = NewBar();
   TradesThisSymbol = TotalTradesThisSymbol (TradeSymbol);
   
   SPoint  = MarketInfo (TradeSymbol, MODE_POINT);
   Spread  = MarketInfo (TradeSymbol, MODE_SPREAD) * SPoint;
   SDigits = MarketInfo (TradeSymbol, MODE_DIGITS);
   
   Direction = Direction (TradeSymbol, PeriodDirection, DirectionMode);
   ValueComment = Filter(TradeSymbol, PeriodTrade, FilterMode, okBuy, okSell);
   
   Comment ("\nSymbol: ", TradeSymbol, "\nMACD Direction: ", Direction, "\n", ValueComment);

   ///////////////////////////////////////////////////////////////////////////////
   //  Place new orders and modify pending ones only on the beginning of new bar
   ///////////////////////////////////////////////////////////////////////////////
   if ( NewBarTrade ) {
      /////////////////////////////////////////////////
      //  Place new order
      /////////////////////////////////////////////////
      if ( TradesThisSymbol < 1 ) {

         LotMM = CalcMM(MM);
         if ( LotMM < 0 )  return(0);

         ticket = 0;

         if ( Direction == 1 && okBuy ) {
            MarkTrade();
	         Print ("TSD BuyStop: ", TradeSymbol, " ", LotMM, " ", CalcOpenBuy(), " ", CalcSlBuy(), " ", CalcTpBuy());
            ticket = OrderSend (TradeSymbol, OP_BUYSTOP, LotMM, CalcOpenBuy(), Slippage, CalcSlBuy(), CalcTpBuy(),
		                       "TSD BuyStop", MagicNumber, 0, Blue);
         } 
		   
         if ( Direction == -1 && okSell ) {
            MarkTrade();
	         Print ("TSD SellStop: ", TradeSymbol, " ", LotMM, " ", CalcOpenSell(), " ", CalcSlSell(), " ", CalcTpSell());
	         ticket = OrderSend (TradeSymbol, OP_SELLSTOP, LotMM, CalcOpenSell(), Slippage, CalcSlSell(), CalcTpSell(),
	                             "TSD SellStop", MagicNumber, 0, Red);
   	   }
 
   	   if ( ticket == -1 )  ReportError ();
	      if ( ticket != 0 )   return(0);
   	} // End of TradesThisSymbol < 1

      /////////////////////////////////////////////////
      //  Pending Order Management
      /////////////////////////////////////////////////
      for (i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != TradeSymbol || OrderMagicNumber() != MagicNumber)  continue;

         if ( OrderType () == OP_BUYSTOP ) {
            if ( Direction != 1 ) {
               MarkTrade();
               OrderDelete ( OrderTicket() );
               return(0);
            }
            if ( ComparePrices (CalcOpenBuy(), OrderOpenPrice()) != 0 ||
                 ComparePrices (CalcSlBuy(), OrderStopLoss()) != 0 ) {
               MarkTrade();
     		      OrderModify (OrderTicket(), CalcOpenBuy(), CalcSlBuy(), CalcTpBuy(), 0, White);
               return(0);
            }
         }

         if ( OrderType () == OP_SELLSTOP ) {
            if ( Direction != -1 ) {
               MarkTrade();
               OrderDelete ( OrderTicket() );
               return(0);
            }
            if ( ComparePrices (CalcOpenSell(), OrderOpenPrice()) != 0 ||
                 ComparePrices (CalcSlSell(), OrderStopLoss()) != 0 ) {
               MarkTrade();
     		      OrderModify (OrderTicket(), CalcOpenSell(), CalcSlSell(), CalcTpSell(), 0, Gold);
               return(0);
            }
         }
      } // End of Pending Order Management
   } // End of NewBarTrade

   /////////////////////////////////////////////////
   //  Stop Loss Management
   /////////////////////////////////////////////////
   if ( TrailingStop > 0 ) {
      for (i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != TradeSymbol || OrderMagicNumber() != MagicNumber)  continue;
         if ( TrailStop (i, TrailingStop) )  return(0);
      }
   }

   return(0);
}
//+------------------------------------------------------------------+
double CalcOpenBuy  () { return (dMax (iHigh(TradeSymbol, PeriodTrade, 1) + 1*SPoint + Spread,
                                       MarketInfo(TradeSymbol, MODE_ASK) + 16*SPoint)); }
double CalcOpenSell () { return (dMin (iLow(TradeSymbol, PeriodTrade, 1) - 1*SPoint,
                                       MarketInfo(TradeSymbol, MODE_BID) - 16*SPoint)); }
double CalcSlBuy  () { return (iLow (TradeSymbol, PeriodTrade, 1) - 1*SPoint); }
double CalcSlSell () { return (iHigh(TradeSymbol, PeriodTrade, 1) + 1*SPoint + Spread); }
double CalcTpBuy  () {
   double PriceOpen = CalcOpenBuy(), SL = CalcSlBuy();
   if ( TakeProfit == 0 )  return(0);
   return (PriceOpen + dMax(TakeProfit*SPoint, (PriceOpen - SL)*2));
}
double CalcTpSell () {
   double PriceOpen = CalcOpenSell(), SL = CalcSlSell();
   if ( TakeProfit == 0 )  return(0);
   return (PriceOpen - dMax(TakeProfit*SPoint, (SL - PriceOpen)*2));
}
//+------------------------------------------------------------------+
bool TrailStop (int i, int TrailingStop) {
   double StopLoss;

   if ( OrderType() == OP_BUY ) {
      if ( MarketInfo (TradeSymbol, MODE_BID) < OrderOpenPrice () )  return;
      StopLoss = iLow(TradeSymbol, PeriodTrailing, Lowest (TradeSymbol, PeriodTrailing, MODE_LOW, CandlesTrailing+1, 0)) - 1*SPoint;
      StopLoss = dMin (MarketInfo (TradeSymbol, MODE_BID)-TrailingStop*SPoint, StopLoss);
      if ( ComparePrices (StopLoss, OrderStopLoss() + 4*SPoint) == 1 ) {
         MarkTrade();
         OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, White);
         return(true);
      }
   }
   
   if ( OrderType() == OP_SELL ) {
      if ( MarketInfo (TradeSymbol, MODE_ASK) > OrderOpenPrice () )  return;
      StopLoss = iHigh(TradeSymbol, PeriodTrailing, Highest (TradeSymbol, PeriodTrailing, MODE_HIGH, CandlesTrailing+1, 0)) + 1*SPoint
                 + Spread;
      StopLoss = dMax (MarketInfo (TradeSymbol, MODE_ASK)+TrailingStop*SPoint, StopLoss);
      if ( ComparePrices (StopLoss, OrderStopLoss() - 4*SPoint) == -1 ) {
         MarkTrade();
         OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, Gold);
         return(true);
      }
   }
}
//+------------------------------------------------------------------+
int Direction (string TradeSymbol, int PeriodDirection, int Mode) {
   double Previous, Previous2;

   if (Mode == DIRECTION_MACD ) {
	   Previous  = iMACD (TradeSymbol, PeriodDirection, DirectionFastEMA, DirectionSlowEMA, DirectionSignal,
	                      PRICE_MEDIAN, MODE_MAIN, 1);
	   Previous2 = iMACD (TradeSymbol, PeriodDirection, DirectionFastEMA, DirectionSlowEMA, DirectionSignal,
	                      PRICE_MEDIAN, MODE_MAIN, 2);
	}
	else if (Mode == DIRECTION_OSMA) {
	   Previous  = iOsMA (TradeSymbol, PeriodDirection, DirectionFastEMA, DirectionSlowEMA, DirectionSignal,
	                      PRICE_MEDIAN, 1);
	   Previous2 = iOsMA (TradeSymbol, PeriodDirection, DirectionFastEMA, DirectionSlowEMA, DirectionSignal,
	                      PRICE_MEDIAN, 2);
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
double CalcMM (int MM) {
   double LotMM;

   if ( MM < -1) {
      if ( AccountFreeMargin () < 5 )  return(-1);
		LotMM = MathFloor (AccountBalance()*Leverage/1000);
		if ( LotMM < 1 )  LotMM = 1;
		LotMM = LotMM/100;
   }
	if ( MM == -1 ) {
		if ( AccountFreeMargin() < 50 )  return(-1);
		LotMM = MathFloor(AccountBalance()*Leverage/10000);
		if ( LotMM < 1 )  LotMM = 1;
		LotMM = LotMM/10;
   }
	if ( MM == 0 ) {
		if ( AccountFreeMargin() < MarginChoke ) return(-1); 
		LotMM = Lots;
	}
	if ( MM > 0 ) {
      if ( AccountFreeMargin() < 500 )  return(-1);
		LotMM = MathFloor(AccountBalance()*Leverage/100000);
 		if ( LotMM < 1 )  LotMM = 1;
	}
	if ( LotMM > LotsMax )  LotMM = LotsMax;
	return(LotMM);
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
double dMax (double val1, double val2) {
  if (val1 > val2)  return(val1);
  return(val2);
}
//+------------------------------------------------------------------+
double dMin (double val1, double val2) {
  if (val1 < val2)  return(val1);
  return(val2);
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
   static datetime BarTime = 0;
   static int NewBarPairs = 999;
   if ( NewBarPairs < ArraySize(pairs) ) {
//      Print ("NEW BAR. Count: ", NewBarPairs, " Symbol: ", TradeSymbol);
      NewBarPairs++;
      return (true);
   }
   if ( BarTime != iTime(TradeSymbol, PeriodTrade, 0) ) {
      BarTime = iTime(TradeSymbol, PeriodTrade, 0);
      NewBarPairs = 0;
   }
   return(false);
}

