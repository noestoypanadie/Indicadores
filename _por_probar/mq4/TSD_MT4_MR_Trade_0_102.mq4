//+------------------------------------------------------------------+
//|                                   TSD_MR_Trade_MACD_WPR_0_10.mq4 |
//|                           Copyright � 2005 Bob O'Brien / Barcode |
//|             TSD v1.2 rewritten to MQL4 and enhanced by Mindaugas |
//|                   magic number and backtesting mod by Nick Bilak |
//|                                           TSD Trade version 0.10 |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2005 Bob O\'Brien / Barcode"

#include <stdlib.mqh>

#define MAGICNUM  20050720

#define  DIRECTION_MACD 1
#define  DIRECTION_OSMA 2

#define  FILTER_WPR     1
#define  FILTER_FORCE   2

// which indicators to use
int DirectionMode = DIRECTION_MACD, FilterMode = FILTER_WPR;
// trading periods
int PeriodDirection = PERIOD_W1, PeriodTrade = PERIOD_D1, PeriodTrailing = PERIOD_H4, CandlesTrailing = 3;
// currency pairs to trade

// parameters for iWPR and iForce indicators
int WilliamsP = 24, WilliamsL = -75, WilliamsH = -25;
int ForceP = 2;

int TakeProfit = 100, TrailingStop = 60;
int Slippage = 5, LotsMax = 50;
double Lots = 0.1;
int MM = 0, Leverage = 1, MarginChoke = 200;

string TradeSymbol;
int Pair = 0;
datetime LastTrade = 0;
double Spread, SPoint;

//+------------------------------------------------------------------+

int init()   { return(0); }
int deinit() { return(0); }

//+------------------------------------------------------------------+

int start() {
   int TradesThisSymbol, Direction;
   int i, ticket;
   
   bool okSell, okBuy;
   
   double PriceOpen, Buy_Sl, Buy_Tp, LotMM, WilliamsValue;
   string ValueComment;
   
   if ( (LastTrade + 15) > CurTime() )  return(0);
   
   TradeSymbol = Symbol();
   
   Spread = MarketInfo (TradeSymbol, MODE_SPREAD)*Point;
   SPoint = Point;
   
   TradesThisSymbol = TotalTradesThisSymbol (TradeSymbol);
   
   Direction = Direction (TradeSymbol, PeriodDirection, DirectionMode);
   ValueComment = Filter(TradeSymbol, PeriodTrade, FilterMode, okBuy, okSell);
   
   //Comment ("\nSymbol: ", TradeSymbol, "\nMACD Direction: ", Direction, "\n", ValueComment);

   /////////////////////////////////////////////////
   //  Place new order
   /////////////////////////////////////////////////
   if ( IsNewDayBar() ) {  
      if ( TradesThisSymbol < 1 ) {

         LotMM = CalcMM(MM);
         if ( LotMM < 0 )  return(0);

         ticket = 0;

         if ( Direction == 1 && okBuy ) {
            MarkTrade();
	         //Print ("TSD BuyStop: ", TradeSymbol, " ", LotMM, " ", CalcOpenBuy(), " ", CalcSlBuy(), " ", CalcTpBuy());
            ticket = OrderSend (TradeSymbol, OP_BUYSTOP, LotMM, CalcOpenBuy(), Slippage, CalcSlBuy(), CalcTpBuy(),
		                          "TSD BuyStop", MAGICNUM, 0, Blue);
		   }
		   
         if ( Direction == -1 && okSell ) {
            MarkTrade();
	         //Print ("TSD SellStop: ", TradeSymbol, " ", LotMM, " ", CalcOpenSell(), " ", CalcSlSell(), " ", CalcTpSell());
	         ticket = OrderSend (TradeSymbol, OP_SELLSTOP, LotMM, CalcOpenSell(), Slippage, CalcSlSell(), CalcTpSell(),
	                             "TSD SellStop", MAGICNUM, 0, Red);
	      }
 
	      if ( ticket == -1 )  ReportError ();
	      if ( ticket != 0 )   return(0);
	   } // End of TradesThisSymbol < 1
		
      /////////////////////////////////////////////////
      //  Pending Order Management
      /////////////////////////////////////////////////
      for (i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != TradeSymbol || OrderMagicNumber() != MAGICNUM)  continue;

         if ( OrderType () == OP_BUYSTOP ) {
            if ( Direction != 1 ) {
               MarkTrade();
               OrderDelete ( OrderTicket() );
               return(0);
            }
            if ( iHigh(TradeSymbol, PeriodTrade, 1) < iHigh(TradeSymbol, PeriodTrade, 2) &&
                 ( !CompareDoublesMy (CalcSlBuy(), OrderStopLoss()) ||
                   !CompareDoublesMy (CalcTpBuy(), OrderTakeProfit()) ) ) {
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
            if ( iLow(TradeSymbol, PeriodTrade, 1) > iLow(TradeSymbol, PeriodTrade, 2) &&
                 ( !CompareDoublesMy (CalcSlSell(), OrderStopLoss()) ||
                   !CompareDoublesMy (CalcTpSell(), OrderTakeProfit()) ) ) {
               MarkTrade();
     		      OrderModify (OrderTicket(), CalcOpenSell(), CalcSlSell(), CalcTpSell(), 0, Gold);
               return(0);
            }
         }
      } // End of Pending Order Management
   } //new day bar
   
   /////////////////////////////////////////////////
   //  Stop Loss Management
   /////////////////////////////////////////////////
   if ( TrailingStop > 0 ) {
      for (i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != TradeSymbol || OrderMagicNumber() != MAGICNUM )  continue;
         if ( TrailStop (i, TrailingStop) )  return(0);
      }
   }

   return(0);
}
//+------------------------------------------------------------------+
/*
double CalcOpenBuy  () { return (dMax (iHigh(TradeSymbol, PeriodTrade, 1) + 1*SPoint + Spread,
                                       Ask + 16*SPoint)); }
double CalcOpenSell () { return (dMin (iLow(TradeSymbol, PeriodTrade, 1) - 1*SPoint,
                                       Bid - 16*SPoint)); }
*/

double CalcOpenBuy() { return (iHigh(TradeSymbol, PeriodTrade, 1) + 1*SPoint + Spread); }
double CalcOpenSell() { return (iLow(TradeSymbol, PeriodTrade, 1) - 1*SPoint); }

double CalcSlBuy() { return (iLow(TradeSymbol, PeriodTrade, 1) - 1*SPoint); }
double CalcSlSell() { return (iHigh(TradeSymbol, PeriodTrade, 1) + 1*SPoint + Spread); }

double CalcTpBuy() {
   double PriceOpen = CalcOpenBuy(), SL = CalcSlBuy();
   return (PriceOpen + dMax(TakeProfit*SPoint, (PriceOpen - SL)*2));
}

double CalcTpSell  () {
   double PriceOpen = CalcOpenSell(), SL = CalcSlSell();
   return (PriceOpen - dMax(TakeProfit*SPoint, (SL - PriceOpen)*2));
}
//+------------------------------------------------------------------+
bool TrailStop (int i, int TrailingStop) {
   double StopLoss;

   if ( OrderType() == OP_BUY ) {
      if ( Bid < OrderOpenPrice () )  return;
      StopLoss = iLow(TradeSymbol, PeriodTrailing, Lowest (TradeSymbol, PeriodTrailing, MODE_LOW, CandlesTrailing+1, 0)) - 1*Point;
      StopLoss = dMin (Bid-TrailingStop*SPoint, StopLoss);
      if ( StopLoss > OrderStopLoss() ) {
         MarkTrade();
         OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, White);
         return(true);
      }
   }
   
   if ( OrderType() == OP_SELL ) {
      if ( Ask > OrderOpenPrice () )  return;
      StopLoss = iHigh(TradeSymbol, PeriodTrailing, Highest (TradeSymbol, PeriodTrailing, MODE_HIGH, CandlesTrailing+1, 0)) + 1*Point
                 + Spread;
      StopLoss = dMax (Ask+TrailingStop*SPoint, StopLoss);
      if ( StopLoss < OrderStopLoss() ) {
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
	   Previous  = iMACD (TradeSymbol, PeriodDirection, 5, 34, 5, PRICE_MEDIAN, MODE_MAIN, 1);
	   Previous2 = iMACD (TradeSymbol, PeriodDirection, 5, 34, 5, PRICE_MEDIAN, MODE_MAIN, 2);
	}
	else {
	   Previous  = iOsMA (TradeSymbol, PeriodDirection, 5, 34, 5, PRICE_MEDIAN, 1);
	   Previous2 = iOsMA (TradeSymbol, PeriodDirection, 5, 34, 5, PRICE_MEDIAN, 2);
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
         if ( OrderSymbol() == TradeSymbol && OrderMagicNumber() == MAGICNUM)
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

bool CompareDoublesMy(double number1,double number2)
  {
   if( NormalizeDouble(number1,4)-NormalizeDouble(number2,4)==0.0 ) return(true);
   else return(false);
  }

bool IsNewDayBar() {
   if ( TimeDay(Time[0]) != TimeDay(Time[1]) )
      return (true);
   else
      return (false);
}