/*
+--------+
|CCIGrab |
+--------+

Theory of operation
===================
+-100 in 2 or 3 bars, then order in proper direction
small losslimit, large profitmade

TIME FRAME
==========
whatever works best

PAIRS
=====
EURUSD

ENTRY LONG
==========
CCI < -100 to CCI > +100

ENTRY SHORT
===========
CCI > +100 to CCI < -100

EXIT
====
ProfitMade (optimized by month)

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
01    - 

*/


// variables declared here are GLOBAL in scope

#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// user input
extern double Lots=0.1;
extern int    Slippage=2;
extern double ProfitMade=42;
extern double LossLimit=95;

extern int    cciperiod=2;
extern int    cciprice=3; //typical
extern int    ccilevel=30;

extern double TrailStop=999;
extern int    PLBreakEven=999;

// naming and numbering
int      MagicNumber  = 200601291336;
string   TradeComment = "CCIGrab_00_";

// Bar handling
datetime bartime=0;
int      bartick=0;
int      objtick=0;

// Trade control
bool TradeAllowed=true;

// GlobalVariableCheck(static) counter 
// for number of basket closes
int  maxDrawDown=0;
int  maxOrderOpen=0;

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
   Print("DE-Init happened ",CurTime());
   Comment(" ");
   
   Print( "MaxDD=",maxDrawDown  );
   Print( "MaxOO=",maxOrderOpen );

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
   
   //indcator related variables
   int cci1=0;
   int cci2=0;
   int cci3=0;
      
   // bar counting
   if(bartime!=Time[0]) 
     {
      bartime=Time[0];
      bartick++; 
      objtick++;
      TradeAllowed=true;
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

   if(OrdersPerSymbol>maxOrderOpen)maxOrderOpen=OrdersPerSymbol;
   if(  AccountBalance()-AccountEquity() > maxDrawDown ) maxDrawDown=AccountBalance()-AccountEquity();
   Comment( "MaxDD=",maxDrawDown," MaxOO=",maxOrderOpen );

   // insert indicator here   
   cci1=iCCI(Symbol(),0,cciperiod,cciprice,0);
   cci2=iCCI(Symbol(),0,cciperiod,cciprice,1);
   cci3=iCCI(Symbol(),0,cciperiod,cciprice,2);
   
   if( cci1<(ccilevel*(-1)) && (cci2>ccilevel        || cci3>ccilevel) ) { BUYme=true;}
   if( cci1>ccilevel        && (cci2<(ccilevel*(-1)) || cci3<(ccilevel*(-1)) ) ) { SELLme=true;}

   if(TradeAllowed)
     {
      //ENTRY LONG (buy, Ask) 
      if(BUYme)
		  {
		   //Ask(buy, long)
         SL=Ask-((LossLimit+10)*p);
         TP=Ask+((ProfitMade+10)*p);
         OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,SL,TP,TradeComment,MagicNumber,White);
         gle=GetLastError();
         if(gle==0)
           {
            Print("BUY  Ask=",Ask," bartick=",bartick);
            ObjectCreate("myx"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], High[0]+(7*p));
            ObjectSetText("myx"+DoubleToStr(objtick,0),"B",15,"Arial",White);
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
         SL=Bid+((LossLimit+10)*p);
         TP=Bid-((ProfitMade+10)*p);
         OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,SL,TP,TradeComment,MagicNumber,Red);
         gle=GetLastError();
         if(gle==0)
           {
            Print("SELL Bid=",Bid," bartick=",bartick); 
            ObjectCreate("myx"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], High[0]+(7*p));
            ObjectSetText("myx"+DoubleToStr(objtick,0),"S",15,"Arial",White);
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




