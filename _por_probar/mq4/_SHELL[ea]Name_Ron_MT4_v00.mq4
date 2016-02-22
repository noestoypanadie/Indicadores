/*
+--------+
|Shell   |
+--------+

Please rename this program to something like  [ea]xxxxxx_yyyyyy__vzz_MT4.mq4

xxxxxx = your EA's name 
yyyyyy = your name (so we know your mods from everyone else)
vzz    = your version number (01, 02, 03...99) so we know what is the latest

Change the comments throughout to reflect your scheme



Theory of operation
(Put information about your scheme here)

TIME FRAME
==========
(what time frame is best for your scheme)

PAIRS
=====
(Are there any specific pairs)

ENTRY LONG
==========
(How are you deciding to Ask/Buy/Long)

ENTRY SHORT
===========
(How are you deciding to Bid/Sell/Short)

EXIT
====
(How do you get out of a trade, supposedly with profit)

MONEY MANAGEMENT
================
(Do you have a money management scheme)

RISK MANAGEMENT
===============
(do you have a risk management scheme)

FAILURE MANAGEMENT
==================
GetLastError on every transaction


VERSION HISTORY
===============
00    - initial concept
01    - 

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
extern int    BasketProfit=9999;      // if equity reaches this level, close trades
extern int    BasketLoss=9999;        // if equity reaches this negative level, close trades

// naming and numbering
int      MagicNumber  = 200601182020; // allows multiple experts to trade on same account
string   TradeComment = "Shell_00_";  // comment so multiple EAs can be seen in Account History

// Bar handling
datetime bartime=0;                   // used to determine when a bar has moved
int      bartick=0;                   // number of times bars have moved
int      objtick=0;                   // used to draw objects on the chart

// Trade control
bool TradeAllowed=true;               // used to manage trades


// Min/Max tracking
double maxOrders;
double maxEquity;
double minEquity;




//+-------------+
//| Custom init |
//|-------------+
// Called ONCE when EA is added to chart or recompiled

int init()
  {
   int    i;
   string o;
   //remove the old objects 
   for(i=0; i<Bars; i++) 
     {
      o=DoubleToStr(i,0);
      ObjectDelete("myx"+o);
      ObjectDelete("myz"+o);
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
   int    i;
   string o;
   //remove the old objects 
   
   for(i=0; i<Bars; i++) 
     {
      o=DoubleToStr(i,0);
      ObjectDelete("myx"+o);
      ObjectDelete("myz"+o);
     }
   objtick=0;
   
   Print("MAX number of orders",maxOrders);
   Print("MAX equity          ",maxEquity);
   Print("MIN equity          ",minEquity);
   
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
   double CurrentBasket=0;
   
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
   if(OrdersPerSymbol>maxOrders) maxOrders=OrdersPerSymbol;

     
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
        
   //+-----------------------------+
   //| Insert your indicator here  |
   //| And set either BUYme or     |
   //| SELLme true to place orders |
   //+-----------------------------+
   
   
   //+------------+
   //| End Insert |
   //+------------+

   //ENTRY LONG (buy, Ask) 
   if(TradeAllowed && BUYme)
     {
      if(LossLimit ==0) SL=0; else SL=Ask-((LossLimit+7)*Point() );
      if(ProfitMade==0) TP=0; else TP=Ask+((ProfitMade+7)*Point() );
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
     }//BUYme
        
   //ENTRY SHORT (sell, Bid)
   if(TradeAllowed && SELLme)
    {
      if(LossLimit ==0) SL=0; else SL=Bid+((LossLimit+7)*Point() );
      if(ProfitMade==0) TP=0; else TP=Bid-((ProfitMade+7)*Point() );
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
      }//SELLme

     
   //Basket profit or loss
   CurrentBasket=AccountEquity()-AccountBalance();
   if(CurrentBasket>maxEquity) maxEquity=CurrentBasket;
   if(CurrentBasket<minEquity) minEquity=CurrentBasket;
   if( CurrentBasket>=BasketProfit || CurrentBasket<=(BasketLoss*(-1)) ) CloseEverything();
   
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
               SL=OrderOpenPrice()+(spread*2);
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
            if(CurrentProfit >= TrailStop*p )
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
            if((ProfitMade>0 && CurrentProfit>=(ProfitMade*p)) || (LossLimit>0 && CurrentProfit<=((LossLimit*(-1))*p))  )
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
               SL=OrderOpenPrice()-(spread*2);
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
            if(CurrentProfit >= TrailStop*p)
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
            if( (ProfitMade>0 && CurrentProfit>=(ProfitMade*p)) || (LossLimit>0 && CurrentProfit<=((LossLimit*(-1))*p))  )
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



//+-----------------+
//| CloseEverything |
//+-----------------+
// Closes all OPEN and PENDING orders

int CloseEverything()
  {
   double myAsk;
   double myBid;
   int    myTkt;
   double myLot;
   int    myTyp;

   int i;
   bool result = false;
    
   for(i=OrdersTotal();i>=0;i--)
     {
      OrderSelect(i, SELECT_BY_POS);

      myAsk=MarketInfo(OrderSymbol(),MODE_ASK);            
      myBid=MarketInfo(OrderSymbol(),MODE_BID);            
      myTkt=OrderTicket();
      myLot=OrderLots();
      myTyp=OrderType();
            
      switch( myTyp )
        {
         //Close opened long positions
         case OP_BUY      :result = OrderClose(myTkt, myLot, myBid, Slippage, Red);
         break;
      
         //Close opened short positions
         case OP_SELL     :result = OrderClose(myTkt, myLot, myAsk, Slippage, Red);
         break;

         //Close pending orders
         case OP_BUYLIMIT :
         case OP_BUYSTOP  :
         case OP_SELLLIMIT:
         case OP_SELLSTOP :result = OrderDelete( OrderTicket() );
       }
    
      if(result == false)
        {
         Alert("Order " , myTkt , " failed to close. Error:" , GetLastError() );
         Print("Order " , myTkt , " failed to close. Error:" , GetLastError() );
         Sleep(3000);
        }  

      Sleep(1000);

     } //for
  
  } // closeeverything





//+-----------------+
//| CloseOpenOrders |
//+-----------------+
// Close only open, active orders, 
// leaving pending orders in place

int CloseOpenOrders()
  {
   double myAsk;
   double myBid;
   double myTkt;
   double myLot;

   int i;
   bool result = false;
    
   for(i=OrdersTotal();i>=0;i--)
     {
      OrderSelect(i, SELECT_BY_POS);

      myAsk=MarketInfo(OrderSymbol(),MODE_ASK);            
      myBid=MarketInfo(OrderSymbol(),MODE_BID);            
      myTkt=OrderTicket();
      myLot=OrderLots();
      
      switch( OrderType() )
        {
         //Close opened long positions
         case OP_BUY      :result = OrderClose(myTkt, myLot, myBid, Slippage, Red);
         break;
      
         //Close opened short positions
         case OP_SELL     :result = OrderClose(myTkt, myLot, myAsk, Slippage, Red);
         break;
       }
    
      if(result == false)
        {
         Alert("Order " , myTkt , " failed to close. Error:" , GetLastError() );
         Print("Order " , myTkt , " failed to close. Error:" , GetLastError() );
         Sleep(3000);
        }  

     } //for
  
  } // closeopenorders



double Divergence(int Fast_Period, int Slow_Period, int Fast_Price, int Slow_Price, int mypos)
  {
   // Simple moving average divergence
   // Tried HMA and it didn't work well AT ALL!
   
   double maF1, maF2, maS1, maS2;
   double dv1, dv2, rtn;

   maF1=iMA(Symbol(),0,Fast_Period,0,MODE_SMA,Fast_Price,mypos);
   maS1=iMA(Symbol(),0,Slow_Period,0,MODE_SMA,Slow_Price,mypos);
   dv1=(maF1-maS1);

   maF2=iMA(Symbol(),0,Fast_Period,0,MODE_SMA,Fast_Price,mypos+1);
   maS2=iMA(Symbol(),0,Slow_Period,0,MODE_SMA,Slow_Price,mypos+1);
   dv2=((maF1-maS1)-(maF2-maS2));

   // dynamic around Close(0)
   rtn=(dv1-dv2);
   return(rtn);
   
  }




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


void logwrite (string filename, string mydata)
  {
   int myhandle;
   myhandle=FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_READ, ";");
   if(myhandle>0)
     {
      FileSeek(myhandle,0,SEEK_END);
      FileWrite(myhandle, mydata);
      FileClose(myhandle);
     }
  } 