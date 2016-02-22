//+------------------------------------------------------------------+
//| 3MA Bunny Cross Expert                               |
//+------------------------------------------------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern double MAFASTtime=5;
extern double MASLOWtime=25;




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

   double    p=Point();
      
   bool     found=false;
   bool    rising=false;
   bool   falling=false;
   bool    bought=false;
   bool      sold=false;

   
   int      cnt=0;
   int      err=0;
   

   // Error checking
   if(Bars<100)                        {Print("Bars less than 100"); return(0);}
   if(AccountFreeMargin()<(1000*Lots)) {Print("We have no money");   return(0);}

   // get all the moving averages at once
   cMAfst=iMA(Symbol(),0,MAFASTtime,0,MODE_LWMA,PRICE_CLOSE, 1);
   pMAfst=iMA(Symbol(),0,MAFASTtime,0,MODE_LWMA,PRICE_CLOSE, 2);
   cMAslo=iMA(Symbol(),0,MASLOWtime,0,MODE_LWMA,PRICE_CLOSE, 1);
   pMAslo=iMA(Symbol(),0,MASLOWtime,0,MODE_LWMA,PRICE_CLOSE, 2);
   //MA100= iMA(Symbol(),0,100,0,MODE_LWMA,PRICE_CLOSE, 1);

   // determine if FST line is rising or falling around SLO line
   if (pMAfst<pMAslo && cMAfst>cMAslo) {rising=true;  falling=false;}
   if (pMAfst>pMAslo && cMAfst<cMAslo) {rising=false; falling=true;}

   // Does the Symbol() have an open order
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {found=true; break;}
         else
        {found=false;}        
     }
   
   //Leave if there is no open order 
   if (found==false)
     {
      //if (rising)  OrderSend(Symbol(),OP_BUY, Lots,Ask,3,Ask-(p*50),0,"BC Buy ",16123,0,White);
      //if (falling) OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+(p*50),0,"BC Sell",16321,0,Red);
      if (rising)  OrderSend(Symbol(),OP_BUY, Lots,Ask,3,0,0,"BC Buy ",16123,0,White);
      if (falling) OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"BC Sell",16321,0,Red);
      return(0);
     }
   
   // Leave if order was less than 4 periods ago
   //if ((Time[0]-OrderOpenTime())<300) {Print(Symbol()," not old enough ", Time[0]-OrderOpenTime()); return(0);}
   //if ((Time[0]-OrderOpenTime())<300) {return(0);}

   if (OrderType()==0) {bought=true;  sold=false;}
   if (OrderType()==1) {bought=false; sold=true;}

   // wrong direction, just print report
   if (rising && bought) {Print("Cross, but already Buy "); return(0);}
   if (falling && sold)  {Print("Cross, but already Sell"); return(0);}
     
   if (rising && sold)       //exist sell
     {
      Print(Symbol()," CLOSE sell BUY buy");
      OrderClose(OrderTicket(),Lots,Ask,0,Red);
      err=GetLastError();
      if(err==0)
        {
         Print("BUY  Order started  ",Ask);
         //OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-(p*50),0,"BC Buy ",16123,0,White);
         OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"BC Buy ",16123,0,White);
         if(GetLastError()==0)Comment("BC_BUY  Order opened : ",Ask);
        }
         else
        {
         Print(Symbol(),"BUY Error ",err);
        }
     }
   if (falling && bought)  // exist buy
     {
      Print(Symbol(),Time[0],OrderOpenTime(),"CLOSE buy BUY sell");
      OrderClose(OrderTicket(),Lots,Bid,0,White);
      err=GetLastError();
      if(err==0)
        {
         Print("SELL Order started  ",Bid);
         //OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+(p*50),0,"BC Sell",16321,0,Red);
         OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"BC Sell",16321,0,Red);
         if(GetLastError()==0)Comment("BC_SELL Order opened : ",Bid );
        }
         else
        {
         Print(Symbol(),"SELL Error ",err);
        }
     }


   //Print(Symbol()," Tick");
   return(0);
  }

