//+------------------------------------------------------------------+
//| 1MA Expert                               |
//+------------------------------------------------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern double ALLOWChanges=0;
extern double MovingAvg = 7;
extern double filter = 1.1;


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
   double   cMA=0, pMA=0, xMA=0;
   double   p=Point();
      
   bool     found=false;
   bool    rising=false;
   bool   falling=false;
   bool    bought=false;
   bool      sold=false;

   int      cnt=0;
/*     
   // Symbols that I've optimized
   if (ALLOWChanges!=0)
     {
      if (Symbol()=="AUDUSD") {MovingAvg=10; filter= 8.2;}
      if (Symbol()=="EURAUD") {MovingAvg= 6; filter= 8.0;}
      if (Symbol()=="EURCHF") {MovingAvg= 7; filter= 3.6;}
      if (Symbol()=="EURGBP") {MovingAvg=10; filter= 0.5;}
      if (Symbol()=="EURJPY") {MovingAvg= 2; filter= 9.9;}
      if (Symbol()=="EURUSD") {MovingAvg= 1; filter= 0.9;}
      if (Symbol()=="GBPCHF") {MovingAvg= 4; filter=12.0;}
      if (Symbol()=="GBPJPY") {MovingAvg=10; filter= 9.3;}
      if (Symbol()=="GBPUSD") {MovingAvg= 1; filter= 3.9;}
      if (Symbol()=="USDCAD") {MovingAvg= 1; filter= 0.9;}
      if (Symbol()=="USDCHF") {MovingAvg= 1; filter= 4.0;}
      if (Symbol()=="USDJPY") {MovingAvg=21; filter=11.6;}
     }
*/   

   // Error checking
   if(Bars<100)                        {Print("Bars less than 100"); return(0);}
   if(AccountFreeMargin()<(1000*Lots)) {Print("We have no money");   return(0);}

   cMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 0);
   pMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 1);
   xMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 2);
   if (pMA+(filter*p)<cMA) {rising=true;  falling=false;}
   if (pMA-(filter*p)>cMA) {rising=false; falling=true;}
   //if (xMA+(filter*p)<pMA && pMA+(filter*p)<cMA) {rising=true;  falling=false;}
   //if (xMA-(filter*p)>pMA && pMA-(filter*p)>cMA) {rising=false; falling=true;}
   //if (xMA<pMA<cMA) {rising=true;  falling=false;}
   //if (xMA>pMA>cMA) {rising=false; falling=true;}

   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
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
   
   if (!found && rising)
     {
      //OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-(p*13),Ask+(p*15),"1MA Buy",11123,0,White);
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"1MA Buy",11123,0,White);
      return(0);
     }

   if (!found && falling)
     {
      //OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+(p*13),Bid-(p*15),"1MA Sell",11321,0,Red);
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"1MA Sell",11321,0,Red);
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

