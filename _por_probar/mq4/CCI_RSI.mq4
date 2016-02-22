//=============================================================================
//												CCI_RSI.mq4
//												Originally by: Robert Hill
//												
// 8/7/2006 Added booleans to test each indicator and to speed up backtesting
//          Added call to OrderReliableLastErr to replace GetLastError
//          Search for open trade using SelectByTicket instead of SelectByPos
//          Added more comments to explain the code
// 8/10/2006 Modified code to allow other methods to be tested
//           Separated logic for entry and exit signals
//           Modified Boolean selections for indicators to integer for backtest
// 9/14/2006 Added Accelerator
//=============================================================================

#property copyright "Robert Hill"

#include <OrderReliable_V1_0_0.mqh>

//+---------------------------------------------------+
//|Money Management                                   |
//+---------------------------------------------------+
extern bool MoneyManagement = true;   // Change to false if you want to shutdown money management controls.
                                      // Lots = 1 will be in effect and only 1 lot will be open regardless of equity.
extern double TradeSizePercent = 10;  // Change to whatever percent of equity you wish to risk.
extern double	Lots				= 1;    // Number of lots to trade when MoneyManagement is false
double MaxLots                = 100.0;// Maximum number of lots allowed by broker
//---- input parameters
extern double	TakeProfit			= 0;
extern double	StopLoss 			= 60;
extern int UseTrailingStop = 0;
extern  int		TrailingStopType 	= 2; // Type 1 trails immediately, type 2 waits for move size TrailingStop before trail begins
extern double	TrailingStop		= 40;

extern string Sep1 = "======= General Inputs =======";
extern  int SignalCandle = 1; // 0 opens and closes trades on current unclosed bar, 1 on closed bar
extern int ExitOnCross = 1; // Exit trade when signals say reverse of entry

// H4 RSI parameters
extern int TrendTimeFrame = 240;
extern int RSI_TrendPeriod = 20;
extern int RSI_TrendBuyEntry = 51;
extern int RSI_TrendSellEntry = 49;
//  RSI parameters
extern int RSI_Entry_Period = 14;
extern int RSI_BuyEntry = 50;
extern int RSI_SellEntry = 50;
extern int CCI_Period = 14;
extern int CCI_BuyEntry = 100;
extern int CCI_SellEntry = -100;

extern int UseAcc = 1;
extern int AccLevel = 7;

extern int UseRSI_Exit = 1;
extern int RSI_BuyExit = 50;
extern int RSI_SellExit = 50;
extern int UseCCI_Exit = 1;
extern int CCI_BuyExit = 0;
extern int CCI_SellExit = 0;

extern bool UseTimeLimit = true;
extern int StartHour =8;     // Start trades after time
extern int StopHour = 15;      // Stop trading after time
bool YesStop;

double lotMM;
int ticket;
 string  ExpertName="CCI_RSI";
 int     MagicCode = 5;

int      MagicNumber;  // Magic number of the trades. must be unique to identify
string   nameEA;             // identifies the expert

//=============================================================================
// expert initialization function
//=============================================================================
int init()
{
    MagicNumber = MagicCode*1000 + func_Symbol2Val(Symbol())*100 + func_TimeFrame_Const2Val(Period());
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


//=============================================================================
//
//								CheckEntrySignals()
//
//	Function to tell whether or not there is a trade to place.
//
// This is the original strategy
// The code is optimized by checking each indicator in sequence looking for
// a rule not to be met. When a rule is not met, the function immediately
// returns 0 for no trade
//
// This means that the code is checking for the reverse rule
// ie. if SMA needs to be greater than TMA then check for SMA < TMA
//
// When all rules are met the direction for the trade is returned
//
// BUY
//   Rule 1 - RSI(20) on 4Hr above 51 - Used for long term trend
//   Rule 2 - RSI(14) above 50
//   Rule 3 - CCI(14) > 100  
//   Rule 4 - Accelerator > 10  
//
// SELL
//   Rule 1 - RSI(20) on 4Hr below 49 - Used for long term trend
//   Rule 2 - RSI(14) below 50
//   Rule 3 - CCI(14) < -100
//   Rule 4 - Accelerator < -10  
//  
//	RETURN VALUE:
//
//		1:	If the rules are met to place a long trade
//
//		2:	If the rules are met to place a short trade
//
//		0:	If the rules are not met
//
//=============================================================================
int CheckEntrySignals()
{
   double myRSI240, myRSI, myCCI, myAcc;
   double myRSIprev, myCCIprev;
	

   myRSI240 = iRSI(Symbol(),TrendTimeFrame,RSI_TrendPeriod,PRICE_CLOSE,SignalCandle);
// Moved indicator calls to here, were called twice each in prior version

     if (myRSI240 > RSI_TrendBuyEntry) // Check for direction to place trade
     {
// Direction is long so check other indicators for long trades
// If check fails immediately return 0

// Check CCI

      myCCI = iCCI(Symbol(),0,CCI_Period,PRICE_CLOSE,SignalCandle);
      myCCIprev = iCCI(Symbol(),0,CCI_Period,PRICE_CLOSE,SignalCandle+1);
      if (myCCI < CCI_BuyEntry) return(0);

// Check if CCI is rising

      if (myCCIprev > myCCI) return(0);

// CCI OK so check RSI

       myRSI = iRSI(Symbol(),0,RSI_Entry_Period,PRICE_CLOSE,SignalCandle);
       myRSIprev = iRSI(Symbol(),0,RSI_Entry_Period,PRICE_CLOSE,SignalCandle+1);
       if ( myRSI < RSI_BuyEntry ) return(0);
       
// Check if RSI is rising

      if (myRSIprev > myRSI) return(0);

// RSI OK so Check Accelerator

       if (UseAcc == 1)
       {
           myAcc = iAC(NULL, 0, SignalCandle);
           if (myAcc < AccLevel*Point) return(0);
       }
       
// If we get to here then all indicators say to buy

       return(1);
     }
     

     if (myRSI240 < RSI_TrendSellEntry)
     {
// Direction is short so check other indicators for short trades
// If check fails immediately return 0

// Check CCI

      myCCI = iCCI(Symbol(),0,CCI_Period,PRICE_CLOSE,SignalCandle);
      if (myCCI > CCI_SellEntry) return(0);
       
// Check if CCI is falling

      if (myCCIprev < myCCI) return(0);
      
// CCI OK so check RSI

       if ( myRSI > RSI_SellEntry ) return(0);

// Check if RSI is falling

      if (myRSIprev < myRSI) return(0);
      
// RSI OK so Check Accelerator

       if (UseAcc == 1)
       {
           if (myAcc > -AccLevel*Point) return(0);
       }

// If we get to here then all indicators say to sell

       return(2);
     }

	return (0); // has not changed

}

//=============================================================================
//
//								CheckExitSignalsBuy()
//
//	Function to tell whether or not there is a buy trade to close.
//
// This is the original strategy
// The code is optimized by checking each indicator in sequence looking for
// a rule not to be met. When a rule is not met, the function immediately
// returns 0 for no close
//
// This means that the code is checking for the reverse rule
// ie. if SMA needs to be greater than TMA then check for SMA < TMA
//
// Close BUY
//   Rule 1 - RSI(14) below 50
//   Rule 2 - CCI(14) below 100  
//
//  
//	RETURN VALUE:
//
//		true:	If the rules are met to close a long trade
//
//		false:	If the rules are not met
//
//=============================================================================
bool CheckExitSignalsBuy()
{
   double myRSI, myCCI;
   bool RSI_Exit, CCI_Exit;
   
	
// Assume Exit is met

   RSI_Exit = true;
   CCI_Exit = true;

// If an indicator is used for exit assume condition is not met by setting to false

// Direction is long so check indicators for close long trades
//  check RSI

     if (UseRSI_Exit > 0)
     {
       myRSI = iRSI(Symbol(),0,RSI_Entry_Period,PRICE_CLOSE,SignalCandle);
       RSI_Exit = false;
       if ( myRSI < RSI_BuyExit ) RSI_Exit = true;
     }

// Check CCI

      if (UseCCI_Exit > 0)
      {
        myCCI = iCCI(Symbol(),0,CCI_Period,PRICE_CLOSE,SignalCandle);
        CCI_Exit = false;
         if (myCCI < CCI_BuyExit) CCI_Exit = true;
      }

// Now check if all indicators say to exit

     
     return(RSI_Exit && CCI_Exit);
   }

    
//=============================================================================
//
//								CheckExitSignalsSell()
//
//	Function to tell whether or not there is a trade to close.
//
// This is the original strategy
// The code is optimized by checking each indicator in sequence looking for
// a rule not to be met. When a rule is not met, the function immediately
// returns 0 for no close
//
// This means that the code is checking for the reverse rule
// ie. if SMA needs to be greater than TMA then check for SMA < TMA
//
// Close SELL
//   Rule 4 - RSI(14) above 50
//   Rule 2 - CCI(14) above -100
//  
//	RETURN VALUE:
//
//		true:	If the rules are met to close a short trade
//
//		false:	If the rules are not met
//
//=============================================================================
bool CheckExitSignalsSell()
{
   double myRSI, myCCI;
   bool CCI_Exit, RSI_Exit;
   
	
// Assume Exit is met

   CCI_Exit = true;
   RSI_Exit = true;


// Moved indicator calls to here, were called twice each in prior version
// Direction is short so check indicators for close short trades

//  check RSI

     if (UseRSI_Exit > 0)
     {
       myRSI = iRSI(Symbol(),0,RSI_Entry_Period,PRICE_CLOSE,SignalCandle);
        RSI_Exit = false;
        if ( myRSI > RSI_SellExit ) RSI_Exit = true;
     }

// Check CCI

      if (UseCCI_Exit > 0)
      {
        myCCI = iCCI(Symbol(),0,CCI_Period,PRICE_CLOSE,SignalCandle);
        CCI_Exit = false;
         if (myCCI > CCI_SellExit) CCI_Exit = true;
      }


// Now check if all indicators say to exit

     return( RSI_Exit && CCI_Exit);
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
	int cnt, total, PlaceTrade;
	bool CloseTrade;
	double TP;	
	
	
	
	
	total = CheckOpenTrades();
	if (total < 1) 
	{
      if (UseTimeLimit)
      {
// trading from 7:00 to 13:00 GMT
// trading from Start1 to Start2

      YesStop = true;
      if (Hour() >= StartHour && Hour() < StopHour) YesStop = false;
//      Comment ("Trading has been stopped as requested - wrong time of day");
      if (YesStop) return (0);
      }

      lotMM = GetLots();
	   PlaceTrade = CheckEntrySignals();

		if (PlaceTrade == 1)
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
				Print("Error opening BUY order : ", OrderReliableLastErr()); 
			return(0);
		}
		
		if (PlaceTrade == 2)
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
				Print("Error opening SELL order : ", OrderReliableLastErr()); 
			return(0);
		}
		return(0);
	} 
	  
	OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
		
//	if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)
//			continue;

		// Should it be closed because of a cross reversal?
		bool result = false;
		if (ExitOnCross > 0)
		{
			// We have a long position open and MAs have switched
			if (OrderType() == OP_BUY)
			{		  
	         CloseTrade = CheckExitSignalsBuy();
	         if (CloseTrade)
	         {
				// Close position
				   result = OrderCloseReliable(OrderTicket(), OrderLots(), Bid, 3, Violet); 
				   if (!result)
				   {
				   	Print("In OP_BUY, ExitOnCross=TRUE && isCrossed=2, but FAILED to exit.");
					   Alert("In OP_BUY, ExitOnCross=TRUE && isCrossed=2, but FAILED to exit.");
				   }
				   return(0);
				}
			}
		
			// We have a short position open and MAs have switched
			if (OrderType() == OP_SELL)
			{				
            CloseTrade = CheckExitSignalsSell();
	         if (CloseTrade)
	         {
				// Close position
				   result = OrderCloseReliable(OrderTicket(), OrderLots(), Ask, 3, Violet);
				   if (!result)
				   {
					   Print("In OP_SELL, ExitOnCross=TRUE && isCrossed=1, but FAILED to exit.");
					   Alert("In OP_SELL, ExitOnCross=TRUE && isCrossed=1, but FAILED to exit.");
				   }
				   return(0);
				}
			}
		}
		
		if (!result && UseTrailingStop > 0)	// Handle mods to trailing stop
			HandleTrailingStop(OrderType(), OrderTicket(), OrderOpenPrice(), OrderStopLoss(), OrderTakeProfit());
//	}

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

/*	Removed until we decide if we really want this for this EA
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
*/
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
				
/*	Removed until we decide if we really want this for this EA
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
*/
		 }
	 }
	 return(0);
}

//+------------------------------------------------------------------+
//| Get number of lots for this trade                                |
//+------------------------------------------------------------------+
double GetLots()
{
   double lot;
   
   lot = Lots;
   if(MoneyManagement)
   {
     lot = LotsOptimized();
   }
   if (lot >= 1.0) lot = MathFloor(lot); else lot = 1.0;
   return(lot);
}

//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+

double LotsOptimized()
  {
   double lot=Lots;
//---- select lot size
   lot=NormalizeDouble(MathFloor(AccountFreeMargin()*TradeSizePercent/10000)/10,1);
   
  // Check if mini or standard Account

    if (lot < 1.0) lot = 1.0;
    if (lot > MaxLots) lot = MaxLots;

   return(lot);
  } 

//+------------------------------------------------------------------+
//| Time frame interval appropriation  function                      |
//+------------------------------------------------------------------+

int func_TimeFrame_Const2Val(int Constant ) {
   switch(Constant) {
      case 1:  // M1
         return(1);
      case 5:  // M5
         return(2);
      case 15:
         return(3);
      case 30:
         return(4);
      case 60:
         return(5);
      case 240:
         return(6);
      case 1440:
         return(7);
      case 10080:
         return(8);
      case 43200:
         return(9);
   }
}

//+------------------------------------------------------------------+
//| Time frame string appropriation  function                               |
//+------------------------------------------------------------------+

string func_TimeFrame_Val2String(int Value ) {
   switch(Value) {
      case 1:  // M1
         return("M1");
      case 2:  // M1
         return("M5");
      case 3:
         return("M15");
      case 4:
         return("M30");
      case 5:
         return("H1");
      case 6:
         return("H4");
      case 7:
         return("D1");
      case 8:
         return("W1");
      case 9:
         return("MN1");
   	default: 
   		return("undefined " + Value);
   }
}

int func_Symbol2Val(string symbol) {
   string mySymbol = StringSubstr(symbol,0,6);
	if(mySymbol=="AUDCAD") return(1);
	if(mySymbol=="AUDJPY") return(2);
	if(mySymbol=="AUDNZD") return(3);
	if(mySymbol=="AUDUSD") return(4);
	if(mySymbol=="CHFJPY") return(5);
	if(mySymbol=="EURAUD") return(6);
	if(mySymbol=="EURCAD") return(7);
	if(mySymbol=="EURCHF") return(8);
	if(mySymbol=="EURGBP") return(9);
	if(mySymbol=="EURJPY") return(10);
	if(mySymbol=="EURUSD") return(11);
	if(mySymbol=="GBPCHF") return(12);
	if(mySymbol=="GBPJPY") return(13);
	if(mySymbol=="GBPUSD") return(14);
	if(mySymbol=="NZDUSD") return(15);
	if(mySymbol=="USDCAD") return(16);
	if(mySymbol=="USDCHF") return(17);
	if(mySymbol=="USDJPY") return(18);
	return(19);
}



