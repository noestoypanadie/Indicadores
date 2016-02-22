/*
+------------------------------------+
| TRUE_SCALPER                       |
+------------------------------------+

Theory of operation

Based on MA3 of Bar[1] being higher or lower than MA7 of Bar[1]
       AND  
RSI2 of Bar[2] transitioning to RSI of Bar[1]

ProfitMade and StopLosses are optimized per pair per month
Triple Threat Trailing Stops optimized per pair per month


TIME FRAME
==========
Place on 5 minute chart


PAIRS
=====
As optimized. It will NOT work well on every pair


ENTRY LONG
==========
MA3(Bar[1]) is greater than MA7(Bar[1]) by at least 1 pip
RSI(2-period Bar[2]) less than RSI_Neg and RSI Bar[1] greater than RSI_Pos2


ENTRY SHORT
===========
MA3(Bar[1]) is less than than MA7(Bar[1]) by at least 1 pip
RSI(2-period Bar[2]) greater than RSI_Pos and RSI Bar[1] less than RSI_Neg2


EXIT
====
ProfitMade, TrailingStop or TP/SL if internet fails or computer crashed


MONEY MANAGEMENT
================
-none-


RISK MANAGEMENT
===============
-none-


FAILURE MANAGEMENT
==================
Fairly complete, as most failures will be resolved on the 
next tick. Comments written to log and file


VERSION HISTORY
===============

 v2a - This is the one used successfully by Jean-François 
       (if you call TP of 9 and SL of 175 a 'success')
       Ron converted from MT3 to MT4 and released into the wild.
       Designed for M5 but I attached it to M15 and it worked fine.
       long if EMA3>EMA7:::EMA3<EMA7<0 
       Code Adapted from  Scalper EAs to use EMA and RSI and multiple currencies

 v4 - Fixed a couple of ELSE statements that should NOT
      have been there


 Spent a LOT of time debugging the backtester


 v11- added sell-&-hedge
      added abandon-after-#-of-ticks
      added init() section to load optimized symbol info


Spent a lot of time gathering comments and testing various stratigies


 v37(11)- - reverted to v2a
          - upgraded to include improved theory of operation
          - changed bull & bear to slow & fast  
          - added debug Print() for good/bad transactions
          - added debug File() for tracking bars-per-trade
          
 v38(11)- - tried and rejected - close on next cross
          - tried and only marginal - move SL to BE at some profit level
          - tried TradeAllowed holdoff till next cross (misses LOTS of profit)
          - found that gbpusd likes RSINEG and RSIPOS at differing levels (EUREKA!) 
          - profit levels MUST be - % of volitility and stop loss at volitility + % (double EUREKA!)

 v39(11)- - tried seedling code and reverted to 38
 
 v40(11)- - trying 2 or 3 orders open at once (linear gain, like trading 0.1 vs 1.0)
          - added magic number
          - modified multiple-order-open to work with TradeAllowed
          - finally understand that the retracement needs to be optimized, not the profit

 v40-43 - - tried several other indicators to escape the bad trades, reverted to
            v11 to clear the confusion so it's now v11+proper ProfitMade setting
            and proprt RSI optimization for the profit level 
 
 v44(11)- - back to v11 with profitmade at 1/4 volitility and optimized StopLoss and RSI
          - removed commented old "abandon" code
          - removed ordernum code
          - tried and discarded 2nd MA and 2nd RSI from multiple periods

 v45    - - fixed chart time at 15Min, so accidental timeframe won't mess up again
          - added RSI transition code that wasn't in the old MQL script, looks promising
        
 v46    - - added TradeAllowed back in, only trade once right after MA cross
            and all RSI are at 50
            
 v47    - - moved TradeAllowed to bartick, so ANY valid trade is taken regardless of number open
 
 v48    - - Added some switches to the externs so people can test in various states 
            of variables when released into the wild
          - Added multi-orders so we can hedge some, and do some discretionary trading
          - Optimized GBPUSD for multiple trades
          
 v49    - - Removed to hihi and lolo tracking code 
 
 v49c   - - Released to group
 
 v49h   - - Added the ability to specify the number of long and short orders that can
            be open at once, so the 'hedge' effect isn't blocked by a full limit of 
            orders, all in one direction.
 v49L   - - Added ProfitLock(tm) of my own style 
            Found 2 errors. found two return(0) inside the 'for' loop that closes orders. 
            This would have caused orders not to be closed until the next tick. Was causing
            a small but noticable difference in profit, and would severly affected the
            handling of profits during spikes.
 
 v49N   - - Added true trailing stop
            Fixed a small error in Break-even lock, where SL was calculated + and applied -

 v49P   - - Added a closing trailing stop, as profits increase
            Added TripleThreat(tm) trailing stop. Very Nice equity curve  :)
            Released to group Nov 13 2005
 
*/


// variables declared here are GLOBAL in scope

#property copyright "Ron Thompson & Jacob Yego"
#property link      "http://www.lightpatch.com/forex/TrueScalper49+"

// user input
extern double Lots=0.1;
extern double Slippage=2;
extern double NumberOfLongOrders=12;
extern double NumberOfShortOrders=13;

// these two lines are over-ridden my TrailEnable
extern double ProfitMade=106;
extern double StopLoss=55;

// ProfitLock(tm) Thanks Roger!
extern bool   PLEnabled=false;
extern double PLBreakEven=52;

// Triple-Threat(tm) Trailing Stop (by Ron)
extern bool   TrailEnable=true;

extern double TrailingStopLevel1=   0;
extern double TrailingStop1=      105;

extern double TrailingStopLevel2= 157;
extern double TrailingStop2=       79;

extern double TrailingStopLevel3= 291;
extern double TrailingStop3=       16;

// only used in case computer or internet fails
// NEXT_VERSION change this to trail/follow about 10-20 pips
// ahead of actual order, to prevent loss during failures
double   TakeProfit=999;

// naming and numbering
double   MagicNumber  = 200511131042;
string   TradeComment = "TrueScalper_49P_";

// Bar handling
datetime bartime=0;
double   bartick=0;

// one trade per cross control
bool TradeAllowed=false;

int handle=0;


//+-------------+
//| Custom init |
//|-------------+
// Called ONCE when EA is added to chart or recompiled
int init()
  {
   handle=FileOpen("TSDATA_"+Symbol(),FILE_CSV|FILE_WRITE,",");

   FileWrite(handle,"Init happened ",CurTime());
   Print(           "Init happened ",CurTime());

   FileWrite(handle,Symbol()," is using ProfitMade=",ProfitMade," and StopLoss=",StopLoss);
   Print(           Symbol()," is using ProfitMade=",ProfitMade," and StopLoss=",StopLoss);

   Comment(TradeComment);
  }


//+----------------+
//| Custom DE-init |
//+----------------+
// Called ONCE when EA is removed from chart
int deinit()
  {
   FileWrite(handle,"DE-Init happened ",CurTime());
   Print(           "DE-Init happened ",CurTime());
   
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
   
   double   cnt=0;
   double   gle=0;
   double   OrdersPerSymbol=0;
   double   OrdersLong=0;
   double   OrdersShort=0;
   
   double  SL=0; //stop loss
   double  TP=0; //take profit
   double  TS=0; //trailing stop
   
   double  CurrentProfit=0;

   // Moving Averages
   double  MAFast=0;
   double  MASlow=0;

   // RSI indicator and direction
   double  RSI=0;
   double  RSI2=0;
   bool    RSIPOS=false;
   bool    RSINEG=false;


   // PLEASE NOTE
   // There is no error checking here for AccountFreeMargin
   // That's because ProfitMade & TrailingStop are in a loop at the bottom of this code.
   // If you exit on no margin, you can NEVER collect profit from remaing 
   // open trades because the code that would collect it can never execute.
   // Besides, the server won't let you trade anyway, so it was only a courtesy.
   
   // bar counting
   if(bartime!=Time[0]) {bartime=Time[0]; bartick++; TradeAllowed=true;}
   
   // 3-period and 7-period EXPONENTIAL moving averageon CLOSE of Bar[1]
   MAFast=iMA(Symbol(),15,3,0,MODE_EMA,PRICE_CLOSE,1);
   MASlow=iMA(Symbol(),15,7,0,MODE_EMA,PRICE_CLOSE,1);
   
   // 2-period RSI on Bar[2]
   RSI= iRSI(Symbol(),15,2,PRICE_CLOSE,2);
   RSI2=iRSI(Symbol(),15,2,PRICE_CLOSE,1);

   // Determine what polarity RSI is in
   if(RSI>50 && RSI2<50) {RSIPOS=true;}
   if(RSI<50 && RSI2>50) {RSINEG=true;}


   OrdersPerSymbol=0;
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
        {
         OrdersPerSymbol++;
         if(OrderType()==OP_BUY)  {OrdersLong++;}
         if(OrderType()==OP_SELL) {OrdersShort++;}
        }
     }

   if((OrdersPerSymbol < (NumberOfLongOrders+NumberOfShortOrders)) && TradeAllowed)
     {
     
      //ENTRY LONG (buy, Ask) 
      if(MAFast>(MASlow+p) && RSINEG && OrdersLong<NumberOfLongOrders)
		  {
		   //Ask(buy, long)
         SL=Ask-(StopLoss*p);
         TP=Ask+(TakeProfit*p);
         OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,SL,TP,TradeComment,MagicNumber,White);
         gle=GetLastError();
         if(gle==0)
           {
            Print           ("BUY  Ask=",Ask," bartick=",bartick);
            bartick=0;
            TradeAllowed=false;
           }
            else 
           {
            Print           ("BUY  -----ERROR----- Ask=",Ask," MAFast=",MAFast," MASlow=",MASlow," RSI=",RSI," gle=",gle," bartick=",bartick);
           }
        }
        
      //ENTRY SHORT (sell, Bid)
      if(MAFast<(MASlow-p) && RSIPOS && OrdersShort<NumberOfShortOrders)
        {
         SL=Bid+(StopLoss*p);
         TP=Bid-(TakeProfit*p);
         OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,SL,TP,TradeComment,MagicNumber,Red);
         gle=GetLastError();
         if(gle==0)
           {
            Print           ("SELL Bid=",Bid," bartick=",bartick); 
            bartick=0;
            TradeAllowed=false;
           }
            else 
           {
            Print           ("SELL -----ERROR----- Bid=",Bid," MAFast=",MAFast," MASlow=",MASlow," RSI=",RSI," gle=",gle," bartick=",bartick); 
           }
        }
     } //if


   // CLOSE order if profit target made
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber )
        {
         if(OrderType()==OP_BUY)
           {
            CurrentProfit=Bid-OrderOpenPrice();
            
            // did we make our desired BUY profit?
            if(!TrailEnable && CurrentProfit > ProfitMade*p)
              {
               OrderClose(OrderTicket(),Lots,Bid,Slippage,White);
              }

            if (PLEnabled && CurrentProfit >= PLBreakEven*p && OrderOpenPrice()>OrderStopLoss())
              {
               Print ("BUYMODIFY BREAKEVEN  bartick=",bartick); 
               SL=OrderOpenPrice()+(spread*p);
               TP=OrderTakeProfit();
               OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, White);
              }

            if (TrailEnable)
              {
               if(CurrentProfit > TrailingStopLevel1*p) {TS=TrailingStop1;}
               if(CurrentProfit > TrailingStopLevel2*p) {TS=TrailingStop2;}
               if(CurrentProfit > TrailingStopLevel3*p) {TS=TrailingStop3;}

               // check to see if we can move the trailing stop
               if( Bid-OrderStopLoss()>TS*p )
                 {
                  SL=Bid-(TS*p);
                  TP=OrderTakeProfit();
                  //Print ("BUYMODIFY TRAILINGSTOP=",SL,"  bartick=",bartick); 
                  OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, White);
                 }
              }// TrailEnable
              
           } // if BUY


         if(OrderType()==OP_SELL)
           {
            CurrentProfit=OrderOpenPrice()-Ask;
            
            // did we make our desired SELL profit?
            if(!TrailEnable && CurrentProfit > ProfitMade*p)
              {
               OrderClose(OrderTicket(),Lots,Ask,Slippage,Red);
              }

            if (PLEnabled && CurrentProfit >= PLBreakEven*p && OrderOpenPrice()<OrderStopLoss())
                 {
                  //Print ("SELLMODIFY BREAKEVEN  bartick=",bartick); 
                  SL=OrderOpenPrice()-(spread*p);
                  TP=OrderTakeProfit();
                  OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, Red);
                 }

            if (TrailEnable)
              {
               if(CurrentProfit > TrailingStopLevel1*p) {TS=TrailingStop1;}
               if(CurrentProfit > TrailingStopLevel2*p) {TS=TrailingStop2;}
               if(CurrentProfit > TrailingStopLevel3*p) {TS=TrailingStop3;}

               // check to see if we can move the trailing stop
               if(OrderStopLoss()-Ask > TS*p)
                 {
                  SL=Ask+(TS*p);
                  TP=OrderTakeProfit();
                  Print ("SELLMODIFY TRAILINGSTOP=",SL,"  bartick=",bartick); 
                  OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, Red);
                 }

              } // TrailEnable

           } //if SELL

        } // if(OrderSymbol)

     } // for

  } // start()




/*

code for later
  
                 gle=GetLastError();
               if(gle==0)
                 {
                  //Print           ("BUYCLOSE Bid=",Bid," bartick=",bartick); 
                  bartick=0;
                 }
                  else 
                 {
                  Print           ("BUY  CLOSE -----ERROR----- Bid=",Bid," MAFast=",MAFast," MASlow=",MASlow," RSI=",RSI," gle=",gle," bartick=",bartick);
                 }


               if(gle==0)
                 {
                  //Print           ("SELLCLOSE Ask=",Ask," bartick=",bartick);
                  bartick=0;
                 }
                  else 
                 {
                  Print           ("SELL CLOSE -----ERROR----- Ask=",Ask," MAFast=",MAFast," MASlow=",MASlow," RSI=",RSI," gle=",gle," bartick=",bartick);
                 }




*/


