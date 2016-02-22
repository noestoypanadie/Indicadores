//+-------------------+
//| 1MA Expert        |
//+-------------------+
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

   int     cnt;
   double slA=0, slB=0, tpA=0, tpB=0;
   double p=Point();
   double cCI=0;
   int found=777;
   
   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   if(barmove0==Open[0] && barmove1==Open[1]) {                        return(0);}

   // bars moved, update current position
   barmove0=Open[0];
   barmove1=Open[1];
   
   cCI=iCCI(Symbol(),0,30,PRICE_OPEN,0);


   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {found=111; break;}
         else
        {found=333;}
     }

   Print("---",Symbol()," found=",found);


   
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

   if (!found && cCI>50)  
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,0,slA,tpA,"CCI Buy",11123,0,White);
     }

   if (!found && cCI<-50)
     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,0,slB,tpB,"CCI Sell",11321,0,Red);
     }

   return(0);
  }

