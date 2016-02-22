//+------------------------------------------+
//| 2MA Expert
//+------------------------------------------+

// This one is a dog. Tried on several timeframes and no-go

/*

Put a 5 period Exponential MA of the Open, 
and a 5EMA of the Close on a chart, on any 
timeframe. The above results were given from 
the 1hr chart.

Buy when the MA of the Close crosses above 
the MA of the Open, and vice versa for reversing 
the position to Short. This is theoretically 
an "always in the market" system.

The system takes advantage of the fact that 
when the market is in an uptrend, the closes 
will be above the Opens in a given timeframe. 

And vice versa.

Now, the system catches trends VERY WELL, 
both beginning and ending, as you can see below. 
The problem, and the reason I'm writing this post, 
is that it gets whipsawed (as any trendfollowing system) 
on sideways markets.

*/

#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double        Lots = 1.0 ;
extern int     TakeProfit = 0   ;
extern int       StopLoss = 0   ;

// Global scope
double barmove0 = 0;
double barmove1 = 0;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//|------------------------------------------------------------------|

int init()
  {
   return(0);
  }


//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int start()
  {

   bool      found=false;
   bool     rising=false;
   bool    falling=false;
   bool      cross=false;

   double slA=0, slB=0, tpA=0, tpB=0;
   double p=Point();
   
   double emaF, emaM, emaS;
   double PemaF, PemaM, PemaS;
   
   int      cnt=0;

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   if(barmove0==Open[0] && barmove1==Open[1]) {                        return(0);}

   // bars moved, update current position
   barmove0=Open[0];
   barmove1=Open[1];

   // since the bar just moved
   // calculate TP and SL for (B)id and (A)sk
   tpA=Ask+(p*TakeProfit);
   slA=Ask-(p*StopLoss);
   tpB=Bid-(p*TakeProfit);
   slB=Bid+(p*StopLoss);
   if (TakeProfit<=0) {tpA=0; tpB=0;}           
   if (StopLoss<=0)   {slA=0; slB=0;}           
   

   // Hourly chart
   // 3 WMA's 5/10/15
   // ADX (14)
   //emaF= iMA(Symbol(),PERIOD_H4,  2,0,PRICE_OPEN,MODE_EMA,0);
   emaM= iMA(Symbol(),0,25,0,PRICE_OPEN,MODE_EMA,1);
   emaS= iMA(Symbol(),0,25,0,PRICE_CLOSE,MODE_EMA,1);
   PemaM= iMA(Symbol(),0,25,0,PRICE_OPEN,MODE_EMA,2);
   PemaS= iMA(Symbol(),0,25,0,PRICE_CLOSE,MODE_EMA,2);
   
   if (PemaM<emaS && emaM>emaS) { falling=true; cross=true; Print("p=",PemaM," c=",emaM," s=",emaS);}
   if (PemaM>emaS && emaM<emaS) { rising=true;  cross=true; Print("p=",PemaM," c=",emaM," s=",emaS);}

   // close then open orders based on cross
   if (cross)
     {
      // Close ALL the open orders 
      for(cnt=OrdersTotal();cnt>=0;cnt--)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            if (OrderType()==0) {OrderClose(OrderTicket(),Lots,Bid,3,White);}
            if (OrderType()==1) {OrderClose(OrderTicket(),Lots,Ask,3,Red);}
           }
        }
      // Open new order based on direction of cross
      if (rising)  OrderSend(Symbol(),OP_BUY,Lots,Ask,3,slA,tpA,"ZZZ100",11123,0,White);
      if (falling) OrderSend(Symbol(),OP_SELL,Lots,Bid,3,slB,tpB,"ZZZ100",11321,0,Red);

      return(0);
     }
     
   return(0);
  }


