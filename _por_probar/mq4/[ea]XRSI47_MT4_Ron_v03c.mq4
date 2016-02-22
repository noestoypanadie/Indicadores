//+------------------------+
//|       XRSI N by N      |
//+------------------------+
//

/*
Theory of operation
-------------------
This is a scalping expert based on cross of RSISlow & RSIFast
This is a STOP/REVERSE system (which means always-in)


TIME FRAME
----------
5 MINUTES suggested but may support 15MIN with tweaks


SUGGESTED PAIRS
---------------
GBPUSD


ENTRY LONG
----------
RSIFast(Bar[2]) less than RSISlow(Bar[2]) and RSIFast(Bar[1]) greater than RSISlow(Bar[1])

(if RSIType=1, i.e. PRICE_OPEN, then)
RSIFast(Bar[1]) less than RSISlow(Bar[1]) and RSIFast(Bar[0]) greater than RSISlow(Bar[0])


ENTRY SHORT
-----------
RSIFast([2]) greater than RSISlow(Bar[2]) and RSIFast(bar[1]) less than RSISlow(Bar[1])

(if RSIType=1, i.e. PRICE_OPEN, then)
RSIFast(Bar[1]) greater than RSISlow(Bar[1]) and RSIFast(Bar[0]) less than RSISlow(Bar[0])


EXIT
----
Sell on cross and take opposite trade


MONEY MANAGEMENT
----------------
-none-


RISK MANAGEMENT
---------------
-none-


FAILURE PROTECTION
------------------
Orders are opened with stoploss and takeprofit of 50 
since it's unlikely to affect scalping, and is safe 
enough in case of power failure or the internet disruption


*/


#property copyright "George Toffolo - MT4 code by Ron Thompson"
#property link      "http://www.lightpatch.com/forex"


/*
For RSIType, use the following:
-------------------------------
PRICE_CLOSE 0 Close price. 
PRICE_OPEN 1 Open price. 
PRICE_HIGH 2 High price. 
PRICE_LOW 3 Low price. 
PRICE_MEDIAN 4 Median price, (high+low)/2. 
PRICE_TYPICAL 5 Typical price, (high+low+close)/3. 
PRICE_WEIGHTED 6 Weighted close price, (high+low+close+close)/4. 
*/

// generic user input
extern double Lots=0.1;
extern int    Slippage=2;
extern int    Slow_RSI=14;
extern int    Fast_RSI=7;
extern int    Type_RSI=6;
extern bool   UseBar0=false;


// Bar handling
datetime bartime=0;
int      bartick=0;




//+------------------------------------+
//| EA load code                       |
//+------------------------------------+

int init()
  {
   Print("Init happened ",CurTime());
   Comment(" ");
  }


//+------------------------------------+
//| EA unload code                     |
//+------------------------------------+

int deinit()
  {
   Print("DE-Init happened ",CurTime());
   Comment(" ");
  }



//+------------------------------------+
//| EA main code                       |
//+------------------------------------+

int start()
  {
   double p=Point();
   int      cnt=0;
   int      gle=0;

   int      OrdersPerSymbol=0;

   double  pRSIFast=0,  RSIFast=0;
   double  pRSISlow=0,  RSISlow=0;
   bool    Rising=false, Falling=false;
   
   string TradeComment = "XRSI47";

   // Error checking & bar counting
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}

   // RSI and previous RSI for crossover
   if(UseBar0) 
     { 
      RSIFast=iRSI(Symbol(),0,Fast_RSI,Type_RSI,0);
      pRSIFast=iRSI(Symbol(),0,Fast_RSI,Type_RSI,1);
      RSISlow=iRSI(Symbol(),0,Slow_RSI,Type_RSI,0);
      pRSISlow=iRSI(Symbol(),0,Slow_RSI,Type_RSI,1);
     }
      else
     { 
      RSIFast=iRSI(Symbol(),0,Fast_RSI,Type_RSI,1);
      pRSIFast=iRSI(Symbol(),0,Fast_RSI,Type_RSI,2);
      RSISlow=iRSI(Symbol(),0,Slow_RSI,Type_RSI,1);
      pRSISlow=iRSI(Symbol(),0,Slow_RSI,Type_RSI,2);
     }

   // Determine if there was a cross
   if(pRSIFast<pRSISlow && RSIFast>RSISlow) {Rising=true;  Falling=false;}
   if(pRSIFast>pRSISlow && RSIFast<RSISlow) {Rising=false; Falling=true;}
   
   // count the open orders for this symbol 
   OrdersPerSymbol=0;
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol() == Symbol())
        {
         OrdersPerSymbol++;
        }
     }
     
   // count the open orders for this symbol 
   OrdersPerSymbol=0;
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol() == Symbol())
        {
         OrdersPerSymbol++;
        }
     }
     
   // Initial order placement
   if(OrdersPerSymbol==0)
     {
      Print("No Pending orders for ",Symbol()," Rising=",Rising," Falling=",Falling," bartick=",bartick);
     
      //ENTRY Ask(buy, long) 
      if(Rising)
		  {
		   Print("Placing initial BUY order on RISING indicator");
		   Print("pRSIFast=",pRSIFast," RSIFast=",RSIFast,"   pRSISlow=",pRSISlow," RSISlow=",RSISlow);
         OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,Ask-(50*p),Ask+(50*p),TradeComment,10101,White);
         gle=GetLastError();
         if(gle==0) {PrintAsk("BUY "); bartick=0;} else {PrintAskErr("BUY ",gle);}
        }
        
      //ENTRY Bid (sell, short)
      if(Falling)
        {
		   Print("Placing initial SELL order on FALLING indicator");
		   Print("pRSIFast=",pRSIFast," RSIFast=",RSIFast,"   pRSISlow=",pRSISlow," RSISlow=",RSISlow);
         OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,Bid+(50*p),Bid-(50*p),TradeComment,10101,Red);
         gle=GetLastError();
         if(gle==0) {PrintBid("SELL"); bartick=0;} else {PrintBidErr("SELL",gle);}
        }
     } //if


   // Existing order, determine if direction changed
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()==Symbol())
        {

         // RSI crossed down, so swap BUY for SELL
         if (OrderType() == OP_BUY && Falling)
           {
            OrderClose(OrderTicket(),Lots,Bid,Slippage,White);
            gle=GetLastError();
            if(gle==0) {PrintBid("CLOSE BUY "); bartick=0;} else {PrintBidErr("CLOSE BUY ",gle);}
            OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,Bid+(50*p),Bid-(50*p),TradeComment,10101,Red);
            gle=GetLastError();
            if(gle==0) {PrintBid("SELL"); bartick=0;} else {PrintBidErr("SELL",gle);}
           } // if BUY


         // RSI crossed up, so swap SELL for BUY
         if (OrderType() == OP_SELL && Rising)
           {
            OrderClose(OrderTicket(),Lots,Ask,Slippage,Red);
            gle=GetLastError();
            if(gle==0) {PrintAsk("CLOSE SELL");} else {PrintAskErr("CLOSE SELL",gle);}
            OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,Ask-(50*p),Ask+(50*p),TradeComment,10101,White);
            gle=GetLastError();
            if(gle==0) {PrintAsk("BUY "); bartick=0;} else {PrintAskErr("BUY ",gle);}
           } //if SELL

        }//if OrderSymbol...
     }//for


   return(0);
  } // start()


void PrintAsk(string msg)
  {
   Print(msg," ",Symbol(),"Ask=",Ask," Ticks=",bartick," ",CurTime());
  }

void PrintAskErr(string msg, int gle)
  {
   Print(msg," ",Symbol()," Err=",gle," Order -------FAILED-------  ",Ask," Ticks=",bartick," ",CurTime());
  }

void PrintBid(string msg)
  {
   Print(msg," ",Symbol(),"Ask=",Ask," Ticks=",bartick," ",CurTime());
  }

void PrintBidErr(string msg, int gle)
  {
   Print(msg," ",Symbol(),"Ask=",Ask," Ticks=",bartick," ",CurTime());
  }


