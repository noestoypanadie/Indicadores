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

   if(AccountFreeMargin()<(1000*Lots)) {Print("We have no money");   return(0);}

   if (Open[2]<Open[1]<Open[0]) {rising=true;  falling=false;}
   if (Open[2]>Open[1]>Open[0]) {rising=true;  falling=false;}
   
   OrderClose(OrderTicket(),Lots,Ask,0,Red);
   if (rising)  
     {
      Print("DTBUY ",Ask);
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"1MA Buy",11123,0,White);
     }
   if (falling)
     {
      Print("DTSELL ",Bid);
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"1MA Sell",11321,0,Red);
     }

   return(0);
  }

