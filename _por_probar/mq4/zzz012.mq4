//+------------------------------------------------------------------+
//| 1MA Expert                               |
//+------------------------------------------------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern int    TakeProfit=50;
extern int    StopLoss=25;
extern int      myCCIs=160;
extern int      myCCIm=80;
extern int      myCCIf=40;


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

   bool      found=false;
   bool     rising=false;
   bool    falling=false;
   bool      cross=false;

   double slA=0, slB=0, tpA=0, tpB=0;
   double p=Point();
   
   double cCCIs;
   double cCCIm;
   double cCCIf;
   
   int      cnt=0;

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   if(barmove0==Open[0] && barmove1==Open[1]) {                        return(0);}

   // bars moved, update current position
   barmove0=Open[0];
   barmove1=Open[1];

   // currently one order at a time FROM ZERO
   for(cnt=0; cnt<=OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol()) {return(0);}
     }

   // since the bar just moved
   // calculate TP and SL for (B)id and (A)sk
   tpA=Ask+(p*TakeProfit);
   slA=Ask-(p*StopLoss);
   tpB=Bid-(p*TakeProfit);
   slB=Bid+(p*StopLoss);
   if (TakeProfit<=0) {tpA=0; tpB=0;}           
   if (StopLoss<=0)   {slA=0; slB=0;}           
   
   // get CCI based on OPEN
   cCCIs=iCCI(Symbol(),0,myCCIs,PRICE_OPEN,0);
   cCCIm=iCCI(Symbol(),0,myCCIm,PRICE_OPEN,0);
   cCCIf=iCCI(Symbol(),0,myCCIf,PRICE_OPEN,0);

   // is it crossing zero up or down
   if (cCCIs>=100 && cCCIm>=100 && cCCIf>=100)    { rising=true;}
   if (cCCIs<=-100 && cCCIm<=-100 && cCCIf<=-100) {falling=true;}
   
   // Open new order based on direction of cross
   if (rising)  OrderSend(Symbol(),OP_BUY,Lots,Ask,3,slA,tpA,"ZZZ012",11123,0,White);
   if (falling) OrderSend(Symbol(),OP_SELL,Lots,Bid,3,slB,tpB,"ZZZ012",11321,0,Red);
      
   
   return(0);
  }

