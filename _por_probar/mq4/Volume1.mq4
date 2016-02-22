//+------------------------------------------------------------------+
//|                           Volume Expert - HyPip                    |
//+------------------------------------------------------------------+
   
#property copyright "Converted by Chris (*HyPip*)"
#property link      ""

extern int StopLoss = 50;
extern int TrailingStop = 20;
extern int TakeProfit = 200;
extern double Lots = 0.1;
datetime BarTime;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init()
  {
  }
  
  int start()
   {
 int cnt, ticket,TradesThisSymbol=0,total=0;
   if(Bars<100) return(0);
   //if(myStopLoss<10)return(0);

////////////////////////////////////////////////////



////////////////////////////////////////////////////

string mth,now;
if (Month() == 1) mth="January";
if (Month() == 2) mth="February";
if (Month() == 3) mth="March";
if (Month() == 4) mth="April";
if (Month() == 5) mth="May";
if (Month() == 6) mth="June";
if (Month() == 7) mth="July";
if (Month() == 8) mth="August";
if (Month() == 9) mth="September";
if (Month() == 10) mth="October";
if (Month() == 11) mth="November";
if (Month() == 12) mth="December";

now=Day()+" "+mth+" "+Year()+" "+Hour()+":"+Minute();

///////////////////////////////////////////////////

  // Prevent multiple trades on the same pair
  
    total=OrdersTotal();
     TradesThisSymbol=0;
   for(cnt=0;cnt<total;cnt++)
     { 
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
       
       if(OrderSymbol()==Symbol())
       {
         TradesThisSymbol ++;
       } 
   }

////////////////////////////////////////////////////

      if(AccountFreeMargin()<(1000*Lots))
      {
         Alert("No money. Free Margin = ", AccountFreeMargin());
         return(0);
      }
////////////////////////////////////////////////////
      


double vol1=Volume[1];
double vol2=Volume[2];

if (vol1>vol2) Comment("Down trend");
if (vol1<vol2) Comment("Up trend");
if (vol1 == vol2) return(0);

if(Symbol() == "EURUSD") double StartMinute1 = 1;
if(Symbol() == "GBPUSD") double StartMinute2 = 2;
if(Symbol() == "USDCHF") double StartMinute3 = 3;
if(Symbol() == "USDJPY") double StartMinute4 = 4;
if(Symbol() == "AUDUSD") double StartMinute5 = 5;
if(Symbol() == "USDCAD") double StartMinute6 = 6;

////////////////////////////////////////////////////


// Close if order open longer than 3 hours 57 mins

// NOTE: This section of code doesn't always seem to work - any ideas anyone?

for(cnt=0;cnt<OrdersTotal();cnt++) 
{
   OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
   if  (Hour()==11 || Hour()==15 || Hour()==19 || Hour()==23 || Hour()==3 || Hour()==7)
      {
      if (Minute()==57 || Minute()==58 || Minute()==59)
      {
      if (OrderType()==OP_BUY) 
         {
         OrderClose(OrderTicket(),Lots,Ask,3,White);
         return(0);
         }
      if (OrderType()==OP_SELL)
         {
         OrderClose(OrderTicket(),Lots,Bid,3,White);
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
  	  } // close for for(cnt=0;cnt<total;cnt++)
   } // close for if(TradesThisSymbol > 0)

// TRADE ENTRY
// This code copied from another expert - possibly TSD?

if( (Minute() >= StartMinute1) ||
   (Minute() >= StartMinute2) ||
   (Minute() >= StartMinute3) ||
   (Minute() >= StartMinute4) ||
   (Minute() >= StartMinute5) ||
   (Minute() >= StartMinute6))
{
	double DummyField = 0; // dummy statement because MT will not allow me to use a continue statement
} 
else return(0);

//exit if not new bar
if(BarTime == Time[0]) {return(0);}
//new bar, update bartime
BarTime = Time[0];

      if (TradesThisSymbol ==0)
      {
      if (vol1<vol2)
         {
            OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,"Volume BUY",638744,0,Blue);
            return(0);
         }
      if (vol1>vol2)
         {
            OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,"Volume SELL",638744,0,Red);
            return(0);
         }
      }
      

return(0);
}