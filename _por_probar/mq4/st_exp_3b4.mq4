//+------------------------------------------------------------------+
//| 1MA Expert                               |
//+------------------------------------------------------------------+

// b.2  very good if optimized per pair - chop still limits gains
// b.3  added Pyramiding - this would be awesom, but chop kills
// b.4  adding a /2 for exit filter - nope, didn't work


#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern double MovingAvg = 7;
extern double filter = 1.1;
extern double Pyramid = 5;

       double barmove0 = 0;
       double barmove1 = 0;
         int  risingcnt = 0;
         int fallingcnt = 0;


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
   if(AccountFreeMargin()<(1000*Lots))        {Print("We have no money");   return(0);}
   if(Bars<100)                               {Print("Bars less than 100"); return(0);}
   if(barmove0==Open[0] && barmove1==Open[1]) {Print("Bar has not moved");  return(0);}

   barmove0=Open[0];
   barmove1=Open[1];

   cMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 0);
   pMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 1);


   // rising and falling is filter-qualified by some number of points
   // and each rise/fall is counted for pyramiding decision later
   if (pMA+(filter*p)<cMA) {rising=true;  falling=false; risingcnt++;}
   if (pMA-(filter*p)>cMA) {rising=false; falling=true; fallingcnt++;}

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
   

   // there is no order and MA is rising, BUY something
   // and reset the pyramid counters
   if (!found && rising)
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"1MA Buy",11123,0,White);
      if (Pyramid>0) {fallingcnt=0; risingcnt=0;}
      return(0);
     }


   // there is no order and MA is falling, SELL something
   // and reset the pyramid counters
   if (!found && falling)
     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"1MA Sell",11321,0,Red);
      if (Pyramid>0) {fallingcnt=0; risingcnt=0;}
      return(0);
     }

   // existing SELL and the direction changed
   // loop to close all pyramid orders 
   if (rising && sold)
     {
      for(cnt=0;cnt<OrdersTotal();cnt++)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            OrderClose(OrderTicket(),Lots,Ask,0,Red);
            Sleep(10000);
           }        
        }
      if (Pyramid>0) {fallingcnt=0; risingcnt=0;}
     }


   // existing BUY and the direction changed
   // loop to close all pyramid orders 
   if (falling && bought)
     {
      for(cnt=0;cnt<OrdersTotal();cnt++)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            OrderClose(OrderTicket(),Lots,Bid,0,White);
            Sleep(10000);
           }        
        }
      if (Pyramid>0) {fallingcnt=0; risingcnt=0;}
     }


   if (Pyramid>0)
     {
      // BUY ASK another lot?
      if (rising && bought && risingcnt>=Pyramid)
        {
         OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"1MA Pyramid Buy",22123,0,White);
         if (Pyramid>0) {fallingcnt=0; risingcnt=0;}
         return(0);
        }

      // SELL BID another lot?
      if (falling && sold && fallingcnt>=Pyramid)
        {
         OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"1MA Pyramid Sell",22321,0,Red);
         if (Pyramid>0) {fallingcnt=0; risingcnt=0;}
         return(0);
        }
     }


   return(0);
  }

