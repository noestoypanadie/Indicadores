//+------------------------+
//|       XRSI47           |
//+------------------------+
//

/*
Theory of operation
-------------------
This is a scalping expert based on cross of RSI4 & RSI7
This is a STOP/REVERSE system (which means always-in)
(This is probably going to need a pip filter for chop)


TIME FRAME
----------
5 MINUTES


SUGGESTED PAIRS
---------------
GBPUSD


ENTRY LONG
----------
RSI4([2]) less than RSI7(Bar[2]) and RSI4(bar[1]) greater than RSI7(Bar[1])


ENTRY SHORT
-----------
RSI4([2]) greater than RSI7(Bar[2]) and RSI4(bar[1]) less than RSI7(Bar[1])


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


// generic user input
extern double Lots=0.1;
extern int    Slippage=2;


//+------------------------------------+
//| EA load code                       |
//+------------------------------------+

int init()
  {
   Print("Init happened");
  }


//+------------------------------------+
//| EA unload code                     |
//+------------------------------------+

int deinit()
  {
   Print("DE-Init happened");
   Comment(" ");
  }



//+------------------------------------+
//| EA main code                       |
//+------------------------------------+

int start()
  {
   double p=Point();
   int      cnt=0;

   int      OrdersPerSymbol=0;

   double  pRSI4=0,  RSI4=0;
   double  pRSI7=0,  RSI7=0;
   bool    Rising=false, Falling=false;
   
   string TradeComment = "XRSI47";

   // Error checking & bar counting
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}

   // 2-period moving average on Bar[2]
    RSI4=iRSI(Symbol(),0,4,PRICE_CLOSE,1);
   pRSI4=iRSI(Symbol(),0,4,PRICE_CLOSE,2);
    RSI7=iRSI(Symbol(),0,7,PRICE_CLOSE,1);
   pRSI7=iRSI(Symbol(),0,7,PRICE_CLOSE,2);

   // Determine if there was a cross
   if(pRSI4<pRSI7 && RSI4>RSI7) {Rising=true;  Falling=false;}
   if(pRSI4>pRSI7 && RSI4<RSI7) {Rising=false; Falling=true;}
   
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
      //ENTRY Ask(buy, long) 
      if(Rising)
		  {
         OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,Ask-(50*p),Ask+(50*p),TradeComment,10101,White);
         Print("Initial BUY");
        }
        
      //ENTRY Bid (sell, short)
      if(Falling)
        {
         OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,Bid+(50*p),Bid-(50*p),TradeComment,10101,Red);
         Print("Initial SELL");
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
            OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,Bid+(50*p),Bid-(50*p),TradeComment,10101,Red);
           } // if BUY


         // RSI crossed up, so swap SELL for BUY
         if (OrderType() == OP_SELL && Rising)
           {
            OrderClose(OrderTicket(),Lots,Ask,Slippage,Red);
            OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,Ask-(50*p),Ask+(50*p),TradeComment,10101,White);
           } //if SELL

        }//if OrderSymbol...
     }//for


   return(0);
  } // start()




