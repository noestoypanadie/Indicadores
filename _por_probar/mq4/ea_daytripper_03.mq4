//+-------------------+
//| 1MA Expert        |
//+-------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern double MovingAvg=10;
extern double filter=0;
extern int   TakeProfit=0;
extern int   StopLoss=0;

// Global scope
      double barmove0 = 0;
      double barmove1 = 0;
       int  risingcnt = 0;
       int fallingcnt = 0;
       int periodcnt  = 0;



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

   int     cnt=0;
   double  cMA=0, pMA=0;
   double p=Point();
   double slA,slB,tpA,tpB;
   double cCI=0;
      
   bool    rising=false;
   bool   falling=false;

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {return(0);}
   if(Bars<100)                               {return(0);}
   if(barmove0==Open[0] && barmove1==Open[1]) {return(0);}

   // bars moved, update current position
   barmove0=Open[0];
   barmove1=Open[1];
   
   cMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 0);
   pMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 1);
   cCI=iCCI(Symbol(), 0, 30, 1,0);

   if (pMA+(filter*p)<cMA) {rising=true;  falling=false;}
   if (pMA-(filter*p)>cMA) {rising=false; falling=true;}
   
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         if (OrderType()==0)
           {
            //bought=true;
            if (cCI<0) OrderClose(OrderTicket(),Lots,Bid,0,White);
           }
         if (OrderType()==1) 
           {
            //sold=true;
            if (cCI>0) OrderClose(OrderTicket(),Lots,Ask,0,Red);
           }

        }
     }

   if (TakeProfit==0)
     {
      tpA=0;
      tpB=0;
     }
      else
     {
      tpA=Ask+(p*TakeProfit);
      tpB=Bid-(p*TakeProfit);
     }
     
   if (StopLoss==0)
     {
      slA=0;
      slB=0;
     }
      else
     {
      slA=Ask-(p*StopLoss);
      slB=Bid+(p*StopLoss);
     }
     

   if (rising)  
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,slA,tpA,"1MA Buy",11123,0,White);
     }
   if (falling)
     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,slB,tpB,"1MA Sell",11321,0,Red);
     }

   return(0);
  }

