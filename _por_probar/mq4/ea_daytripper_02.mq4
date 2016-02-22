//+-------------------+
//| 1MA Expert        |
//+-------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern double MovingAvg=10;

// Global scope
double prevTime=0;


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

   bool    rising=false;
   bool   falling=false;
   bool    bought=false;
   bool      sold=false;
      
   int cnt;
   
   if(AccountFreeMargin()<(1000*Lots)) {Print("We have no money");   return(0);}

   if (Open[1]<Open[0]) {rising=true;  falling=false;}
   if (Open[1]>Open[0]) {rising=true;  falling=false;}
   
   // Does the Symbol() have an open order
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         if (OrderType()==0) {bought=true;  sold=false;}
         if (OrderType()==1) {bought=false; sold=true;}
         if (rising && bought) return(0);
         if (falling && sold)  return(0);
         break;
        }
     }
   
   OrderClose(OrderTicket(),Lots,Ask,0,Red);
      
   if (rising)  
     {
      //Print("DTBUY ",Ask);
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"1MA Buy",11123,0,White);
     }
   if (falling)
     {
      //Print("DTSELL ",Bid);
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"1MA Sell",11321,0,Red);
     }

   return(0);
  }

