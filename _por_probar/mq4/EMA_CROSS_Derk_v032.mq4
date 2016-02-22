//=============================================================================
//												EMA_CROSS_Derk_v03.mq4
//												Originally by: Coders Guru
//												http://www.forex-tsd.com
//
// Modifications
// -----------------------------------
// 7/21/2006	Added money management
// Robert Hill
//				Added calculation of MagicNumber
//
//				Added EMA Angle filter
//
//
// 7/19/2006	Reformatted code, added comments
// Derk Wehler
//				Added HandleTrailingStop() function and changed start()
//				function to use it.
//
//				Added use of OrderReliable library
//
//				Added extern TrailingStopType (which should always be
//				set to either 1 or 2), for use with new HandleTrailingStop()
//
// 				Added UsePrevClose parameter, and usage in FreshCross()
//
//
// 6/4/2006		Fixed bugs and added exit on fresh cross option
// Robert Hill
//				Added use of TakeProfit of 0
//
//				Modified for trade on open of closed candle
//
//				Added Trades in this symbol and MagicNumber check
//				to allow trades on different currencies at same time
//
//=============================================================================

#property copyright "Coders Guru"
#property link		"http://www.forex-tsd.com"

#include <OrderReliable_V0_2_5.mqh>

// MOMEY MANAGEMENT:
// Change 'MoneyManagement' to false if you want to shutdown money management controls, in 
// which case the EA will only open 'Lots' number of lots, regardless of equity.
extern bool 	MoneyManagement 	= true;		
extern double 	TradeSizePercent 	= 10;		// Percent of equity you wish to risk.
extern double	Lots				= 1;		// Starting lots value
extern double 	MaxLots 			= 100.0;	// Maximum amount of lots it will trade using MM

extern double	TakeProfit			= 130;
extern double	StopLoss 			= 100;
extern bool 	UseTrailingStop 	= true;
extern int		TrailingStopType 	= 2;
extern double	TrailingStop		= 40;
extern double 	FirstMove 			= 20;       // Type 3  first level pip gain
extern double 	FirstStopLoss 		= 15;       // Move Stop to Breakeven
extern double 	SecondMove 			= 30;       // Type 3 second level pip gain
extern double 	SecondStopLoss 		= 20;       // Move stop to lock is profit
extern double 	ThirdMove 			= 40;		// Type 3 third level pip gain
extern double 	TrailingStop3 		= 20;       // Move stop and trail from there

extern int 		ShortEma 			= 10;	// 17?
extern int 		LongEma 			= 80;	// 40?
extern bool 	ExitOnCross 		= false;
extern bool		UsePrevClose		= true;
extern int 		SignalCandle 		= 1;
extern string	ExpertName			= "EMA_CROSS_";
extern int		MagicCode 			= 5;

// EMA Angle parameters
extern bool 	UseEMAAngle 		= true;
extern double 	AngleTreshold		= 0.2;
extern int 		StartEMAShift		= 3;
extern int 		EndEMAShift			= 0;



int      MagicNumber;	// Magic number of the trades. must be unique to identify
string   nameEA;		// Identifies the expert

//=============================================================================
// expert initialization function
//=============================================================================
int init()
{
	MagicNumber = MagicCode * 1000 + func_Symbol2Val(Symbol()) * 100 + func_TimeFrame_Const2Val(Period());
	nameEA = ExpertName + Symbol() + "_" + func_TimeFrame_Val2String(func_TimeFrame_Const2Val(Period()));

	return(0);
}


//=============================================================================
// expert deinitialization function
//=============================================================================
int deinit()
{
	return(0);
}

//===================================================================
//							EMA_Angle.mq4 
//							    jpkfox
//
//	You can use this indicator to measure when the EMA angle is
//	"near zero". AngleTreshold determines when the angle for the
//	EMA is "about zero": when the value is between
//	[-AngleTreshold, AngleTreshold] (or when the histogram is red).
//
//	PARAMETERS:
//
//		EMAPeriod: 		EMA period
//
//		AngleTreshold: 	The angle value is "about zero" when 
//						it is between the values 
//						[-AngleTreshold, AngleTreshold].
//
//		StartEMAShift: 	The starting point to calculate the 
//						angle. This is a shift value to the 
//						left from the observation point. Should 
//						be StartEMAShift > EndEMAShift.
//
//		EndEMAShift: 	The ending point to calculate the
//						angle. This is a shift value to the 
//						left from the observation point. Should 
//						be StartEMAShift > EndEMAShift.
//
//	RETURN VALUE:
//
//  	 1:		Angle up is OK
//  	-1:		Angle down is OK
//		 0:		Angle is too flat
//
//===================================================================
int EMA_Angle(int EMAPeriod)
{
	double	fEndMA, fStartMA;
	double	fAngle, mFactor, dFactor;
	double	angle;
	int 	ShiftDif;
	string	Sym;

	dFactor = 2 * 3.14159 / 180.0;
	mFactor = 10000.0;
	Sym = StringSubstr(Symbol(), 3, 3);
	if (Sym == "JPY") 
		mFactor = 100.0;
		
	ShiftDif = StartEMAShift - EndEMAShift;
	mFactor /= ShiftDif; 

	fEndMA = iMA(NULL, 0, EMAPeriod, 0, MODE_EMA, PRICE_MEDIAN, SignalCandle + EndEMAShift);
	fStartMA = iMA(NULL, 0, EMAPeriod, 0, MODE_EMA, PRICE_MEDIAN, SignalCandle + StartEMAShift);
	
	// 10000.0 : Multiply by 10000 so that the fAngle is not too small
	// for the indicator Window.
	fAngle = mFactor * (fEndMA - fStartMA)/2.0;
//	fAngle = MathArctan(fAngle)/dFactor;

      
	if (fAngle > AngleTreshold)
	 	return(1);

	else if (fAngle < -AngleTreshold)
 		return(-1);

	return(0);
}

//=============================================================================
//
//								FreshCross()
//
//	Function to tell whether or not there is a "fresh" cross.  
//
//	RETURN VALUE:
//
//		1:	If the short MA line is above the long, and was below on the  
//			previous candle
//
//		2:	If the short MA line is below the long, and was above on the  
//			previous candle
//
//		0:	If the the EMA lines of the current and previous candle are 
//			in the same position relative to each other
//
//=============================================================================
int FreshCross()
{
	double SEma, LEma,SEmaP, LEmaP;
	int emaAngle;
	
	SEma = iMA(NULL, 0, ShortEma, 0, MODE_EMA, PRICE_CLOSE, SignalCandle);
	LEma = iMA(NULL, 0, LongEma, 0, MODE_EMA, PRICE_CLOSE, SignalCandle);
	
	SEmaP = iMA(NULL, 0, ShortEma, 0, MODE_EMA, PRICE_CLOSE, SignalCandle+1);
	LEmaP = iMA(NULL, 0, LongEma, 0, MODE_EMA, PRICE_CLOSE, SignalCandle+1);

	emaAngle = EMA_Angle(LongEma);
	
	// Don't work in the first load, wait for the first cross!
	if (UsePrevClose)	// use cross plus previous candle's close
	{
		if (SEma > LEma && SEmaP < LEmaP && Close[SignalCandle+1] > SEmaP && 
			Ask > SEmaP && (emaAngle == 1 || !UseEMAAngle)) 
			return(1); //up
			
		if (SEma < LEma && SEmaP > LEmaP && Close[SignalCandle+1] < SEmaP && 
			Bid < SEmaP && (emaAngle == -1 || !UseEMAAngle)) 
			return(2); //down
	}
	else	// Normal method --just use cross
	{	
		if (SEma > LEma && SEmaP < LEmaP && (emaAngle == 1 || !UseEMAAngle)) 
			return(1); // up

		if (SEma < LEma && SEmaP > LEmaP && (emaAngle == -1 || !UseEMAAngle)) 
			return(2); // down
	}

	return (0); // has not changed
}

//=============================================================================
//
//								CheckOpenTrades()
//
//	RETURN VALUE:
//
//		The number of trades this EA has currently open
//
//=============================================================================
int CheckOpenTrades()
{
	int cnt;
	int NumTrades;	// Number of buy and sell trades in this symbol
	
	NumTrades = 0;
	for (cnt=OrdersTotal()-1; cnt>=0; cnt--)
	{
		OrderSelect (cnt, SELECT_BY_POS, MODE_TRADES);
		if (OrderSymbol() != Symbol()) 
			continue;
			
		if (OrderMagicNumber() != MagicNumber)
			continue;
		
		if (OrderType() == OP_BUY)  
			NumTrades++;
			
		if (OrderType() == OP_SELL) 
			NumTrades++;
				 
	}
	return (NumTrades);
}


//=============================================================================
// expert start function
//=============================================================================
int start()
{
	int cnt, ticket, total, isCrossed;
	double lotMM;
	double TP;	
	
	if (Bars < 100)
	{
		Print("bars less than 100");
		return(0);  
	}


	
	isCrossed = FreshCross();
	
	total = CheckOpenTrades();
	if (total < 1) 
	{
		lotMM = GetLots();
		if (isCrossed == 1)
		{
			TP = 0;
			if (TakeProfit > 0) 
				TP = Ask + TakeProfit * Point;
				
			ticket = OrderSendReliable(Symbol(), OP_BUY, lotMM, Ask, 3, Ask - StopLoss*Point, 
										TP, nameEA, MagicNumber, 0, Green);
			if (ticket > 0)
			{
				if (OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
					Print("BUY order opened : ", OrderOpenPrice());
			}
			else 
				Print("Error opening BUY order : ", GetLastError()); 
				
			return(0);
		}
		
		if (isCrossed == 2)
		{
			TP = 0;
			if (TakeProfit > 0) 
				TP = Bid - TakeProfit * Point;
			ticket = OrderSendReliable(Symbol(), OP_SELL, lotMM, Bid, 3, Bid + StopLoss*Point,
										TP, nameEA, MagicNumber, 0, Red);
			if (ticket > 0)
			{
				if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) 
					Print("SELL order opened : ", OrderOpenPrice());
			}
			else 
				Print("Error opening SELL order : ", GetLastError()); 
				
			return(0);
		}
		return(0);
	} 
	  
	for (cnt=0; cnt < total; cnt++)
	{
		OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
		
		if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
			continue;

		// Should it be closed because of a cross reversal?
		bool result = false;
		if (ExitOnCross && isCrossed != 0)
		{
			// We have a long position open and MAs have switched
			if (OrderType() == OP_BUY && isCrossed == 2)
			{		  
				// Close position
				result = OrderCloseReliable(OrderTicket(), OrderLots(), Bid, 3, Violet); 
				if (!result)
				{
					Print("In OP_BUY, ExitOnCross=TRUE && isCrossed=2, but FAILED to exit.");
					Alert("In OP_BUY, ExitOnCross=TRUE && isCrossed=2, but FAILED to exit.");
				}
			}
		
			// We have a short position open and MAs have switched
			else if (OrderType() == OP_SELL && isCrossed == 1)
			{				
				// Close position
				result = OrderCloseReliable(OrderTicket(), OrderLots(), Ask, 3, Violet);
				if (!result)
				{
					Print("In OP_SELL, ExitOnCross=TRUE && isCrossed=1, but FAILED to exit.");
					Alert("In OP_SELL, ExitOnCross=TRUE && isCrossed=1, but FAILED to exit.");
				}
			}
		}
		
		if (!result && UseTrailingStop)	// Handle mods to trailing stop
			HandleTrailingStop(OrderType(), OrderTicket(), OrderOpenPrice(), OrderStopLoss(), OrderTakeProfit());
	}

	return(0);
}


//=============================================================================
//
// 							HandleTrailingStop()
//
//	Type 1 moves the stoploss without delay.
//
//	Type 2 waits for price to move the amount of the trailStop
//	before moving stop loss then moves like type 1
//
//	Type 3 uses up to 3 levels for trailing stop
//		Level 1 Move stop to 1st level
//		Level 2 Move stop to 2nd level
//		Level 3 Trail like type 1 by fixed amount other than 1
//			NOTE: Level3 Removed for now (see below) 
//
//	Possible future types
//	Type 4 uses 2 for 1, every 2 pip move moves stop 1 pip
//	Type 5 uses 3 for 1, every 3 pip move moves stop 1 pip
//
//	PARAMETERS:
//
//		type:		OP_BUY or OP_SELL
//		ticket:		the ticket number
//		open_price:	the order's open price
//		cur_sl:		the order's current StopLoss value
//		cur_tp:		the order's current TakeProfit value
//
//	RETURN VALUE:
//		zero for now
//
//  Calling example 
//	HandleTrailingStop("BUY",OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
//
//=============================================================================
int HandleTrailingStop(int type, int ticket, double open_price, double cur_sl, double cur_tp)
{
	double pt, TS = 0;

	if (type == OP_BUY)
	{
		switch (TrailingStopType)
		{
			case 1: 
				pt = Point * StopLoss;
				if (Bid - cur_sl > pt) 
					OrderModifyReliable(ticket, open_price, Bid - pt, cur_tp, 0, Aqua);
				break;
				
			case 2: 
				pt = Point * TrailingStop;
				if (Bid - open_price > pt && (cur_sl < Bid - pt || cur_sl == 0))
					OrderModifyReliable(ticket, open_price, Bid - pt, cur_tp, 0, Aqua);
				break;

			case 3: 
				if (Bid - open_price > FirstMove * Point)
				{
					TS = open_price + FirstMove * Point - FirstStopLoss * Point;
					if (cur_sl < TS)
						OrderModifyReliable(ticket, open_price, TS, cur_tp, 0, Aqua);
				}

				if (Bid - open_price > SecondMove * Point)
				{
					TS = open_price + SecondMove * Point - SecondStopLoss * Point;
					if (cur_sl < TS)
						OrderModifyReliable(ticket, open_price, TS, cur_tp, 0, Aqua);
				}
	  
	 			if (Bid - open_price > ThirdMove * Point)
	 			{
		 			TS = Bid  - TrailingStop3 * Point;
	 				if (cur_sl < TS)
						OrderModifyReliable(ticket, open_price, TS, cur_tp, 0, Aqua);
	 			}
	 			break;
		}
		return(0);
	}


	else if (type ==  OP_SELL)
	{
		switch (TrailingStopType)
		{
			case 1: 
				pt = Point * StopLoss;
				if (cur_sl - Ask > pt) 
					OrderModifyReliable(ticket, open_price, Ask+pt, cur_tp, 0, Aqua);
				break;
				
			case 2: 
				pt = Point * TrailingStop;
				if (open_price - Ask > pt && (cur_sl > Ask + pt || cur_sl == 0))
					OrderModifyReliable(ticket, open_price, Ask+pt, cur_tp, 0, Aqua);
				break;

			case 3: 
				if (open_price - Ask > FirstMove * Point)
				{
					TS = open_price - FirstMove * Point + FirstStopLoss * Point;
					if (cur_sl > TS)
						OrderModifyReliable(ticket, open_price, TS, cur_tp, 0, Aqua);
				}
				
				if (open_price - Ask > SecondMove * Point)
				{
					TS = open_price - SecondMove * Point + SecondStopLoss * Point;
					if (cur_sl > TS)
						OrderModifyReliable(ticket, open_price, TS, cur_tp, 0, Aqua);
				}
				
				if (open_price - Ask > ThirdMove * Point)
				{
					TS = Ask + TrailingStop3 * Point;					
					if (cur_sl > TS)
						OrderModifyReliable(ticket, open_price, TS, cur_tp, 0, Aqua);
			}
			break;
		 }
	 }
	 return(0);
}

//=============================================================================
// Get number of lots for this trade
//=============================================================================
double GetLots()
{
	double lot;

	lot = Lots;
	if (MoneyManagement)
		lot = LotsOptimized();

	if (lot >= 1.0) 
		lot = MathFloor(lot); 
	else 
		lot = 1.0;
		
	return(lot);
}

//=============================================================================
// Calculate optimal lot size
//=============================================================================
double LotsOptimized()
{
	double lot = Lots;

	// select lot size
	lot = NormalizeDouble(MathFloor(AccountFreeMargin() * TradeSizePercent / 10000) / 10, 1);
   
	// Check if mini or standard Account
    if (lot < 1.0) 
    	lot = 1.0;
    	
    if (lot > MaxLots) 
    	lot = MaxLots;

	return(lot);
} 

//=============================================================================
// Time frame interval appropriation function
//=============================================================================
int func_TimeFrame_Const2Val(int Constant) 
{
	switch (Constant) 
	{
		case 1:			return(1);  	// M1
		case 5:  		return(2);		// M5
		case 15:		return(3);		// M15
		case 30:		return(4);		// M30
		case 60:		return(5);		// H1
		case 240:		return(6);		// H4
		case 1440:		return(7);		// D1
		case 10080:		return(8);		// W1
		case 43200:		return(9);		// M1
	}
}

//=============================================================================
// Time frame string appropriation function
//=============================================================================
string func_TimeFrame_Val2String(int Value) 
{
	switch (Value) 
	{
		case 1:		return("M1");
		case 2:		return("M5");
		case 3:		return("M15");
		case 4:		return("M30");
		case 5:		return("H1");	
		case 6:		return("H4");
		case 7:		return("D1");
		case 8:		return("W1");
		case 9:		return("MN1");
		default: 	return("undefined " + Value);
	}
}

//=============================================================================
// Time frame value appropriation function
//=============================================================================
int func_Symbol2Val(string symbol) 
{
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



