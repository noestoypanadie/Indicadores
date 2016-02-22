//+------------------------------------------------------------------+
//| 1MA Expert                               |
//+------------------------------------------------------------------+

// b.2  very good if optimized per pair - chop still limits gains
// b.3  added Pyramiding - this would be awesom, but chop kills
// b.4  adding a /2 for exit filter - nope, didn't work
// b.5  added lagurre, but not used yet


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

extern double gamma=0.5;

double L0 = 0;
double L1 = 0;
double L2 = 0;
double L3 = 0;
double L0A = 0;
double L1A = 0;
double L2A = 0;
double L3A = 0;
double LRSI = 0;
double CU = 0;
double CD = 0;

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
   double  lowpass0=0, lowpass1=0;
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
   lowpass0=lagurre(0);


   // rising and falling is filter-qualified by some number of points
   // and each rise/fall is counted for pyramiding decision later
   if (pMA+(filter*p)<cMA) {rising=true;  falling=false; risingcnt++;}
   if (pMA-(filter*p)>cMA) {rising=false; falling=true; fallingcnt++;}

   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderComment()=="INITTRANS")
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
   // comment here is very important in identifying initial transaction
   // of the many that may be involved in the pyramid
   if (!found && rising)
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"INITTRANS",11123,0,White);
      if (Pyramid>0) {fallingcnt=0; risingcnt=0;}
      return(0);
     }


   // there is no order and MA is falling, SELL something
   // and reset the pyramid counters
   // comment here is very important in identifying initial transaction
   // of the many that may be involved in the pyramid
   if (!found && falling)
     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"INITTRANS",11321,0,Red);
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
            OrderClose(OrderTicket(),Lots,Ask,2,Red);
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
            OrderClose(OrderTicket(),Lots,Bid,2,White);
            Sleep(10000);
           }        
        }
      if (Pyramid>0) {fallingcnt=0; risingcnt=0;}
     }


   if (Pyramid>0)
     {
      // BUY ASK another lot?
      //if (rising && bought && risingcnt>=Pyramid && OrderOpenPrice()<Open[0])
      if (rising && bought && risingcnt>=Pyramid)
        {
         OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"1MA Pyramid Buy",22123,0,White);
         if (Pyramid>0) {fallingcnt=0; risingcnt=0;}
         return(0);
        }

      // SELL BID another lot?
      //if (falling && sold && fallingcnt>=Pyramid && OrderOpenPrice()>Open[0])
      if (falling && sold && fallingcnt>=Pyramid)
        {
         OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"1MA Pyramid Sell",22321,0,Red);
         if (Pyramid>0) {fallingcnt=0; risingcnt=0;}
         return(0);
        }
     }

   return(0);
  }



double lagurre (int i)
  {
   L0A = L0;
   L1A = L1;
   L2A = L2;
   L3A = L3;
   L0 = (1 - gamma)*Open[i] + gamma*L0A;
   L1 = - gamma *L0 + L0A + gamma *L1A;
   L2 = - gamma *L1 + L1A + gamma *L2A;
   L3 = - gamma *L2 + L2A + gamma *L3A;

   CU = 0;
   CD = 0;
    
   if (L0 >= L1) CU = L0 - L1; else CD = L1 - L0;
   if (L1 >= L2) CU = CU + L1 - L2; else CD = CD + L2 - L1;
   if (L2 >= L3) CU = CU + L2 - L3; else CD = CD + L3 - L2;

   if (CU + CD != 0) LRSI = CU / (CU + CD);
   return(LRSI);
  }




