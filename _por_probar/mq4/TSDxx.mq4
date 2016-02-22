/*[[
	Name := TDSGlobal
	Author := Copyright © 2005 Bob O'Brien / Barcode, Modified by Frank Chamanara(to be run on a 4hr chart)
	Link := 
	Notes := Based on Alexander Elder's Triple Screen system, Weekly System.
]]*/

//+------------------------------------------------------------------+
//|  External Variables                                              |
//+------------------------------------------------------------------+

extern int Lots = 1;
extern int TakeProfit = 50;
extern int Stoploss = 25;
extern int TrailingStop = 20;	
extern int Slippage=5;			// Slippage
//+------------------------------------------------------------------+
//|   Internal Variables                                             |
//+------------------------------------------------------------------+

int BuyEntryOrderTicket=0,SellEntryOrderTicket=0,cnt=0,total=0,h,m,risk=20;

double MacdCurrent=0, MacdPrevious=0, MacdPrevious2=0, Direction=0, OsMAPrevious=0, OsMAPrevious2=0, OsMADirection=0;
double O1,H1,L1,newbar=0;
double PriceOpen=0,lotMM;
double ForcePos=0, ForceNeg=0, Force=0,NewPrice=0;						

bool First=True;
bool hasatrade=false;

datetime prevtime=0;

int start()
{

// initial data checks

   if(Bars<50)
     {
      Print("bars less than 50");
      return(0);  
     }

	     Comment(Year(),"-",Month(),"-",Day(),"  ",Hour(),":",Minute(),
        "\n","MacdPrevious = ",MacdPrevious,"    OsMAPrevious = ",OsMAPrevious,
        "\n","MacdPrevious2 = ",MacdPrevious2,"   OsMAPrevious2 = ",OsMAPrevious2,
        "\n","Direction = ",Direction,"    OsMADirection = ",OsMADirection,
        "\n",
        "\n","Daily Force = ",Force,
        "\n","Is Force Bullish = ",ForcePos,
        "\n","Is Force Bearish = ",ForceNeg,
        "\n",
        "\n","Total Orders = ",total,
        "\n",
        "\n","Daily Open = ",O1,
        "\n","Daily High = ",H1,
        "\n","Daily Low = ",L1,
        "\n",
        "\n","Current Ask Price + 16 pips = ",Ask+(16*Point),
        "\n","Current Bid Price - 16 pips = ",Bid-(16*Point));  
     
if(prevtime == Time[0]) return(0);      // Always start at the new bar
prevtime = Time[0];

// =================================================================================
// PYRAMIDING - LINEAR
// Money Management risk exposure compounding
// =================================================================================
  lotMM = (MathCeil(AccountBalance() * risk / 20000) / 10);
  if (lotMM < 0.1) lotMM = Lots;
  if (lotMM > 1.0) lotMM = MathCeil(lotMM);

/////////////////////////////////////////////////
//  Pending Order Management
/////////////////////////////////////////////////
total=OrdersTotal();
hasatrade = false;   
for(cnt=0;cnt<total;cnt++)
{
OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)
         {
            hasatrade = true;
				if(OsMADirection == -1)
  				{ 
  				   OrderDelete(OrderTicket());
	        		return(0); 
				} // close for if(Direction == -1)
			} // close for if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)

         if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)
         {
            hasatrade = true;
				if(OsMADirection == 1)
  				{ 
  				   OrderDelete(OrderTicket());
	        		return(0); 
				} //close for if(Direction == 1)
			} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)


         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)
   	   {
				if(High[1] < High[2])
	  			{ 
					if(High[1] > (Ask + 16 * Point))
	  				{ 
	  	   		  OrderModify(OrderTicket(),High[1] + 1 * Point,Low[1] - 1 * Point,OrderTakeProfit(),0,Cyan);
                 return(0);					
	  				} //close for if(High[1] > (Ask + 16 * Point))
	  				else
	  				{
	  				  OrderModify(OrderTicket(),Ask + 16 * Point,Low[1] - 1 * Point,OrderTakeProfit(),0,Cyan);
                 return(0);					
	  				
	  				} //close for else statement
	  			} //close for if(High[1] < High[2])
	  		} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)
	  
	      if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)
   		{
				if(Low[1] > Low[2])
				{ 
					if(Low[1] < (Bid - 16 * Point))
					{
		   		  OrderModify(OrderTicket(),Low[1] - 1 * Point,High[1] + 1 * Point,OrderTakeProfit(),0,Cyan);
                 return(0);					
					} // close for if(Low[1] < (Bid - 16 * Point))
					else
					{
					  OrderModify(OrderTicket(),Bid - 16 * Point,High[1] + 1 * Point,OrderTakeProfit(),0,Cyan);
                 return(0);					
      
					} //close for else statement
				} //close for if(Low[1] > Low[2])
			} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)
			
			
} // close for for(cnt=0;cnt<total;cnt++)
      
  if(AccountFreeMargin()<(100*Lots))
    {
     Print("We have no money. Free Margin = ", AccountFreeMargin());    
     return(0);  
    }      
  

     h = TimeHour(CurTime());
     m = TimeMinute(CurTime());
     O1=iOpen(NULL,1440,1);
     H1=iHigh(NULL,1440,1);
     L1=iLow(NULL,1440,1);

     
	  MacdPrevious  = iMACD(NULL,240,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
	  MacdPrevious2 = iMACD(NULL,240,12,26,9,PRICE_CLOSE,MODE_MAIN,2);
	  
	  OsMAPrevious  = iOsMA(NULL,240,12,26,9,PRICE_CLOSE,1);
	  OsMAPrevious2 = iOsMA(NULL,240,12,26,9,PRICE_CLOSE,2);

     Force = iForce(NULL,60,24,MODE_EMA,PRICE_CLOSE,1); 
     ForcePos = iForce(NULL,60,24,MODE_EMA,PRICE_CLOSE,1) > 0;
	  ForceNeg = iForce(NULL,60,24,MODE_EMA,PRICE_CLOSE,1) < 0;

	  
	  if (MacdPrevious > MacdPrevious2) Direction = 1;
	  if (MacdPrevious < MacdPrevious2) Direction = -1;
	  if (MacdPrevious == MacdPrevious2) Direction = 0;
	  
	  if (OsMAPrevious > OsMAPrevious2) OsMADirection = 1;
	  if (OsMAPrevious < OsMAPrevious2) OsMADirection = -1;
	  if (OsMAPrevious == OsMAPrevious2) OsMADirection = 0;
	   

/////////////////////////////////////////////////////////////////
//  Process the next bar details for any possible buy/sell order
/////////////////////////////////////////////////////////////////
if (!hasatrade)   // no open orders
{   
	   
	   if(OsMADirection == 1 && ForceNeg)
		{
			PriceOpen = High[1] + 1 * Point;		// Buy 1 point above high of previous candle
			if(PriceOpen > (Ask + 16 * Point))  // Check if buy price is a least 16 points > Ask
			{
				BuyEntryOrderTicket=OrderSend(Symbol(),OP_BUYSTOP,lotMM,PriceOpen,Slippage,Low[1] - 1 * Point,PriceOpen + TakeProfit * Point,"Buy Entry Order placed at "+CurTime(),0,0,Green);
				return(0);

			} // close for if(PriceOpen > (Ask + 16 * Point))
			else
			{
			   NewPrice = Ask + 16 * Point;
				BuyEntryOrderTicket=OrderSend(Symbol(),OP_BUYSTOP,lotMM,NewPrice,Slippage,Low[1] - 1 * Point,NewPrice + TakeProfit * Point,"Buy Entry Order placed at "+CurTime(),0,0,Green);
				return(0);
			} // close for else statement
	   } // close for if(Direction == 1 && ForceNeg)
     
     
     if(OsMADirection == -1 && ForcePos)
     {
         PriceOpen = Low[1] - 1 * Point;
			if(PriceOpen < (Bid - 16 * Point)) // Check if buy price is a least 16 points < Bid
			{
				SellEntryOrderTicket=OrderSend(Symbol(),OP_SELLSTOP,lotMM,PriceOpen,Slippage,High[1] + 1 * Point,PriceOpen - TakeProfit * Point,"Sell Entry Order placed at "+CurTime(),0,0,Green);
				return(0);
			} // close for if(PriceOpen < (Bid - 16 * Point))
			else
			{
				NewPrice = Bid - 16 * Point;
				SellEntryOrderTicket=OrderSend(Symbol(),OP_SELLSTOP,lotMM,NewPrice,Slippage,High[1] + 1 * Point,NewPrice - TakeProfit * Point,"Sell Entry Order placed at "+CurTime(),0,0,Green);
            return(0);			
			} // close for else statement

      } // close for if(Direction == -1 && ForcePos)

} // end of hasatrade 

/////////////////////////////////////////////////
//  Stop Loss Management
/////////////////////////////////////////////////

  total=OrdersTotal();
  for(cnt=0;cnt<total;cnt++)
  { 
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

     if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)
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
	
     if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)
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
		 
}  // close for for(cnt=0;cnt<total;cnt++)
//return(0);
} // close for int start

