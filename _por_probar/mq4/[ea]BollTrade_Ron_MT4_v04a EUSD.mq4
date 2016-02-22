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


// user input
//                                             "12345678901234567890123456789012345678901";
extern string MinFreeMarginPct_is =            "percent of freemargin necessary to trade ";
extern double MinFreeMarginPct    =      25.0;  
extern string StartingBalance_is0 =            "Acct Start Balance (x  1 for 1 lot)      ";
extern string StartingBalance_is1 =            "                   (x 10 for .1 lots)    ";
extern string StartingBalance_is2 =            "                   (x100 for .01 lots)   ";
extern int    StartingBalance     =    1229;
extern string LotResolution_is    =            "LotIncrease grows by this many decimals  ";
extern int    LotResolution       =       2;
extern string ProfitMade_is       =            "PIPS PROFIT you want to make per trade   ";
extern double ProfitMade          =       8; 
extern string BasketProfit_is     =            "close all orders if this $ profit        ";
extern double BasketProfit        =       0;
extern string LossLimit_is        =            "PIPS LOSS you can afford per trade       ";
extern double LossLimit           =      35;
extern string VolumeMax_is        =            "Vol[0]&[1] below this before trading     ";
extern double VolumeMax           =     250;
extern string TradeEveryBar_is    =            "One trade for EVERY bar that qualifies   ";
extern bool   TradeEveryBar       =    true;
extern string FoldFrames_is       =            "For each new multiple order, double lots ";
extern bool   FoldFrames          =   false;
extern string BDistance_is        =            "Pips outside bollinger before trading    ";
extern double BDistance           =      14;
extern string BPeriod_is          =            "Bollinger period                         ";
extern int    BPeriod             =      15;
extern string Deviation_is        =            "Bollinger deviation                      ";
extern double Deviation           =       2.0;
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

// naming and numbering
int    MagicNumber  = 363642;            // allows multiple experts to trade on same account
string TradeComment = "_bolltrade_v04a.txt";
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
      // Don't alow frames to extend very far past
      // their actual occurance
      if(bartick>6) lotsi=Lots;
      if(TradeEveryBar) TradeAllowed=true;
     }

   // Lot increasement based on AccountBalance
   Lots=NormalizeDouble(AccountBalance()/StartingBalance,LotResolution);
   if( Lots>myMODE_MAXLOTS) Lots=myMODE_MAXLOTS;
   
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
      loopcount=0;
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
   if( TradeAllowed && SELLme )
     {
      loopcount=0;
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

            // Did we make a profit
            //======================
            if(ProfitMade>0 && CurrentProfit>=(ProfitMade*Point))     CloseBuy("PROFIT");
              

            // Did we take a loss
            //====================
            if(LossLimit>0 && CurrentProfit<=(LossLimit*(-1)*Point))  CloseBuy("LOSS");
              
           } // if BUY


         if(OrderType()==OP_SELL)
           {
            CurrentProfit=(OrderOpenPrice()-Ask);
            if(logtick) logwrite(TradeComment,"SELL CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);
           
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
  


  
  
    