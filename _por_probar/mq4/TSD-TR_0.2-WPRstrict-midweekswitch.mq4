/*[[
	Name := TSD
	Author := Copyright © 2005 Bob O'Brien / Barcode, MT4 code by Jesse Breaker, modified by TR
	Link := 
	Notes := Based on Alexander Elder's Triple Screen system. To be run on ANY chart timeframe, but assumes that each daily bar starts at 00:00.
	Lots := 1
	Stop Loss := 0
	Take Profit := 100
	Trailing Stop := 60
]]*/
//+------------------------------------------------------------------+
//|  External Variables                                              |
//+------------------------------------------------------------------+

extern double LotsIfNoMM = 1.0;
extern int TakeProfit = 100;
extern int Stoploss = 0;
extern int TrailingStop = 60;	
extern int WPRperiod=24;		
extern int Slippage=5;			// Slippage
extern int MM_Mode=0,MM_Risk=20;

int cnt=0,total=0,Leverage=10;

double MacdCurrent=0, MacdPrevious=0, MacdPrevious2=0, Direction=0, OsMAPrevious=0, OsMAPrevious2=0, OsMADirection=0;

double newbar=999,LastLogTime=0,PrevDay=0,PrevMonth=0,PrevYear=0,PrevCurtime=0;

double PriceOpen=0,Lots;								// Price Open


bool First=True,OperationSuccess;

double TradesThisSymbol=0;
double WilliamsBuy=0, WilliamsSell=0, ForcePos=0, ForceNeg=0, Force=0,NewPrice=0;
double StartMinute1=0,EndMinute1=0,StartMinute2=0,EndMinute2=0,StartMinute3=0,EndMinute3=0;
double StartMinute4=0,EndMinute4=0,StartMinute5=0,EndMinute5=0,StartMinute6=0,EndMinute6=0;
double StartMinute7=0,EndMinute7=0,DummyField=0;

int start()
{
Lots=NormalizeDouble(MathCeil(AccountBalance()*Leverage/1000)/100,2);
if (! IsTesting()) 
Comment("TSD for MT4 ver beta 0.3 - DO NOT USE WITH REAL MONEY YET",
        "\n",
        "\n","Weekly MacdPrevious = ",MacdPrevious,"    Weekly OsMAPrevious = ",OsMAPrevious,
        "\n","Weekly MacdPrevious2 = ",MacdPrevious2,"    Weekly OsMAPrevious2 = ",OsMAPrevious2,
        "\n","Weekly Direction = ",Direction,"    Weekly OsMADirection = ",OsMADirection,
        "\n",
        "\n","Is Daily Williams Bullish = ",WilliamsBuy,
        "\n","Is Daily Williams Bearish = ",WilliamsSell,
        "\n",
        "\n","Total Orders = ",total,
        "\n","Trades this Symbol(",Symbol(),") = ",TradesThisSymbol,
        "\n",
        "\n","New Bar Time is ",TimeToStr(newbar),
        "\n",
        "\n","Daily High[1] = ",iHigh(Symbol(),PERIOD_D1, 1),
        "\n","Daily High[2] = ",iHigh(Symbol(),PERIOD_D1, 2),
        "\n","Daily Low[1] = ",iLow(Symbol(),PERIOD_D1, 1),
        "\n","Daily Low[2] = ",iLow(Symbol(),PERIOD_D1, 2),
        "\n",
        "\n","Current Ask Price + 16 pips = ",Ask+(16*Point),
        "\n","Current Bid Price - 16 pips = ",Bid-(16*Point));
        
        
        
   if (MM_Mode < 0)  {
   Lots = MathCeil(AccountBalance()*MM_Risk/10000)/10;
     if (Lots > 100) {  
     Lots = 100;  
     }
   } else {
   Lots = LotsIfNoMM;
   }
   if (MM_Mode > 0)  
    {
   Lots = MathCeil(AccountBalance()*MM_Risk/10000)/10;
    if (Lots > 1)  
    {
    Lots = MathCeil(Lots);
    }
    if (Lots < 1)  
    {
    Lots = 1;
    }
    if (Lots > 100)  
    {  
     Lots = 100;  
     }
   }
        

     
	            
/////////////////////////////////////////////////
//  Process the next bar details
/////////////////////////////////////////////////

if (newbar != TimeDayOfWeek(CurTime())) 
{
	 newbar        = TimeDayOfWeek(CurTime());
	 //Newbar will be reset to 999 if the once-a-day order operations below fail, to ensure that they are retried on the next tick.


	  MacdPrevious  = iMACD(NULL,10080,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
	  MacdPrevious2 = iMACD(NULL,10080,12,26,9,PRICE_CLOSE,MODE_MAIN,2);
	  
	  if (newbar<4) //Modify this to switch to using current week's OSMA on a specific day of the week (0-Sunday,1,2,3,4,5,6) 
         {
         OsMAPrevious  = iOsMA(NULL,10080,12,26,9,PRICE_CLOSE,1);
	      OsMAPrevious2 = iOsMA(NULL,10080,12,26,9,PRICE_CLOSE,2);
         }
         else
         {
         OsMAPrevious  = iOsMA(NULL,10080,12,26,9,PRICE_CLOSE,0);
	      OsMAPrevious2 = iOsMA(NULL,10080,12,26,9,PRICE_CLOSE,1);
         }
         
	  //OsMAPrevious  = iCustom(NULL,10080,"OsMAtestclone_0.5",12,26,9,0,1);
	  //OsMAPrevious2 = iCustom(NULL,10080,"OsMAtestclone_0.5",12,26,9,0,2);
	  //OsMAPrevious  = iCustom(NULL,PERIOD_D1,"OsMA_5_bar_rolling_0.4",12,26,9,0,1);
	  //OsMAPrevious2 = iCustom(NULL,PERIOD_D1,"OsMA_5_bar_rolling_0.4",12,26,9,0,2);

     /*
     Force = iForce(NULL,1440,2,MODE_EMA,PRICE_CLOSE,1); 
     ForcePos = iForce(NULL,1440,2,MODE_EMA,PRICE_CLOSE,1) > 0;
	  ForceNeg = iForce(NULL,1440,2,MODE_EMA,PRICE_CLOSE,1) < 0;
      */
      
	  WilliamsBuy = iWPR(NULL,1440,WPRperiod,1) < -50;
	  WilliamsSell = iWPR(NULL,1440,WPRperiod,1) >= -50;


	  if (MacdPrevious > MacdPrevious2) Direction = 1;
	  if (MacdPrevious < MacdPrevious2) Direction = -1;
	  if (MacdPrevious == MacdPrevious2) Direction = 0;
	  
	  if (OsMAPrevious > OsMAPrevious2) OsMADirection = 1;
	  if (OsMAPrevious < OsMAPrevious2) OsMADirection = -1;
	  if (OsMAPrevious == OsMAPrevious2) OsMADirection = 0;
	          
        
        

/////////////////////////////////////////////////
//  Pending Order Management
/////////////////////////////////////////////////

   total=OrdersTotal();
      TradesThisSymbol=0;
      for(cnt=0;cnt<total;cnt++)
      { 
          OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      
          if(OrderSymbol()==Symbol())
          {
            TradesThisSymbol ++;
          } // close for if(OrderSymbol()==Symbol())
      } // close for for(cnt=0;cnt<total;cnt++)        

   if(TradesThisSymbol > 0)
	{
      total=OrdersTotal();
      for(cnt=0;cnt<total;cnt++)
  	   { 
  	      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)
         {

				if(OsMADirection == -1)
  				{ 
  				   OperationSuccess=OrderDelete(OrderTicket());
  				   if (OperationSuccess==FALSE)
  				      {
  				      newbar=999;
  				      return(0);
  				      }
				} // close for if(Direction == -1)
			} // close for if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)

         if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)
         {

				if(OsMADirection == 1)
  				{ 
  				   OperationSuccess=OrderDelete(OrderTicket());
  				   if (OperationSuccess==FALSE)
  				      {
  				      newbar=999;
  				      return(0);
  				      }
				} //close for if(Direction == 1)
			} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)


         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)
   	   {
				if(iHigh(Symbol(),PERIOD_D1, 1) < iHigh(Symbol(),PERIOD_D1, 2))
	  			{ 
					if(iHigh(Symbol(),PERIOD_D1, 1) > (Ask + 16 * Point))
	  				{ 
	  	   		  OperationSuccess=OrderModify(OrderTicket(),iHigh(Symbol(),PERIOD_D1, 1) + 1 * Point,iLow(Symbol(),PERIOD_D1, 1) - 1 * Point,iHigh(Symbol(),PERIOD_D1, 1) + 1 * Point + TakeProfit * Point,0,Cyan);
  				      if (OperationSuccess==FALSE)
  				         {
  				         newbar=999;
  				         return(0);
  				         }
	  				} //close for if(iHigh(Symbol(),PERIOD_D1, 1) > (Ask + 16 * Point))
	  				else
	  				{
	  				  OperationSuccess=OrderModify(OrderTicket(),Ask + 16 * Point,iLow(Symbol(),PERIOD_D1, 1) - 1 * Point,Ask + 16 * Point + TakeProfit * Point,0,Cyan);
  				      if (OperationSuccess==FALSE)
  				         {
  				         newbar=999;
  				         return(0);
  				         }
	  				
	  				} //close for else statement
	  			} //close for if(iHigh(Symbol(),PERIOD_D1, 1) < iHigh(Symbol(),PERIOD_D1, 2))
	  		} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)
	  
	      if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)
   		{
				if(iLow(Symbol(),PERIOD_D1, 1) > iLow(Symbol(),PERIOD_D1, 2))
				{ 
					if(iLow(Symbol(),PERIOD_D1, 1) < (Bid - 16 * Point))
					{
		   		  OperationSuccess=OrderModify(OrderTicket(),iLow(Symbol(),PERIOD_D1, 1) - 1 * Point,iHigh(Symbol(),PERIOD_D1, 1) + 1 * Point,iLow(Symbol(),PERIOD_D1, 1) - 1 * Point - TakeProfit * Point,0,Cyan);
  				      if (OperationSuccess==FALSE)
  				         {
  				         newbar=999;
  				         return(0);
  				         }
					} // close for if(iLow(Symbol(),PERIOD_D1, 1) < (Bid - 16 * Point))
					else
					{
					  OperationSuccess=OrderModify(OrderTicket(),Bid - 16 * Point,iHigh(Symbol(),PERIOD_D1, 1) + 1 * Point,Bid - 16 * Point - TakeProfit * Point,0,Cyan);
  				      if (OperationSuccess==FALSE)
  				         {
  				         newbar=999;
  				         return(0);
  				         }
      
					} //close for else statement
				} //close for if(iLow(Symbol(),PERIOD_D1, 1) > iLow(Symbol(),PERIOD_D1, 2))
			} //close for if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)
		} // close for for(cnt=0;cnt<total;cnt++)
	} // close for if(TradesThisSymbol > 0)


/////////////////////////////////////////////////
//  NEW Orders to Place
/////////////////////////////////////////////////


   total=OrdersTotal();
     TradesThisSymbol=0;
     for(cnt=0;cnt<total;cnt++)
     { 
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      
         if(OrderSymbol()==Symbol())
         {
           TradesThisSymbol ++;
         } // close for if(OrderSymbol()==Symbol())
     } // close for for(cnt=0;cnt<total;cnt++)        

	 if(TradesThisSymbol < 1) 
	 {
	   
	   if(OsMADirection == 1 && WilliamsBuy)
		{
			PriceOpen = iHigh(Symbol(),PERIOD_D1, 1) + 1 * Point;		// Buy 1 point above high of previous candle
			if(PriceOpen > (Ask + 16 * Point))  // Check if buy price is a least 16 points > Ask
			{
				OperationSuccess=OrderSend(Symbol(),OP_BUYSTOP,Lots,PriceOpen,Slippage,iLow(Symbol(),PERIOD_D1, 1) - 1 * Point,PriceOpen + TakeProfit * Point,"Buy Entry Order placed at "+CurTime(),0,0,Green);
		      if (OperationSuccess==FALSE)
		         {
		         newbar=999;
		         return(0);
		         }
      
			} // close for if(PriceOpen > (Ask + 16 * Point))
			else
			{
			   NewPrice = Ask + 16 * Point;
				OperationSuccess=OrderSend(Symbol(),OP_BUYSTOP,Lots,NewPrice,Slippage,iLow(Symbol(),PERIOD_D1, 1) - 1 * Point,NewPrice + TakeProfit * Point,"Buy Entry Order placed at "+CurTime(),0,0,Green);
		      if (OperationSuccess==FALSE)
		         {
		         newbar=999;
		         return(0);
		         }
 			} // close for else statement
	   } // close for if(Direction == 1 && WilliamsSell)
     
     
     if(OsMADirection == -1 && WilliamsSell)
     {
         PriceOpen = iLow(Symbol(),PERIOD_D1, 1) - 1 * Point;
			if(PriceOpen < (Bid - 16 * Point)) // Check if buy price is a least 16 points < Bid
			{
				OperationSuccess=OrderSend(Symbol(),OP_SELLSTOP,Lots,PriceOpen,Slippage,iHigh(Symbol(),PERIOD_D1, 1) + 1 * Point,PriceOpen - TakeProfit * Point,"Sell Entry Order placed at "+CurTime(),0,0,Green);
		      if (OperationSuccess==FALSE)
		         {
		         newbar=999;
		         return(0);
		         }
			} // close for if(PriceOpen < (Bid - 16 * Point))
			else
			{
				NewPrice = Bid - 16 * Point;
				OperationSuccess=OrderSend(Symbol(),OP_SELLSTOP,Lots,NewPrice,Slippage,iHigh(Symbol(),PERIOD_D1, 1) + 1 * Point,NewPrice - TakeProfit * Point,"Sell Entry Order placed at "+CurTime(),0,0,Green);
		      if (OperationSuccess==FALSE)
		         {
		         newbar=999;
		         return(0);
		         }
			} // close for else statement

      } // close for if(Direction == -1 && WilliamsBuy)
    } //Close of if(TradesThisSymbol < 1)





} // close for if (newbar != Time[0]) 




/////////////////////////////////////////////////
//  Stop Loss Management
/////////////////////////////////////////////////

total=OrdersTotal();
  TradesThisSymbol=0;
  for(cnt=0;cnt<total;cnt++)
  { 
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      
      if(OrderSymbol()==Symbol())
      {
        TradesThisSymbol ++;
      } // close for if(OrderSymbol()==Symbol())
  } // close for for(cnt=0;cnt<total;cnt++)        

if(TradesThisSymbol > 0)
{
  total=OrdersTotal();
  for(cnt=0;cnt<total;cnt++)
  { 
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

     if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)
    	{
         
         if (IsTesting() && LastLogTime != iTime(NULL,PERIOD_H1,1)) 
         {
            LastLogTime=iTime(NULL,PERIOD_H1,1);
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit()+Point*1,0,Cyan);
         }


			if(Ask-OrderOpenPrice() > (TrailingStop * Point))
  			{ 
				if(OrderStopLoss() < (Ask - TrailingStop * Point))
				{ 
	   		   OrderModify(OrderTicket(),OrderOpenPrice(),Ask - TrailingStop * Point,Ask + TakeProfit * Point,0,Cyan);
               //return(0);					

				} // close for if(OrderStopLoss() < (Ask - TrailingStop * Point))
			} // close for if(Ask-OrderOpenPrice() > (TrailingStop * Point))
		} // close for if(OrderSymbol()==Symbol() && OrderType()==OP_BUY)
	
     if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)
		{
		
         if (IsTesting() && LastLogTime != iTime(NULL,PERIOD_H1,1)) 
         {
            LastLogTime=iTime(NULL,PERIOD_H1,1);
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit()-Point*1,0,Cyan);
         }


			if(OrderOpenPrice() - Bid > (TrailingStop * Point))
			{ 
				if(OrderStopLoss() > (Bid + TrailingStop * Point))
				{ 
	   		   OrderModify(OrderTicket(),OrderOpenPrice(),Bid + TrailingStop * Point,Bid - TakeProfit * Point,0,Cyan);
               //return(0);					

				} // close for if(OrderStopLoss() > (Bid + TrailingStop * Point))
			} // close for if(OrderOpenPrice() - Bid > (TrailingStop * Point))
         //else if (IsTesting()) OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit()-Point*1,0,Cyan);
		 } // close for if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)
  	  } // close for for(cnt=0;cnt<total;cnt++)
   } // close for if(TradesThisSymbol > 0)
  
	

//return(0);

} // close for start

