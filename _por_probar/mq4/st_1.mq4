//+------------------------------------------------------------------+
//| 3MA Bunny Cross Expert                               |
//+------------------------------------------------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern double stoploss = 100;
extern double fastMA = 40;
extern double slowMA = 100;



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
   double   cMAfst=0, pMAfst=0;
   double   cMAslo=0, pMAslo=0;
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

   // get all the moving averages at once
   cMAfst=iMA(Symbol(), 0, fastMA, 0, MODE_LWMA, PRICE_CLOSE, 1);
   pMAfst=iMA(Symbol(), 0, fastMA, 0, MODE_LWMA, PRICE_CLOSE, 2);
   cMAslo=iMA(Symbol(), 0, slowMA, 0, MODE_LWMA, PRICE_CLOSE, 1);
   pMAslo=iMA(Symbol(), 0, slowMA, 0, MODE_LWMA, PRICE_CLOSE, 2);

   // determine if FST line is rising or falling around SLO line
   if (pMAfst<=pMAslo && cMAfst>=cMAslo) {rising=true;  falling=false;}
   if (pMAfst>=pMAslo && cMAfst<=cMAslo) {rising=false; falling=true;}

   // Does the Symbol() have an open order
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         found=true;
         ccl=Close[1];  
         osl=OrderStopLoss();
         nslB=ccl-(stoploss*p);
         nslS=ccl+(stoploss*p);
         break;
        }
         else
        {
         found=false;
        }        
     }
   

   // trail stop (usr bar 1, NOT 0)
   if (found && OrderType()==0 && nslB > osl )
     {
      Print("BUY MODIFY! ",Symbol()," osl=",osl," ccl=",ccl," nslB=",nslB);
      OrderModify(OrderTicket(),OrderOpenPrice(),nslB,OrderTakeProfit(),0,Red);
     }

   // trail stop (usr bar 1, NOT 0)
   if (found && OrderType()==1 && nslS < osl )
     {
      Print("SELL MODIFY! ",Symbol()," osl=",osl," ccl=",ccl," nslS=",nslS );
      OrderModify(OrderTicket(),OrderOpenPrice(),nslS,OrderTakeProfit(),0,Red);
     }


   if (found==false && rising)
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-(p*stoploss),0,"BC Buy",16123,0,White);
      //OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"BC Buy",16123,0,White);
      return(0);
     }

   if (found==false && falling)
     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+(p*stoploss),0,"BC Sell",16321,0,Red);
      //OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"BC Sell",16321,0,Red);
      return(0);
     }

   if (OrderType()==0) {bought=true;  sold=false;}
   if (OrderType()==1) {bought=false; sold=true;}

   // wrong direction, just print report
   if (rising && bought) {Print("Cross, but already Buy "); return(0);}
   if (falling && sold)  {Print("Cross, but already Sell"); return(0);}
     
   if (rising && sold)       //exist sell
     {
      Print(Symbol()," CLOSE sell order");
      OrderClose(OrderTicket(),Lots,Ask,0,Red);
     }
   if (falling && bought)  // exist buy
     {
      Print(Symbol()," CLOSE buy order");
      OrderClose(OrderTicket(),Lots,Bid,0,White);
     }

   return(0);
  }

