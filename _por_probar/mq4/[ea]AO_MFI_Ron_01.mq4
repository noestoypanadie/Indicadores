//+------------------------------------------------------------------+
//| MFI + AO                                                         |
//+------------------------------------------------------------------+
#property copyright "Ron T"
#property link      "http://www.lightpatch.com/forex"

// user input
extern double Lots=1.0;
extern int MFIPeriod=14;
extern int TakeProfit=60;
extern int StopLoss=15;

// These are externs just so they're easy to adjust
extern int AOBuyLevel=0;
extern int AOSellLevel=0;
extern int MFIBuyLevel=50;
extern int MFISellLevel=50;

//Bar movement
double newbar=0;

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

   double p=Point();
   int      cnt=0;

   bool      found=false;
   bool     rising=false;
   bool    falling=false;
   bool      cross=false;

   double barmove0, barmove1;
   double  i0, i1, i2, i3;

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}

   // do nothing unless the bar moved
   if (newbar == Time[0])                     {                        return(0);}

   // bar moved, update time   
   newbar=Time[0];
   
   
   // One order per Symbol
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() )
        {
         return(0);
        }
     }

   // finally we can compute a few things
   i2=iAO(Symbol(),0,0);
   i3=iMFI(Symbol(),0,MFIPeriod,0);
      
   //Long AO above 0 and MFI above 60
   if (i2>AOBuyLevel && i3>=MFIBuyLevel)
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-(StopLoss*p),Ask+(TakeProfit*p),"ZMRLQVYX",11123,0,White);
     }
        
   //Short AO below 0 and MFI below 40
   if (i2<AOSellLevel && i3<=MFISellLevel)
     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Ask+(StopLoss*p),Ask-(TakeProfit*p),"ZMRLQVYX",11321,0,Red);
     }
        
   return(0);
  }
//+------------------------------------------------------------------+