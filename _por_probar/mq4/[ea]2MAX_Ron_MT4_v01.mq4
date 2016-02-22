/*
+--------+
|2MAX    |
+--------+

Theory of operation
Long term MA against short term MA

TIME FRAME
==========
trying M15

PAIRS
=====
GBPUSD

ENTRY LONG
==========
Fast cross above slow

ENTRY SHORT
===========
Fast cross below slow

EXIT
====
Stop and Reverse

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
01    - initial concept

*/


// variables declared here are GLOBAL in scope

#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// user input
extern double Lots=0.1;               // how many lots to trade at a time 
extern int    Slippage=2;             // how many pips of slippage can you tolorate
extern int    MASlow=6;
extern int    MAFast=89;
extern double ProfitMade=999;          // how much money do you expect to make
extern double LossLimit=999;           // how much loss can you tolorate
extern double TrailStop=999;          // trailing stop (999=no trailing stop)
extern int    PLBreakEven=999;        // set break even when this many pips are made (999=off)
extern int    StartHour=0;            // your local time to start making trades
extern int    StopHour=24;            // your local time to stop making trades
extern int    BasketProfit=9999;      // if equity reaches this level, close trades
extern int    BasketLoss=9999;        // if equity reaches this negative level, close trades
extern string FileName="2MAXLog";

// naming and numbering
int      MagicNumber  = 200604052129; // allows multiple experts to trade on same account
string   TradeComment = "2MAX_01_";   // comment so multiple EAs can be seen in Account History

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
   logwrite( FileName, "Init happened "+CurTime());
   Comment(" ");
  }

//+----------------+
//| Custom DE-init |
//+----------------+
// Called ONCE when EA is removed from chart

int deinit()
  {
   Print("MAX number of orders",maxOrders);
   Print("MAX equity          ",maxEquity);
   Print("MIN equity          ",minEquity);
   
   Print("DE-Init happened ",CurTime());
   logwrite( FileName, "DE-Init happened "+CurTime());
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
      
   // indicator things
   double PmaF, PmaS, CmaF, CmaS;

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

     
   //+-----------------------------+
   //| Insert your indicator here  |
   //| And set either BUYme or     |
   //| SELLme true to place orders |
   //+-----------------------------+
   
   CmaS=iMA(Symbol(),0,MASlow,0,MODE_SMA,PRICE_OPEN,0);
   PmaS=iMA(Symbol(),0,MASlow,0,MODE_SMA,PRICE_OPEN,1);

   CmaF=iMA(Symbol(),0,MAFast,0,MODE_LWMA,PRICE_OPEN,0);
   PmaF=iMA(Symbol(),0,MAFast,0,MODE_LWMA,PRICE_OPEN,1);
   
   ObjectDelete("xCmaS");
   ObjectCreate("xCmaS", OBJ_TEXT, 0, Time[0], CmaS);
   ObjectSetText("xCmaS","+",15,"Arial",White);

   ObjectDelete("xCmaF");
   ObjectCreate("xCmaF", OBJ_TEXT, 0, Time[0], CmaF);
   ObjectSetText("xCmaF","+",15,"Arial",White);

   ObjectDelete("xPmaS");
   ObjectCreate("xPmaS", OBJ_TEXT, 0, Time[1], PmaS);
   ObjectSetText("xPmaS","+",15,"Arial",White);

   ObjectDelete("xPmaF");
   ObjectCreate("xPmaF", OBJ_TEXT, 0, Time[1], PmaF);
   ObjectSetText("xPmaF","+",15,"Arial",White);

   
   
   if(TradeAllowed && PmaF<PmaS && CmaF>CmaS)
     {
      CloseEverything();
      //BUYme=true;
      
     }
     
   if(TradeAllowed && PmaF>PmaS && CmaF<CmaS) 
     {
      CloseEverything();
      //SELLme=true;
     }
   
   
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
            if(CurrentProfit>=(ProfitMade*p) || CurrentProfit<=((LossLimit*(-1))*p)  )
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
            if( CurrentProfit>=(ProfitMade*p) || CurrentProfit<=((LossLimit*(-1))*p)  )
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