//+------------------------------------------------------------------+
//| 3MA Bunny Cross Expert                               |
//+------------------------------------------------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;



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
   double    MAxxx=0;

      
   int      total=0;
   bool     found=false;
   bool    rising=false;
   bool   falling=false;
   bool    bought=false;
   bool      sold=false;
   bool oldenough=false;
   bool   MAxxxup=false;
   bool   MAxxxdn=false;
   
   int      cnt=0;
   int      err=0;
   
   string cmmt="";
   
   //
   // Error checking
   //
   
   if(Bars<100)
     {
      Print("bars less than 100");
      return(0);
     }
   
   if(AccountFreeMargin()<(1000*Lots))
     {
      Print("We have no money");
      return(0);
     }


   cMAfst=iMA(Symbol(),0,5 ,0,MODE_LWMA,PRICE_CLOSE, 1);
   pMAfst=iMA(Symbol(),0,5 ,0,MODE_LWMA,PRICE_CLOSE, 2);
      
   cMAslo=iMA(Symbol(),0,25,0,MODE_LWMA,PRICE_CLOSE, 1);
   pMAslo=iMA(Symbol(),0,25,0,MODE_LWMA,PRICE_CLOSE, 2);

   MAxxx=iMA(Symbol(),0,100,0,MODE_LWMA,PRICE_CLOSE, 1);

   if (pMAfst<=pMAslo && cMAfst>=cMAslo) {rising=true;  falling=false;}
   if (pMAfst>=pMAslo && cMAfst<=cMAslo) {rising=false; falling=true;}


   found=false;
   total=OrdersTotal();
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         //Print("Found symbol");
         found=true;
         break;
        }
     }

   if (found)
     {
      if (OrderType()==0) {bought=true;  sold=false;}
      if (OrderType()==1) {bought=false; sold=true;}
     }

   if (OrderOpenTime()<Time[4]) {oldenough=true;} else {oldenough=false;}
     
   // wrong direction, just print report
   if (found && rising && bought && oldenough) {Print("Cross, but already SELL");}
   if (found && falling && sold && oldenough) {Print("Cross, but already BUY");}

   if (MAxxx>cMAfst){MAxxxup=true; MAxxxdn=false;}
   if (MAxxx<cMAfst){MAxxxdn=true; MAxxxup=false;}

   if (found && rising && sold && MAxxxup && oldenough)       //exist sell
     {
      Print(Symbol(), Time[0],OrderOpenTime()," CLOSE sell BUY buy");
      OrderClose(OrderTicket(),Lots,Ask,0,Red);
      err=GetLastError();
      if(err==0)
        {
         Print("BUY  Order started  ",Ask);
         OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"BC Buy ",16123,0,White);
         if(GetLastError()==0)Comment("BC_BUY  Order opened : ",Ask);
        }
     }
   if (found && falling && bought && MAxxxdn && oldenough)  // exist buy
     {
      Print(Symbol(),Time[0],OrderOpenTime(),"CLOSE buy BUY sell");
      OrderClose(OrderTicket(),Lots,Bid,0,White);
      err=GetLastError();
      if(err==0)
        {
         Print("SELL Order started  ",Bid);
         OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"BC Sell",16321,0,Red);
         if(GetLastError()==0)Comment("BC_SELL Order opened : ",Bid );
        }
     }


   return(0);
  }

