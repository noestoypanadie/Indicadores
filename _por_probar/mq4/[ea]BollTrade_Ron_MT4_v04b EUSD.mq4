//+------+
//|BollTrade
//+------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"
// This EA is NEVER TO BE SOLD individually 
// This EA is NEVER TO BE INCLUDED as part of a collection that is SOLD

//4a  - removed lots from externs
//4a  - added StartingBalance as extern
//4a  - compounding is gone. it was an insane idea 
//4a  - replaced compounding with 1 order per bar. Max is 5 in past year.
//4a  - added option (TradeEveryBar) to turn on or off the multi-trade feature
//4a  - added option (FoldFrames) to double lots on each successive multiple order 
//4a  - added frame limit to 6 bars past last successful market order
//4a  - removed BasketLoss
//4a  - removed trailing stop
//4a  - fixed invalid volume problem, couple of places escaped MAXLOTS check
//4a  - fixed the Open loops so they time out after 25 seconds. Missed it before.

//4b - I know long and short can be controlled in MT4, but for completeness, added it here
//4b - removed min and max equity, it is wrong on folding and compounding
//4b - fixed the closetrade exits on zero open orders. Been broken since 3k1
//4b - added TradeStyles so you can trade against trend(default) or with trend based on time 
//4b - reordered externs


// user input
//                                             "12345678901234567890123456789012345678901";
extern string ProfitMade1_is      =            "PIPS PROFIT per trade Style 1            ";
extern double ProfitMade1         =       8; 
extern string ProfitMade2_is      =            "PIPS PROFIT per trade Style 2            ";
extern double ProfitMade2         =      17; 
extern string LossLimit1_is       =            "PIPS LOSS per trade Style 1              ";
extern double LossLimit1          =      35;
extern string LossLimit2_is       =            "PIPS LOSS per trade Style 2              ";
extern double LossLimit2          =      23;
extern string BDistance1_is       =            "Pips outside bollinger before trading    ";
extern double BDistance1          =      14;
extern string BDistance2_is       =            "Pips outside bollinger before trading    ";
extern double BDistance2          =      14;
extern string BPeriod1_is         =            "Bollinger period                         ";
extern int    BPeriod1            =      15;
extern string BPeriod2_is         =            "Bollinger period                         ";
extern int    BPeriod2            =      15;
extern string Deviation1_is       =            "Bollinger deviation                      ";
extern double Deviation1          =       2.0;
extern string Deviation2_is       =            "Bollinger deviation                      ";
extern double Deviation2          =       2.0;

extern string TradeLong_is        =            "Make Long(BUY) Trades if true            ";
extern bool   TradeLong           =    true;
extern string TradeShort_is       =            "Make Short(SELL) Trades if true          ";
extern bool   TradeShort          =    true;
extern string TradeEveryBar_is    =            "One trade for EVERY bar that qualifies   ";
extern bool   TradeEveryBar       =    true;

extern string MinFreeMarginPct_is =            "percent of freemargin necessary to trade ";
extern double MinFreeMarginPct    =      25.0;  
extern string StartingBalance_is0 =            "Acct Start Balance (x  1 for 1 lot)      ";
extern string StartingBalance_is1 =            "                   (x 10 for .1 lots)    ";
extern string StartingBalance_is2 =            "                   (x100 for .01 lots)   ";
extern int    StartingBalance     =    1000;
extern string LotResolution_is    =            "LotIncrease grows by this many decimals  ";
extern int    LotResolution       =       2;
extern string BasketProfit_is     =            "close all orders if this $ profit        ";
extern double BasketProfit        =       0;
extern string VolumeMax_is        =            "Vol[0]&[1] below this before trading     ";
extern double VolumeMax           =     250;
extern string FoldFrames_is       =            "For each new multiple order, double lots ";
extern bool   FoldFrames          =   false;

extern string ExtraComment_is     =            "appended to TradeComment for each order  ";
extern string ExtraComment        =     ""  ;
extern string KillLogging_is      =            "Turn off ALL logging                     ";
extern bool   KillLogging         =    false;
extern string logging_is          =            "Logging of data on order Open and Close  ";
extern bool   logging             =    false;
extern string logerrs_is          =            "Logging of errors when they happen       ";
extern bool   logerrs             =    false;
extern string logtick_is          =            "Log information on each tick             ";
extern bool   logtick             =    false; 


// non-external flag settings
int    Slippage=2;                       // how many pips of slippage can you tolorate

// naming and numbering
int    MagicNumber1 = 1363642;           // allows multiple experts to trade on same account
int    MagicNumber2 = 2363642;           // allows multiple experts to trade on same account
string TradeComment = "_bolltrade_v04b.txt";
int    LL2SL=10;                         // LossLimit to StopLoss server spread
int    maxloop=50;                       // no more than 50 tries/25 seconds to open/close an order

// Bar handling
datetime bartime=0;                      // used to determine when a bar has moved
int      bartick=0;                      // number of times bars have moved

// Lot calculations
double   Lots;                           // used during StartingBalance calculation
double   lotsi;                          // used in doubling calculations
int      myMODE_MAXLOTS=50;              // limit number of lots pre trade 

// Trade control
bool   TradeAllowed=true;                // used to manage trades
int    TradingStyle;                     // 1 = counter(default) trades 2 = contra trades
                                             
int    maxOrders;                        // statistic for maximum numbers or orders open at one time

// used for verbose error logging
#include <stdlib.mqh>

// Start-Stop Time arrays
string SST[200];
string TSC[200];


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
 

   // Use these to stop trading alltogether
   // between the times you choose
   int sstCnt=0;
   SST[sstCnt]  ="2006.11.07 13:15:00"; sstCnt++;
   SST[sstCnt]  ="2006.11.07 15:15:00"; sstCnt++;
 
 
   // Use these to change the style when you think
   // it would be better to trade WITH the trend
   int tscCnt=0;   
   TSC[tscCnt]  ="2006.09.08 11:15:00"; tscCnt++;
   TSC[tscCnt]  ="2006.09.08 13:14:00"; tscCnt++;

   TSC[tscCnt]  ="2006.09.21 14:45:00"; tscCnt++;
   TSC[tscCnt]  ="2006.09.21 17:29:00"; tscCnt++;

   TSC[tscCnt]  ="2006.10.06 10:45:00"; tscCnt++;
   TSC[tscCnt]  ="2006.10.06 12:44:00"; tscCnt++;

   TSC[tscCnt]  ="2006.10.31 14:00:00"; tscCnt++;
   TSC[tscCnt]  ="2006.10.31 15:59:00"; tscCnt++;

   TSC[tscCnt]  ="2006.11.03 12:30:00"; tscCnt++;
   TSC[tscCnt]  ="2006.11.03 14:59:00"; tscCnt++;

   TSC[tscCnt]  ="2006.11.24 07:00:00"; tscCnt++;
   TSC[tscCnt]  ="2006.11.24 10:00:00"; tscCnt++;


   TradeComment=TradeComment+" "+ExtraComment;

   if(MinFreeMarginPct<  1) MinFreeMarginPct=1;
   if(MinFreeMarginPct>100) MinFreeMarginPct=100;

   logwrite(TradeComment,"LotIncrease ACTIVE Balance="+AccountBalance()+" StartingBalance="+StartingBalance+" Lots="+NormalizeDouble(AccountBalance()/StartingBalance,LotResolution));
   Print(                "LotIncrease ACTIVE Balance="+AccountBalance()+" StartingBalance="+StartingBalance+" Lots="+NormalizeDouble(AccountBalance()/StartingBalance,LotResolution));

   logwrite(TradeComment,"Init Complete");
   Print(                "Init Complete");

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
   Print(                "MAX number of orders "+maxOrders);

   logwrite(TradeComment,"DE-Init Complete");
   Print(                "DE-Init Complete");

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
      // Don't alow frames to extend very far past
      // their actual occurance
      if(bartick>6) lotsi=Lots;
      if(TradeEveryBar) TradeAllowed=true;
      if(logging) logwrite(TradeComment,"New bar at");
     }

   // Lot increasement based on AccountBalance
   Lots=NormalizeDouble(AccountBalance()/StartingBalance,LotResolution);
   if( Lots>myMODE_MAXLOTS) Lots=myMODE_MAXLOTS;
   
   OrdersPerSymbol=0;
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber1)
        {
         OrdersPerSymbol++;
        }
     }
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber2)
        {
         OrdersPerSymbol++;
        }
     }
   
   if(OrdersPerSymbol==0)
     {
      TradeAllowed=true;
      bartick=0;                   // no open orders means frame must be complete
      lotsi=Lots;                  // reset lots when everything in the frame is done
     }


   // keep some statistics
   if(OrdersPerSymbol>maxOrders) maxOrders=OrdersPerSymbol;

     
   //+-----------------------------+
   //| Insert your indicator here  |
   //| And set either BUYme or     |
   //| SELLme true to place orders |
   //+-----------------------------+

   // Bollinger and bands
	double ma;
	double stddev;
	double bup, bux;
	double bdn, bdx;

   // volume limiter
   int v1=Volume[1];
   int v0=Volume[0];
      
   // trades-off and style change
   datetime gstart;
   datetime gstop;

   // is it time to change trading styles
   // if not set style to 1 (default)
   TradingStyle=1;
   for(cnt=0; cnt<ArraySize(TSC); cnt=cnt+2)
     {
      gstart=StrToTime(TSC[cnt]);
      gstop=StrToTime(TSC[cnt+1]);
      if(Time[0]>=gstart && Time[0]<=gstop)
        {
         TradingStyle=2;
         if(logging) logwrite(TradeComment,"TradingStyle set to 2");
        }
      }


	if(TradingStyle==1)
	  {
	   ma = iMA(Symbol(),0,BPeriod1,0,MODE_SMA,PRICE_OPEN,0);
	   stddev = iStdDev(Symbol(),0,BPeriod1,0,MODE_SMA,PRICE_OPEN,0);   
      bup = ma+(Deviation1*stddev);
      bdn = ma-(Deviation1*stddev);
      
      bux=(bup+(BDistance1*Point));
      bdx=(bdn-(BDistance1*Point));
     }
     
	if(TradingStyle==2)
	  {
	   ma = iMA(Symbol(),0,BPeriod2,0,MODE_SMA,PRICE_OPEN,0);
	   stddev = iStdDev(Symbol(),0,BPeriod2,0,MODE_SMA,PRICE_OPEN,0);   
      bup = ma+(Deviation2*stddev);
      bdn = ma-(Deviation2*stddev);
      
      bux=(bup+(BDistance2*Point));
      bdx=(bdn-(BDistance2*Point));
     }

   string myCmt="Up="+bup+" Dn="+bdn+" Close="+Close[0]+" Vol_1="+v1+" Vol_0="+v0;
   if(Close[0]>bup)                 myCmt="S "+myCmt;
   if(Close[0]<bdn)                 myCmt="B "+myCmt;
   if(Close[0]<bup && Close[0]>bdn) myCmt="X "+myCmt;
   Comment(myCmt);
   
   // < and NOT <= so tick won't match 0 in a non-tick bar
   bool  volumeOK=false;
   if(Volume[0]<VolumeMax && Volume[1]<VolumeMax) volumeOK=true;
   if (VolumeMax==0) volumeOK=true;

   bool     TradesOff=false;
   for(cnt=0; cnt<ArraySize(SST); cnt=cnt+2)
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
      if(TradingStyle==1)
        {
         SELLme=true; 
         if(logging) logwrite(TradeComment,"---SELLme happened Style 1"); 
        }
      if(TradingStyle==2)
        {
         BUYme=true; 
         if(logging) logwrite(TradeComment,"---BUYme happened Style 2"); 
        }
     }

   // if close is below lower band + BDistance then BUY
   if(Close[0]<bdx && volumeOK && !TradesOff) 
     {
      if(TradingStyle==1)
        {
         BUYme=true;  
         if(logging) logwrite(TradeComment,"----BUYme happened Style 1"); 
        }
        
      if(TradingStyle==2)
        {
         SELLme=true;  
         if(logging) logwrite(TradeComment,"----SELLme happened Style 2"); 
        }
        
     }

   //+------------+
   //| End Insert |
   //+------------+

   //ENTRY LONG (buy, Ask) 
   if( TradeAllowed && TradeLong && BUYme)
     {
      loopcount=0;
      while(true)
        {
         if( AccountFreeMargin()< (AccountBalance()*(MinFreeMarginPct/100)) )
           {
            if(logging) logwrite(TradeComment,"Your BUY equity is too low to trade");
            break;
           }

         if(TradingStyle==1)
           {
            if(LossLimit1 ==0) SL=0; else SL=Ask-((LossLimit1+LL2SL)*Point );
            if(ProfitMade1==0) TP=0; else TP=Ask+((ProfitMade1+LL2SL)*Point );
            ticket=OrderSend(Symbol(),OP_BUY,lotsi,Ask,Slippage,SL,TP,TradeComment,MagicNumber1,White);
           }

         if(TradingStyle==2)
           {
            if(LossLimit2 ==0) SL=0; else SL=Ask-((LossLimit2+LL2SL)*Point );
            if(ProfitMade2==0) TP=0; else TP=Ask+((ProfitMade2+LL2SL)*Point );
            ticket=OrderSend(Symbol(),OP_BUY,lotsi,Ask,Slippage,SL,TP,TradeComment,MagicNumber2,White);
           }

         gle=GetLastError();
         if(gle==0)
           {
            if(logging) logwrite(TradeComment,"                                                                ");
            if(logging) logwrite(TradeComment,"BUY Ticket="+ticket+" bdn="+bdn+" Ask="+Ask+" Lots="+Lots+" SL="+SL+" TP="+TP);
            TradeAllowed=false;
            bartick=0;
            if(TradeEveryBar && FoldFrames) lotsi=lotsi*2;
            if(lotsi>myMODE_MAXLOTS) lotsi=myMODE_MAXLOTS;
            break;
           }
            else 
           {
            if(logerrs) logwrite(TradeComment,"-----ERROR-----  opening BUY order: Lots="+lotsi+" SL="+SL+" TP="+TP+" Bid="+Bid+" Ask="+Ask+" ticket="+ticket+" Err="+gle+" "+ErrorDescription(gle)); 
            Print("-----ERROR-----  opening BUY order: Lots="+lotsi+" SL="+SL+" TP="+TP+" Bid="+Bid+" Ask="+Ask+" ticket="+ticket+" Err="+gle+" "+ErrorDescription(gle)); 
            
            RefreshRates();
            Sleep(500);

            loopcount++;
            if(loopcount>maxloop) break;

           }
        }//while   
     }//BUYme
        

   //ENTRY SHORT (sell, Bid)
   if( TradeAllowed && TradeShort && SELLme )
     {
      loopcount=0;
      while(true)
        {
         if( AccountFreeMargin()< (AccountBalance()*(MinFreeMarginPct/100)) )
           {
            if(logging) logwrite(TradeComment,"Your SELL equity is too low to trade");
            break;
           }

         if(TradingStyle==1)
           {
            if(LossLimit1 ==0) SL=0; else SL=Bid+((LossLimit1+LL2SL)*Point );
            if(ProfitMade1==0) TP=0; else TP=Bid-((ProfitMade1+LL2SL)*Point );
            ticket=OrderSend(Symbol(),OP_SELL,lotsi,Bid,Slippage,SL,TP,TradeComment,MagicNumber1,Red);
           }

         if(TradingStyle==2)
           {
            if(LossLimit2 ==0) SL=0; else SL=Bid+((LossLimit2+LL2SL)*Point );
            if(ProfitMade2==0) TP=0; else TP=Bid-((ProfitMade2+LL2SL)*Point );
            ticket=OrderSend(Symbol(),OP_SELL,lotsi,Bid,Slippage,SL,TP,TradeComment,MagicNumber2,Red);
           }

         gle=GetLastError();
         if(gle==0)
           {
            if(logging) logwrite(TradeComment,"                                                                 ");
            if(logging) logwrite(TradeComment,"SELL Ticket="+ticket+" bup="+bup+" Bid="+Bid+" Lots="+Lots+" SL="+SL+" TP="+TP);
            TradeAllowed=false;
            bartick=0;
            if(TradeEveryBar && FoldFrames) lotsi=lotsi*2;
            if(lotsi>myMODE_MAXLOTS) lotsi=myMODE_MAXLOTS;
            break;
           }
            else 
           {
            if(logerrs) logwrite(TradeComment,"-----ERROR-----  opening SELL order: Lots="+lotsi+" SL="+SL+" TP="+TP+" Bid="+Bid+" Ask="+Ask+" ticket="+ticket+" Err="+gle+" "+ErrorDescription(gle)); 
            Print("-----ERROR-----  opening SELL order: Lots="+lotsi+" SL="+SL+" TP="+TP+" Bid="+Bid+" Ask="+Ask+" ticket="+ticket+" Err="+gle+" "+ErrorDescription(gle)); 

            RefreshRates();
            Sleep(500);

            loopcount++;
            if(loopcount>maxloop) break;

           }
        }//while
     }//SELLme


   //Basket profit or loss
   CurrentBasket=AccountEquity()-AccountBalance();
   if( BasketProfit>0 && CurrentBasket>=BasketProfit )      CloseEverything();

   //
   // Order Management
   //
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() )
        {
        
         if(OrderType()==OP_BUY)
           {
            CurrentProfit=(Bid-OrderOpenPrice()) ;
            if(logtick) logwrite(TradeComment,"BUY  CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);

            // Did we make a profit
            //======================
            if(TradingStyle==1 && OrderMagicNumber()==MagicNumber1 && ProfitMade1>0 && CurrentProfit>=(ProfitMade1*Point))     CloseBuy("PROFIT");
            if(TradingStyle==2 && OrderMagicNumber()==MagicNumber2 && ProfitMade2>0 && CurrentProfit>=(ProfitMade2*Point))     CloseBuy("PROFIT");
              

            // Did we take a loss
            //====================
            if(TradingStyle==1 && OrderMagicNumber()==MagicNumber1 && LossLimit1>0 && CurrentProfit<=(LossLimit1*(-1)*Point))  CloseBuy("LOSS");
            if(TradingStyle==2 && OrderMagicNumber()==MagicNumber2 && LossLimit2>0 && CurrentProfit<=(LossLimit2*(-1)*Point))  CloseBuy("LOSS");
              
           } // if BUY


         if(OrderType()==OP_SELL)
           {
            CurrentProfit=(OrderOpenPrice()-Ask);
            if(logtick) logwrite(TradeComment,"SELL CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);
           
            // Did we make a profit
            //======================
            if(TradingStyle==1 && ProfitMade1>0 && CurrentProfit>=(ProfitMade1*Point) ) CloseSell("PROFIT");
            if(TradingStyle==2 && ProfitMade2>0 && CurrentProfit>=(ProfitMade2*Point) ) CloseSell("PROFIT");

            // Did we take a loss
            //====================
            if(TradingStyle==1 && LossLimit1>0 && CurrentProfit<=(LossLimit1*(-1)*Point) ) CloseSell("LOSS");
            if(TradingStyle==2 && LossLimit2>0 && CurrentProfit<=(LossLimit2*(-1)*Point) ) CloseSell("LOSS");

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
      if( OrderSymbol()==Symbol() && (OrderMagicNumber()==MagicNumber1 || OrderMagicNumber()==MagicNumber2) )
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

   Print(mydata);
   
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
   
   string bTK=" Ticket="+OrderTicket();
   string bSL=" SL="+OrderStopLoss();
   string bTP=" TP="+OrderTakeProfit();
   string bPM;
   string bLL;
   string bER;

   if(TradingStyle==1)
     {
      bPM=" PM="+ProfitMade1;
      bLL=" LL="+LossLimit1;
     }
   if(TradingStyle==2)
     {
      bPM=" PM="+ProfitMade2;
      bLL=" LL="+LossLimit2;
     }

   while(true)
     {
      OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,White);
      gle=GetLastError();
      bER=" error="+gle+" "+ErrorDescription(gle);

      if(gle==0)
        {
         if(logging) logwrite(TradeComment,"CLOSE BUY "+myInfo+ bTK + bSL + bTP + bPM + bLL);
         break;
        }
       else 
        {
         if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE BUY "+myInfo+ bER +" Bid="+Bid+ bTK + bSL + bTP + bPM + bLL);
         RefreshRates();
         Sleep(500);
        }


      // sometimes an order close is delayed, or a gap jumps to the LL2SL on the server
      // This keeps a server-closed order from hanging here
      OrdersPerSymbol=0;
      for(cnt=OrdersTotal();cnt>=0;cnt--)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber1) OrdersPerSymbol++;
        }
      for(cnt=OrdersTotal();cnt>=0;cnt--)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber2) OrdersPerSymbol++;
        }
   
      if(OrdersPerSymbol==0) break;

                    
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

   string sTK=" Ticket="+OrderTicket();
   string sSL=" SL="+OrderStopLoss();
   string sTP=" TP="+OrderTakeProfit();
   string sPM;
   string sLL;
   string sER;
      
   if(TradingStyle==1)
     {
      sPM=" PM="+ProfitMade1;
      sLL=" LL="+LossLimit1;
     }
   if(TradingStyle==2)
     {
      sPM=" PM="+ProfitMade2;
      sLL=" LL="+LossLimit2;
     }

   while(true)
     {
      OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Red);
      gle=GetLastError();
      sER=" error="+gle+" "+ErrorDescription(gle);
      
      if(gle==0)
        {
         if(logging) logwrite(TradeComment,"CLOSE SELL "+myInfo + sTK + sSL + sTP + sPM + sLL);
         break;
        }
      else 
        {
         if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE SELL "+myInfo+ sER +" Ask="+Ask+ sTK + sSL + sTP + sPM + sLL);
         RefreshRates();
         Sleep(500);
        }

      // sometimes an order close is delayed, or a gap jumps to the LL2SL on the server
      // This keeps a server-closed order from hanging here
      OrdersPerSymbol=0;
      for(cnt=OrdersTotal();cnt>=0;cnt--)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber1) OrdersPerSymbol++;
        }
      for(cnt=OrdersTotal();cnt>=0;cnt--)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if( OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber2) OrdersPerSymbol++;
        }
   
      if(OrdersPerSymbol==0) break;
                    
      loopcount++;
      if(loopcount>maxloop) break;
                 
     }//while                 
  }    
  


  
  
    