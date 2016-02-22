//=============================================================================
//                                                       YOUR EA NAME HERE.mq4
//                                            Copyright © 2006, YOUR NAME HERE
//                                                      YOUR WEBSITE NAME HERE
//
// DERK COMMENT 1
// First off, notice how I have removed those stupid "|" things in the 
// comments.  They only serve as a pain in the ass when you go to modify 
// your comment blocks because you are constantly having to change the 
// position of those "|"s.
//=============================================================================
#property copyright "Copyright © 2006, Derk Wehler"
#property link      "http://www.metaquotes.net"

// DERK COMMENT 2
// Notice I have spaced out your externs so they are nicely readable
// And here's an early hint right here.  Go into your MetaEditor 
// Tools / Options and under the General tab, set your tabs == 4 and 
// REMOVE the check in the box that says "Insert spaces".
//
//---- input parameters
extern int 		wpr			= 55;
extern double 	wprup		= -20;
extern double 	wprdn		= -80;
extern int 		rsi			= 3;
extern double 	rsiup		= 80;
extern double 	rsidn		= 20;
extern double 	stochup		= 80;
extern double 	stochdn		= 25;
extern double 	TP1 		= 13;
extern double 	TP2 		= 8;
extern double 	TP3 		= 5;
extern double 	SL1 		= 100;
extern double 	SL2 		= 40;
extern double 	LotSize1 	= 0.1;
extern double 	LotSize2 	= 0.1;

//=============================================================================
// expert initialization function
//=============================================================================
int init()
{
// DERK COMMENT 3
// Remove extraneous crap the medaEditor inserts, like this:

//-----

//-----
	return(0);
}


int deinit()
{
	return(0);
}


int start()
{
	// DERK COMMENT 4
	// Magic number should be an integer, and must be 
	// smaller than: 4294967296.  So NO, NOT 200610062146
//	double MagicNumber = 200610062146 + Period();
	int MagicNumber = 1800 + Period();

	// int LotSize=MathFloor( AccountBalance( ) / 10000);
	// if (LotSize < 1)
	// {
	// LotSize = 1;
	// }

	// DERK COMMENT 5
	// Notice that I have tabbed out all your code, and spaced it out consistantly, 
	// so that, for example, your lines now look like this:
	//
	// 		OrderSend(Symbol(), OP_BUY, LotSize1, Ask, 2, Ask - SL1 * Point, Ask + TP1 * Point, NULL, MagicNumber, 0, Green);
	//
	// instead of this:
	//
	//		OrderSend(Symbol( ),OP_BUY, LotSize1, Ask,2,Ask-SL1*Point,Ask+ TP1*Point, NULL,MagicNumber ,0,Green) ;
	// 
	// These two are functionally the same, but which is easier to read?  Is it 
	// critical you use my particular method of code formatting?  Absolutely not.  
	// But use SOME form, and make it look nice so other people can read your code, 
	// and so you can read it better 6 months from now when you go back to change it.
	// TAB OUT your code correctly so others (and you) can easily read the flow of 
	// the function of the code.
	//
	// Read over my version here and compare it to your own.  I bet you find mine 
	// easier to undertstand.  DO this fro mthe beginning with each new piece of 
	// code you write, and put in LOTS of comments on what the code does, even if
	// it seems fairly obvious at the time you are writing it.  You will be glad later.
	//
	double currentClose = iClose(Symbol(), 60, 1);
	double priorClose = iClose(Symbol(), 60, 2);
	double oldestClose = iClose(Symbol(), 60, 3);
	int Total_Orders = 0;

	for (int i=OrdersTotal(); i >= 0; i--)
	{
		OrderSelect(i, SELECT_ BY_POS, MODE_ TRADES);
		if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
		{
			Total_Orders++;
			Print("Total Orders: ", Total_Orders) ;
		}
	}
	Print("Total Orders: ", Total_Orders, ", MagicNum: ", MagicNumber, 
			", Orderstotal: ", OrdersTotal(), ", OMN: ", OrderMagicNumber());

	// DERK COMMENT 6
	// As for the actual problem you are having, I cannot be sure what 
	// the problem is.  You said you have several experts you'd like 
	// to se on diff pairs.  You mean you want to use this expert on 
	// several pairs, or do you have other experts?
	//
	// As Ron said, it sounds like you need to just use different 
	// MagicNumbers in each of your EAs.  Your magic number, above 
	// (COMMENT 4) is the only functional change I have made to this 
	// code.  If you have another EA, copy and paste that line in for 
	// you other EA, but change the base from 1800 to some other number
	// in the other code.
	//
	// New Orders:
	double myWPR = iWPR(Symbol(), 240, wpr, 2);
	double myRsi = iRSI(Symbol(), 240, rsi, PRICE_CLOSE, 2);
	double myStoch = iStochastic(Symbol(), 60, 8, 3, 3, MODE_SMA, 0, MODE_MAIN, 2);
	if (myStoch < stochdn && currentClose > priorClose && 
		priorClose > oldestClose && Total_Orders == 0)
	{
		OrderSend(Symbol(), OP_BUY, LotSize1, Ask, 2, Ask - SL1 * Point, Ask + TP1 * Point, NULL, MagicNumber, 0, Green);
		OrderSend(Symbol(), OP_BUY, LotSize1, Ask, 2, Ask - SL1 * Point, Ask + TP2 * Point, NULL, MagicNumber, 0, Green);
		OrderSend(Symbol(), OP_BUY, LotSize1, Ask, 2, Ask - SL1 * Point, Ask + TP3 * Point, NULL, MagicNumber, 0, Green);
	}
	if (myStoch > stochup && currentClose < priorClose && 
		priorClose < oldestClose 	&& Total_Orders == 0)
	{
		OrderSend(Symbol(), OP_SELL, LotSize1, Bid, 2, Bid + SL1 * Point, Bid - TP1 * Point, NULL, MagicNumber, 0, Red);
		OrderSend(Symbol(), OP_SELL, LotSize1, Bid, 2, Bid + SL1 * Point, Bid - TP2 * Point, NULL, MagicNumber, 0, Red);
		OrderSend(Symbol(), OP_SELL, LotSize1, Bid, 2, Bid + SL1 * Point, Bid - TP3 * Point, NULL, MagicNumber, 0, Red);
	}
}

