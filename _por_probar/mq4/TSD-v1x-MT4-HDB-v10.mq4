/*[[
	Name := TDS
	Author := based on original by Bob O'Brien / Barcode as modified for MT4 by JB
	Link := 
	Notes := Based on Alexander Elder's Triple Screen system. 
	Lots := 1
	Stop Loss := 0
	Take Profit := 100
	Trailing Stop := 60
]]*/
#property copyright "No copyright - thanks to Bob OBrien, JB and all traders who help test"
#property link      "http://finance.groups.yahoo.com/group/MetaTrader_Experts_and_Indicators/"
//#property version      "1.0"
// DISCLAIMER ***** IMPORTANT NOTE ***** READ BEFORE USING ***** 
// This expert advisor can open and close real positions and hence do real trades and lose real money.
// This is not a 'trading system' but a simple robot that places trades according to fixed rules.
// The author has no pretentions as to the profitability of this system and does not suggest the use
// of this EA other than for testing purposes in demo accounts.
// Use of this system is free - but u may not resell it - and is without any garantee as to its
// suitability for any purpose.
// By using this program you implicitly acknowledge that you understand what it does and agree that 
// the author bears no responsibility for any losses.
// Before using, please also check with your broker that his systems are adapted for the frequest trades
// associated with this expert.
//
//
// Place this on any chart less than 1 day. I use it on 5 min charts to do back tests in 'open prices only' mode 
// as this seems to be the least buggy.
//
//+------------------------------------------------------------------+
//|  External Variables                                              |
//+------------------------------------------------------------------+
extern int MagicNumber = 7000;               // Magic number of the trades. must be unique to identify
                                             // This means that only orders, positions with this magic number are considered
                                             // so one can have multiple strategies running on same pair as long as
                                             // this number+symbol is unique.
extern string Name = "TDS-v1x-MT4-HDB-v10";  // name of EA to put in order commet
extern double Lots = 1.0;
extern int TakeProfit = 100;
extern int Stoploss = 0;
extern int TrailingStop = 60;	
extern int Slippage=5;
extern int StartYear=2005;                   // in back testing, blocks trades before this year
extern int MM=0,Leverage=1,AcctSize=10000;   // MM, etc. is not implemented

extern int longPeriod = PERIOD_W1;           // this is the time constant for the weekly variables
extern int shortPeriod = PERIOD_D1;          // this is the time constant for the daily variables
extern int breakoutPeriod = PERIOD_D1;       //                           for the high / low used for buy / sell stops
extern int TSDLongMethod = 1;                // 0 = MACD, 1 = OsMA, 2 = Williams, 3 = Force
extern int TSDShortMethod = 3;               // 0 = MACD, 1 = OsMA, 2 = Williams, 3 = Force
                                             // use these indexes to determine which method is used to determine
                                             // the global direction (TSDlongMethod) and short-term entry (TSDSHortMethod)
extern int WilliamsH = -25;                  // Williams high limit
extern int WilliamsL = -75;                  // Williams low limit
extern int WilliamsP = 24;                   // Williams period for short time frame entry
extern int ForceP = 2;                       // Force period for short time frame entry

extern int longP1 = 12;                      // Oscillator P1 for long time frame direction
extern int longP2 = 26;                      // Oscillator P2 for long time frame direction
extern int longP3 = 9;                       // Oscillator P3 for long time frame direction

extern int pipsFromCurrent = 16;             // minimum distance between current price and stop order

// private variables
int BuyEntryOrderTicket=0,SellEntryOrderTicket=0,cnt=0,total=0, Direction=0;
double MacdCurrent=0, MacdPrevious=0, MacdPrevious2=0, MacdDirection=0, OsMAPrevious=0, OsMAPrevious2=0, OsMADirection=0;
double newbar=0,PrevDay=0,PrevMonth=0,PrevYear=0,PrevCurtime=0;
double PriceOpen=0;								// Price Open
double TradesThisSymbol=0;
double ForcePos=0, ForceNeg=0, Force=0,NewPrice=0;
double high1=0, high2=0, low1=0,low2=0;

int start()
{
     if ( TimeYear(Time[0]) < StartYear ) return;
 
 // i need to update this          	   
Comment("TSD for MT4 ver 0.1 HDB - DO NOT USE WITH REAL MONEY YET",
        "\n",
        "\n","Weekly MacdPrevious = ",MacdPrevious,"    Weekly OsMAPrevious = ",OsMAPrevious,
        "\n","Weekly MacdPrevious2 = ",MacdPrevious2,"    Weekly OsMAPrevious2 = ",OsMAPrevious2,
        "\n","Weekly MacdDirection = ",MacdDirection,"    Weekly OsMADirection = ",OsMADirection,
        "\n",
        "\n","Daily Force = ",Force,
        "\n","Is Daily Force Bullish = ",ForcePos,
        "\n","Is Daily Force Bearish = ",ForceNeg,
        "\n",
        "\n","Total Orders = ",total,
        "\n","Trades this Symbol(",Symbol(),") = ",TradesThisSymbol,
        "\n",
        "\n","New Bar Time is ",TimeToStr(newbar),
        "\n",
        "\n","Daily High[1] = ",high1,
        "\n","Daily High[2] = ",high2,
        "\n","Daily Low[1] = ",low1,
        "\n","Daily Low[2] = ",low2,
        "\n",
        "\n","Current Ask Price + 16 pips = ",Ask+(16*Point),
        "\n","Current Bid Price - 16 pips = ",Bid-(16*Point));

//
// I have removed the anti collision code since MT4 no longer has constraints on order rate
// 
//
     
/////////////////////////////////////////////////
//  Process the next bar details
/////////////////////////////////////////////////

double timeinterval = (-newbar + Time[0])/60;            // number of minutes since last treatement
if (timeinterval >= breakoutPeriod) 
{
	  newbar        = Time[0];

     total=OrdersTotal();
     TradesThisSymbol=0;
	  for(cnt=0;cnt<total;cnt++)
     { 
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
	      if(OrderSymbol()==Symbol() && (OrderMagicNumber() == MagicNumber) )    // limit the search to trades with the same OrderMagicNumber
	      {
	        TradesThisSymbol ++;
	      } // close for if(OrderSymbol()==Symbol())
	  } // close for for(cnt=0;cnt<total;cnt++)        

	  Direction = 0;                                                             // select a method to determine the long term trend
	  if ( TSDLongMethod == 0)                                                   // use the MACD
	  {
	     MacdDirection = 0;
	     MacdPrevious  = iMACD(NULL,longPeriod,longP1,longP2,longP3,PRICE_CLOSE,MODE_MAIN,1);
	     MacdPrevious2 = iMACD(NULL,longPeriod,longP1,longP2,longP3,PRICE_CLOSE,MODE_MAIN,2);
	     if (MacdPrevious > MacdPrevious2) MacdDirection = 1;
	     if (MacdPrevious < MacdPrevious2) MacdDirection = -1;
	     Direction = MacdDirection;
	  }
	  if ( TSDLongMethod == 1)                                                   // use the OsMA
	  {
	     OsMADirection = 0;
	     OsMAPrevious  = iOsMA(NULL,longPeriod,longP1,longP2,longP3,PRICE_CLOSE,1);
	     OsMAPrevious2 = iOsMA(NULL,longPeriod,longP1,longP2,longP3,PRICE_CLOSE,2);
	     if (OsMAPrevious > OsMAPrevious2) OsMADirection = 1;
	     if (OsMAPrevious < OsMAPrevious2) OsMADirection = -1;
	     Direction = OsMADirection;
	  }

	  if ( TSDLongMethod == 2)                                                   // use the Force - may the force be with you
	  {
        double Force1 = iForce(NULL,longPeriod,longP1,MODE_EMA,PRICE_CLOSE,1); 
        double Force2 = iForce(NULL,longPeriod,longP1,MODE_EMA,PRICE_CLOSE,2); 
	     if (Force1 > Force2) Direction = 1;
	     if (Force1 < Force2) Direction = -1;
	  }

	  if ( TSDLongMethod == 3)                                                   // use  Williams
	  {
	     double WillP1 = iWPR(NULL, longPeriod, longP1,1);
	     double WillP2 = iWPR(NULL, longPeriod, longP1,2);
	     if (WillP1 > WillP2) Direction = 1;
	     if (WillP1 < WillP2) Direction = -1;
	  }

	  high1 =iHigh(NULL,breakoutPeriod,1);                                       // determine the high of previous bar
	  high2 =iHigh(NULL,breakoutPeriod,2);
	  low1 =iLow(NULL,breakoutPeriod,1);
	  low2 =iLow(NULL,breakoutPeriod,2);
	  
	 if(TradesThisSymbol < 1) 
	 {
	    bool goLong = false;                                                     // determine if short term condition met for entry
	    bool goShort = false;

	    if ( TSDShortMethod == 0)                                                // using MACD
	     {
	        double Macd  = iMACD(NULL,shortPeriod,longP1,longP2,longP3,PRICE_CLOSE,MODE_MAIN,1);
	        // not sure what to do here
	     }
	     	    
	    if ( TSDShortMethod == 1)                                                // using OsMA
	     {
	        double OsMA  = iOsMA(NULL,shortPeriod,longP1,longP2,longP3,PRICE_CLOSE,1);
	        // not sure what to do here
	     }
	     	    
	    if ( TSDShortMethod == 2)                                                // using Williams
	     {
	        double WillP = iWPR(NULL, shortPeriod, WilliamsP,1);
	        goLong = WillP < WilliamsH;
	        goShort = WillP > WilliamsL;
	     }
	     
	    if ( TSDShortMethod == 3)                                                // using Force
	     {
            Force = iForce(NULL,shortPeriod,ForceP,MODE_EMA,PRICE_CLOSE,1); 
            ForcePos = Force > 0;
	         ForceNeg = Force < 0;
	         goLong = ForceNeg;
	         goShort = ForcePos;
	     }
	     
	   if(Direction == 1 && goLong)
		{
			PriceOpen = high1 + 1 * Point;		             // Buy 1 point above high of previous candle
			if(PriceOpen > (Ask + pipsFromCurrent * Point))  // Check if buy price is a least 16 points > Ask
			{
				BuyEntryOrderTicket=OrderSend(Symbol(),OP_BUYSTOP,Lots,PriceOpen,Slippage,low1 - 1 * Point,PriceOpen + TakeProfit * Point,Name,MagicNumber,0,Green);
				return(0);

			} // close for if(PriceOpen > (Ask + 16 * Point))
			else
			{
			   NewPrice = Ask + pipsFromCurrent * Point;
				BuyEntryOrderTicket=OrderSend(Symbol(),OP_BUYSTOP,Lots,NewPrice,Slippage,low1 - 1 * Point,NewPrice + TakeProfit * Point,Name,MagicNumber,0,Green);
				return(0);
			} // close for else statement
	   } // close for if(Direction == 1 && ForceNeg)
     
     
     if(Direction == -1 && goShort)
     {
         PriceOpen = low1 - 1 * Point;
			if(PriceOpen < (Bid - pipsFromCurrent * Point)) // Check if buy price is a least 16 points < Bid
			{
				SellEntryOrderTicket=OrderSend(Symbol(),OP_SELLSTOP,Lots,PriceOpen,Slippage,high1 + 1 * Point,PriceOpen - TakeProfit * Point,Name,MagicNumber,0,Red);
				return(0);
			} // close for if(PriceOpen < (Bid - 16 * Point))
			else
			{
				NewPrice = Bid - pipsFromCurrent * Point;
				SellEntryOrderTicket=OrderSend(Symbol(),OP_SELLSTOP,Lots,NewPrice,Slippage,high1 + 1 * Point,NewPrice - TakeProfit * Point,Name,MagicNumber,0,Red);
            return(0);			
			} // close for else statement

      } // close for if(Direction == -1 && ForcePos)
    } //Close of if(TradesThisSymbol < 1)


/////////////////////////////////////////////////
//  Pending Order Management
/////////////////////////////////////////////////

    if(TradesThisSymbol > 0)
	   {
      total=OrdersTotal();
      for(cnt=0;cnt<total;cnt++)
  	   { 
  	      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if( (OrderSymbol()==Symbol()) && (OrderType()==OP_BUYSTOP) && (OrderMagicNumber() == MagicNumber) )
         {
				if(Direction == -1)
  				{ 
  				   OrderDelete(OrderTicket());
				} // close for if(Direction == -1)
			} // close for if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)

         if((OrderSymbol()==Symbol()) && (OrderType()==OP_SELLSTOP) && (OrderMagicNumber() == MagicNumber) )
         {
				if(Direction == 1)
  				{ 
  				   OrderDelete(OrderTicket());
				} //close for if(Direction == 1)
			} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)

         if((OrderSymbol()==Symbol()) && (OrderType()==OP_BUYSTOP) && (OrderMagicNumber() == MagicNumber) )
   	   {
				if(high1 < high2)
	  			{ 
					if(high1 > (Ask + pipsFromCurrent * Point))
	  				{ 
	  	   		  OrderModify(OrderTicket(),high1 + 1 * Point,low1 - 1 * Point,OrderTakeProfit(),0,Cyan);
	  				} //close for if(High[1] > (Ask + 16 * Point))
	  				else
	  				{
	  				  OrderModify(OrderTicket(),Ask + pipsFromCurrent * Point,low1 - 1 * Point,OrderTakeProfit(),0,Cyan);			
	  				} //close for else statement
	  			} //close for if(High[1] < High[2])
	  		} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)
	  
	      if((OrderSymbol()==Symbol()) && (OrderType()==OP_SELLSTOP) && (OrderMagicNumber() == MagicNumber) )
   		{
				if(low1 > low2)
				{ 
					if(low1 < (Bid - pipsFromCurrent * Point))
					{
		   		  OrderModify(OrderTicket(),low1 - 1 * Point,high1 + 1 * Point,OrderTakeProfit(),0,Cyan);
					} // close for if(Low[1] < (Bid - 16 * Point))
					else
					{
					  OrderModify(OrderTicket(),Bid - pipsFromCurrent * Point,high1 + 1 * Point,OrderTakeProfit(),0,Cyan);      
					} //close for else statement
				} //close for if(Low[1] > Low[2])
			} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)
		} // close for for(cnt=0;cnt<total;cnt++)
	} // close for if(TradesThisSymbol > 0)
} // close for if (newbar != Time[0]) 

/////////////////////////////////////////////////
//  Stop Loss Management
/////////////////////////////////////////////////
  total=OrdersTotal();
  for(cnt=0;cnt<total;cnt++)
  { 
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

     if((OrderSymbol()==Symbol()) && (OrderType()==OP_BUY) && (OrderMagicNumber() == MagicNumber) )
    	{
			if(Ask-OrderOpenPrice() > (TrailingStop * Point))
  			{ 
				if(OrderStopLoss() < (Ask - TrailingStop * Point))
				{ 
	   		   OrderModify(OrderTicket(),OrderOpenPrice(),Ask - TrailingStop * Point,Ask + TakeProfit * Point,0,Cyan);
               return(0);					

				} // close for if(OrderStopLoss() < (Ask - TrailingStop * Point))
			} // close for if(Ask-OrderOpenPrice() > (TrailingStop * Point))
		} // close for if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)
	
     if((OrderSymbol()==Symbol()) && (OrderType()==OP_SELL) && (OrderMagicNumber() == MagicNumber) )
		{
			if(OrderOpenPrice() - Bid > (TrailingStop * Point))
			{ 
				if(OrderStopLoss() > (Bid + TrailingStop * Point))
				{ 
	   		   OrderModify(OrderTicket(),OrderOpenPrice(),Bid + TrailingStop * Point,Bid - TakeProfit * Point,0,Cyan);
               return(0);					

				} // close for if(OrderStopLoss() > (Bid + TrailingStop * Point))
			} // close for if(OrderOpenPrice() - Bid > (TrailingStop * Point))
		 } // close for if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)
  	  } // close for for(cnt=0;cnt<total;cnt++)
} // close for start

