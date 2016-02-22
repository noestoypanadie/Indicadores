//=============================================================================
//									  Dorian-Ash_v1.0.mq4 (Version 1.0)
//												 Dorian Cox / Ash Woods
//												  ashwoods155@yahoo.com
//
//=============================================================================
#property copyright "AshWoods"
#property link	  "http://www.nowebsite.com"

#include <OrderReliable_V0_2_5.mqh>

#define NUM_TRIES 	10

extern int		TakeProfit = 50;		// Your Take Profit value in pips
extern int		StopLoss = 10;			// Your Stop Loss value in pips
extern int		TrailingStop = 20;		// Trailing Stop distance in pips; disabled if 0
extern int		Slippage = 3;			// Maximum Slippage allowed when entering trade
extern int		QtyCandles = 1;			// Number of Previous Candles to check for determining High & Lows
extern int		PipToMove = 5;			// The number of pips price must move for breakout trade
extern bool		UseBreakEven = TRUE;	// If true, EA will move S/L to "breakeven" value when ahead
//extern int	BEPips = 0;				// [Break Even] Pips.  If zero, it will use spread
extern bool		UseMM = FALSE;			// If true, use Money Management to determine lot size
extern int		RiskPercent = 3;		// % of margin to risk if using Money Management
extern double	Lots = 0.1;				// Default lots to use (if NOT using Money Management)
extern string	TradeLog = "DorianAsh";	// Name of file created to log progress of the EA
//extern int	Magic = 8675309;		// "Magic Number" used to identify trades

int 	MagicNumber;

double	high, low, spread;
				
string 	filename;

static bool		BreakEvenSet = FALSE;
static int 		OO_Ticket = -1;				// (OO = Open Order) Ticket Number
static int		OO_Type = -1;				// Type of trade (e.g. OP_BUY)
static double	OO_Lots = -1;				// Number of lots
static double	OO_OpenPrice = -1;			// Open price of the trade
static double	OO_StopLoss = -1;			// StopLoss value
static double	OO_BuyStop = -1;			// Price to enter a buy trade
static double	OO_SellStop = -1;			// Price to enter a sell trade
static double	OO_BuyTP = -1;				// Take Profit value for buy
static double	OO_SellTP = -1;				// Take profit value for sell


//=============================================================================
// expert initialization function
//=============================================================================
int init()
{
	MagicNumber = 4000 + func_Symbol2Val(Symbol()) * 100 + func_TimeFrame_Const2Val(Period());
	ObjectsDeleteAll();
	return(0);
}

//=============================================================================
// expert deinitialization function
//=============================================================================
int deinit()
{
	ObjectsDeleteAll();
	return(0);
}

double LotsOptimized()
{
	double lot = Lots;
	
	//---- select lot size
	if (UseMM) 
		lot = NormalizeDouble(MathFloor(AccountFreeMargin() * RiskPercent / 100) / 100, 1);
   
	// lot at this point is number of standard lots
	return(lot);
} 


//=============================================================================
// Count the number of open buy and sell positions
//=============================================================================
int CountOpenPositions()
{
	int cnt, NumPositions;
	int NumBuyTrades, NumSellTrades;   // Number of buy and sell trades in this symbol

	NumBuyTrades = 0;
	NumSellTrades = 0;
	for (cnt=OrdersTotal()-1; cnt>=0; cnt--)
	{
		OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
		if (OrderSymbol() != Symbol()) 
			continue;
		if (OrderMagicNumber() != MagicNumber)  
			continue;

		if (OrderType() == OP_BUY)
			NumBuyTrades++;
		if (OrderType() == OP_SELL) 
			NumSellTrades++;             

		if (OrderType() == OP_BUY || OrderType() == OP_SELL)
		{
			OO_Ticket = OrderTicket();
			OO_Type = OrderType();
			OO_OpenPrice = OrderOpenPrice();
			OO_Lots = OrderLots();
		}
	}
	NumPositions = NumBuyTrades + NumSellTrades;
	return (NumPositions);
}

/*
//=============================================================================
// Open a buy stop position using global vars set in start function
//=============================================================================
void OpenBuyStop()
{
	int ticket, err, tries;
	tries = 0;
	if (!GlobalVariableCheck("InTrade")) 
	{
		while (tries < NUM_TRIES)
		{
			GlobalVariableSet("InTrade", CurTime());  // set lock indicator
			ticket = OrderSendReliable(Symbol(), OP_BUYSTOP, LotsOptimized(), highOpen, Slippage,
								0, highTP, "EA Order", MagicNumber, 0, CLR_NONE);
			Write("In function OpenBuyStop OrderSend Executed, ticket = " + ticket);
			GlobalVariableDel("InTrade");   // clear lock indicator
			if (ticket <= 0) 
			{
				Comment("Error Occured : " + ErrorDescription(GetLastError()) + " BuyStop @ " + highOpen + " TakeProfit @" + highTP);
				Write("Error Occured : " + ErrorDescription(GetLastError()) + " BuyStop @ " + highOpen + " TakeProfit @" + highTP);
				tries++;
			} 
			else 
				tries = NUM_TRIES;
		} 
	}
}
  

//=============================================================================
// Open a sell stop position using global vars set in start function
//=============================================================================
void OpenSellStop()
{
	int ticket, err, tries;
	tries = 0;
	if (!GlobalVariableCheck("InTrade")) 
	{
		while (tries < NUM_TRIES)
		{
			GlobalVariableSet("InTrade", CurTime());  // set lock indicator
			ticket = OrderSendReliable(Symbol(), OP_SELLSTOP, LotsOptimized(), lowOpen, Slippage,
								0, lowTP, "EA Order", MagicNumber, 0, CLR_NONE);
			Write("In function OpenSellStop OrderSend Executed, ticket = " + ticket);
			GlobalVariableDel("InTrade");   // clear lock indicator
			if (ticket <= 0) 
			{
				Comment("Error Occured : " + ErrorDescription(GetLastError()) + " BuyStop @ " + lowOpen + " TakeProfit @" + lowTP);
				Write("Error Occured : " + ErrorDescription(GetLastError()) + " BuyStop @ " + lowOpen + " TakeProfit @" + lowTP);
				tries++;
			} 
			else 
				tries = NUM_TRIES;
		}
	}
}
*/


//=============================================================================
// Open a buy position using global vars set in start function
//=============================================================================
void OpenBuy()
{
	int ticket, err;
//	int tries;
//	tries = 0;

	Print("=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=");
	Print("ENTERED OpenBuy()... Now attempting to buy @ ", OO_BuyStop);
//	if (!GlobalVariableCheck("InTrade")) 
//	{
//		while (tries < NUM_TRIES)
//		{
//			GlobalVariableSet("InTrade", CurTime());  // set lock indicator
			
			ticket = OrderSendReliable(Symbol(), OP_BUY, LotsOptimized(), OO_BuyStop, Slippage,
								0, OO_BuyTP, "EA Order", MagicNumber, 0, CLR_NONE);
								
			Print("In function OpenBuy OrderSend Executed, ticket = ", ticket);
			Write("In function OpenBuy OrderSend Executed, ticket = " + ticket);
			
//			GlobalVariableDel("InTrade");   // clear lock indicator
			
			if (ticket <= 0) 
			{
				Print("OpenBuy() - Error Occured : " + ErrorDescription(GetLastError()) + " Buy @ " + OO_BuyStop + " TakeProfit @" + OO_BuyTP);
				Write("OpenBuy() - Error Occured : " + ErrorDescription(GetLastError()) + " Buy @ " + OO_BuyStop + " TakeProfit @" + OO_BuyTP);
//				tries++;
			} 
//			else 
//				tries = NUM_TRIES;
//		} 
//	}
	Print("=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=");
}
  

//=============================================================================
// Open a sell position using global vars set in start function
//=============================================================================
void OpenSell()
{
	int ticket, err;
//	int tries;
//	tries = 0;

	Print("=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=");
	Print("ENTERED OpenSell()... Now attempting to sell @ ", OO_SellStop);
//	if (!GlobalVariableCheck("InTrade")) 
//	{
//		while (tries < NUM_TRIES)
//		{
//			GlobalVariableSet("InTrade", CurTime());  // set lock indicator
			
			ticket = OrderSendReliable(Symbol(), OP_SELL, LotsOptimized(), OO_SellStop, Slippage,
								0, OO_SellTP, "EA Order", MagicNumber, 0, CLR_NONE);
								
			Print("In function OpenSell OrderSend Executed, ticket = ", ticket);
			Write("In function OpenSell OrderSend Executed, ticket = " + ticket);
			
//			GlobalVariableDel("InTrade");   // clear lock indicator
			
			if (ticket <= 0) 
			{
				Print("OpenSell() - Error Occured : " + ErrorDescription(GetLastError()) + " BuyStop @ " + OO_SellStop + " TakeProfit @" + OO_SellTP);
				Write("OpenSell() - Error Occured : " + ErrorDescription(GetLastError()) + " BuyStop @ " + OO_SellStop + " TakeProfit @" + OO_SellTP);
//				tries++;
			} 
//			else 
//				tries = NUM_TRIES;
//		}
//	}
	Print("=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=");
}


//=============================================================================
// Close an open order; try three times in case of failure
//=============================================================================
bool CloseOpenOrder(int ticket, double lots, double price, int slippage)
{
//	int  tries;
	bool CloseSuccessful = FALSE;
	
	Print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
	Print("ENTERED CloseOpenOrder()... Now attempting to close @ ", price);
//	tries = 0;
//	if (!GlobalVariableCheck("ClosingTrade")) 
//	{
//		while (tries < NUM_TRIES)
//		{
//			GlobalVariableSet("ClosingTrade", CurTime());  // set lock indicator
			
			CloseSuccessful = OrderCloseReliable(ticket, lots, price, slippage);
			
			Write("In function CloseOpenOrder OrderClose executed....");
//			GlobalVariableDel("ClosingTrade");   // clear lock indicator
			
			if (!CloseSuccessful) 
			{
				int errNum = GetLastError();
				Comment("Error #" + errNum + " occured, CloseOpenOrder: " + ErrorDescription(errNum));
				Write("....Error #" + errNum + " occured, CloseOpenOrder: " + ErrorDescription(errNum));
//				tries++;
			} 
			else 
			{
//				tries = NUM_TRIES;
				Write("....Close successful");
			}
//		}
//	}
	Print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
	return (CloseSuccessful);
}


//=============================================================================
// Handle tracking of the initial stoploss value
//=============================================================================
void DoInitialStopLoss()
{
	if (OO_StopLoss == -1 && StopLoss != 0)
	{
		double PipValue = spread + StopLoss * Point;
		if (OO_Type == OP_BUY)
			PipValue = -PipValue;
		
		Print("=======================================================================");
		Print("Ticket = ", OO_Ticket, "   Price = ", OO_OpenPrice, "   S/L = ", OO_StopLoss);
		OO_StopLoss = OO_OpenPrice + PipValue;
		Print("DoInitialStopLoss: Setting S/L = ", OO_StopLoss);
		Print("=======================================================================");
	}
}


//=============================================================================
// Handle tracking of the breakeven stoploss value
//=============================================================================
void DoBreakEven(int byPips)
{
	if (BreakEvenSet)
		return;

	double PipValue = byPips * Point;
	double CurPrice = Bid;
	if (OO_Type == OP_SELL)
	{
		PipValue = -PipValue;
		CurPrice = Ask;
	}
		
	double BreakEvenPrice = OO_OpenPrice + PipValue;
	
	// Set the static global OO_StopLoss to the breakeven, if applicable
	if ((OO_Type == OP_SELL && CurPrice < BreakEvenPrice && BreakEvenPrice < OO_StopLoss) ||
		(OO_Type == OP_BUY && CurPrice > BreakEvenPrice && BreakEvenPrice > OO_StopLoss))
	{
		Print("=======================================================================");
		Print("Ticket = ", OO_Ticket, "   Price = ", OO_OpenPrice, "   S/L = ", OO_StopLoss);
		OO_StopLoss = BreakEvenPrice;
		BreakEvenSet = TRUE;
		Print("DoBreakEven: Setting S/L = ", OO_StopLoss);
		Print("=======================================================================");
	}
}


//=============================================================================
// Handle tracking of the trailing stoploss value
//=============================================================================
void DoTrail()
{
	if (OO_Type == OP_BUY &&
		Bid - OO_OpenPrice > TrailingStop * Point &&
		(OO_StopLoss < Bid - TrailingStop * Point || OO_StopLoss == -1))
	{
		Print("=======================================================================");
		Print("Ticket = ", OO_Ticket, "   Price = ", OO_OpenPrice, "   S/L = ", OO_StopLoss);
		OO_StopLoss = Bid - TrailingStop * Point;
		Print("DoTrail: Setting S/L = ", OO_StopLoss);
		Print("=======================================================================");
		return(0);
	}

	if (OO_Type == OP_SELL &&
		OO_OpenPrice - Ask > TrailingStop * Point &&
		(OO_StopLoss > Ask + TrailingStop * Point || OO_StopLoss == -1))
	{
		Print("=======================================================================");
		Print("Ticket = ", OO_Ticket, "   Price = ", OO_OpenPrice, "   S/L = ", OO_StopLoss);
		OO_StopLoss = Ask + TrailingStop * Point;
		Print("DoTrail: Setting S/L = ", OO_StopLoss);
		Print("=======================================================================");
		return(0);
	}
}

/*
//=============================================================================
// Delete all open pending orders for this currency (that we have placed)
//=============================================================================
void DeletePendingOrders()
{
	int myTkt;
	int myTyp;
	bool result = FALSE;

//	Comment("\nDeletePendingOrders: OrdersTotal = ", OrdersTotal());
	Write("DeletePendingOrders: OrdersTotal = " + OrdersTotal());
	for (int i=OrdersTotal()-1; i >= 0; i--)
	{
		int tries = 0;
		while (tries < NUM_TRIES)
		{		
//			Comment("\nSelecting Order Posiiton # ", i);
//			Write("Selecting Order Posiiton # " + i);
			OrderSelect(i, SELECT_BY_POS);
		
			if (OrderSymbol() != Symbol())
				break;

			myTkt = OrderTicket();
			myTyp = OrderType();

			Comment("\nOrder Ticket # ", myTkt);
			Write("Order Ticket # " + myTkt);
			switch (myTyp)
			{
				// Close pending orders
				case OP_BUYLIMIT:
				case OP_BUYSTOP:
				case OP_SELLLIMIT:
				case OP_SELLSTOP:
					result = OrderDelete(myTkt);
					break;
				
				default:	// Do nothing with open orders
					break;
			}

			if (result == 0)
			{
//				Comment("\nOrder Delete RETURNED FALSE");
				Write("Order Delete RETURNED FALSE");
				Print( "Order ", myTkt, " failed to close. Error:", GetLastError() );
				tries++;
			}
			else
				tries = NUM_TRIES;
		}
	}
}
*/


int Write(string str)
{
	int handle, err;

	handle = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_CSV); //, "/t");
	
	if (handle < 0)
	{
		err = GetLastError();
    	Print("FileOpen error(",err,"): ", ErrorDescription(err));
		handle = FileOpen(filename, FILE_WRITE|FILE_CSV); //, "/t");
	}
		
	if (handle < 0)
	{
		err = GetLastError();
    	Print("FileOpen error(",err,"): ", ErrorDescription(err));
		return(0);
	}
		
	FileSeek(handle, 0, SEEK_END);	  
	FileWrite(handle, str + " Time " + TimeToStr(CurTime(), TIME_DATE|TIME_SECONDS));
	FileClose(handle);
}


bool NotDuringTradingTimes()
{
	// DORIAN: I did not complete this, so for now, it runs at all times
	return (FALSE);
}


//=============================================================================
//=============================================================================
// expert start function
//=============================================================================
//=============================================================================
int start()
{
	static int prevBars = -1;

	static int count = 0;	
	count++;
	Comment("Run #", count, "\n");

	spread = Ask - Bid;
		
	// Assemble the log file name
	filename = TradeLog + "_" + StringSubstr(Symbol(), 0, 6) + "_" + Month() + "-" + Day() + ".log";

	// Make sure this parameter is set to a sensible value	
	if (QtyCandles < 1)
	{
		Alert("QtyCandles MUST be more than zero");
		Write("QtyCandles MUST be more than zero");
		return(0);
	}
	
//	double StopLevel = MarketInfo(Symbol(),MODE_STOPLEVEL);
//	if (StopLevel > PipToMove)
//	{
//		Alert("Brokerage minimum stop-order level is: ", StopLevel, ". Please change PipToMove.");
//		Write("Brokerage minimum stop-order level is: " + StopLevel + ". Please change PipToMove.");
//		return(0);
//	}
	
	// If user has set trading times, then see if now in in range
	// The reason we check DoAlways is that if the user defined a
	// specific time to check after news, there is no need to also 
	// check trading hours, it should override it.
	if (NotDuringTradingTimes())
		return(0);
		
	
	// Check if we are in any open positions
	int positions = CountOpenPositions();
	if (positions > 1)
	{
		Alert("ERROR! EA has managed to open more than one position!");
		Write("ERROR! EA has managed to open more than one position!");
		return(0);
	}
	
	// If we are NOT in trade, check to see if we should be
	else if (positions == 0)
	{
		// Open a Buy or Sell for this candle only if it has hit the price
		if (OO_BuyStop <= Ask && OO_BuyStop > 0)
			OpenBuy();
			
		else if (OO_SellStop >= Bid && OO_BuyStop > 0)
			OpenSell();
	}
			
	// If we are in an open position...
	else if (positions == 1)
	{
		// Now check whether or not to close the order
		if ((OO_Type == OP_BUY && Bid <= OO_StopLoss) ||
			(OO_Type == OP_SELL && Ask >= OO_StopLoss))
		{
			if (CloseOpenOrder(OO_Ticket, OO_Lots, OO_StopLoss, 0))
			{
				OO_Ticket = -1;
				OO_Type = -1;
				OO_OpenPrice = -1;
				OO_Lots = -1;
				OO_BuyStop = -1;
				OO_SellStop = -1;
				OO_BuyTP = -1;
				OO_SellTP = -1;
			}
			else
			{
				if (OO_Type == OP_BUY)
					Print("  ******* BUY ORDER #", OO_Ticket, " FAILED TO CLOSE: bid = ", Bid, "   S/L = ", OO_StopLoss);
				else
					Print("  ******* SELL ORDER #", OO_Ticket, " FAILED TO CLOSE: ask = ", Ask, "   S/L = ", OO_StopLoss);
			}
		}
		else
		{
			// Set initial stopless
			DoInitialStopLoss();
		
			// SetBreakEven will check to see if the price has moved in 
			// favour of our trade.  If it has, by a certain amount, it 
			// will change the S/L value to a "breakeven" point, where 
			// you will be assured to at least not lose money on the trade.
			if (UseBreakEven)
				DoBreakEven(spread);

			// If using a trailing stop, adjust as neccessary
			if (TrailingStop > 0) 
				DoTrail();
		}
	}



	// At least for now, we only want to be in one open position at a time.
	// So if we still have one open position, no need to go further 
	if (1 == CountOpenPositions())
		return(0);

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// At this point, everything else we do is related to placing orders, and 
	// we only want to place orders at the start of a new candle.  
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	// Return if this is NOT a new candle
	int curBars = Bars;
	if (prevBars == -1)
		prevBars = curBars;

	if (curBars == prevBars)
		return(0);

	prevBars = curBars;



	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// From here on, code should only execute once, at the start of a candle
	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	// In order to keep each currency this EA may be running on from trying to 
	// cancel and replace orders at the same time, pause a different span 
	// depending on the currency
	int timing = func_Symbol2Val(Symbol()) * 100;
	Sleep(timing);
	
	//// No longer neccessary because we do not place Stop orders
	// Delete any orders still pending from the last candle
	//	DeletePendingOrders();

	// Initialize high and low
	high = iHigh(NULL, 0, 0);
	low = iLow(NULL, 0, 0);

	// Find the highest high and lowest low for 'QtyCandles' candles
	for (int i=1; i <= QtyCandles; i++) 
		if (iHigh(NULL, 0, i) > high) 
			high = iHigh(NULL, 0, i);
			
	for (i=1; i <= QtyCandles; i++) 
		if (iLow(NULL, 0, i) < low) 
			low = iLow(NULL, 0, i);

	// Set some global variables used in various places
	OO_BuyTP	= 0;
	OO_SellTP	= 0;
		
	// Take into account the spread for high only 
	// (because we assume that the prices graphed are Ask and we have to buy at Bid(?))
	OO_BuyStop 	= high + spread + PipToMove * Point;
	OO_SellStop = low - PipToMove * Point;

	// First, delete old buy and sell stop lines
	ObjectDelete("BuyStop");
	ObjectDelete("SellStop");
		
	// Then, create lines at potential buy and sell stops for visual confirmation
	ObjectCreate("BuyStop", 1, 0, 0, OO_BuyStop, 0, OO_BuyStop);
	ObjectSet("BuyStop", OBJPROP_COLOR, Lime);
	ObjectSet("BuyStop", OBJPROP_STYLE, STYLE_DASH);
	ObjectCreate("SellStop", 1, 0, 0, OO_SellStop, 0, OO_SellStop);
	ObjectSet("SellStop", OBJPROP_COLOR, Red);
	ObjectSet("SellStop", OBJPROP_STYLE, STYLE_DASH);
	
	Print("/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\");
	Print("    OO_BuyStop == ", OO_BuyStop, "      OO_SellStop == ", OO_SellStop);
	Print("\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/");
	Comment("\n\nBuyStop = ", OO_BuyStop, "      SellStop = ", OO_SellStop);
	Sleep(2000);
	
	if (TakeProfit != 0)
	{
		OO_BuyTP 	= OO_BuyStop + TakeProfit * Point;
		OO_SellTP 	= OO_SellStop - spread - TakeProfit * Point;
	}
	
	// Print out all settings, etc, in a comment
	Comment("\n\n\nDorian-Ash v1.0 By AshWoods155\n\nHigh @ ", high, "  Buy Order @ ", OO_BuyStop, "  TakeProfit @ ", OO_BuyTP, 
			"\nLow @ ", low, "  Sell Order @ ", OO_SellStop, "  TakeProfit @ ", OO_SellTP, 
			"\nQtyCandles : ", QtyCandles, "  Use BreakEven : ", UseBreakEven, "  spread : ", spread, 
			"\nUse Money Management : ", UseMM, "  RiskPercent: ", RiskPercent, "  Lots : ", LotsOptimized());
	
	return(0);
}

  
//=============================================================================
// return error description
//=============================================================================
string ErrorDescription(int error_code)
{
	string error_string;

	switch (error_code)
	{
		//---- codes returned from trade server
		case 0:
		case 1:   error_string = "no error";													break;
		case 2:   error_string = "common error";												break;
		case 3:   error_string = "invalid trade parameters";									break;
		case 4:   error_string = "trade server is busy";										break;
		case 5:   error_string = "old version of the client terminal";							break;
		case 6:   error_string = "no connection with trade server";								break;
		case 7:   error_string = "not enough rights";											break;
		case 8:   error_string = "too frequent requests";										break;
		case 9:   error_string = "malfunctional trade operation";								break;
		case 64:  error_string = "account disabled";											break;
		case 65:  error_string = "invalid account";												break;
		case 128: error_string = "trade timeout";												break;
		case 129: error_string = "invalid price";												break;
		case 130: error_string = "invalid stops";												break;
		case 131: error_string = "invalid trade volume";										break;
		case 132: error_string = "market is closed";											break;
		case 133: error_string = "trade is disabled";											break;
		case 134: error_string = "not enough money";											break;
		case 135: error_string = "price changed";												break;
		case 136: error_string = "off quotes";													break;
		case 137: error_string = "broker is busy";												break;
		case 138: error_string = "requote";														break;
		case 139: error_string = "order is locked";												break;
		case 140: error_string = "long positions only allowed";									break;
		case 141: error_string = "too many requests";											break;
		case 145: error_string = "modification denied because order too close to market";		break;
		case 146: error_string = "trade context is busy";										break;
		//---- mql4 errors
		case 4000: error_string = "no error";													break;
		case 4001: error_string = "wrong function pointer";										break;
		case 4002: error_string = "array index is out of range";								break;
		case 4003: error_string = "no memory for function call stack";							break;
		case 4004: error_string = "recursive stack overflow";									break;
		case 4005: error_string = "not enough stack for parameter";								break;
		case 4006: error_string = "no memory for parameter string";								break;
		case 4007: error_string = "no memory for temp string";									break;
		case 4008: error_string = "not initialized string";										break;
		case 4009: error_string = "not initialized string in array";							break;
		case 4010: error_string = "no memory for array\' string";								break;
		case 4011: error_string = "too long string";											break;
		case 4012: error_string = "remainder from zero divide";									break;
		case 4013: error_string = "zero divide";												break;
		case 4014: error_string = "unknown command";											break;
		case 4015: error_string = "wrong jump (never generated error)";							break;
		case 4016: error_string = "not initialized array";										break;
		case 4017: error_string = "dll calls are not allowed";									break;
		case 4018: error_string = "cannot load library";										break;
		case 4019: error_string = "cannot call function";										break;
		case 4020: error_string = "expert function calls are not allowed";						break;
		case 4021: error_string = "not enough memory for temp string returned from function";	break;
		case 4022: error_string = "system is busy (never generated error)";						break;
		case 4050: error_string = "invalid function parameters count";							break;
		case 4051: error_string = "invalid function parameter value";							break;
		case 4052: error_string = "string function internal error";								break;
		case 4053: error_string = "some array error";											break;
		case 4054: error_string = "incorrect series array using";								break;
		case 4055: error_string = "custom indicator error";										break;
		case 4056: error_string = "arrays are incompatible";									break;
		case 4057: error_string = "global variables processing error";							break;
		case 4058: error_string = "global variable not found";									break;
		case 4059: error_string = "function is not allowed in testing mode";					break;
		case 4060: error_string = "function is not confirmed";									break;
		case 4061: error_string = "send mail error";											break;
		case 4062: error_string = "string parameter expected";									break;
		case 4063: error_string = "integer parameter expected";									break;
		case 4064: error_string = "double parameter expected";									break;
		case 4065: error_string = "array as parameter expected";								break;
		case 4066: error_string = "requested history data in update state";						break;
		case 4099: error_string = "end of file";												break;
		case 4100: error_string = "some file error";											break;
		case 4101: error_string = "wrong file name";											break;
		case 4102: error_string = "too many opened files";										break;
		case 4103: error_string = "cannot open file";											break;
		case 4104: error_string = "incompatible access to a file";								break;
		case 4105: error_string = "no order selected";											break;
		case 4106: error_string = "unknown symbol";												break;
		case 4107: error_string = "invalid price parameter for trade function";					break;
		case 4108: error_string = "invalid ticket";												break;
		case 4109: error_string = "trade is not allowed";										break;
		case 4110: error_string = "longs are not allowed";										break;
		case 4111: error_string = "shorts are not allowed";										break;
		case 4200: error_string = "object is already exist";									break;
		case 4201: error_string = "unknown object property";									break;
		case 4202: error_string = "object is not exist";										break;
		case 4203: error_string = "unknown object type";										break;
		case 4204: error_string = "no object name";												break;
		case 4205: error_string = "object coordinates error";									break;
		case 4206: error_string = "no specified subwindow";										break;
		default:   error_string = "unknown error";
	}

	return(error_string);
}  


//=============================================================================
// Two functions used to calculate unique magic number
//=============================================================================
int func_TimeFrame_Const2Val(int Constant ) 
{
	switch(Constant) 
	{
		case 1:
			return(1);	// M1
		case 5:
			return(2);	// M5
		case 15:
			return(3);	// M15
		case 30:
			return(4);	// M30
		case 60:
			return(5);	// H1
		case 240:
			return(6);	// H4
		case 1440:
			return(7);	// D1
		case 10080:
			return(8);	// W1
		case 43200:
			return(9);	// MN
	}
}


int func_Symbol2Val(string symbol) 
{
	// Handle problem of trailing chars on mini accounts.
	string mySymbol = StringSubstr(symbol,0,6); 
	
	if (mySymbol=="AUDCAD") return(1);
	if (mySymbol=="AUDJPY") return(2);
	if (mySymbol=="AUDNZD") return(3);
	if (mySymbol=="AUDUSD") return(4);
	if (mySymbol=="CHFJPY") return(5);
	if (mySymbol=="EURAUD") return(6);
	if (mySymbol=="EURCAD") return(7);
	if (mySymbol=="EURCHF") return(8);
	if (mySymbol=="EURGBP") return(9);
	if (mySymbol=="EURJPY") return(10);
	if (mySymbol=="EURUSD") return(11);
	if (mySymbol=="GBPCHF") return(12);
	if (mySymbol=="GBPJPY") return(13);
	if (mySymbol=="GBPUSD") return(14);
	if (mySymbol=="NZDUSD") return(15);
	if (mySymbol=="USDCAD") return(16);
	if (mySymbol=="USDCHF") return(17);
	if (mySymbol=="USDJPY") return(18);
	return(19);
}



