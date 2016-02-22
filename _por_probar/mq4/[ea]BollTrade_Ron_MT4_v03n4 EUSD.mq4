//+------+
//|BollTrade
//+------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"
// This EA is NEVER TO BE SOLD individually 
// This EA is NEVER TO BE INCLUDED as part of a collection that is SOLD


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

//3m3 - added avoidance times 
//3m3 - removed TradeOnFriday, as it is redundant with avoidance times 
//3m2 - Proved TimeSinceOpen has no benificial effect, distribution after open too even
//3m2 - removed Equity pos neg and zero as statistics were bad for compounding
//3m2 - removed OrdersBuy and OrdersSell as they are unused

//3n3 - removed lotincrease, lots, lotresolution from externs
//3n3 - lotincrease is ALWAYS active now
//3n3 - lotresolution requires a recompile to change now
//3n3 - added StartingBalance as extern, hope users can figure it out)
//3n3 - compounding is gone. it was an insane idea 
//3n3 - replaced compounding with 1 order per bar. Max is 4 in past year.
//3n4 - removed BasketLoss to make BasketTrail easier



// user input
//                                             "12345678901234567890123456789012345678901";
//extern string MinFreeMarginPct_is =            "percent of freemargin necessary to trade ";
extern double MinFreeMarginPct    =      25.0;  
//extern string StartingBalance_is  =            "Account Start Balance (x10 for .1 lots)  ";
extern int    StartingBalance     =   12290;
//extern string ProfitMade_is       =            "PIPS PROFIT you want to make per trade   ";
extern double ProfitMade          =       8; 
//extern string TrailStop_is        =            "AFTER ProfitMade, trail by this many pips"
extern double TrailStop           =       0;
//extern string BasketProfit_is     =            "close all orders if this $ profit        ";
extern double BasketProfit        =       0;
//extern string BasketTrail_is      =            "Follow basket in case of more profit     ";
//extern double BasketTrail         =       0;
//extern string LossLimit_is        =            "PIPS LOSS you can afford per trade       ";
extern double LossLimit           =      35;
//extern string VolumeMax_is        =            "Vol[0]&[1] below this before trading     ";
extern double VolumeMax           =     250;
//extern string BDistance_is        =            "pips outside bollinger before trading    ";
extern double BDistance           =      14;
//extern string BPeriod_is          =            "Bollinger period                         ";
extern int    BPeriod             =      15;
//extern string Deviation_is        =            "Bollinger deviation                      ";
extern double Deviation           =       2.0;
//extern string ExtraComment_is     =            "appended to TradeComment for each order  ";
extern string ExtraComment        =     ""  ;
//extern string KillLogging_is      =            "Turn off ALL logging                     ";
extern bool   KillLogging         =    true ;
//extern string logging_is          =            "Logging of data on order Open and Close  ";
extern bool   logging             =    true ;
//extern string logerrs_is          =            "Logging of errors when they happen       ";
extern bool   logerrs             =    true ;
//extern string logtick_is          =            "Log information on each tick             ";
extern bool   logtick             =   false ; 


// non-external flag settings
int    Slippage=2;                       // how many pips of slippage can you tolorate

// naming and numbering
int    MagicNumber  = 363642;            // allows multiple experts to trade on same account
string TradeComment = "_bolltrade_v03n.txt";
int    LL2SL=10;                         // LossLimit to StopLoss server spread
int    maxloop=50;                       // no more than 50 tries/25 seconds to close an order

// Bar handling
datetime bartime=0;                      // used to determine when a bar has moved
int      bartick=0;                      // number of times bars have moved
double   Lots;                           // used during StartingBalance calculation
double   lotsi;                          // used in doubling calculations
int      LotResolution=2;                // IBFX mini account can tolorate 2 decimal places

// Trade control
bool   TradeAllowed=true;                // used to manage trades
double privateLossLimit=0;               // used with TrailStop

// Min/Max tracking and tick logging
int    maxOrders;                        // statistic for maximum numbers or orders open at one time
double maxEquity=0;                      // statistic for maximum equity level
double minEquity=999999;                 // statistic for minimum equity level

// used for verbose error logging
#include <stdlib.mqh>

// Start-Stop Time array
string SST[200];

// EA Specific
double bup;
double bdn;

//+-------------+
//| Custom init |
//|-------------+
// Called ONCE when EA is added to chart or recompiled

int init()
  {
   // Even numbered elements are STOP times 
   // Odd numbered elements are START times 
   //
   // THESE ARE IN SERVER-SIDE TIME!!!!!! 
   // (usually GMT, your broker may vary)
   //
   SST[0]  ="2006.11.07 13:15:00";  SST[1]  ="2006.11.07 15:15:00";


   TradeComment=TradeComment+" "+ExtraComment;
   if(MinFreeMarginPct==0) MinFreeMarginPct=1;

   logwrite(TradeComment,"LotIncrease ACTIVE Balance="+AccountBalance()+" StartingBalance="+StartingBalance+" Lots="+NormalizeDouble(AccountBalance()/StartingBalance,LotResolution));
   Print("LotIncrease ACTIVE Account balance="+AccountBalance()+" StartingBalance="+StartingBalance+" Lots="+NormalizeDouble(AccountBalance()/StartingBalance,LotResolution));

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
      TradeAllowed=true;
     }

   // Lot increasement based on AccountBalance when expert is (re)started
   // this will trade 1.0, then 1.1, then 1.2 etc as account balance grows
   // or 0.9 then 0.8 then 0.7 as account balance shrinks 
   Lots=NormalizeDouble(AccountBalance()/StartingBalance,LotResolution);
   if( Lots>MarketInfo(Symbol(), MODE_MAXLOT) ) Lots=MarketInfo(Symbol(), MODE_MAXLOT);
   


   OrdersPerSymbol=0;
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
        {
         OrdersPerSymbol++;
        }
     }
   
   if(OrdersPerSymbol==0)
     {
      TradeAllowed=true;
      lotsi=Lots;                  //reset lots when everything in the frame is done
      privateLossLimit=LossLimit;  //reset PrivateLimit too
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
   bup = ma+(Deviation*stddev);
   bdn = ma-(Deviation*stddev);
   
   double bux=(bup+(BDistance*Point));
   double bdx=(bdn-(BDistance*Point));

   string myCmt;
   int v1=Volume[1];
   int v0=Volume[0];
   myCmt="Up="+bup+" Dn="+bdn+" Close="+Close[0]+" Vol_1="+v1+" Vol_0="+v0;
   if(Close[0]>bup)                 myCmt="S "+myCmt;
   if(Close[0]<bdn)                 myCmt="B "+myCmt;
   if(Close[0]<bup && Close[0]>bdn) myCmt="X "+myCmt;
   Comment(myCmt);
      
   // < and NOT <= so tick won't match 0 in a non-tick bar
   bool  volumeOK=false;
   if(Volume[0]<VolumeMax && Volume[1]<VolumeMax) volumeOK=true;
   if (VolumeMax==0) volumeOK=true;

   bool     TradesOff=false;
   datetime gstart;
   datetime gstop;
   //for(cnt=0; cnt<ArraySize(SST); cnt=cnt+2)
   for(cnt=0; cnt<12; cnt=cnt+2)
     {
      gstart=StrToTime(SST[cnt]);
      gstop=StrToTime(SST[cnt+1]);
      if(Time[0]>=gstart && Time[0]<=gstop)
        {
         Print( Time[0],CurTime() );
         TradesOff=true;
        }
      }

   // if close is above upper band + BDistance then SELL
   if(Close[0]>bux && volumeOK && !TradesOff) 
     {
      SELLme=true; 
      if(logging) logwrite(TradeComment,"---SELLme happened"); 
     }

   // if close is below lower band + BDistance then BUY
   if(Close[0]<bdx && volumeOK && !TradesOff) 
     {
      BUYme=true;  
      if(logging) logwrite(TradeComment,"----BUYme happened"); 
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
         ticket=OrderSend(Symbol(),OP_BUY,lotsi,Ask,Slippage,SL,TP,TradeComment,MagicNumber,White);
         gle=GetLastError();
         if(gle==0)
           {
            if(logging) logwrite(TradeComment,"                                                                ");
            if(logging) logwrite(TradeComment,"BUY Ticket="+ticket+" bdn="+bdn+" Ask="+Ask+" Lots="+Lots+" SL="+SL+" TP="+TP);
            TradeAllowed=false;
            lotsi=lotsi*2;
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
         ticket=OrderSend(Symbol(),OP_SELL,lotsi,Bid,Slippage,SL,TP,TradeComment,MagicNumber,Red);
         gle=GetLastError();
         if(gle==0)
           {
            if(logging) logwrite(TradeComment,"                                                                 ");
            if(logging) logwrite(TradeComment,"SELL Ticket="+ticket+" bup="+bup+" Bid="+Bid+" Lots="+Lots+" SL="+SL+" TP="+TP);
            TradeAllowed=false;
            lotsi=lotsi*2;
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

   // accumulate statistics
   if(CurrentBasket>maxEquity) { maxEquity=CurrentBasket; }
   if(CurrentBasket<minEquity) { minEquity=CurrentBasket; }
   

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
            if(LossLimit>0 && CurrentProfit<=(privateLossLimit*(-1)*Point))  CloseBuy("LOSS");
              
           } // if BUY


         if(OrderType()==OP_SELL)
           {
            CurrentProfit=(OrderOpenPrice()-Ask);
            if(logtick) logwrite(TradeComment,"SELL CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);

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
            if( LossLimit>0 && CurrentProfit<=(privateLossLimit*(-1)*Point) ) CloseSell("LOSS");

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
  


  
  
    