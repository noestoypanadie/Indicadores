//+---------------------------+
//| Expert Cross Framework    |
//+---------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern int    TakeProfit=255;
extern int    StopLoss=0;
extern int    Interval=1;
extern int       myCCIs=30;   //  5 days
extern int       myCCIl=150;  // 25 days

// Global scope
double barmove0 = 0;
double barmove1 = 0;
int         itv = 0;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//|------------------------------------------------------------------|

int init()
  {
   itv=Interval;
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

   bool      found=false;
   bool     rising=false;
   bool    falling=false;
   bool      cross=false;

   double slA=0, slB=0, tpA=0, tpB=0;
   double p=Point();
   
   double cCIs;
   double cCIm;
   double cCIf;
   
   int      cnt=0;

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   if(barmove0==Open[0] && barmove1==Open[1]) {                        return(0);}

   // bars moved, update current position
   barmove0=Open[0];
   barmove1=Open[1];

   // interval (bar) counter
   // used to pyramid orders during trend
   itv++;
   
   // since the bar just moved
   // calculate TP and SL for (B)id and (A)sk
   tpA=Ask+(p*TakeProfit);
   slA=Ask-(p*StopLoss);
   tpB=Bid-(p*TakeProfit);
   slB=Bid+(p*StopLoss);
   if (TakeProfit==0) {tpA=0; tpB=0;}           
   if (StopLoss==0)   {slA=0; slB=0;}           
   
   // get CCI based on OPEN
   cCIs=iCCI(Symbol(),0,125,PRICE_OPEN,0);
   cCIm=iCCI(Symbol(),0, 25,PRICE_OPEN,0);
   cCIf=iCCI(Symbol(),0,  5,PRICE_OPEN,0);

   // is it crossing zero up or down
   if (cCI1<=0 && cCI0>=0 && cCIZ>0) { rising=true; cross=true; Print("Rising  Cross");}
   if (cCI1>=0 && cCI0<=0 && cCIZ<0) {falling=true; cross=true; Print("Falling Cross");}
   
   // close then open orders based on cross
   // pyramid below based on itv
   if (cross)
     {
      // Close ALL the open orders 
      for(cnt=OrdersTotal();cnt>0;cnt--)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            if (OrderType()==0) {OrderClose(OrderTicket(),Lots,Bid,3,White);}
            if (OrderType()==1) {OrderClose(OrderTicket(),Lots,Ask,3,Red);}
            itv=0;
           }
        }
      // Open new order based on direction of cross
      if (rising)  OrderSend(Symbol(),OP_BUY,Lots,Ask,3,slA,tpA,"ZZZ100",11123,0,White);
      if (falling) OrderSend(Symbol(),OP_SELL,Lots,Bid,3,slB,tpB,"ZZZ100",11321,0,Red);
      
      // clear the interval counter
      itv=0;
     }
   
   // Only pyramid if order already open
   found=false;
   for(cnt=OrdersTotal();cnt>0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         if (OrderType()==0)  //BUY
           {
            if (itv >= Interval)
              {
               OrderSend(Symbol(),OP_BUY,Lots,Ask,3,slA,tpA,"ZZZ100",11123,0,White);
               itv=0;
              }
           }
         if (OrderType()==1)  //SELL
           {
            if (itv >= Interval)
              {
               OrderSend(Symbol(),OP_SELL,Lots,Bid,3,slB,tpB,"ZZZ100",11321,0,Red);
               itv=0;
              }
           }
         found=true;
         break;
        }
     }
   return(0);
  }

