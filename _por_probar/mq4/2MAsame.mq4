//+------------------------------------------+
//| 2MA same style, different origin
//+------------------------------------------+

#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double        Lots = 1.0 ;

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

   double p=Point();
   
   double  ma1, ma2, pma2;
   
   int      cnt=0;

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   //if(barmove0==Open[0] && barmove1==Open[1]) {                        return(0);}

   // bars moved, update current position
   //barmove0=Open[0];
   //barmove1=Open[1];

   ma1= iMA(Symbol(),PERIOD_H1, 24   ,0,PRICE_OPEN,MODE_SMA,0);
   ma2= iMA(Symbol(),PERIOD_M15,24*4 ,0,PRICE_OPEN,MODE_SMA,0);
   pma2=iMA(Symbol(),PERIOD_M15,24*4 ,0,PRICE_OPEN,MODE_SMA,1);

   if (pma2<ma1 && ma2>ma1) { rising=true;  cross=true;}
   if (pma2>ma1 && ma2<ma1) { falling=true; cross=true;}

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
      if (rising)  OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"ZZZ100",11123,0,White);
      if (falling) OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"ZZZ100",11321,0,Red);

      return(0);
     }
     
   return(0);
  }


