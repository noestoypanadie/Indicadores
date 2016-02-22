/////////////////////////////////////////////////////////////////////////////////////////
//
//																CoinFlip_v01.mq4
//																Derk wehler
//

#property copyright "Derk Wehler"
#property link      ""
#include <OrderReliable_V1_1_0.mqh>

extern string	S1 = "-- MONEY MANAGEMENT SETTINGS --";
extern bool 	MoneyManagement = false;
extern double	TradeSizePercent = 10;	// Change to whatever percent of equity you wish to risk.
extern double	Lots = 1.0;
extern double	MaxLots = 100.0;
extern string	S2 = " ";
extern string	S3 = "-- INDICATOR SETTINGS --";
extern bool		UseTrend		= false;
extern int		LMSA_Period 	= 10;
extern string	S4 = " ";
extern string	S5 = "-- OTHER SETTINGS --";
extern int		Slippage		= 1;
extern string	Name_Expert		= "CoinFlip";


int MagicNumber;
int TradesInThisSymbol;

int ary[2][3];

int init()
{
	MathSrand(LocalTime());
	MagicNumber = 2112 + func_Symbol2Val(Symbol())*100 + func_TimeFrame_Const2Val(Period());
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
	
	bool direction;
	if (UseTrend)
		direction = NoFlip();
	else
		direction = Flip();
		
	if (CheckOpenPositions() == 0)
	{
		Print("=============================================================");
		if (direction)
		{
			OrderSendReliable(Symbol(), OP_BUY, GetLots(), Ask, Slippage, 0, 0, 
								GetCommentForOrder(), MagicNumber, 0, CLR_NONE);
			Print("===================  No open positions, Opening BUY =====================");
		}
		else
		{
			OrderSendReliable(Symbol(), OP_SELL, GetLots(), Bid, Slippage, 0, 0, 
								GetCommentForOrder(), MagicNumber, 0, CLR_NONE);
			Print("===================  No open positions, Opening SELL ====================");
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
// Flip
// Return whether to go long or short in a trade based on an indicator
//=============================================================================
bool NoFlip()
{
	int CheckSegments = 10;

	int		lsmaDirection[100];
	double 	lsmaNeutral[101];
	double 	lsmaUp[101];
	double 	lsmaDown[101];
	int 	retVal = 0;

	
	// Check for the direction (or color) of the LSMA line for the last several segments
	for (int i=0; i < CheckSegments+1; i++)
	{
		lsmaNeutral[i] = iCustom(NULL, 0, "LSMA", LMSA_Period, 0, i);	// ALWAYS ! 0x7FFFFFFF
		lsmaUp[i] = iCustom(NULL, 0, "LSMA", LMSA_Period, 1, i);		// Green if i & i-1 ! 0x7FFFFFFF
		lsmaDown[i] = iCustom(NULL, 0, "LSMA", LMSA_Period, 2, i);		//  Red  if i & i-1 ! 0x7FFFFFFF
	}


	// Determine the color (direction) of these line segments
	for (i=0; i < CheckSegments; i++)
	{
		// For any candle pair, i & i-1, the LSMA line is Green (heading up) if...
		if (lsmaUp[i] != 0x7FFFFFFF && lsmaUp[i+1] != 0x7FFFFFFF)
			lsmaDirection[i] = 1;
		//
		// The LSMA line is Red (heading down)
		else if (lsmaDown[i] != 0x7FFFFFFF && lsmaDown[i+1] != 0x7FFFFFFF)
			lsmaDirection[i] = -1;
		//
		// Otherwise it is neutral
		else
			lsmaDirection[i] = 0;
	}
	
	if (lsmaDirection[i] == 1)
		return (true);
		
	if (lsmaDirection[i] == -1)
		return (false);
		
	// If the indicator is not going up OR down, then flip a coin...
	return (Flip());
}


//=============================================================================
// CheckExitCondition
// Check if exit condition is met
//=============================================================================
bool CheckExitCondition(string TradeType)
{
	if ((Close[1] < Close[2] && TradeType == "BUY") ||
		(Close[1] > Close[2] && TradeType == "SELL"))
	{
		Print("EXIT_CONDITION: EXIT!!  Direction: ", TradeType);
		return (TRUE);
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

		double price = Bid;
		string direction = "BUY";
		int type = OrderType();
		if (type == OP_BUY || type == OP_SELL)
		{
			if (OrderType() == OP_SELL)
			{
				price = Ask;
				direction = "SELL";
			}
			bool close = CheckExitCondition(direction);
			
			if (close)
			{
				Print("===================================================================");
				OrderCloseReliable(OrderTicket(), OrderLots(), price, Slippage, CLR_NONE);
				Print("=========================  CLOSING POSIITON  ============================");
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

	if (lot < 1.0) lot = 1.0;
	if (lot > MaxLots) lot = MaxLots;

	return(lot);
} 


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

