//+------------------------------------------------------------------+
//| 1MA Expert                               |
//+------------------------------------------------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern int    TakeProfit=20;
extern int    StopLoss=10;


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

   bool     rising=false;
   bool    falling=false;
   bool      cross=false;

   double slA=0, slB=0, tpA=0, tpB=0;
   double p=Point();
   
   double cCI0;
   double cCI1;
   
   int      cnt=0;

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   if(barmove0==Open[0] && barmove1==Open[1]) {                        return(0);}

   // bars moved, update current position
   barmove0=Open[0];
   barmove1=Open[1];

   cCI0=iCCI(Symbol(),0,30,PRICE_OPEN,0);
   cCI1=iCCI(Symbol(),0,30,PRICE_OPEN,1);

   if (cCI1<0 && cCI0>0) { rising=true; cross=true;}
   if (cCI1>0 && cCI0<0) {falling=true; cross=true;}
   
   if (cross)
     {
      // Does the Symbol() have an open order
      for(cnt=0;cnt<OrdersTotal();cnt++)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            if (OrderType()==0) {OrderClose(OrderTicket(),Lots,Bid,3,White);}
            if (OrderType()==1) {OrderClose(OrderTicket(),Lots,Ask,3,Red);}
           }
        }
     }
   
   if (TakeProfit!=0)
     {
      tpA=Ask+(p*TakeProfit);
      tpB=Bid-(p*TakeProfit);
     }
      else
     {
      tpA=0;
      tpB=0;
     }           

   if (StopLoss!=0)
     {
      slA=Ask-(p*StopLoss);
      slB=Bid+(p*StopLoss);
     }
      else
     {
      slA=0;
      slB=0;
     }           

   if (rising)  OrderSend(Symbol(),OP_BUY,Lots,Ask,3,slA,tpA,"ZZZ100",11123,0,White);
   if (falling) OrderSend(Symbol(),OP_SELL,Lots,Bid,3,slB,tpB,"ZZZ100",11321,0,Red);
   
   
   return(0);
  }

