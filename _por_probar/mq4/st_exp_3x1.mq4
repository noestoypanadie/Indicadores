//+------------------------------------------------------------------+
//| 1MA Expert                               |
//+------------------------------------------------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern double MovingAvg = 10;

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
   double   cMA=0, pMA=0;
   double   p=Point();
      
   bool     found=false;
   bool    rising=false;
   bool   falling=false;
   bool    bought=false;
   bool      sold=false;

   int      cnt=0;
   int      err=0;
   
   int      rty=0;
   

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   if(barmove0==Open[0] && barmove1==Open[1]) {                        return(0);}

   // bars moved, update current position
   barmove0=Open[0];
   barmove1=Open[1];



   // PRICE_OPEN is the only stable price point for Bar0
   cMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 0);
   pMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 1);

   // is the MA rising or falling (N-pip filter)
   // filter affects close AND buy transactions
   if (pMA<cMA) {rising=true;  falling=false;}
   if (pMA>cMA) {rising=false; falling=true;}

   // Does the Symbol() have an open order
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         // yes, set found, get the existing bought/sold state
         // and then break, so there's only 1 order per symbol
         found=true;
         if (OrderType()==0) {bought=true;  sold=false;}
         if (OrderType()==1) {bought=false; sold=true;}
         break;
        }
         else
        {
         found=false;
        }        
     }
   

   // If there is no order, then
   // place one based on MA direction
   if (!found && rising)
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-(p*13),Ask+(p*15),"1MA Buy",11123,0,White);
      return(0);
     }

   if (!found && falling)
     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+(p*13),Bid-(p*15),"1MA Sell",11321,0,Red);
      return(0);
     }


   if (rising && sold)       //existing sell
     {
      OrderClose(OrderTicket(),Lots,Ask,0,Red);
     }
   if (falling && bought)  // existing buy
     {
      OrderClose(OrderTicket(),Lots,Bid,0,White);
     }


   return(0);
  }

