/*
+---------+
|H4Scalp  |
+---------+

Theory of operation
@ orders per bar with atr/2 for TP and NO stop loss
Sell everything at next bar 

TIME FRAME
==========
H4

PAIRS
=====
Any high-ATR pair

ENTRY LONG
==========
Beginning of bar 

ENTRY SHORT
===========
Beginning of bar 

EXIT
====
ATR/2 takeprofit

MONEY MANAGEMENT
================
none

RISK MANAGEMENT
===============
none

FAILURE MANAGEMENT
==================
GetLastError on every transaction


VERSION HISTORY
===============
00    - initial concept


*/


// variables declared here are GLOBAL in scope

#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// user input
extern double Lots=0.1;               // how many lots to trade at a time 
extern int    Slippage=2;             // how many pips of slippage can you tolorate
extern double ProfitMade=34;          // how much money do you expect to make
extern double LossLimit=45;           // how much loss can you tolorate
extern double TrailStop=999;          // trailing stop (999=no trailing stop)
extern int    PLBreakEven=999;        // set break even when this many pips are made (999=off)
extern int    StartHour=0;            // your local time to start making trades
extern int    StopHour=24;            // your local time to stop making trades

// naming and numbering
int      MagicNumber  = 200601182020; // allows multiple experts to trade on same account
string   TradeComment = "Shell_00_";  // comment so multiple EAs can be seen in Account History

// Bar handling
datetime bartime=0;                   // used to determine when a bar has moved
int      bartick=0;                   // number of times bars have moved
int      objtick=0;                   // used to draw objects on the chart

// Trade control
bool TradeAllowed=true;               // used to manage trades


//+-------------+
//| Custom init |
//|-------------+
// Called ONCE when EA is added to chart or recompiled

int init()
  {
   int i;

   //remove the old objects 
   for(i=0; i<Bars; i++) 
     {
      ObjectDelete("myx0"+DoubleToStr(i,0));
      ObjectDelete("myz0"+DoubleToStr(i,0));
     }
   objtick=0;

   Print("Init happened ",CurTime());
   Comment(" ");
  }

//+----------------+
//| Custom DE-init |
//+----------------+
// Called ONCE when EA is removed from chart

int deinit()
  {
   int i;
   //remove the old objects 
   for(i=0; i<Bars; i++) 
     {
      ObjectDelete("myx0"+DoubleToStr(i,0));
      ObjectDelete("myz0"+DoubleToStr(i,0));
     }
   objtick=0;
   
   Print("DE-Init happened ",CurTime());
   Comment(" ");
  }


//+-----------+
//| Main      |
//+-----------+
// Called EACH TICK and each Bar[]

int start()
  {

   double p=Point();
   double spread=Ask-Bid;
   
   int      cnt=0;
   int      gle=0;
   int      OrdersPerSymbol=0;
   int      OrdersBUY=0;
   int      OrdersSELL=0;
  
   // stoploss and takeprofit and close control
   double SL=0;
   double TP=0;
   double CurrentProfit=0;
   
   // direction control
   bool BUYme=false;
   bool SELLme=false;
      
   // bar counting
   if(bartime!=Time[0]) 
     {
      bartime=Time[0];
      bartick++; 
      objtick++;

      if(Hour()>=StartHour && Hour()<=StopHour)
        {
         TradeAllowed=true;
        }
     }


   OrdersPerSymbol=0;
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
        {
         OrdersPerSymbol++;
         if(OrderType()==OP_BUY) {OrdersBUY++;}
         if(OrderType()==OP_SELL){OrdersSELL++;}
        }
     }

     
   //TradeBars = MathFloor(CurTime() - OrderOpenTime())/60/Period();

   // TradeAllowed on close keeps from closing 'just opened' orders
   //if( OrdersPerSymbol>0 && (x2buy || x2sell) && TradeAllowed )
   //  {
   //   // crossover, so close orders
   //   for(cnt=0;cnt<OrdersTotal();cnt++)
   //     {
   //      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
   //      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber )
   //        {
   //         if(OrderType()==OP_BUY) {OrderClose(OrderTicket(),Lots,Bid,Slippage,White);}
   //         if(OrderType()==OP_SELL){OrderClose(OrderTicket(),Lots,Ask,Slippage,Red);}
   //        }
   //     }
   //  }
        

   if(TradeAllowed)
     {
      //ENTRY LONG (buy, Ask) 
      if(BUYme)
		  {
		   //Ask(buy, long)
         SL=Ask-((LossLimit+5)*p);
         TP=Ask+((ProfitMade+5)*p);
         OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,SL,TP,TradeComment,MagicNumber,White);
         gle=GetLastError();
         if(gle==0)
           {
            Print("BUY  Ask=",Ask," bartick=",bartick);
            ObjectCreate("myx"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], High[0]+(7*p));
            ObjectSetText("myx"+DoubleToStr(objtick,0),"B",15,"Arial",Red);
            bartick=0;
            TradeAllowed=false;
           }
            else 
           {
            Print("-----ERROR----- BUY  Ask=",Ask," error=",gle," bartick=",bartick);
           }
        }
        
      //ENTRY SHORT (sell, Bid)
      if(SELLme )
        {
         //Bid (sell, short)
         SL=Bid+((LossLimit+5)*p);
         TP=Bid-((ProfitMade+5)*p);
         OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,SL,TP,TradeComment,MagicNumber,Red);
         gle=GetLastError();
         if(gle==0)
           {
            Print("SELL Bid=",Bid," bartick=",bartick); 
            ObjectCreate("myx"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], High[0]+(7*p));
            ObjectSetText("myx"+DoubleToStr(objtick,0),"S",15,"Arial",Red);
            bartick=0;
            TradeAllowed=false;
           }
            else 
           {
            Print("-----ERROR----- SELL Bid=",Bid," error=",gle," bartick=",bartick);
           }

        }

     } //if allowed

   // CLOSE order if profit target made
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber )
        {
        
         if(OrderType()==OP_BUY)
           {
            CurrentProfit=Bid-OrderOpenPrice() ;

            // modify for break even
            if (CurrentProfit >= PLBreakEven*p && OrderOpenPrice()>OrderStopLoss())
              {
               SL=OrderOpenPrice()+((spread*2)*p);
               TP=OrderTakeProfit();
               OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, White);
               gle=GetLastError();
               if(gle==0)
                 {
                  Print("MODIFY BREAKEVEN BUY  Bid=",Bid," bartick=",bartick); 
                  ObjectCreate("myz"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], Low[0]-(7*p));
                  ObjectSetText("myz"+DoubleToStr(objtick,0),"BE",15,"Arial",White);
                 }
                  else 
                 {
                  Print("-----ERROR----- MODIFY BREAKEVEN BUY  Bid=",Bid," error=",gle," bartick=",bartick);
                 }
              }

            // modify for trailing stop
            if(CurrentProfit > TrailStop*p )
              {
               SL=Bid-(TrailStop*p);
               TP=OrderTakeProfit();
               OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, White);
               gle=GetLastError();
               if(gle==0)
                 {
                  Print ("MODIFY TRAILSTOP BUY  StopLoss=",SL,"  bartick=",bartick,"OrderTicket=",OrderTicket()," CurrProfit=",CurrentProfit); 
                  ObjectCreate("myz"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], Low[0]-(7*p));
                  ObjectSetText("myz"+DoubleToStr(objtick,0),"TS",15,"Arial",White);
                 }
                  else 
                 {
                  Print("-----ERROR----- MODIFY TRAILSTOP BUY  Bid=",Bid," error=",gle," bartick=",bartick);
                 }
              }

            // did we make our desired BUY profit
            // or did we hit the BUY LossLimit
            if(CurrentProfit>(ProfitMade*p) || CurrentProfit<(LossLimit*(-1))*p  )
              {
               OrderClose(OrderTicket(),Lots,Bid,Slippage,White);
               gle=GetLastError();
               if(gle==0)
                 {
                  Print("CLOSE BUY  Bid=",Bid," bartick=",bartick); 
                  ObjectCreate("myz"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], Low[0]-(7*p));
                  ObjectSetText("myz"+DoubleToStr(objtick,0),"C",15,"Arial",White);
                 }
                  else 
                 {
                  Print("-----ERROR----- CLOSE BUY  Bid=",Bid," error=",gle," bartick=",bartick);
                 }
              }
              
           } // if BUY


         if(OrderType()==OP_SELL)
           {

            CurrentProfit=OrderOpenPrice()-Ask;
            
            // modify for break even
            if (CurrentProfit >= PLBreakEven*p && OrderOpenPrice()<OrderStopLoss())
              {
               SL=OrderOpenPrice()-((spread*2)*p);
               TP=OrderTakeProfit();
               OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, Red);
               gle=GetLastError();
               if(gle==0)
                 {
                  Print("MODIFY BREAKEVEN SELL Ask=",Ask," bartick=",bartick);
                  ObjectCreate("myz"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], Low[0]-(7*p));
                  ObjectSetText("myz"+DoubleToStr(objtick,0),"BE",15,"Arial",Red);
                 }
                  else 
                 {
                  Print("-----ERROR----- MODIFY BREAKEVEN SELL Ask=",Ask," error=",gle," bartick=",bartick);
                 }
              }

            // modify for trailing stop
            if(CurrentProfit > TrailStop*p)
              {
               SL=Ask+(TrailStop*p);
               TP=OrderTakeProfit();
               OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, Red);
               gle=GetLastError();
               if(gle==0)
                 {
                  Print ("MODIFY TRAILSTOP SELL StopLoss=",SL,"  bartick=",bartick,"OrderTicket=",OrderTicket()," CurrProfit=",CurrentProfit); 
                  ObjectCreate("myz"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], Low[0]-(7*p));
                  ObjectSetText("myz"+DoubleToStr(objtick,0),"TS",15,"Arial",Red);
                 }
                  else 
                 {
                  Print("-----ERROR----- MODIFY TRAILSTOP SELL Ask=",Ask," error=",gle," bartick=",bartick);
                 }
              }

            // did we make our desired SELL profit?
            if( CurrentProfit>(ProfitMade*p) || CurrentProfit<(LossLimit*(-1))*p  )
              {
               OrderClose(OrderTicket(),Lots,Ask,Slippage,Red);
               gle=GetLastError();
               if(gle==0)
                 {
                  Print("CLOSE SELL Ask=",Ask," bartick=",bartick);
                  ObjectCreate("myz"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], Low[0]-(7*p));
                  ObjectSetText("myz"+DoubleToStr(objtick,0),"C",15,"Arial",Red);
                 }
                  else 
                 {
                  Print("-----ERROR----- CLOSE SELL Ask=",Ask," error=",gle," bartick=",bartick);
                 }
                 
              }

           } //if SELL
           
        } // if(OrderSymbol)
        
     } // for

  } // start()

/*

int PlaceOrder(string currency, string BuySell, int PM, int LL)
  {
   // Returns GetLastError number
   
   // you can call with ProfitMade or LossLimit set to 
   // zero, and none will be set when order is placed
  
   int gle=0;      // GetLastError number
   
   double mySL;    // locally generated SL
   double myTP;    // locally generated TP
   
   double myAsk   = MarketInfo(currency, MODE_ASK);
   double myBid   = MarketInfo(currency, MODE_BID);
   double myPoint = MarketInfo(currency, MODE_POINT);

   //Ask(buy, long)
   if (BuySell=="BUY")
     {
      if(LL==0) mySL=0; else mySL=myAsk-(LL*myPoint);
      if(PM==0) myTP=0; else myTP=myAsk+(PM*myPoint);
      OrderSend(currency,OP_BUY,Lots,myAsk,Slippage,mySL,myTP,TradeComment,MagicNumber,White);
      gle=GetLastError();
      if(gle==0)
        {
         Print("----Place Order      Symbol=",currency," StopLoss=",mySL," TakeProfit=",myTP," Ask=",myAsk);
         return(0);
        }
         else 
        {
         Print("----ERROR----",gle," Symbol=",currency," error=",gle," StopLoss=",mySL," TakeProfit=",myTP," Ask=",myAsk);
         return(gle);
        }
     }

     
   //Bid (sell, short)
   if (BuySell=="SELL")
     {
      if(LL==0) mySL=0; else mySL=myBid+(LossLimit*myPoint);
      if(PM==0) myTP=0; else myTP=myBid-(ProfitMade*myPoint);
      OrderSend(currency,OP_SELL,Lots,myBid,Slippage,mySL,myTP,TradeComment,MagicNumber,White);
      gle=GetLastError();
      if(gle==0)
        {
         Print("----Place Order      Symbol=",currency," StopLoss=",mySL," TakeProfit=",myTP," Bid=",myBid);
        }
         else 
        {
         Print("----ERROR----",gle," Symbol=",currency," StopLoss=",mySL," TakeProfit=",myTP," Bid=",myBid);
        }
     }

  }//PlaceOrder


*/