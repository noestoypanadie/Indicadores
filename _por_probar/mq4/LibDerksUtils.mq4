//=============================================================================
//                            LibDerksUtils.mq4
//
//                      Copyright © 2006, Derk Wehler 
//                          ashwoods155@yahoo.com
//=============================================================================
#property copyright "Copyright © 2006, Derk Wehler"
#property link      "no site"
#property library

// DerksUtils included only for #defines at top
#include <LibDerksUtils.mqh>
#include <LibOrderReliable_v1_1_2.mqh>


//----------------------------------------------------------------------------
//                     Money Management Helper Functions
//----------------------------------------------------------------------------
double LotsOptimized(double TradeSizePercent, double Lots, double MaxLots)
{
	double lot = Lots;

	lot = NormalizeDouble(MathFloor(AccountFreeMargin() * TradeSizePercent / 10000) / 10, 1);

	// Check if mini or standard Account

	if (lot < 1.0) lot = 1.0;
	if (lot > MaxLots) lot = MaxLots;

	return(lot);
} 


double GetLots(bool MoneyManagement, double TradeSizePercent, double Lots, double MaxLots)
{
	double lot;

	lot = Lots;
	if (MoneyManagement)
	 	lot = LotsOptimized(TradeSizePercent, Lots, MaxLots);
	 	
	if (lot >= 1.0) 
		lot = MathFloor(lot); 
	else 
		lot = 1.0;
		
	return(lot);
}


//----------------------------------------------------------------------------
//                       Magic Number Helper Functions
//----------------------------------------------------------------------------
int TimeFrameConst2Val(int TF_In_Minutes) 
{
	switch(TF_In_Minutes) 
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


int SymbolConst2Val(string symbol) 
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


//----------------------------------------------------------------------------
//                              Trading Functions
//----------------------------------------------------------------------------

//=============================================================================
//
// PURPOSE:
//     Return the number of open positions (buy, sell, or both)
//
// PARAMETERS:
//      magic:  The magic number to match
//        dir:  The direction sought; either 
//              OP_BOTH (-1) for both
//                   -or-
//              OP_BUY for ALL pending buys
//                   -or-
//              OP_SELL for ALL pending sells
//
// RETURN VALUE:
//              The number of open orders as requested
//
//=============================================================================
int NumOpenPositions(int magic, int dir)
{
	int cnt;
	int NumBuyTrades, NumSellTrades;   // Number of buy and sell trades in this symbol

	NumBuyTrades = 0;
	NumSellTrades = 0;
	for (cnt=OrdersTotal()-1; cnt >= 0; cnt--)
	{
		OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
		if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) 
			continue;
		
		// We only want open orders; if we wanted pending too, we could use OrdersTotal()
		if (OrderType() != OP_BUY && OrderType() != OP_SELL)
			continue;

		if (OrderType() == OP_BUY)
			NumBuyTrades++;
		else if (OrderType() == OP_SELL)
			NumSellTrades++;
	}
	
	if (dir == OP_BOTH)
		return (NumBuyTrades + NumSellTrades);
	else if (dir == OP_BUY)
		return (NumBuyTrades);
	else if (dir == OP_SELL)
		return (NumSellTrades);
}


//=============================================================================
//
// PURPOSE:
//     Return the number of pending orders (buy, sell, or both)
//
// PARAMETERS:
//      magic:	The magic number to match
//        dir:  The direction sought; either 
//              ALL_PENDING (-1) for all:
//                  -or-
//              ALL_PENDING_BUYS (-2) for all pending Buy orders:
//                  -or-
//              ALL_PENDING_SELLS (-3) for all pending Sell orders:
//                  -or-
//              OP_BUYSTOP for all pending Buy Stops
//                  -or-
//              OP_BUYLIMIT for all pending Buy Limits
//                  -or-
//              OP_SELLSTOP for all pending Sell Stops
//                  -or-
//              OP_SELLLIMIT for all pending Sell Limits
//
// RETURN VALUE:
//              The number of pending orders as requested
//
//=============================================================================
int NumPendingOrders(int magic, int dir)
{
	int cnt;
	int NumBuyStops = 0;
	int NumSellStops = 0;
	int NumBuyLimits = 0;
	int NumSellLimits = 0; 

	for (cnt=OrdersTotal()-1; cnt >= 0; cnt--)
	{
		OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
		if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) 
			continue;
		
		int type = OrderType();
		
		if (type == OP_BUY || type == OP_SELL)
			continue;

		else if (type == OP_BUYSTOP)
			NumBuyStops++;
		else if (type == OP_SELLSTOP)
			NumSellStops++;
		else if (type == OP_BUYLIMIT)
			NumBuyLimits++;
		else if (type == OP_SELLLIMIT)
			NumSellLimits++;
	}

	if (dir == ALL_PENDING)
		return (NumBuyStops + NumSellStops + NumBuyLimits + NumSellLimits);
	else if (dir == ALL_PENDING_BUYS)
		return (NumBuyStops + NumBuyLimits);
	else if (dir == ALL_PENDING_SELLS)
		return (NumSellStops +  NumSellLimits);
	else if (dir == OP_BUYSTOP)
		return (NumBuyStops);
	else if (dir == OP_BUYLIMIT)
		return (NumBuyLimits);
	else if (dir == OP_SELLSTOP)
		return (NumSellStops);
	else if (dir == OP_SELLLIMIT)
		return (NumSellLimits);
}


//=============================================================================
//
// PURPOSE:
//     Close all pending orders, with the following restrictions.
//
// PARAMETERS:
//      magic:	The magic number to match
//        dir:  The direction sought; either 
//              ALL_PENDING (-1) for all:
//                  -or-
//              ALL_PENDING_BUYS (-2) for all pending Buy orders:
//                  -or-
//              ALL_PENDING_SELLS (-3) for all pending Sell orders:
//                  -or-
//              OP_BUYSTOP for all pending Buy Stops
//                  -or-
//              OP_BUYLIMIT for all pending Buy Limits
//                  -or-
//              OP_SELLSTOP for all pending Sell Stops
//                  -or-
//              OP_SELLLIMIT for all pending Sell Limits
//
// RETURN VALUE:
//              The number of orders deleted
//
//=============================================================================
int ClosePendingOrders(int magic, int dir)
{
	int retVal = 0;
	
	for (int cnt=OrdersTotal()-1; cnt >= 0; cnt--)
	{
		OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
		if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) 
			continue;
		
		int type = OrderType();
		
		if (type == OP_BUY || type == OP_SELL)
			continue;
		else if (type == OP_BUYSTOP && dir != OP_BUYSTOP && 
			dir != ALL_PENDING_BUYS && dir != ALL_PENDING)
			continue;
		else if (type == OP_SELLSTOP && dir != OP_SELLSTOP && 
			dir != ALL_PENDING_SELLS && dir != ALL_PENDING)
			continue;
		else if (type == OP_BUYLIMIT && dir != OP_BUYLIMIT && 
			dir != ALL_PENDING_BUYS && dir != ALL_PENDING)
			continue;
		else if (type == OP_SELLLIMIT && dir != OP_SELLLIMIT && 
			dir != ALL_PENDING_SELLS && dir != ALL_PENDING)
			continue;
			
		// So now we have filtered out the undesirables.
		// If we got this far, we need to delete the order
		bool ret = OrderDeleteReliable(OrderTicket());
		if (ret)
			retVal++;
	}
	return (retVal);
}


//=============================================================================
//
// PURPOSE:
//     Given a matrix of orders (using arrays), loop through current open and 
//     pending orders, placing any orders from the matrix not already there.
//
// PARAMETERS:
//      magic:  The magic number to match
//        dir:  An array containing the order type for each entry in the 
//              matrix (e.g. OP_BUY, OP_SELLSTOP)
//      price:  An array containing the order price for each entry in the 
//              matrix 
//        sls:  An array contianing the initial stop loss to set for each 
//              entry in the matrix
//        tps:  An array contianing the initial take profit to set for 
//              each entry in the matrix
//
// RETURN VALUE:
//              The number of orders successfully placed
//
//=============================================================================
int ReplenishOrders(int magic, int dir[], double price[], double sls[], double tps[])
{
	// Not yet implemented; this function will 
	// make it easier to set up grid-type EAs
}


//=============================================================================
//
// PURPOSE:
//	    Loops through all open orders and adjust trailing stop accordingly
//
//
// PARAMETERS:
//
//      TrailType:	The type of trailing stop to use:
//
//          1:  Moves the stoploss without delay (pip for pip).
//
//          2:  Waits for price to move the amount of the trailing stop
//              (TrailPips) before moving stop loss then moves like type 1.
//              The only difference between this and type 1 is that this 
//              one will not initially move the SL until the it would be
//              set at breakeven.
//
//          3:  Uses up to 3 levels for trailing stop
//                  Level 1 Move stop to 1st level
//                  Level 2 Move stop to 2nd level
//                  Level 3 Trail like type 1 by fixed amount other than 1
//
//          4:  Ratchets the SL up:
//                  e.g. if SL = 20, and open price is 1.2400, then
//                  when price reaches 1.2420, SL is set to 1.2400; when 
//                  it gets to 1.2440, SL is moved to 1.2420, etc
//
//      TrailPips:  The trailing stop value in pips
//
//      Magic:      The magic number to check
//
//      Dir:        "Buy":  Modify only OP_BUY orders
//                  "Sell": Modify only OP_SELL orders
//                  "Both": Modify both OP_BUY & OP_SELL orders
//
//
//    The remainder of the params are used only for TrailType 3:
//
//      FirstMove:      When the trade is in profit this much...
//      FirstStopLoss:  Move SL this far from the current price
//
//      SecondMove:     When the trade is in profit this much...
//      SecondStopLoss: Move SL this far from the current price
//
//      ThirdMove:      When the trade is in profit this much...
//      TrailPips:      Use this value & trail like TrailType 1
//
//
// RETURN VALUE:
//
//      True: 	All OrderModify calls returned successfully
//      False:	One or more calls failed
//
//
// Calling examples:
//
//      AdjTrailOnAllOrders( 3, 30, 19999, OP_SELL, 30, 20, 40, 30, 60);
//      AdjTrailOnAllOrders( 1, 25, MagicNumber, OP_BOTH, 0, 0, 0, 0, 0);
//
// NOTE: OP_BOTH is defined in LibDerkUtils.mqh, as well as some others
//
// For Copy & Paste usage:
//      AdjTrailOnAllOrders(type, pips, magic, dir, Mv1, SL1, Mv2, SL2, Mv3);
//=============================================================================
bool AdjTrailOnAllOrders(
	int TrailType, 
	int	TrailPips,
	int	Magic,
	int Direction,
	int FirstMove, 
	int FirstStopLoss, 
	int SecondMove, 
	int SecondStopLoss, 
	int ThirdMove)
{
	double 	SL = 0;
	double 	openPrice, curSL, curTP;
	bool 	retValue = true;
	int		ticket;

	double TrailVal = TrailPips* Point;
	double dFirstMove = FirstMove * Point;
	double dFirstStopLoss = FirstStopLoss * Point;
	double dSecondMove = SecondMove * Point;
	double dSecondStopLoss = SecondStopLoss * Point;
	double dThirdMove = ThirdMove * Point;

	for (int cnt=OrdersTotal()-1; cnt >= 0; cnt--)
	{
		int type = OrderType();
		OrderSelect(cnt, SELECT_BY_POS);
		if (OrderSymbol() != Symbol() || 
			OrderMagicNumber() != Magic || 
			(type != OP_BUY && type != OP_SELL))
			continue;
			
		curSL = OrderStopLoss();
		curTP = OrderTakeProfit();
		ticket = OrderTicket();
		openPrice = OrderOpenPrice();
		
		if (type == OP_BUY && (Direction == OP_BUY || Direction == OP_BOTH))
		{
			switch (TrailType)
			{
				case 1: 
					if (curSL < Bid - TrailVal) // was: (Bid - curSL > TrailVal), which is the same
						if (!OrderModifyReliable(ticket, openPrice, Bid - TrailVal, curTP, 0, Aqua))
							retValue = false;
					break;
				
				case 2: 
					if (Bid - openPrice > TrailVal && (curSL < Bid - TrailVal || curSL == 0))
						if (!OrderModifyReliable(ticket, openPrice, Bid - TrailVal, curTP, 0, Aqua))
						{
							retValue = false;
							Comment("OrderModifyReliable Failed, Price = ", openPrice, "   SL = ", Bid - TrailVal);
							Print("OrderModifyReliable Failed, Price = ", openPrice, "   SL = ", Bid - TrailVal);
						}
					break;

				case 3: 
					if (Bid - openPrice > dFirstMove)
					{
						SL = openPrice + dFirstMove - dFirstStopLoss;
						if (curSL < SL)
							if (!OrderModifyReliable(ticket, openPrice, SL, curTP, 0, Aqua))
								retValue = false;
					}

					if (Bid - openPrice > dSecondMove)
					{
						SL = openPrice + dSecondMove - dSecondStopLoss;
						if (curSL < SL)
							if (!OrderModifyReliable(ticket, openPrice, SL, curTP, 0, Aqua))
								retValue = false;
					}
	  
	 				if (Bid - openPrice > dThirdMove)
	 				{
		 				SL = Bid  - TrailVal;
	 					if (curSL < SL)
							if (!OrderModifyReliable(ticket, openPrice, SL, curTP, 0, Aqua))
								retValue = false;
	 				}
	 				break;

				case 4: 
					if (Bid - curSL > TrailVal * 2)
						if (!OrderModifyReliable(ticket, openPrice, Bid - TrailVal, curTP, 0, Aqua))
							retValue = false;
					break;
			}
		}

		if (type == OP_SELL && (Direction == OP_SELL || Direction == OP_BOTH))
		{
			switch (TrailType)
			{
				case 1: 
					if (curSL > Ask + TrailVal) // was: (curSL - Ask > TrailVal), which is the same
						if (!OrderModifyReliable(ticket, openPrice, Ask + TrailVal, curTP, 0, Aqua))
							retValue = false;
					break;
				
				case 2: 
					if (openPrice - Ask > TrailVal && (curSL > Ask + TrailVal || curSL == 0))
						if (!OrderModifyReliable(ticket, openPrice, Ask + TrailVal, curTP, 0, Aqua))
						{
							retValue = false;
							Comment("OrderModifyReliable Failed, Price = ", openPrice, "   SL = ", Ask + TrailVal);
							Print("OrderModifyReliable Failed, Price = ", openPrice, "   SL = ", Ask + TrailVal);
						}
					break;

				case 3: 
					if (openPrice - Ask > dFirstMove)
					{
						SL = openPrice - dFirstMove + dFirstStopLoss;
						if (curSL > SL)
							if (!OrderModifyReliable(ticket, openPrice, SL, curTP, 0, Aqua))
								retValue = false;
					}
				
					if (openPrice - Ask > dSecondMove)
					{
						SL = openPrice - dSecondMove + dSecondStopLoss;
						if (curSL > SL)
							if (!OrderModifyReliable(ticket, openPrice, SL, curTP, 0, Aqua))
								retValue = false;
					}
				
					if (openPrice - Ask > dThirdMove)
					{
						SL = Ask + TrailVal;					
						if (curSL > SL)
							if (!OrderModifyReliable(ticket, openPrice, SL, curTP, 0, Aqua))
								retValue = false;
					}
					break;

				case 4: 
					if (curSL - Ask > TrailVal * 2)
						if (!OrderModifyReliable(ticket, openPrice, Ask + TrailVal, curTP, 0, Aqua))
							retValue = false;
					break;
		 	}
	 	}
	}
	return(retValue);
}


//----------------------------------------------------------------------------
//                          Error Handling Functions
//----------------------------------------------------------------------------
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

