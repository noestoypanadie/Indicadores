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



// user input
extern double MinFreeMarginPct=   25.0;  // percent of account freemargin necessary to trade
extern double ProfitMade   =       8;    // how many pips do you want to make PER TRADE
extern double BasketProfit =     285;    // if compounding, close EVERYTHING if this $ profit
extern double LossLimit    =      35;    // how much can you afford to lose
extern double BasketLoss   =       0;    // if compounding, close EVERYTHING if this % loss
extern double BreakEven    =       0;    // set stoploss to OrderOpenPrice after this many pips profit
extern double TrailStop    =       0;    // trail the order price starting from 1st tick
extern double VolumeMax    =     330;    // Volume must be below this before orders placed
extern double VolumeMin    =       0;    // Volume must be above this before orders placed
extern bool   Compounding  =    true;    // buy more as the distance outside the band increases
extern int    CompoundStep =       3;    // how many pips movement before compounding
extern double BDistance    =      14;    // how many pips outside the bollinger before opening orders
extern int    BPeriod      =      15;    // Bollinger period
extern double Deviation    =       2.0;  // Bollinger deviation
extern double Lots         =       1.0;  // how many lots to trade at a time 
extern bool   LotIncrease  =    true ;   // grow lots based on balance = true
extern bool   TradeOnFriday=    true ;   // trade on Friday, or not
extern string ExtraComment =    " "  ;   // appended to TradeComment in init()
extern bool   KillLogging  =    true ;   // don't do ANY logging
extern bool   logging      =    true ;   // log data or not
extern bool   logerrs      =    true ;   // log errors or not
extern bool   logtick      =   false ;   // log tick data while orders open (or not)


// non-external flag settings
int    Slippage=2;                       // how many pips of slippage can you tolorate
double CompoundTrack;                    // used to track compounding and steps

// naming and numbering
int    MagicNumber  = 363640;            // allows multiple experts to trade on same account
string TradeComment = "_bolltrade_v03j.txt";
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
double maxEquity;                        // statistic for maximum equity level
double minEquity;                        // statistic for minimum equity level
double maxOEquity;                       // statistic for maximum equity level per order
double minOEquity;                       // statistic for minimum equity level per order 
double EquityPos=0;                      // statistic for number of ticks order was positive
double EquityNeg=0;                      // statistic for number of ticks order was negative
double EquityZer=0;                      // statistic for number of ticks order was zero

// used for verbose error logging
#include <stdlib.mqh>


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
      StartingBalance=AccountBalance()/Lots;
      //StartingBalance=13820;
      logwrite(TradeComment,"LotIncrease ACTIVE Account balance="+AccountBalance()+" Lots="+Lots+" StartingBalance="+StartingBalance);
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
     }

   // Lot increasement based on AccountBalance when expert is started
   // this will trade 1.0, then 1.1, then 1.2 etc as account balance grows
   // or 0.9 then 0.8 then 0.7 as account balance shrinks 
   if(LotIncrease)
     {
      Lots=NormalizeDouble(AccountBalance()/StartingBalance,1);
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
      CompoundTrack=0;
      
      // This allows the 1st order at BDistance after everything closes
      // others are handled in the indicator section 
      TradeAllowed=true;
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
   double bup = ma+(Deviation*stddev);
   double bdn = ma-(Deviation*stddev);

   if(Close[0]>bup)                 Comment("S Up="+bup+" Dn="+bdn+" Close="+Close[0]+" Vol_1="+Volume[1]+" Vol_0="+Volume[0]);
   if(Close[0]<bdn)                 Comment("B Up="+bup+" Dn="+bdn+" Close="+Close[0]+" Vol_1="+Volume[1]+" Vol_0="+Volume[0]);
   if(Close[0]<bup && Close[0]>bdn) Comment("X Up="+bup+" Dn="+bdn+" Close="+Close[0]+" Vol_1="+Volume[1]+" Vol_0="+Volume[0]);
   
   // < and NOT <= so tick won't match 0 in a non-tick bar
   bool  volumeOK=false;
   if( Volume[0]>VolumeMin && Volume[1]<VolumeMax && Volume[0]<VolumeMax) volumeOK=true;
   if (VolumeMax==0) volumeOK=true;
 
   bool TradeDay=true;
   if(DayOfWeek()==5 && TradeOnFriday==false) TradeDay=false;
   
   // if close is above upper band + BDistance then SELL
   if(Close[0]>bup+(BDistance*Point) && volumeOK && TradeDay) 
     {
      SELLme=true; 
      if(logging) logwrite("BollTick3g.txt","---SELLme happened"); 
      if(Compounding && CompoundTrack>0 && Close[0]>CompoundTrack)
        {
         SELLme=true; 
         TradeAllowed=true;
         if(logging) logwrite("BollTick3h.txt","---SELLme happened again "+CompoundTrack ); 
        }
     }

   // if close is below lower band + BDistance then BUY
   if(Close[0]<bdn-(BDistance*Point) && volumeOK && TradeDay) 
     {
      BUYme=true;  
      if(logging) logwrite("BollTick3h.txt","----BUYme happened"); 
      if(Compounding && CompoundTrack>0 && Close[0]<CompoundTrack)
        {
         BUYme=true;
         TradeAllowed=true;
         if(logging) logwrite("BollTick3g.txt","----BUYme happened again "+CompoundTrack ); 
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
            CompoundTrack=Close[0]+(CompoundStep*Point);
            //CompoundTrack=Ask;
            if(logging) logwrite(TradeComment,"                                                                ");
            if(logging) logwrite(TradeComment,"BUY Ticket="+ticket+" Ask="+Ask+" Lots="+Lots+" SL="+SL+" TP="+TP);
            maxOEquity=0;
            minOEquity=0;
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
            CompoundTrack=Close[0]-(CompoundStep*Point);
            //CompoundTrack=Bid;
            if(logging) logwrite(TradeComment,"                                                                 ");
            if(logging) logwrite(TradeComment,"SELL Ticket="+ticket+" Bid="+Bid+" Lots="+Lots+" SL="+SL+" TP="+TP);
            maxOEquity=0;
            minOEquity=0;
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
   CurrentBasket=AccountEquity()-AccountBalance();
   if(CurrentBasket>maxEquity) { maxEquity=CurrentBasket; maxOEquity=CurrentBasket; }
   if(CurrentBasket<minEquity) { minEquity=CurrentBasket; minOEquity=CurrentBasket; }
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

      if(OrderType()==OP_BUY)       CloseBuy ("BASKET");
      if(OrderType()==OP_SELL)      CloseSell("BASKET");
      if(OrderType()==OP_BUYLIMIT)  OrderDelete( OrderTicket() );
      if(OrderType()==OP_SELLLIMIT) OrderDelete( OrderTicket() );
      if(OrderType()==OP_BUYSTOP)   OrderDelete( OrderTicket() );
      if(OrderType()==OP_SELLSTOP)  OrderDelete( OrderTicket() );

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
            logwrite(TradeComment,"MAX order equity "+maxOEquity);
            logwrite(TradeComment,"MIN order equity "+minOEquity);
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
            logwrite(TradeComment,"MAX order equity "+maxOEquity);
            logwrite(TradeComment,"MIN order equity "+minOEquity);
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