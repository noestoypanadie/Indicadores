//+------+
//|BollTrade
//+------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"


// This EA is NEVER TO BE SOLD!



//3g - added refreshrates in order close sections matching the order open sections
//3g - changed CurrTime in logwrite() to gregorian format
//3g - changed TradeComment and MagicNumber
//3g - changed logging and logerrs default to true 
//3g - added logwrite of blank line when opening orders to create visual seperation in log
//3g - added logwrite of data excursions outside upper and lower bollinger bands
//3g - cleaned up some blank line spacing
//3g - added halfPip variable, but not using it just yet
//3h - changed LossLimit to 39(+1) and BDistance to 14(-1)
//3h - added 500mS delay after order errors
//3h - added Compounding to increase orders as peak rises. (Wow!)
//3h - no longer using TradeAllowed on a per-bar basis
//3h - no longer using OnlyOneOrder
//3h - removed halfpip
//3h - added Comment to tell the EA is alive

//3i1 - added OrdersPerSymbol to break out of close loops 
//     (use Symbol() and MagicNumber so it'll play nice with other EAs)
//3i1 - added CloseEverything and associated BasketProfit/Loss code
//3i1 - added breakeven and trailingstop
//3i1 - added 'if' to logging during BUYme and SELLme calculations
//3i1 - added equity check as well as user input for equity level
//3i1 - changed Deviation to a double in prep for floating point bollinger
//3i1 - added a loop counter while closing trades, out in 25 seconds

//3i2 - changed AccountEquity and it's minimum to AccountFreeMargin and MinFreeMargin

//3i3 - Added Ben's volume for bar0 and bar1
//3i3 - changed magicnumber and tradecomment
//3i3 - changed Bollinger to MA + StdDev (to the penny - same as Bollinger)
//3i3 - restored StartingBalance calculation instead of the fixed 1402$ entry

//3i4 - added LL2SL to remove embedded constant (LossLimit to StopLoss server spread)
//3i4 - fixed trailing stop. It's been broken a loooooong Time
//3i4 - added Trade on Friday to stay out of much news and NFP

//3j  - released 3i4 with one change to closeall

//3j1 - using CloseBuy and CloseSell so that CloseAll had same loops as profit and loss

//3j2 - added IsTesting() and KillLogging to logwrite. Too many full disk drives
//3j2 - added MAXLOT when calaculating lot size
//3j2 - added ExtraComment string for user, appends to TradeComment
//      WARNING! This affects the file name that is generated for logging
//3j2 - added CompoundStep to allow Compounding in >1pip steps 

//3k  - changed MinEquity to a percent of account balance
//      makes it more correct as account grows with compounding

//3k1 - removed VolumeMin

//3k2 - removed min and max orderequity as compounding causes it to report erronously
//3k2 - finally got minEquity working correctly
//3k2 - every new bar resets CompoundTrack to zero
//3k2 - reworked CompoundTrack as an increment to bup/bdn instead of a Bid price 
//      MaxOpenOrders went from 152 to 12 - MUCH better
//3k2 - CloseAll now uses Symbol() and MagicNumber
//3k2 - Added HELP to the EXTERNs - lets see how people like it.

//3m  - release
//3m2 - added open-distance-from-bollinger as a filter for trades


// user input
//                                             "12345678901234567890123456789012345678901";
extern string MinFreeMarginPct_is =            "percent of freemargin necessary to trade ";
extern double MinFreeMarginPct    =      25.0;  
extern string ProfitMade_is       =            "PIPS PROFIT you want to make per trade   ";
extern double ProfitMade          =       8; 
extern string BasketProfit_is     =            "close all orders if this $ profit        ";
extern double BasketProfit        =      14.5; 
extern string LossLimit_is        =            "PIPS LOSS you can afford per trade       ";
extern double LossLimit           =      35;
extern string BasketLoss_is       =            "close all orders if this $ loss          ";
extern double BasketLoss          =       0;
extern string BreakEven_is        =            "set StopLoss to OpenPrice at this profit ";
extern double BreakEven           =       0;
extern string TrailStop_is        =            "Trail OrderPrice starting from 1st tick  ";
extern double TrailStop           =       0;
extern string VolumeMax_is        =            "Volume must be below this before trading ";
extern double VolumeMax           =     280;
extern string Compounding_is      =            "Open more orders based on CompoundStep   ";
extern bool   Compounding         =    true;
extern string CompoundStep_is     =            "how many pips movement before compounding";
extern int    CompoundStep        =       1;
extern string BDistance_is        =            "pips outside bollinger before trading    ";
extern double BDistance           =      14;
extern string BOpenFilter_is      =            "No trades if open is this far from bands ";
extern int    BOpenFilter         =      11;
extern string BPeriod_is          =            "Bollinger period                         ";
extern int    BPeriod             =      15;
extern string Deviation_is        =            "Bollinger deviation                      ";
extern double Deviation           =       2.0;
extern string Lots_is1            =            "How many lots or partial lots per trade  ";
extern string Lots_is2            =            "Lots affects BasketProfit and Loss       ";
extern double Lots                =       0.1;
extern string LotIncrease_is      =            "grow Lots based on account balance       ";
extern bool   LotIncrease         =    true ;
extern string LotResolution_is    =            "for LotIncrease: 0=FullLot 1=0.1  2=0.01 ";
extern int    LotResolution       =       2 ;
extern string TradeOnFriday_is    =            "trade on Friday, or not                  ";
extern bool   TradeOnFriday       =    true ;
extern string ExtraComment_is     =            "appended to TradeComment for each order  ";
extern string ExtraComment        =     ""  ;
extern string KillLogging_is      =            "Turn off ALL logging                     ";
extern bool   KillLogging         =    true ;
extern string logging_is          =            "Logging of data on order Open and Close  ";
extern bool   logging             =    true ;
extern string logerrs_is          =            "Logging of errors when they happen       ";
extern bool   logerrs             =    true ;
extern string logtick_is          =            "Log information on each tick             ";
extern bool   logtick             =   false ; 


// non-external flag settings
int    Slippage=2;                       // how many pips of slippage can you tolorate
double CompoundTrack=0;                  // used to track compounding and steps

// naming and numbering
int    MagicNumber  = 363641;            // allows multiple experts to trade on same account
string TradeComment = "_bolltrade_v03m.txt";
double StartingBalance=0;                // lot size control if LotIncrease == true
int    LL2SL=10;                         // LossLimit to StopLoss server spread
int    maxloop=50;                       // no more than 50 tries/25 seconds to close an order

// Bar handling
datetime bartime=0;                      // used to determine when a bar has moved
int      bartick=0;                      // number of times bars have moved

// Trade control
bool   TradeAllowed=true;                // used to manage trades


// Min/Max tracking and tick logging
int    maxOrders;                        // statistic for maximum numbers or orders open at one time
double maxEquity=0;                      // statistic for maximum equity level
double minEquity=999999;                 // statistic for minimum equity level
double EquityPos=0;                      // statistic for number of ticks order was positive
double EquityNeg=0;                      // statistic for number of ticks order was negative
double EquityZer=0;                      // statistic for number of ticks order was zero

// used for verbose error logging
#include <stdlib.mqh>


// EA Specific
double bup0;
double bup1;
double bdn0;
double bdn1;

//+-------------+
//| Custom init |
//|-------------+
// Called ONCE when EA is added to chart or recompiled

int init()
  {
   TradeComment=TradeComment+" "+ExtraComment;
   if(MinFreeMarginPct==0) MinFreeMarginPct=1;

   if(LotIncrease)
     {
      StartingBalance=13820;
      logwrite(TradeComment,"LotIncrease ACTIVE Account balance="+AccountBalance()+" StartingBalance="+StartingBalance+" Lots="+NormalizeDouble(AccountBalance()/StartingBalance,LotResolution));
      Print("LotIncrease ACTIVE Account balance="+AccountBalance()+" StartingBalance="+StartingBalance+" Lots="+NormalizeDouble(AccountBalance()/StartingBalance,LotResolution));
      //StartingBalance=AccountBalance()/Lots;
      //logwrite(TradeComment,"LotIncrease ACTIVE Account balance="+AccountBalance()+" Lots="+Lots+" StartingBalance="+StartingBalance);
      //Print("LotIncrease ACTIVE Account balance="+AccountBalance()+" Lots="+Lots+" StartingBalance="+StartingBalance);
     }
    else
     {
      logwrite(TradeComment,"LotIncrease NOT ACTIVE Account balance="+AccountBalance()+" Lots="+Lots);
     }

   logwrite(TradeComment,"Init Complete");
   Comment(" ");
  }

//+----------------+
//| Custom DE-init |
//+----------------+
// Called ONCE when EA is removed from chart

int deinit()
  {

   // always indicate deinit statistics
   logwrite(TradeComment,"MAX number of orders "+maxOrders);
   logwrite(TradeComment,"MAX equity           "+maxEquity);
   logwrite(TradeComment,"MIN equity           "+minEquity);

   // so you can see stats in journal
   Print("MAX number of orders "+maxOrders);
   Print("MAX equity           "+maxEquity);
   Print("MIN equity           "+minEquity);


   logwrite(TradeComment,"DE-Init Complete");
   
   Comment(" ");
  }


//+-----------+
//| Main      |
//+-----------+
// Called EACH TICK and each Bar[]

int start()
  {

   int      cnt=0;
   int      gle=0;
   int      ticket=0;
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

   //safety counter
   int   loopcount=0;
      


   // bar counting
   if(bartime!=Time[0]) 
     {
      bartime=Time[0];
      bartick++; 
      CompoundTrack=0;
      bup1=bup0;
      bdn1=bdn0;
     }

   // Lot increasement based on AccountBalance when expert is started
   // this will trade 1.0, then 1.1, then 1.2 etc as account balance grows
   // or 0.9 then 0.8 then 0.7 as account balance shrinks 
   if(LotIncrease)
     {
      Lots=NormalizeDouble(AccountBalance()/StartingBalance,LotResolution);
      if( Lots>MarketInfo(Symbol(), MODE_MAXLOT) ) Lots=MarketInfo(Symbol(), MODE_MAXLOT);
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
   
   if(OrdersPerSymbol==0)
     {
      // This allows the 1st order at BDistance after everything closes
      // others are handled in the indicator section 
      TradeAllowed=true;

      // this makes a good-sized difference in profits
      // Once the orders all clear, reset the compound limiter
      // so that if price goes BACK UP AGAIN within same bar 
      // you can take advantage of more profit.
      // Makes curve noiser tho, so some people may not like it
       CompoundTrack=0;
     }


   // keep some statistics
   if(OrdersPerSymbol>maxOrders) maxOrders=OrdersPerSymbol;

     
   //+-----------------------------+
   //| Insert your indicator here  |
   //| And set either BUYme or     |
   //| SELLme true to place orders |
   //+-----------------------------+

	double ma = iMA(Symbol(),0,BPeriod,0,MODE_SMA,PRICE_OPEN,0);
	double stddev = iStdDev(Symbol(),0,BPeriod,0,MODE_SMA,PRICE_OPEN,0);   
   bup0 = ma+(Deviation*stddev);
   bdn0 = ma-(Deviation*stddev);
   
   // if NOT compounding, CompoundTrack will always be 0
   double bux= (bup0+(BDistance*Point))+(CompoundTrack*Point);
   double bdx= (bdn0-(BDistance*Point))-(CompoundTrack*Point);

   string myCmt;
   if(Close[0]>bup0)                  myCmt="S Up="+bup0+" Dn="+bdn0+" Close="+Close[0]+" Vol_1="+Volume[1]+" Vol_0="+Volume[0];
   if(Close[0]<bdn0)                  myCmt="B Up="+bup0+" Dn="+bdn0+" Close="+Close[0]+" Vol_1="+Volume[1]+" Vol_0="+Volume[0];
   if(Close[0]<bup0 && Close[0]>bdn0) myCmt="X Up="+bup0+" Dn="+bdn0+" Close="+Close[0]+" Vol_1="+Volume[1]+" Vol_0="+Volume[0];
   Comment(myCmt);
      
   // < and NOT <= so tick won't match 0 in a non-tick bar
   bool  volumeOK=false;
   if(Volume[1]<VolumeMax && Volume[0]<VolumeMax) volumeOK=true;
   if (VolumeMax==0) volumeOK=true;
 
   // no trades if Open[0] is more than BOpenFilter pips outside the bollinger
   bool OpenOK=false;
   if( Open[0]<bup0+(BOpenFilter*Point) && Open[0]>bdn0-(BOpenFilter*Point) ) OpenOK=true;
   if(BOpenFilter==0) OpenOK=true;
   
   bool TradeDay=true;
   if(DayOfWeek()==5 && TradeOnFriday==false) TradeDay=false;

   // if close is above upper band + BDistance then SELL
   if(Close[0]>bux && volumeOK && TradeDay) 
     {
      SELLme=true; 
      if(logging) logwrite(TradeComment,"---SELLme happened"); 
      if(Compounding && CompoundTrack>0 )
        {
         SELLme=true; 
         TradeAllowed=true;
         if(logging) logwrite(TradeComment,"---SELLme happened again at "+CompoundTrack ); 
        }
     }

   // if close is below lower band + BDistance then BUY
   if(Close[0]<bdx && volumeOK && TradeDay) 
     {
      BUYme=true;  
      if(logging) logwrite(TradeComment,"----BUYme happened"); 
      if(Compounding && CompoundTrack>0)
        {
         BUYme=true;
         TradeAllowed=true;
         if(logging) logwrite(TradeComment,"----BUYme happened again at "+CompoundTrack ); 
        }
     }

   //+------------+
   //| End Insert |
   //+------------+

   //ENTRY LONG (buy, Ask) 
   if( TradeAllowed && BUYme)
     {
      while(true)
        {
         if( AccountFreeMargin()< (AccountBalance()*(MinFreeMarginPct/100)) )
           {
            if(logging) logwrite(TradeComment,"Your BUY equity is too low to trade");
            break;
           }

         if(LossLimit ==0) SL=0; else SL=Ask-((LossLimit+LL2SL)*Point );
         if(ProfitMade==0) TP=0; else TP=Ask+((ProfitMade+LL2SL)*Point );
         ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,SL,TP,TradeComment,MagicNumber,White);
         gle=GetLastError();
         if(gle==0)
           {
            if (Compounding && CompoundStep>0) CompoundTrack=CompoundTrack+CompoundStep;
            if(logging) logwrite(TradeComment,"                                                                ");
            if(logging) logwrite(TradeComment,"BUY Ticket="+ticket+" bdn0="+bdn0+" Ask="+Ask+" Lots="+Lots+" SL="+SL+" TP="+TP);
            EquityPos=0;
            EquityNeg=0;
            EquityZer=0;
            TradeAllowed=false;
            break;
           }
            else 
           {
            if(logerrs) logwrite(TradeComment,"-----ERROR-----  opening BUY order: SL="+SL+" TP="+TP+" Bid="+Bid+" Ask="+Ask+" ticket="+ticket+" Err="+gle+" "+ErrorDescription(gle)); 
            Print("-----ERROR-----  opening BUY order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle)); 
            RefreshRates();
            Sleep(500);
           }
        }//while   
     }//BUYme
        

   //ENTRY SHORT (sell, Bid)
   if( TradeAllowed && SELLme )
     {
      while(true)
        {
         if( AccountFreeMargin()< (AccountBalance()*(MinFreeMarginPct/100)) )
           {
            if(logging) logwrite(TradeComment,"Your SELL equity is too low to trade");
            break;
           }

         if(LossLimit ==0) SL=0; else SL=Bid+((LossLimit+LL2SL)*Point );
         if(ProfitMade==0) TP=0; else TP=Bid-((ProfitMade+LL2SL)*Point );
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,SL,TP,TradeComment,MagicNumber,Red);
         gle=GetLastError();
         if(gle==0)
           {
            if (Compounding && CompoundStep>0) CompoundTrack=CompoundTrack+CompoundStep;
            if(logging) logwrite(TradeComment,"                                                                 ");
            if(logging) logwrite(TradeComment,"SELL Ticket="+ticket+" bup0="+bup0+" Bid="+Bid+" Lots="+Lots+" SL="+SL+" TP="+TP);
            EquityPos=0;
            EquityNeg=0;
            EquityZer=0;
            TradeAllowed=false;
            break;
           }
            else 
           {
            if(logerrs) logwrite(TradeComment,"-----ERROR-----  opening SELL order: SL="+SL+" TP="+TP+" Bid="+Bid+" Ask="+Ask+" ticket="+ticket+" Err="+gle+" "+ErrorDescription(gle)); 
            Print("-----ERROR-----  opening SELL order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle));
            RefreshRates();
            Sleep(500);
           }
        }//while
     }//SELLme


   //Basket profit or loss
   CurrentBasket=AccountEquity()-AccountBalance();
   if( BasketProfit>0 && CurrentBasket>=BasketProfit )      CloseEverything();
   if( BasketLoss  >0 && CurrentBasket<=(BasketLoss*(-1)) ) CloseEverything();

   // accumulate statistics
   if(CurrentBasket>maxEquity) { maxEquity=CurrentBasket; }
   if(CurrentBasket<minEquity) { minEquity=CurrentBasket; }
   if(CurrentBasket>0)  EquityPos++;
   if(CurrentBasket<0)  EquityNeg++;
   if(CurrentBasket==0) EquityZer++;
   

   //
   // Order Management
   //
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber )
        {
        
         if(OrderType()==OP_BUY)
           {
            CurrentProfit=(Bid-OrderOpenPrice()) ;
            if(logtick) logwrite(TradeComment,"BUY  CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);

            //
            // Modify for break even
            //=======================
            //
            // OrderStopLoss will be equal to OrderOpenPrice if this event happens
            // thus it will only ever get executed one time per ticket
            if( BreakEven>0 )
              {
               if (CurrentProfit >= BreakEven*Point && OrderOpenPrice()>OrderStopLoss())
                 {
                  SL=OrderOpenPrice()+(Ask-Bid);
                  TP=OrderTakeProfit();
                  OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, White);
                  gle=GetLastError();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"MODIFY BUY BE Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                    }
                     else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- MODIFY BUY  BE Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                    }
                 }
              }


            //
            // check for trailing stop
            //=========================
            //
            if( TrailStop>0 )  
              {                 
               if( Bid-OrderStopLoss()>(TrailStop*Point) )
                 {
                  SL=Bid-(TrailStop*Point);
                  TP=OrderTakeProfit();
                  OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP,0,White);
                  gle=GetLastError();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"MODIFY BUY TS Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                    }
                     else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- MODIFY BUY TS Bid="+Bid+" error="+gle+" "+ErrorDescription(gle)+" ");
                    }
                 }
              }


            // Did we make a profit
            //======================
            if(ProfitMade>0 && CurrentProfit>=(ProfitMade*Point))     CloseBuy("PROFIT");
              

            // Did we take a loss
            //====================
            if(LossLimit>0 && CurrentProfit<=(LossLimit*(-1)*Point))  CloseBuy("PROFIT");
              
           } // if BUY


         if(OrderType()==OP_SELL)
           {
            CurrentProfit=(OrderOpenPrice()-Ask);
            if(logtick) logwrite(TradeComment,"SELL CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);

           
            //
            // Modify for break even
            //=======================
            //
            // OrderStopLoss will be equal to OrderOpenPrice if this event happens
            // thus it will only ever get executed one time per ticket
            if( BreakEven>0 )
              {
               if (CurrentProfit >= BreakEven*Point && OrderOpenPrice()<OrderStopLoss())
                 {
                  SL=OrderOpenPrice()-(Ask-Bid);
                  TP=OrderTakeProfit();
                  OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP, Red);
                  gle=GetLastError();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"MODIFY SELL BE Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                    }
                     else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- MODIFY SELL BE Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                    }
                 }
              }


            //
            // check for trailing stop
            //=========================
            //
            if(TrailStop>0)  
              {                 
               if( (OrderStopLoss()-Ask)>(TrailStop*Point) )
                 {
                  SL=Ask+(TrailStop*Point);
                  TP=OrderTakeProfit();
                  OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP,0,Red);
                  gle=GetLastError();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"MODIFY SELL TS Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                    }
                     else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- MODIFY SELL TS Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                    }

                 }

              }


            // Did we make a profit
            //======================
            if( ProfitMade>0 && CurrentProfit>=(ProfitMade*Point) ) CloseSell("PROFIT");

            // Did we take a loss
            //====================
            if( LossLimit>0 && CurrentProfit<=(LossLimit*(-1)*Point) ) CloseSell("LOSS");

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
   int i;
    
   for(i=OrdersTotal();i>=0;i--)
     {

      OrderSelect(i, SELECT_BY_POS);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
        {
         if(OrderType()==OP_BUY)       CloseBuy ("BASKET");
         if(OrderType()==OP_SELL)      CloseSell("BASKET");
         if(OrderType()==OP_BUYLIMIT)  OrderDelete( OrderTicket() );
         if(OrderType()==OP_SELLLIMIT) OrderDelete( OrderTicket() );
         if(OrderType()==OP_BUYSTOP)   OrderDelete( OrderTicket() );
         if(OrderType()==OP_SELLSTOP)  OrderDelete( OrderTicket() );
        }

      Sleep(1000);

     } //for
  
  } // closeeverything



void logwrite (string filename, string mydata)
  {
   int myhandle;
   string gregorian=TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS);

   // don't log anything if testing or if user doesn't want it
   if(IsTesting()) return(0);
   if(KillLogging) return(0);
   
   myhandle=FileOpen(Symbol()+"_"+filename, FILE_CSV|FILE_WRITE|FILE_READ, ";");
   if(myhandle>0)
     {
      FileSeek(myhandle,0,SEEK_END);
      FileWrite(myhandle, mydata+" "+gregorian);
      FileClose(myhandle);
     }
  } 


void CloseBuy (string myInfo)
  {
   int gle;
   int cnt;
   int OrdersPerSymbol;
   
   int loopcount=0;
   
   while(true)
     {
      OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,White);
      gle=GetLastError();
      if(gle==0)
        {
         if(logging)
           {
            logwrite(TradeComment,"CLOSE BUY "+myInfo+" Ticket="+OrderTicket()+" SL="+OrderStopLoss()+" TP="+OrderTakeProfit()+" PM="+ProfitMade+" LL="+LossLimit);
            logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
            logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
            logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
           }
         break;
        }
       else 
        {
         if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE BUY PROFIT Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
         RefreshRates();
         Sleep(500);
        }

      OrdersPerSymbol=0;
      for(cnt=OrdersTotal();cnt>=0;cnt--)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)  break; 
        }
                    
      loopcount++;
      if(loopcount>maxloop) break;
                     
     }//while
  
  }



void CloseSell (string myInfo)
  {
   int gle;
   int cnt;
   int OrdersPerSymbol;
   
   int loopcount=0;
   
   while(true)
     {
      OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Red);
      gle=GetLastError();
      if(gle==0)
        {
         if(logging)
           {
            logwrite(TradeComment,"CLOSE SELL "+myInfo+" Ticket="+OrderTicket()+" SL="+OrderStopLoss()+" TP="+OrderTakeProfit()+" PM="+ProfitMade+" LL="+LossLimit);
            logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
            logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
            logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
           }
         break;
        }
      else 
        {
         if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE SELL PROFIT Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
         RefreshRates();
         Sleep(500);
        }

      OrdersPerSymbol=0;
      for(cnt=OrdersTotal();cnt>=0;cnt--)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)  break; 
        }
                    
      loopcount++;
      if(loopcount>maxloop) break;
                 
     }//while                 
  }    