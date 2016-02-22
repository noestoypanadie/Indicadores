//+------------------------------------------+
//| 3MA Expert
//+------------------------------------------+


/*

Ok its on a 4 hr chart, 
3 emas 100, 15, 2

Enter a position when emaF and emaS 
both cross through the 100ema (thats it!!)

ok the exit, i feel this needs a little work, 
but at the moment it is as follows

Exit half your position when 2ema cross through 15ema, 
close all of your positon when emaF crosses back through emaS.

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
   
   emaM= iMA(Symbol(),PERIOD_H4, 15,0,PRICE_OPEN,MODE_EMA,0);
   emaS= iMA(Symbol(),PERIOD_H4,100,0,PRICE_OPEN,MODE_EMA,0);
   
   PemaM=iMA(Symbol(),PERIOD_H4, 15,0,PRICE_OPEN,MODE_EMA,1);
   PemaS=iMA(Symbol(),PERIOD_H4,100,0,PRICE_OPEN,MODE_EMA,1);
   
   if (PemaM<emaS && emaM>emaS) { rising=true;  cross=true; Print("p=",PemaM," c=",emaM," s=",emaS);}
   if (PemaM>emaS && emaM<emaS) { falling=true; cross=true; Print("p=",PemaM," c=",emaM," s=",emaS);}

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


