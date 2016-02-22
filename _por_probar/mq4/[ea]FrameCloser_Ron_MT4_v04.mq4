/*
+------------+
|FrameCloser |
+------------+

Theory of operation
===================
Close all open (not pending) orders at BasketProfit

TIME FRAME
==========
M1


PAIRS
=====
EURUSD (most active)


ENTRY LONG
==========
None

ENTRY SHORT
===========
None

EXIT
====
Sell all OPEN (not pending) orders

MONEY MANAGEMENT
================
None


RISK MANAGEMENT
===============
None


FAILURE MANAGEMENT
==================
GetLastError on every transaction
All missed transactions retried on next tick


VERSION HISTORY
===============
00    - initial concept

*/


// variables declared here are GLOBAL in scope

#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// user input
extern int    BasketProfit=350;

// other settings
int Slippage=3;

// naming and numbering
int      MagicNumber  = 16384;


//+-------------+
//| Custom init |
//|-------------+
// Called ONCE when EA is added to chart or recompiled
int init()
  {
   Print("Init happened ",CurTime());
   Comment(" ");
  }

//+----------------+
//| Custom DE-init |
//+----------------+
// Called ONCE when EA is removed from chart
int deinit()
  {
   Print("DE-Init happened ",CurTime());
   Comment(" ");
  }


//+-----------+
//| Main      |
//+-----------+
// Called EACH TICK and each Bar[]

int start()
  {
   
   double currBasket;

   string mySymbol;
   double myAsk;
   double myBid;   

   int      cnt=0;
   int      gle=0;
   int      OrdersOpenCount=0;

   currBasket=AccountEquity()-AccountBalance();
   Comment("Profit/Loss = ",currBasket, " of ",BasketProfit);
   
   if(currBasket>BasketProfit)
     {
      // CLOSE order if profit target made
      for(cnt=0;cnt<OrdersTotal();cnt++)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         //if( OrderMagicNumber()==MagicNumber )
         if( OrderType()==OP_BUY || OrderType()==OP_SELL )
           {
            mySymbol=OrderSymbol();
 
            if(OrderType()==OP_BUY)
              {
               myBid=MarketInfo(mySymbol,MODE_BID);            
               OrderClose(OrderTicket(),OrderLots(),myBid,Slippage,White);
               gle=GetLastError();
               if(gle==0)
                 {
                  Print("CLOSE BUY  Bid=",myBid); 
                 }
                  else 
                 {
                  Print("-----ERROR----- CLOSE BUY  Bid=",myBid," error=",gle);
                 }
              } // if BUY


            if(OrderType()==OP_SELL)
              {
               myAsk=MarketInfo(mySymbol,MODE_ASK);            
               OrderClose(OrderTicket(),OrderLots(),myAsk,Slippage,Red);
               gle=GetLastError();
               if(gle==0)
                 {
                  Print("CLOSE SELL Ask=",myAsk);
                 }
                  else 
                 {
                  Print("-----ERROR----- CLOSE SELL Ask=",myAsk," error=",gle);
                 }
              } //if SELL
           
           } // if(OrderSymbol)
        
        } // for

     } //currBasket

  } // start()



