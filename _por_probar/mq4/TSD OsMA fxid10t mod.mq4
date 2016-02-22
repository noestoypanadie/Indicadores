/*[[
	Name := TDSGlobal
	Author := Copyright © 2005 Bob O'Brien / Barcode
	Link := 
	Notes := Based on Alexander Elder's Triple Screen system. To be run only on a Weekly chart.
	Lots := 1
	Stop Loss := 0
	Take Profit := 100
	Trailing Stop := 60
]]*/
//+------------------------------------------------------------------+
//|  External Variables                                              |
//+------------------------------------------------------------------+

extern double  Lots           = 1.0;
extern int     TakeProfit     = 100,
               Stoploss       = 0,
               TrailingStop   = 60,	
               Slippage       = 5,     // Slippage
               StopYear       = 2005,
               MM             = -2,
               Leverage       = 10,
               MagicNumber    = 1775;

double         AcctSize;      AcctSize=AccountBalance();
string         comment;       comment=Period()+"m TSD OsMA fxid10t mod";
int            BuyEntryOrderTicket=0,
               SellEntryOrderTicket=0,
               cnt=0;
double         MacdCurrent=0,
               MacdPrevious=0,
               MacdPrevious2=0,
               Direction=0,
               OsMAPrevious=0,
               OsMAPrevious2=0,
               OsMADirection=0,
               newbar=0,
               PrevDay=0,
               PrevMonth=0,
               PrevYear=0,
               PrevCurtime=0,
               PriceOpen=0,
               TradesThisSymbol=0,
               ForcePos=0,
               ForceNeg=0,
               Force=0,
               NewPrice=0;
bool           First=True;

int init()  {  return(0);  }
int deinit(){  return(0);  }
int start() {
   
   Lots=NormalizeDouble(MathCeil(AccountBalance()*Leverage/1000)/100,2);
   PrintComments();
   TradesThisSymbol=0;
   for(cnt=0;cnt<OrdersTotal();cnt++) { 
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber) {
	        TradesThisSymbol ++; }  }

   MacdPrevious  = iMACD(NULL,10080,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
   MacdPrevious2 = iMACD(NULL,10080,12,26,9,PRICE_CLOSE,MODE_MAIN,2);
	  
   OsMAPrevious  = iOsMA(NULL,10080,12,26,9,PRICE_CLOSE,1);
   OsMAPrevious2 = iOsMA(NULL,10080,12,26,9,PRICE_CLOSE,2);

   Force = iForce(NULL,1440,2,MODE_EMA,PRICE_CLOSE,1); 
   ForcePos = iForce(NULL,1440,2,MODE_EMA,PRICE_CLOSE,1) > 0;
   ForceNeg = iForce(NULL,1440,2,MODE_EMA,PRICE_CLOSE,1) < 0;

   if (MacdPrevious > MacdPrevious2) Direction = 1;
	if (MacdPrevious < MacdPrevious2) Direction = -1;
	if (MacdPrevious == MacdPrevious2) Direction = 0;

	if (OsMAPrevious > OsMAPrevious2) OsMADirection = 1;
	if (OsMAPrevious < OsMAPrevious2) OsMADirection = -1;
	if (OsMAPrevious == OsMAPrevious2) OsMADirection = 0;


/////////////////////////////////////////////////
//  Process the next bar details
/////////////////////////////////////////////////

if(newbar != Time[0])  {
   newbar  = Time[0];
	if(TradesThisSymbol < 1)  {
      if(OsMADirection == 1 && ForceNeg)  {
         PriceOpen = High[1] + 1 * Point;		// Buy 1 point above high of previous candle
			if(PriceOpen > (Ask + 16 * Point))  // Check if buy price is a least 16 points > Ask
			{BuyEntryOrderTicket=OrderSend(Symbol(),
			                               OP_BUYSTOP,
			                               Lots,
			                               PriceOpen,
			                               Slippage,
			                               Low[1] - 1 * Point,
			                               PriceOpen + TakeProfit * Point,
			                               comment,MagicNumber,0,Green);
         return(0);  } // close for if(PriceOpen > (Ask + 16 * Point))
			else  {
            NewPrice = Ask + 16 * Point;
				BuyEntryOrderTicket=OrderSend(Symbol(),
				                              OP_BUYSTOP,
				                              Lots,
				                              NewPrice,
				                              Slippage,Low[1] - 1 * Point,
				                              NewPrice + TakeProfit * Point,
				                              comment,MagicNumber,0,Green);
         return(0); } // close for else statement
	   } // close for if(Direction == 1 && ForceNeg)

      if(OsMADirection == -1 && ForcePos) {
         PriceOpen = Low[1] - 1 * Point;
			if(PriceOpen < (Bid - 16 * Point)) // Check if buy price is a least 16 points < Bid
			{SellEntryOrderTicket=OrderSend(Symbol(),
			                                OP_SELLSTOP,
			                                Lots,
			                                PriceOpen,
			                                Slippage,
			                                High[1] + 1 * Point,
			                                PriceOpen - TakeProfit * Point,
			                                comment,MagicNumber,0,Red);
         return(0); } // close for if(PriceOpen < (Bid - 16 * Point))
			else  {
            NewPrice = Bid - 16 * Point;
				SellEntryOrderTicket=OrderSend(Symbol(),
				                               OP_SELLSTOP,
				                               Lots,
				                               NewPrice,
				                               Slippage,
				                               High[1] + 1 * Point,
				                               NewPrice - TakeProfit * Point,
				                               comment,MagicNumber,0,Red);
         return(0);  } // close for else statement
      } // close for if(Direction == -1 && ForcePos)
   } //Close of if(TradesThisSymbol < 1)

/////////////////////////////////////////////////
//  Pending Order Management
/////////////////////////////////////////////////

if(TradesThisSymbol > 0)   {
   for(cnt=0;cnt<OrdersTotal();cnt++)  { 
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderType()==OP_BUYSTOP) {
         if(OsMADirection == -1) { 
            OrderDelete(OrderTicket());
	        	return(0); } // close for if(Direction == -1)
			} // close for if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderType()==OP_SELLSTOP)   {
         if(OsMADirection == 1)  { 
            OrderDelete(OrderTicket());
	        	return(0); } //close for if(Direction == 1)
			} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderType()==OP_BUYSTOP) {
         if(High[1] < High[2])   { 
            if(High[1] > (Ask + 16 * Point)) { 
               OrderModify(OrderTicket(),
                           High[1] + 1 * Point,
                           Low[1] - 1 * Point,
                           OrderTakeProfit(),0,Aqua);
            return(0);  } //close for if(High[1] > (Ask + 16 * Point))
	  			else {
                  OrderModify(OrderTicket(),
                              Ask + 16 * Point,
                              Low[1] - 1 * Point,
                              OrderTakeProfit(),0,Aqua);
            return(0);  } //close for else statement
	  			} //close for if(High[1] < High[2])
	  		} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderType()==OP_SELLSTOP)   {
         if(Low[1] > Low[2])  { 
            if(Low[1] < (Bid - 16 * Point))  {
               OrderModify(OrderTicket(),
                           Low[1] - 1 * Point,
                           High[1] + 1 * Point,
                           OrderTakeProfit(),0,Magenta);
            return(0);  } // close for if(Low[1] < (Bid - 16 * Point))
            else   {
               OrderModify(OrderTicket(),
                           Bid - 16 * Point,
                           High[1] + 1 * Point,
                           OrderTakeProfit(),0,Magenta);
            return(0);  } //close for else statement
				} //close for if(Low[1] > Low[2])
			} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)
		} // close for for(cnt=0;cnt<total;cnt++)
	} // close for if(TradesThisSymbol > 0)
} // close for if (newbar != Time[0]) 

/////////////////////////////////////////////////
//  Stop Loss Management
/////////////////////////////////////////////////
if(TradesThisSymbol > 0)   {
   for(cnt=0;cnt<OrdersTotal();cnt++)  { 
   OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderType()==OP_BUY)  {
         if(Ask-OrderOpenPrice() > (TrailingStop * Point))  { 
            if(OrderStopLoss() < (Ask - TrailingStop * Point)) { 
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           Ask - TrailingStop * Point,
                           Ask + TakeProfit * Point,0,Aqua);
            return(0);  } // close for if(OrderStopLoss() < (Ask - TrailingStop * Point))
			} // close for if(Ask-OrderOpenPrice() > (TrailingStop * Point))
		} // close for if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderType()==OP_SELL) {
			if(OrderOpenPrice() - Bid > (TrailingStop * Point))   { 
				if(OrderStopLoss() > (Bid + TrailingStop * Point))   { 
	   		   OrderModify(OrderTicket(),
	   		               OrderOpenPrice(),
	   		               Bid + TrailingStop * Point,
	   		               Bid - TakeProfit * Point,0,Magenta);
            return(0);  } // close for if(OrderStopLoss() > (Bid + TrailingStop * Point))
			} // close for if(OrderOpenPrice() - Bid > (TrailingStop * Point))
		 } // close for if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)
  	  } // close for for(cnt=0;cnt<total;cnt++)
   } // close for if(TradesThisSymbol > 0)
} // close for start

// Functions
void PrintComments() {
Comment("TSD for MT4 ver beta 0.3 - DO NOT USE WITH REAL MONEY YET",
        "\n",
        "\n","Weekly MacdPrevious = ",MacdPrevious,"    Weekly OsMAPrevious = ",OsMAPrevious,
        "\n","Weekly MacdPrevious2 = ",MacdPrevious2,"    Weekly OsMAPrevious2 = ",OsMAPrevious2,
        "\n","Weekly Direction = ",Direction,"    Weekly OsMADirection = ",OsMADirection,
        "\n",
        "\n","Daily Force = ",Force,
        "\n","Is Daily Force Bullish = ",ForcePos,
        "\n","Is Daily Force Bearish = ",ForceNeg,
        "\n",
        "\n","Total Orders = ",OrdersTotal(),
        "\n","Trades this Symbol(",Symbol(),") = ",TradesThisSymbol,
        "\n",
        "\n","New Bar Time is ",TimeToStr(newbar),
        "\n",
        "\n","Daily High[1] = ",High[1],
        "\n","Daily High[2] = ",High[2],
        "\n","Daily Low[1] = ",Low[1],
        "\n","Daily Low[2] = ",Low[2],
        "\n",
        "\n","Current Ask Price + 16 pips = ",Ask+(16*Point),
        "\n","Current Bid Price - 16 pips = ",Bid-(16*Point)); }