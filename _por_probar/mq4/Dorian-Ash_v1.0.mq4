//+---------------------------------------------------------------------+
//|									  Dorian-Ash_v1.0.mq4 (Version 1.0) |
//|												 Dorian Cox / Ash Woods |
//|												  ashwoods155@yahoo.com |
//|																		|
//+---------------------------------------------------------------------+
#property copyright "AshWoods"
#property link	  "http://www.nowebsite.com"

extern int		TakeProfit = 20;		// Your Take Profit value in pips
extern int		StopLoss = 20;			// Your Stop Loss value in pips
extern int		TrailingStop = 10;		// Trailing Stop distance in pips; disabled if 0
extern int		Slippage = 1;			// Maximum Slippage allowed when entering trade
extern int		QtyCandles = 5;			// Number of Previous Candles to check for determining High & Lows
extern int		PipToMove = 5;			// The number of pips price must move for breakout trade
extern bool		UseBreakEven = TRUE;	// If true, EA will move S/L to "breakeven" value when ahead
extern int		BEPips = 0;				// [Break Even] Pips in profit which EA will Move SL to BE+1 after that
extern bool		UseMM = true;			// If true, use Money Management to determine lot size
extern int		RiskPercent = 3;		// % of margin to risk if using Money Management
extern double	Lots = 0.1;				// Default lots to use (if NOT using Money Management)
extern string	TradeLog = "DorianAsh";	// Name of file created to log progress of the EA
extern int		Magic = 8675309;		// "Magic Number" used to identify trades



double	high, 
		low, 
		spread, 
		highOpen, 
		lowOpen, 
		highSL, 
		lowSL, 
		highTP, 
		lowTP;
		
string 	filename;


//+------------------------------------------------------------------+
//| expert initialization function								   |
//+------------------------------------------------------------------+
int init()
{
	ObjectsDeleteAll();
	return(0);
}

//+------------------------------------------------------------------+
//| expert deinitialization function								 |
//+------------------------------------------------------------------+
int deinit()
{
	Comment("");
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


void OpenBuyStop()
{
	int ticket, err, tries;
	tries = 0;
	if (!GlobalVariableCheck("InTrade")) 
	{
		while (tries < 3)
		{
			GlobalVariableSet("InTrade", CurTime());  // set lock indicator
			ticket = OrderSend(Symbol(), OP_BUYSTOP, LotsOptimized(), highOpen, Slippage,
								highSL, highTP, "EA Order", Magic, 0, Red);
			Write("In function OpenBuyStop OrderSend Executed, ticket = "+ticket);
			GlobalVariableDel("InTrade");   // clear lock indicator
			if (ticket <= 0) 
			{
				Write("Error Occured : "+ErrorDescription(GetLastError())+" BuyStop @ "+highOpen+" SL @ "+highSL+" TakeProfit @"+highTP);
				tries++;
			} 
			else 
				tries = 3;
		}
	}
}
  
void OpenSellStop()
 {
	int ticket, err, tries;
	tries = 0;
	if (!GlobalVariableCheck("InTrade")) 
	{
		while (tries < 3)
		{
			GlobalVariableSet("InTrade", CurTime());  // set lock indicator
			ticket = OrderSend(Symbol(), OP_SELLSTOP, LotsOptimized(), lowOpen, Slippage,
								lowSL, lowTP, "EA Order", Magic, 0, Red);
			Write("In function OpenSellStop OrderSend Executed, ticket = "+ticket);
			GlobalVariableDel("InTrade");   // clear lock indicator
			if(ticket <= 0) 
			{
				Write("Error Occured : "+ErrorDescription(GetLastError())+" BuyStop @ "+lowOpen+" SL @ "+lowSL+" TakeProfit @"+lowTP);
				tries++;
			} 
			else 
				tries = 3;
		}
	}
}


void SetBreakEven(int byPips)
{
	for (int i=0; i < OrdersTotal(); i++) 
	{
		OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
		
		// only look if mygrid and symbol...
		if (OrderSymbol() == Symbol() && (OrderMagicNumber() == Magic))  
		{
			double buyBreakEven = OrderOpenPrice() + byPips * Point;
			double sellBreakEven = OrderOpenPrice() - byPips * Point;
			if (OrderType() == OP_BUY && Bid > buyBreakEven && OrderStopLoss() != buyBreakEven) 
			{
				Write("Moving StopLoss of Buy Order to BreakEven: "+buyBreakEven);
				Comment("Moving StopLoss of Buy Order to BreakEven: ", buyBreakEven);
				OrderModify(OrderTicket(), OrderOpenPrice(), buyBreakEven, OrderTakeProfit(), Green);
			}
			
			if (OrderType() == OP_SELL && Ask < sellBreakEven && OrderStopLoss() != sellBreakEven) 
			{ 
				Write("Moving StopLoss of Sell Order to BreakEven:"+sellBreakEven);
				Comment("Moving StopLoss of Sell Order to BreakEven:", sellBreakEven);
				OrderModify(OrderTicket(), OrderOpenPrice(), sellBreakEven, OrderTakeProfit(), Red);
			}
		}
	}
}


void DoTrail()
{
	for (int i=0; i < OrdersTotal(); i++) 
	{
		OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
		
		// only look if mygrid and symbol...
		if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)  
		{		  
			if (OrderType() == OP_BUY &&
				Bid - OrderOpenPrice() > TrailingStop * Point &&
				(OrderStopLoss() < Bid - TrailingStop * Point) || OrderStopLoss() == 0)
			{
				OrderModify(OrderTicket(), OrderOpenPrice(), 
							Bid - TrailingStop * Point, OrderTakeProfit(), 0, Green);
				return(0);
			}

			if (OrderType() == OP_SELL &&
				OrderOpenPrice() - Ask > TrailingStop * Point &&
				(OrderStopLoss() > Ask + TrailingStop * Point) || OrderStopLoss() == 0)
			{
				OrderModify(OrderTicket(), OrderOpenPrice(), 
							Ask + TrailingStop * Point, OrderTakeProfit(), 0 ,Red);
				return(0);
			}
		}
	}
}


void DeletePendingOrders()
{
	int myTkt;
	int myTyp;
	bool result = FALSE;

	Comment("\nDeletePendingOrders: OrdersTotal = ", OrdersTotal());
	for (int i=OrdersTotal(); i > 0; i--)
	{
		OrderSelect(i, SELECT_BY_POS);

		myTkt = OrderTicket();
		myTyp = OrderType();

		switch( myTyp )
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

		if (result == FALSE)
		{
			Alert( "Order ", myTkt, " failed to close. Error:", GetLastError() );
			Print( "Order ", myTkt, " failed to close. Error:", GetLastError() );
			Sleep(3000);
		}  

		Sleep(1000);
	}
}


int Write(string str)
{
	int handle;

	handle = FileOpen(filename, FILE_READ|FILE_WRITE|FILE_CSV, "/t");
	FileSeek(handle, 0, SEEK_END);	  
	FileWrite(handle, str + " Time " + TimeToStr(CurTime(), TIME_DATE|TIME_SECONDS));
	FileClose(handle);
}


bool NotDuringTradingTimes()
{
	// DORIAN: I did not complete this, so for now, it runs at all times
	return (FALSE);
}


//+------------------------------------------------------------------+
//| expert start function											 |
//+------------------------------------------------------------------+
int start()
{
	static int prevBars = -1;

//	static int count = 0;	
//	count++;
//	Comment("Run #", count, "\n");

	// Make sure this parameter is set to a sensible value	
	if (QtyCandles < 1)
	{
		Alert("QtyCandles MUST be more than zero");
		return(0);
	}
	
	// If user has set trading times, then see if now in in range
	// The reason we check DoAlways is that if the user defined a
	// specific time to check after news, there is no need to also 
	// check trading hours, it should override it.
	if (NotDuringTradingTimes())
		return(0);
		
	// Assemble the log file name
	filename = TradeLog + "_" + Symbol() + "_" + Month() + "-" + Day() + ".log";

	// If using break even, and BEPips == 0, use spread instead
	// SetBreakEven will check to see if the price has moved in 
	// favour of our trade.  If it has, by a certain amount, it 
	// will change the S/L value to a "breakeven" point, where 
	// you will be assured to at least not lose money on the trade.
	// By default it's a true breakeven: the spread.  Or it can 
	// be set, using "BEPips".
	if (UseBreakEven)
		if (BEPips == 0)
			SetBreakEven(Ask - Bid);
		else
			SetBreakEven(BEPips);

	// Self-explanatory: If using a trailing stop, adjust it		
	if (TrailingStop > 0) 
		DoTrail();


	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// At this point, everything else we do is related to placing orders, and 
	// we only want to place orders at the start of a new candle.  
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

	// Delete any orders still pending from the last candle
	DeletePendingOrders();

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
	spread 		= Ask - Bid;
	highOpen 	= high + PipToMove * Point;
	lowOpen 	= low - PipToMove * Point;
	highSL 		= highOpen - StopLoss * Point;
	lowSL 		= lowOpen + StopLoss * Point;
	highTP 		= highOpen + spread + TakeProfit * Point;
	lowTP 		= lowOpen - spread - TakeProfit * Point;

	// Print out all settings, etc, in a comment
	Comment("\nDorian-Ash v1.0 By AshWoods155\n\nHigh @ ", high, "  Buy Order @ ", highOpen, "  Stoploss @ ", highSL, "  TakeProfit @ ", highTP, 
			"\nLow @ ", low, "  Sell Order @ ", lowOpen, "  StopLoss @ ", lowSL, "  TakeProfit @ ", lowTP, 
			"\nQtyCandles : ", QtyCandles, "  Use BreakEven : ", UseBreakEven, "  BEPips : ", BEPips, 
			"\nUse Money Management : ", UseMM, "  RiskPercent: ", RiskPercent, "  Lots : ", LotsOptimized());
	
	// Open the Buy Stop and the Sell Stop for this candle
	Write("Opening BuyStop & SellStop");
	OpenBuyStop();
	OpenSellStop();
	
	return(0);
}

  
//+------------------------------------------------------------------+
//| return error description										 |
//+------------------------------------------------------------------+
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



