//+------------------------------------------------------------------+
//| 3MA Bunny Cross Expert                               |
//+------------------------------------------------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern double stoploss = 15;
extern double MovingAvg = 10;


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
   bool oldenough=false;
   
   
   int      cnt=0;
   int      err=0;
   double   ccl=0;
   double   osl=0;
   double   nslB=0;
   double   nslS=0;
   

   // Error checking
   if(Bars<100)                        {Print("Bars less than 100"); return(0);}
   if(AccountFreeMargin()<(1000*Lots)) {Print("We have no money");   return(0);}

   // get 1 & 2 MA (avoid 0, as it's too noisy)
   // (possible mod - open of 0 and 1 has no noise)
   //cMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_CLOSE, 1);
   //pMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_CLOSE, 2);
   cMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 0);  // just for testing
   pMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 1);  // just for testing
   
   if (pMA<=cMA) {rising=true;  falling=false;}
   if (pMA>=cMA) {rising=false; falling=true;}

   // Does the Symbol() have an open order
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         // if found, get all the trailing stoploss data
         // from bar 1 not 0
         found=true;
         //ccl=Close[1];  
         ccl=Close[0];   // just for testing  
         osl=OrderStopLoss();
         nslB=ccl-(stoploss*p);
         nslS=ccl+(stoploss*p);
         if (OrderType()==0) {bought=true;  sold=false;}
         if (OrderType()==1) {bought=false; sold=true;}
         break;
        }
         else
        {
         found=false;
        }        
     }
   

   // If there is no order, place one based on MA direction then
   // leave and the next tick will handle the trailing stop loss
   if (!found && rising)
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-(p*stoploss),0,"BC Buy",16123,0,White);
      return(0);
     }

   if (!found && falling)
     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+(p*stoploss),0,"BC Sell",16321,0,Red);
      return(0);
     }


   // trailing stoploss for BUY(nslB=new stop loss BUY) order
   if (found && bought && nslB > osl )
     {
      OrderModify(OrderTicket(),OrderOpenPrice(),nslB,OrderTakeProfit(),0,Red);
      return(0);
     }

   // trailing stoploss for SELL(nslB=new stop loss SELL) order
   if (found && sold && nslS < osl )
     {
      OrderModify(OrderTicket(),OrderOpenPrice(),nslS,OrderTakeProfit(),0,Red);
      return(0);
     }


   // if the direction has changed, then it's 
   // time to close the order
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

