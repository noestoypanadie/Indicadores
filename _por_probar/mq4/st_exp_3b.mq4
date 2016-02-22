//+------------------------------------------------------------------+
//| 1MA Expert                               |
//+------------------------------------------------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern double MovingAvg = 10;
extern double TakeProfit = 50;
extern double StopLoss = 50;



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
   
   // Symbols that I've optimized
   if (Symbol()=="GBPCHF") {MovingAvg= 5; TakeProfit=91;}
   

   // Error checking
   if(Bars<100)                        {Print("Bars less than 100"); return(0);}
   if(AccountFreeMargin()<(1000*Lots)) {Print("We have no money");   return(0);}

   cMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 0);
   pMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 1);
   if (pMA<cMA) {rising=true;  falling=false;}
   if (pMA>cMA) {rising=false; falling=true;}

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
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-(StopLoss*p),0,"1MA Buy",11123,0,White);
      return(0);
     }

   if (!found && falling)
     {
      //OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+(p*13),Bid-(p*15),"1MA Sell",11321,0,Red);
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+(StopLoss*p),0,"1MA Sell",11321,0,Red);
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

