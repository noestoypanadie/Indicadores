/////////////////////////////////////////////////////////////////////////////////////////
//
//																CoinFlip_v01.mq4
//																Derk wehler
//
// Robert Hill
// 10/16/06 - Fixed a few bugs
//            added stop loss and trailing stop
//            exit on trend change
//            corrected use of LSMA in color
//            Added use of mini-account
//            Added time to allow trades as a possible filter
//            Added Friday close all positions

#property copyright "Derk Wehler"
#property link      ""
#include <OrderReliable_V1_1_0.mqh>

extern string	S1 = "-- MONEY MANAGEMENT SETTINGS --";
extern bool    AccountIsMini = true;      // Change to true if trading mini account
extern bool    MoneyManagement = false;
extern double	TradeSizePercent = 10;	// Change to whatever percent of equity you wish to risk.
extern double	Lots = 1.0;
extern double	MaxLots = 100.0;
extern string	S2 = " ";
extern string	S3 = "-- INDICATOR SETTINGS --";
extern bool		UseTrend		= false;
extern int		LSMA_EntryPeriod 	= 10;
extern bool    UseMomentum = false;
extern int     MomentumPeriod = 10;
extern int     MomentumLevel = 5;
extern bool    UseExitSignal = true;
extern int     LSMA_ExitPeriod = 10;
extern int     LookBack = 2;
extern string	S4 = " ";
extern string	S5 = "-- OTHER SETTINGS --";
//+---------------------------------------------------+
//|Profit controls                                    |
//+---------------------------------------------------+
extern double StopLoss = 55;        // Maximum pips willing to lose per position.
extern bool UseTrailingStop = true;
extern int TrailingStopType = 2;        // Type 1 moves stop immediately, Type 2 waits til value of TS is reached
extern double TrailingStop = 25;    // Change to whatever number of pips you wish to trail your position with.
 double Margincutoff = 800;   // Expert will stop trading if equity level decreases to that level.
extern bool UseTakeProfit = true;
extern int TakeProfit = 50;          // Maximum profit level achieved.
extern int SignalCandle = 1;
extern int		Slippage		= 3;
extern string	Name_Expert		= "CoinFlip";

extern bool UseTradingHours = true;
 int StartHourDST = 7;       // Start trades after time
 int StopHourDST = 15;      // Stop trading after time
 int StartHourNormal = 8;
 int StopHourNormal = 16;
 int StartHour;
 int StopHour;
extern bool UseDST = true;
extern bool UseFridayClose = false;
 string FriCloseTimeNormal = "21:00";      // Close all trades after time on Friday
 string FriCloseTimeDST = "20:00";      // Close all trades after time on Friday
string FriCloseTime;      // Close all trades after time on Friday
string FridayFinalTime;   // No trades to start after time
bool Debug = false;


string setup;
double lotMM;
int MagicNumber;
int TradesInThisSymbol;
bool YesStop;


int init()
{
	MathSrand(LocalTime());
	MagicNumber = 2112 + func_Symbol2Val(Symbol())*100 + func_TimeFrame_Const2Val(Period());
     setup = ""; 
   if (UseDST)
   {
     FriCloseTime = FriCloseTimeDST;
     StartHour = StartHourDST;
     StopHour = StopHourDST;
   }
   else
   {
     FriCloseTime = FriCloseTimeNormal;
     StartHour = StartHourNormal;
     StopHour = StopHourNormal;
   }
	return(0);
}

int deinit()
{
	return(0);
	
	// This is a stubbed out function called merely to prevent compiler warnings
	BumFunc();
}

int start()
{   
	static int prevBars = -1;
	bool direction, YesTrade;
	
	// Return if this is NOT a new candle
	int curBars = Bars;
	if (prevBars == -1)
		prevBars = curBars;

	if (curBars == prevBars)
		return(0);

	prevBars = curBars;

	if (CheckOpenPositions() > 1)
	{
		Print("ERROR ! ERROR ! ERROR : CheckOpenPositions > 1 : ERROR ! ERROR ! ERROR");
		return (0);
	}
	
	HandleOpenPositions();	// Will close open position if appropriate
	
// Check if any open positions were not closed

     TradesInThisSymbol = CheckOpenPositions();

// Only allow 1 trade per Symbol

     if(TradesInThisSymbol > 0) {
       return(0);}

   if (UseTradingHours)
   {
// trading from 7:00 to 13:00 GMT
// trading from Start1 to Start2

   YesStop = true;
   if (Hour() >= StartHour && Hour() <= StopHour) YesStop = false;
//      Comment ("Trading has been stopped as requested - wrong time of day");
   if (YesStop) return (0);
   }
     
	if (UseTrend)
		direction = NoFlip();
	else
		direction = Flip();
		
	if (CheckOpenPositions() == 0)
	{
		Print("=============================================================");
		if (direction)  // BUG FIX - direction was Flip()
		{
		   YesTrade = true;
		   if (UseMomentum)
		   {
		      if(iMomentum(NULL,0,MomentumPeriod,PRICE_CLOSE,SignalCandle) < (100 + MomentumLevel * Point)) YesTrade = false;
		   }
		   if (YesTrade)
		   {
		    OrderSendReliable(Symbol(), OP_BUY, GetLots(), Ask, Slippage, 0, 0, 
						GetCommentForOrder(), MagicNumber, 0, CLR_NONE);
		    Print("===================  No open positions, Opening BUY =====================");
		   }
	   }
		else
		{
		   YesTrade = true;
		   if (UseMomentum)
		   {
		      if(iMomentum(NULL,0,MomentumPeriod,PRICE_CLOSE,SignalCandle) > (-100 - MomentumLevel*Point)) YesTrade = false;
		   }
		   if (YesTrade)
		   {
			  OrderSendReliable(Symbol(), OP_SELL, GetLots(), Bid, Slippage, 0, 0, 
								GetCommentForOrder(), MagicNumber, 0, CLR_NONE);
			  Print("===================  No open positions, Opening SELL ====================");
		   }
		}
	}

	return (0); 
}


///////////////////// FUNCTIONS //////////////////////

//=============================================================================
// Flip
// Return, randomly, whether to go long or short in a trade ("flip a coin")
//=============================================================================
bool Flip()
{
	MathSrand(LocalTime());
	int rand = MathRand();
	Print("===> rand == ", rand, ";   rand % 2 = ", rand%2);
	if (rand % 2 == 1)
		return (TRUE);
	
	return (FALSE);
}


//=============================================================================
// NoFlip
// Return whether to go long or short in a trade based on an indicator
//=============================================================================
bool NoFlip()
{

   double CurLSMA, PrevLSMA, Prev2LSMA;
	int 	retVal = 0;

	
	// Check for the direction (or color) of the LSMA line for the last several segments
    CurLSMA = MathFloor(LSMA(LSMA_EntryPeriod, SignalCandle)/Point)*Point;
    PrevLSMA = MathFloor(LSMA(LSMA_EntryPeriod, SignalCandle+LookBack)/Point)*Point;
    Prev2LSMA = MathFloor(LSMA(LSMA_EntryPeriod, SignalCandle+LookBack + 1)/Point)*Point;


		// For any candle pair, i & i-1, the LSMA line is Green (heading up) if...
   if (CurLSMA > PrevLSMA) return(true);
		//
		// The LSMA line is Red (heading down)
	if (CurLSMA < PrevLSMA) return(false);
		//
		// Otherwise it is neutral
	
		
	// If the indicator is not going up OR down, then flip a coin...
	return (Flip());
}

//+------------------------------------------------------------------------+
//| LSMA - Least Squares Moving Average function calculation               |
//| LSMA_In_Color Indicator plots the end of the linear regression line    |
//+------------------------------------------------------------------------+

double LSMA(int myRperiod, int shift)
{
   int i;
   double sum;
   int length;
   double lengthvar;
   double tmp;
   double wt;

   length = myRperiod;
 
   sum = 0;
   for(i = length; i >= 1  ; i--)
   {
     lengthvar = length + 1;
     lengthvar /= 3;
     tmp = 0;
     tmp = ( i - lengthvar)*Close[length-i+shift];
     sum+=tmp;
    }
    wt = sum*6/(length*(length+1));
    
    return(wt);
}


//=============================================================================
// CheckExitCondition
// Check if exit condition is met
//=============================================================================
bool CheckExitConditionBUY()
{
   double CurLSMA, PrevLSMA;
   bool YesExit;
   
   if(UseFridayClose && DayOfWeek()==5 && CurTime() >= StrToTime(FriCloseTime)) return(true);

   if (UseExitSignal)
   {
      CurLSMA = MathFloor(LSMA(LSMA_ExitPeriod, SignalCandle)/Point)*Point;
      PrevLSMA = MathFloor(LSMA(LSMA_ExitPeriod, SignalCandle+LookBack)/Point)*Point;
   
      if (CurLSMA < PrevLSMA ) YesExit = true;
   }
   else
   {

	  if (Close[1] < Close[2]) YesExit = true;
	}
	
	
	if (YesExit)
	{
			Print("EXIT_CONDITION: EXIT!!  Direction: BUY");
			return(true);
   }
   Print("EXIT_CONDITION: DO NOT EXIT");
	return (FALSE);
}

//=============================================================================
// CheckExitCondition
// Check if exit condition is met
//=============================================================================
bool CheckExitConditionSELL()
{
   double CurLSMA, PrevLSMA;
   bool YesExit;
   
   if(UseFridayClose && DayOfWeek()==5 && CurTime() >= StrToTime(FriCloseTime)) return(true);

   if (UseExitSignal)
   {
      CurLSMA = MathFloor(LSMA(LSMA_ExitPeriod, SignalCandle)/Point)*Point;
      PrevLSMA = MathFloor(LSMA(LSMA_ExitPeriod, SignalCandle+LookBack)/Point)*Point;
   
      if (CurLSMA > PrevLSMA ) YesExit = true;
   }
   else
   {

	  if (Close[1] > Close[2] ) YesExit = true;
	}
	
	
	if (YesExit)
	{
		Print("EXIT_CONDITION: EXIT!!  Direction: SELL");
		return (true);
   }
   
	Print("EXIT_CONDITION: DO NOT EXIT");
	return (FALSE);
}

 
//=============================================================================
// CheckOpenPositions
// Count the number of position this EA has open
//=============================================================================
int CheckOpenPositions()
{
	int cnt, NumPositions;
	int NumBuyTrades, NumSellTrades;   // Number of buy and sell trades in this symbol

	NumBuyTrades = 0;
	NumSellTrades = 0;
	for(cnt=OrdersTotal()-1; cnt >= 0; cnt--)
	{
		OrderSelect (cnt, SELECT_BY_POS, MODE_TRADES);
		if (OrderSymbol() != Symbol()) 
			continue;
		if (OrderMagicNumber() != MagicNumber)  
			continue;

		if (OrderType() == OP_BUY )  
			NumBuyTrades++;
		if (OrderType() == OP_SELL ) 
			NumSellTrades++;
	}
	NumPositions = NumBuyTrades + NumSellTrades;
	return (NumPositions);
}

//+------------------------------------------------------------------+
//| HandleTrailingStop                                               |
//| Type 1 moves the stoploss without delay.                         |
//| Type 2 waits for price to move the amount of the trailStop       |
//| before moving stop loss then moves like type 1                   |
//| Type 3 uses up to 3 levels for trailing stop                     |
//|      Level 1 Move stop to 1st level                              |
//|      Level 2 Move stop to 2nd level                              |
//|      Level 3 Trail like type 1 by fixed amount other than 1      |
//| Possible future types                                            |
//| Type 4 uses 2 for 1, every 2 pip move moves stop 1 pip           |
//| Type 5 uses 3 for 1, every 3 pip move moves stop 1 pip           |
//+------------------------------------------------------------------+
int HandleTrailingStop(int type, int ticket, double op, double os, double tp)
{
    double pt, TS=0, myAsk, myBid;
    double bos,bop,opa,osa;
    
    switch(type)
    {
       case OP_BUY:
       {
		 myBid = MarketInfo(Symbol(),MODE_BID);
       switch(TrailingStopType)
       {
        case 1: pt = Point*StopLoss;
                if(myBid-os > pt)
                OrderModifyReliable(ticket, op, myBid-pt, tp, 0, Aqua); 
                break;
        case 2: pt = Point*TrailingStop;
                if(myBid-op > pt && os < myBid - pt)
                OrderModifyReliable(ticket, op, myBid-pt, tp, 0, Aqua); 
                break;
       }
       return(0);
       break;
       }
    case  OP_SELL:
    {
		myAsk = MarketInfo(Symbol(),MODE_ASK);
       switch(TrailingStopType)
       {
        case 1: pt = Point*StopLoss;
                if(os - myAsk > pt)
                OrderModifyReliable(ticket, op, myAsk+pt, tp, 0, Aqua); 
                break;
        case 2: pt = Point*TrailingStop;
                if(op - myAsk > pt && os > myAsk+pt)
                OrderModifyReliable(ticket, op, myAsk+pt, tp, 0, Aqua); 
                break;
       }
    }
    return(0);
    }
}

//=============================================================================
// Handle Open Positions
// Check if any open positions need to be closed or modified
//=============================================================================
int HandleOpenPositions()
{
	int cnt;
	bool YesClose;
	double pt;

	for (cnt=OrdersTotal()-1; cnt >= 0; cnt--)
	{
		OrderSelect (cnt, SELECT_BY_POS, MODE_TRADES);
		if (OrderSymbol() != Symbol()) 
			continue;
		if (OrderMagicNumber() != MagicNumber)
			continue;

      if(OrderType() == OP_BUY)
      {
            
         if (CheckExitConditionBUY())
          {
				Print("===================================================================");
				OrderCloseReliable(OrderTicket(), OrderLots(), Bid, Slippage, CLR_NONE);
				Print("=========================  CLOSING POSIITON  ============================");
          }
          else
          {
            if (UseTrailingStop)
            {
               HandleTrailingStop(OP_BUY,OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
            }
          }
      }

      if(OrderType() == OP_SELL)
      {
          if (CheckExitConditionSELL())
          {
				Print("===================================================================");
				OrderCloseReliable(OrderTicket(), OrderLots(), Ask, Slippage, CLR_NONE);
				Print("=========================  CLOSING POSIITON  ============================");
          }
          else
          {
             if(UseTrailingStop)  
             {                
               HandleTrailingStop(OP_SELL,OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
             }
          }
       }
	}
}




 
//=============================================================================
// Money Management Functions
//=============================================================================


double LotsOptimized()
{
	double lot = Lots;

	lot = NormalizeDouble(MathFloor(AccountFreeMargin() * TradeSizePercent / 10000) / 10, 1);

	// Check if mini or standard Account

  if(AccountIsMini)
  {
    lot = MathFloor(lot*10)/10;
    
   }

	return(lot);
} 


double GetLots()
{
	double lot;

   if(MoneyManagement)
   {
     lot = LotsOptimized();
   }
   else
   {
     lot = Lots;
   }
   
   if(AccountIsMini)
   {
     if (lot < 0.1) lot = 0.1;
   }
   else
   {
     if (lot >= 1.0) lot = MathFloor(lot); else lot = 1.0;
   }
   if (lot > MaxLots) lot = MaxLots;
   
		
	return(lot);
}



//=============================================================================
// Functions used to calculate unique magic number
//=============================================================================
//=============================================================================
// Time frame interval appropriation  function
//=============================================================================

int func_TimeFrame_Const2Val(int Constant ) 
{
	switch(Constant) 
	{
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


int func_Symbol2Val(string symbol) 
{
	string mySymbol = StringSubstr(symbol,0,6); // Handle problem of trailing m on mini accounts.
	
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


string GetCommentForOrder() 
{
	return (Name_Expert); 
}


void BumFunc()
{
	return (0);
	
	OrderSendReliableMKT(Symbol(), OP_BUY, 0, 3.500, 0, 0, 0, "none", 99, 0);
	OrderModifyReliable(0, 0, 0, 0, 0);
	OrderModifyReliableSymbol(Symbol(), 0, 0, 0, 0, 0);
	OrderCloseReliable(0, 0, 0, 0);
	OrderReliableLastErr();
}

