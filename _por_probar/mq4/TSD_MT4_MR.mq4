//+------------------------------------------------------------------+
//|                                                   TSD_MT4_MR.mq4 |
//|                           Copyright ® 2005 Bob O'Brien / Barcode |
//|                          TSD v1.2 rewritten to MQL4 by Mindaugas |
//+------------------------------------------------------------------+
#property copyright "Copyright ® 2005 Bob O'Brien / Barcode"

//---- input parameters
extern int WilliamsP =  24;
extern int WilliamsL = -75;
extern int WilliamsH = -25;

#include <stdlib.mqh>

int Slippage = 5, LotsMax = 50;
int MM = 0, Leverage = 1, MarginChoke = 500;
int TakeProfit = 100, TrailingStop = 60;

double Spread, Lots = 0.1;

int PeriodMacd = PERIOD_W1, PeriodWilliams = PERIOD_D1, PeriodTrailing = PERIOD_H4, CandlesTrailing = 3;

//+------------------------------------------------------------------+

int init()   { return(0); }
int deinit() { return(0); }

//+------------------------------------------------------------------+

int start() {
   int TradesThisSymbol, Direction;
   int i, ticket;
   
   bool WilliamsSell, WilliamsBuy;
   
   double PriceOpen, Buy_Sl, Buy_Tp, LotMM;
   double WilliamsValue;
   
   datetime NewBar = 0;
   
   Spread = Ask - Bid;
   TradesThisSymbol = TotalTradesThisSymbol ();
   Direction = MacdDirection (PeriodMacd);
   WilliamsValue = iWPR(NULL, PeriodWilliams, WilliamsP, 1);
   
//   Comment ("\nMACD Direction: ", Direction, "\niWPR: ", NormalizeDouble(WilliamsValue, 1));
   
   /////////////////////////////////////////////////
   //  Process the next bar details
   /////////////////////////////////////////////////
   if ( NewBar != iTime (NULL, PeriodWilliams, 0) ) {
      NewBar = iTime (NULL, PeriodWilliams, 0);
      
      if ( TradesThisSymbol < 1 ) {

         LotMM = CalcMM(MM);
         if ( LotMM < 0 )  return(0);

  	   	WilliamsSell = WilliamsValue > WilliamsL;
		   WilliamsBuy  = WilliamsValue < WilliamsH;

         /////////////////////////////////////////////////
         //  New Orders Management
         /////////////////////////////////////////////////
		
         ticket = 0;

         if ( Direction == 1 && WilliamsBuy )
		      ticket = OrderSend (Symbol(), OP_BUYSTOP, LotMM, CalcOpenBuy(), Slippage, CalcSlBuy(), CalcTpBuy(),
		                          "TSD BuyStop", 0, 0, Blue);
		   
         if ( Direction == -1 && WilliamsSell )
		      ticket = OrderSend (Symbol(), OP_SELLSTOP, LotMM, CalcOpenSell(), Slippage, CalcSlSell(), CalcTpSell(),
		                          "TSD SellStop", 0, 0, Red);
 
		   if ( ticket == -1 )  ReportError ();
		   if ( ticket != 0 )   return(0);
		} // End of TradesThisSymbol < 1
		
      /////////////////////////////////////////////////
      //  Pending Order Management
      /////////////////////////////////////////////////
      for (i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != Symbol () )  continue;

         if ( OrderType () == OP_BUYSTOP ) {
            if ( Direction != 1 ) {
               OrderDelete ( OrderTicket() );
               return(0);
            }
            if ( iHigh(NULL, PeriodWilliams, 1) < iHigh(NULL, PeriodWilliams, 2) &&
                 ( !CompareDoubles (CalcSlBuy(), OrderStopLoss()) ||
                   !CompareDoubles (CalcTpBuy(), OrderTakeProfit()) ) ) {
        		   OrderModify (OrderTicket(), CalcOpenBuy(), CalcSlBuy(), CalcTpBuy(), 0, White);
               return(0);
            }
         }

         if ( OrderType () == OP_SELLSTOP ) {
            if ( Direction != -1 ) {
               OrderDelete ( OrderTicket() );
               return(0);
            }
            if ( iLow(NULL, PeriodWilliams, 1) > iLow(NULL, PeriodWilliams, 2) &&
                 ( !CompareDoubles (CalcSlSell(), OrderStopLoss()) ||
                   !CompareDoubles (CalcTpSell(), OrderTakeProfit()) ) ) {
        		   OrderModify (OrderTicket(), CalcOpenSell(), CalcSlSell(), CalcTpSell(), 0, Gold);
               return(0);
            }
         }
      } // End of Pending Order Management
   } // End of Process Next Bar Details
   
   /////////////////////////////////////////////////
   //  Stop Loss Management
   /////////////////////////////////////////////////
   if ( TradesThisSymbol > 0 && TrailingStop > 0 ) {
      for (i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != Symbol () )  continue;
         TrailStop (i, TrailingStop);
      }
   }

   return(0);
}

//+------------------------------------------------------------------+
double CalcOpenBuy  () { return (dMax (iHigh(NULL, PeriodWilliams, 1) + 1*Point + Spread, Ask + 16*Point)); }
double CalcOpenSell () { return (dMin (iLow(NULL, PeriodWilliams, 1) - 1*Point,  Bid - 16*Point)); }
double CalcSlBuy  () { return (iLow (NULL, PeriodWilliams, 1) - 1*Point); }
double CalcSlSell () { return (iHigh(NULL, PeriodWilliams, 1) + 1*Point + Spread); }
double CalcTpBuy  () {
   double PriceOpen = CalcOpenBuy(), SL = CalcSlBuy();
   return (PriceOpen + dMax(TakeProfit*Point, (PriceOpen - SL)*2));
}
double CalcTpSell  () {
   double PriceOpen = CalcOpenSell(), SL = CalcSlSell();
   return (PriceOpen - dMax(TakeProfit*Point, (SL - PriceOpen)*2));
}
//+------------------------------------------------------------------+
void TrailStop (int i, int TrailingStop) {
   double StopLoss;

   if ( OrderType() == OP_BUY ) {
      if ( Bid < OrderOpenPrice () )  return;
      StopLoss = iLow(NULL, PeriodTrailing, Lowest (NULL, PeriodTrailing, MODE_LOW, CandlesTrailing+1, 0)) - 1*Point;
      if ( StopLoss > OrderStopLoss() )
         OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, White);
   }
   
   if ( OrderType() == OP_SELL ) {
      if ( Ask < OrderOpenPrice () )  return;
      StopLoss = iHigh(NULL, PeriodTrailing, Highest (NULL, PeriodTrailing, MODE_HIGH, CandlesTrailing+1, 0)) + 1*Point
                 + Spread;
      if ( StopLoss < OrderStopLoss() )
         OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, Gold);
   }
}
//+------------------------------------------------------------------+
int MacdDirection (int PeriodMacd) {
   int Direction = 0;
   double MacdPrevious, MacdPrevious2;

	MacdPrevious  = iMACD (NULL, PeriodMacd, 5, 34, 5, PRICE_MEDIAN, MODE_MAIN, 1);
	MacdPrevious2 = iMACD (NULL, PeriodMacd, 5, 34, 5, PRICE_MEDIAN, MODE_MAIN, 2);

   if ( MacdPrevious > MacdPrevious2 )
      Direction = 1;
   if ( MacdPrevious < MacdPrevious2 )
      Direction = -1;
   return (Direction);
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
int TotalTradesThisSymbol () {
   int i, TradesThisSymbol = 0;
   
   for (i = 0; i < OrdersTotal(); i++)
      if ( OrderSelect (i, SELECT_BY_POS) )
         if ( OrderSymbol() == Symbol () )
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

