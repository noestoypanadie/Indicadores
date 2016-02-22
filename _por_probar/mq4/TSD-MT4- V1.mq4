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

extern double Lots = 1.0;
extern double TakeProfit = 100;
extern double Stoploss = 0;
extern double TrailingStop = 60;	
extern double Slippage=5;			// Slippage
extern double StopYear=2005;
extern double MM=0,Leverage=1,AcctSize=10000;

int BuyEntryOrderTicket=0,SellEntryOrderTicket=0;

double MacdCurrent=0, MacdPrevious=0, MacdPrevious2=0 ,Direction=0;
string PosNeg="",GlobalName="";
double newbar=0,PrevDay=0,PrevMonth=0,PrevYear=0,PrevCurtime=0;

double PriceOpen=0;								// Price Open
double I=0;										// Misc Counter
double NewBar=0;
bool First=True;
double LotMM=0,LotSize=10000,LotMax=50;
double TradesThisSymbol=0;
double ForcePos=0, ForceNeg=0, NewPrice=0;
double StartMinute1=0,EndMinute1=0,StartMinute2=0,EndMinute2=0,StartMinute3=0,EndMinute3=0;
double StartMinute4=0,EndMinute4=0,StartMinute5=0,EndMinute5=0,StartMinute6=0,EndMinute6=0;
double StartMinute7=0,EndMinute7=0,DummyField=0;

int start()
{

   if (newbar != Time[0]) 
   {
	  newbar        = Time[0];
     MacdCurrent   = iMACD(NULL,10080,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
	  MacdPrevious  = iMACD(NULL,10080,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
	  MacdPrevious2 = iMACD(NULL,10080,12,26,9,PRICE_CLOSE,MODE_MAIN,2);
	  if (MacdPrevious > MacdPrevious2) Direction = 1;
	  if (MacdPrevious < MacdPrevious2) Direction = -1;
	  if (MacdPrevious == MacdPrevious2) Direction = 0;
	  
	  Comment("Weekly MACD Direction is ",Direction,
           "\n","MacdPrevious = ",MacdPrevious," MacdPrevious2 = ",MacdPrevious2);
           
	  int total,cnt;  
     total=OrdersTotal();
	  for(cnt=0;cnt<total;cnt++)
     { 
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
	      
	      if(OrderSymbol()==Symbol())
	      {
	        TradesThisSymbol ++;
	      }
	  }
	  
// Select a range of minutes in the day to start trading based on the currency pair.
// This is to stop collisions occurring when 2 or more currencies set orders at the same time.

if(Symbol() == "USDCHF")
{
    StartMinute1 = 0;
	EndMinute1   = 1;
    StartMinute2 = 8;
	EndMinute2   = 9;
    StartMinute3 = 16;
	EndMinute3   = 17;
    StartMinute4 = 24;
	EndMinute4   = 25;
    StartMinute5 = 32;
	EndMinute5   = 33;
    StartMinute6 = 40;
	EndMinute6   = 41;
    StartMinute7 = 48;
	EndMinute7   = 49;
}
if(Symbol() == "GBPUSD")
{  
    StartMinute1 = 2;
	EndMinute1   = 3;
    StartMinute2 = 10;
	EndMinute2   = 11;
    StartMinute3 = 18;
	EndMinute3   = 19;
    StartMinute4 = 26;
	EndMinute4   = 27;
    StartMinute5 = 34;
	EndMinute5   = 35;
    StartMinute6 = 42;
	EndMinute6   = 43;
    StartMinute7 = 50;
	EndMinute7   = 51;
}
if(Symbol() == "USDJPY")
{
    StartMinute1 = 4;
	EndMinute1   = 5;
    StartMinute2 = 12;
	EndMinute2   = 13;
    StartMinute3 = 20;
	EndMinute3   = 21;
    StartMinute4 = 28;
	EndMinute4   = 29;
    StartMinute5 = 36;
	EndMinute5   = 37;
    StartMinute6 = 44;
	EndMinute6   = 45;
    StartMinute7 = 52;
	EndMinute7   = 53;
}
if(Symbol() == "EURUSD")
{
    StartMinute1 = 6;
	EndMinute1   = 7;
    StartMinute2 = 14;
	EndMinute2   = 15;
    StartMinute3 = 22;
	EndMinute3   = 23;
    StartMinute4 = 30;
	EndMinute4   = 31;
    StartMinute5 = 38;
	EndMinute5   = 39;
    StartMinute6 = 46;
	EndMinute6   = 47;
    StartMinute7 = 54;
	EndMinute7   = 59;
}

if( (Minute() >= StartMinute1 && Minute() <= EndMinute1) ||
   (Minute() >= StartMinute2 && Minute() <= EndMinute2) ||
   (Minute() >= StartMinute3 && Minute() <= EndMinute3) ||
   (Minute() >= StartMinute4 && Minute() <= EndMinute4) ||
   (Minute() >= StartMinute5 && Minute() <= EndMinute5) ||
   (Minute() >= StartMinute6 && Minute() <= EndMinute6) ||
   (Minute() >= StartMinute7 && Minute() <= EndMinute7) )
{
	DummyField = 0; // dummy statement because MT will not allow me to use a continue statement
}
else return(0);

	 if(TradesThisSymbol < 1) 
	 {
	   ForcePos = iForce(NULL,1440,2,MODE_EMA,PRICE_CLOSE,1) > 0;
		ForceNeg = iForce(NULL,1440,2,MODE_EMA,PRICE_CLOSE,1) < 0;
	   
	   if(Direction == 1 && ForceNeg)
		{
			PriceOpen = High[1] + 1 * Point;		// Buy 1 point above high of previous candle
			if(PriceOpen > (Ask + 16 * Point))  // Check if buy price is a least 16 points > Ask
			{
				BuyEntryOrderTicket=OrderSend(Symbol(),OP_BUYSTOP,Lots,PriceOpen,Slippage,Low[1] - 1 * Point,PriceOpen + TakeProfit * Point,"Buy Entry Order placed at "+CurTime(),0,0,Green);
				return(0);

			}
			else
			{
			   NewPrice = Ask + 16 * Point;
				BuyEntryOrderTicket=OrderSend(Symbol(),OP_BUYSTOP,Lots,NewPrice,Slippage,Low[1] - 1 * Point,NewPrice + TakeProfit * Point,"Buy Entry Order placed at "+CurTime(),0,0,Green);
				return(0);
			}
	   }
     
     
     if(Direction == -1 && ForcePos)
     {
         PriceOpen = Low[1] - 1 * Point;
			if(PriceOpen < (Bid - 16 * Point)) // Check if buy price is a least 16 points < Bid
			{
				SellEntryOrderTicket=OrderSend(Symbol(),OP_SELLSTOP,Lots,PriceOpen,Slippage,High[1] + 1 * Point,PriceOpen - TakeProfit * Point,"Sell Entry Order placed at "+CurTime(),0,0,Green);
				return(0);
			}
			else
			{
				NewPrice = Bid - 16 * Point;
				SellEntryOrderTicket=OrderSend(Symbol(),OP_SELLSTOP,Lots,NewPrice,Slippage,High[1] + 1 * Point,NewPrice - TakeProfit * Point,"Sell Entry Order placed at "+CurTime(),0,0,Green);
            return(0);			
			}

      }
    }


/////////////////////////////////////////////////
//  Pending Order Management
/////////////////////////////////////////////////
     if(OrderSymbol()==Symbol())
  		{
   			if(OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP)
   			{
   				   OrderDelete(OrderTicket());
   			}
     	} // Close of symbol check	
	}

	if(TradesThisSymbol > 0)
	{
      total=OrdersTotal();
      for(cnt=0;cnt<total;cnt++)
  	   { 
  	      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)
         {

				if(Direction == -1)
  				{ 
  				   OrderDelete(OrderTicket());
	        		return(0); 
				}
			}

         if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)
         {

				if(Direction == 1)
  				{ 
  				   OrderDelete(OrderTicket());
	        		return(0); 
				}
			}


         if(OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)
   	   {
				if(High[1] < High[2])
	  			{ 
					if(High[1] > (Ask + 16 * Point))
					{ 
		   		  OrderModify(OrderTicket(),High[1] + 1 * Point,Low[1] - 1 * Point,OrderTakeProfit(),0,Cyan);
                 return(0);					
					}
					else
					{
					  OrderModify(OrderTicket(),Ask + 16 * Point,Low[1] - 1 * Point,OrderTakeProfit(),0,Cyan);
                 return(0);					
					
					}
				}
			}
	
	      if(OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP)
   		{
				if(Low[1] > Low[2])
				{ 
					if(Low[1] < (Bid - 16 * Point))
					{
		   		  OrderModify(OrderTicket(),Low[1] - 1 * Point,High[1] + 1 * Point,OrderTakeProfit(),0,Cyan);
                 return(0);					
					}
					else
					{
					  OrderModify(OrderTicket(),Bid - 16 * Point,High[1] + 1 * Point,OrderTakeProfit(),0,Cyan);
                 return(0);					

					}
				}
			}
		}
	


/////////////////////////////////////////////////
//  Stop Loss Management
/////////////////////////////////////////////////
if(TradesThisSymbol > 0)
{
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

				}
			}
		}
	
     if(OrderSymbol()==Symbol() && OrderType()==OP_SELL)
		{
			if(OrderOpenPrice() - Bid > (TrailingStop * Point))
			{ 
				if(OrderStopLoss() > (Bid + TrailingStop * Point))
				{ 
	   		   OrderModify(OrderTicket(),OrderOpenPrice(),Bid + TrailingStop * Point,Bid - TakeProfit * Point,0,Cyan);
               return(0);					

				}
			}
		 }
  	  }	
   }
 } 
	

Comment("Weekly MACD Direction is ",Direction,
           "\n","MacdPrevious = ",MacdPrevious," MacdPrevious2 = ",MacdPrevious2);
return(0);

}

