//+--------+
//|EMAX2   |
//+--------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

/*

Theory of operation
Trade on 2 EMA crossings in contrary direction (planning on retracemant)

TIME FRAME
==========
M5, M15, M30 depending on broker

PAIRS
=====
EURUSD and others

ENTRY LONG
==========
EMA fast crosses down under EMA slow (contrary)

ENTRY SHORT
===========
EMA fast crosses up over EMA slow (contrary)

EXIT
====
ProfitMade or TrailStop

MONEY MANAGEMENT
================
Lot increasement based on account balance

RISK MANAGEMENT
===============
NONE

FAILURE MANAGEMENT
==================
GetLastError on every transaction
logging during trades

VERSION HISTORY
===============
7a  -  migrated to my SHELL to add some features

*/


// extra user input
extern int    ShortEma=2;
extern int    LongEma=12;

// user input
extern double ProfitMade   =       8;    // how much money do you expect to make
extern double LossLimit    =      37;    // how much loss can you tolorate
extern int    BreakEven    =       0;    // set break even when this many pips are made
extern double TrailStop    =       6;    // trailing stop (999=no trailing stop)
extern int    StartHour    =       0;    // your local time to start making trades
extern int    StopHour     =      24;    // your local time to stop making trades
extern int    BasketProfit =    9999;    // if equity reaches this level, close trades
extern int    BasketLoss   =    9999;    // if equity reaches this -level, close trades
extern double Lots         =       0.1;  // how many lots to trade at a time 
extern bool   LotIncrease  =    true;    // grow lots based on balance = true

// non-external flag settings
bool   logging=true  ;                   // log data or not
int    Slippage=2;                       // how many pips of slippage can you tolorate
bool   OneOrderOnly=true;                // one order at a time or not

// naming and numbering
int    MagicNumber  = 200607090936;      // allows multiple experts to trade on same account
string TradeComment = "_EMAX2_v7a.txt";   // comment so multiple EAs can be seen in Account History
double StartingBalance=0;                // lot size control if LotIncrease == true

// Bar handling
datetime bartime=0;                      // used to determine when a bar has moved
int      bartick=0;                      // number of times bars have moved

// Trade control
bool   TradeAllowed=true;                // used to manage trades


// Min/Max tracking and tick logging
int    maxOrders;                        // statistic for maximum numbers or orders open at one time
double maxEquity;                        // statistic for maximum equity level
double minEquity;                        // statistic for minimum equity level


// used for verbose error logging
#include <stdlib.mqh>


//+-------------+
//| Custom init |
//|-------------+
// Called ONCE when EA is added to chart or recompiled

int init()
  {
   if(LotIncrease)
     {
      StartingBalance=AccountBalance()/Lots;
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
      
   // bar counting
   if(bartime!=Time[0]) 
     {
      bartime=Time[0];
      bartick++; 

      if(Hour()>=StartHour && Hour()<=StopHour)
        {
         TradeAllowed=true;
        }
     }

   // Lot increasement based on AccountBalance when expert is started
   // this will trade 1.0, then 1.1, then 1.2 etc as account balance grows
   // or 0.9 then 0.8 then 0.7 as account balance shrinks 
   if(LotIncrease)
     {
      Lots=NormalizeDouble(AccountBalance()/StartingBalance,1);
      if(Lots>50.0) Lots=50.0;
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
   
   // keep some statistics
   if(OrdersPerSymbol>maxOrders) maxOrders=OrdersPerSymbol;

     
   //+-----------------------------+
   //| Insert your indicator here  |
   //| And set either BUYme or     |
   //| SELLme true to place orders |
   //+-----------------------------+
   
   // 2 EMA cross, buy contrary
   double SEmaC, LEmaC;
   double SEmaP, LEmaP;
   static int isCrossed  = 0;
   SEmaC = iMA(Symbol(),0,ShortEma,0,MODE_EMA,PRICE_CLOSE,0);
   LEmaC = iMA(Symbol(),0,LongEma,0,MODE_EMA,PRICE_CLOSE,0);
   SEmaP = iMA(Symbol(),0,ShortEma,0,MODE_EMA,PRICE_CLOSE,1);
   LEmaP = iMA(Symbol(),0,LongEma,0,MODE_EMA,PRICE_CLOSE,1);
   isCrossed = Crossed (LEmaC,SEmaC);
   if(isCrossed==1) BUYme=true;
   if(isCrossed==2) SELLme=true;
   

   //+------------+
   //| End Insert |
   //+------------+

   //ENTRY LONG (buy, Ask) 
   if( (OneOrderOnly && OrdersPerSymbol==0 && BUYme)||(!OneOrderOnly && TradeAllowed && BUYme) )
     {
      if(LossLimit ==0) SL=0; else SL=Ask-((LossLimit+10)*Point );
      if(ProfitMade==0) TP=0; else TP=Ask+((ProfitMade+10)*Point );
      ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,SL,TP,TradeComment,MagicNumber,White);
      gle=GetLastError();
      if(gle==0)
        {
         if(logging) logwrite(TradeComment,"BUY Ticket="+ticket+" Ask="+Ask+" Lots="+Lots+" SL="+SL+" TP="+TP);
         TradeAllowed=false;
        }
         else 
        {
         logwrite(TradeComment,"-----ERROR-----  opening BUY order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle)); 
        }
     }//BUYme
        

   //ENTRY SHORT (sell, Bid)
   if( (OneOrderOnly && OrdersPerSymbol==0 && SELLme)||(!OneOrderOnly && TradeAllowed && SELLme) )
    {
      if(LossLimit ==0) SL=0; else SL=Bid+((LossLimit+10)*Point );
      if(ProfitMade==0) TP=0; else TP=Bid-((ProfitMade+10)*Point );
      ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,SL,TP,TradeComment,MagicNumber,Red);
      gle=GetLastError();
      if(gle==0)
        {
         if(logging) logwrite(TradeComment,"SELL Ticket="+ticket+" Bid="+Bid+" Lots="+Lots+" SL="+SL+" TP="+TP);
         TradeAllowed=false;
        }
         else 
        {
         logwrite(TradeComment,"-----ERROR-----  opening SELL order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle));
        }
      }//SELLme

     
   //Basket profit or loss
   CurrentBasket=AccountEquity()-AccountBalance();
   if( CurrentBasket>=BasketProfit || CurrentBasket<=(BasketLoss*(-1)) ) CloseEverything();

   // accumulate statistics
   if(CurrentBasket>maxEquity) maxEquity=CurrentBasket;
   if(CurrentBasket<minEquity) minEquity=CurrentBasket;
   

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
            CurrentProfit=Bid-OrderOpenPrice() ;
            if(logging) logwrite(TradeComment,"BUY  CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);


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
                     logwrite(TradeComment,"-----ERROR----- MODIFY BUY  BE Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                    }
                 }
              }


            //
            // check for trailing stop
            //=========================
            //
            if( TrailStop>0 )  
              {                 
               if( Bid-OrderOpenPrice()>(TrailStop*Point) )
                 {
                  if( OrderStopLoss()<Bid-(TrailStop*Point) )
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
                        logwrite(TradeComment,"-----ERROR----- MODIFY BUY TS Bid="+Bid+" error="+gle+" "+ErrorDescription(gle)+" ");
                       }
                    }
                 }
              }


            //
            // Did we make a profit
            //======================
            //
            if(ProfitMade>0 && CurrentProfit>=(ProfitMade*Point))
              {
               OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,White);
               gle=GetLastError();
               if(gle==0)
                 {
                  if(logging) logwrite(TradeComment,"CLOSE BUY PROFIT Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                 }
                else 
                 {
                  logwrite(TradeComment,"-----ERROR----- CLOSE BUY PROFIT Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                 }
              }
              

            //
            // Did we take a loss
            //====================
            //
            if( LossLimit>0 && CurrentProfit<=(LossLimit*(-1)*Point)  )
              {
               OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,White);
               gle=GetLastError();
               if(gle==0)
                 {
                  if(logging) logwrite(TradeComment,"CLOSE BUY LOSS Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                 }
                else 
                 {
                  logwrite(TradeComment,"-----ERROR----- CLOSE BUY LOSS Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                 }
              }
              
           } // if BUY


         if(OrderType()==OP_SELL)
           {

            CurrentProfit=OrderOpenPrice()-Ask;
            if(logging) logwrite(TradeComment,"SELL CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);

            
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
                     logwrite(TradeComment,"-----ERROR----- MODIFY SELL BE Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                    }
                 }
              }


            //
            // check for trailing stop
            //=========================
            //
            if(TrailStop>0)  
              {                 
               if( (OrderOpenPrice()-Ask)>(TrailStop*Point) )
                 {
                  if( OrderStopLoss()>(Ask+(TrailStop*Point)) || (OrderStopLoss()==0) )
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
                        logwrite(TradeComment,"-----ERROR----- MODIFY SELL TS Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                       }
                    }
                 }
              }


            //
            // Did we make a profit
            //======================
            //
            if( ProfitMade>0 && CurrentProfit>=(ProfitMade*Point) )
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Red);
               gle=GetLastError();
               if(gle==0)
                 {
                  if(logging) logwrite(TradeComment,"CLOSE SELL PROFIT Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                 }
                  else 
                 {
                  logwrite(TradeComment,"-----ERROR----- CLOSE SELL PROFIT Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                 }
                 
              }


            //
            // Did we take a loss
            //====================
            //
            if( LossLimit>0 && CurrentProfit<=(LossLimit*(-1)*Point) )
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Red);
               gle=GetLastError();
               if(gle==0)
                 {
                  if(logging) logwrite(TradeComment,"CLOSE SELL LOSS Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                 }
                  else 
                 {
                  logwrite(TradeComment,"-----ERROR----- CLOSE SELL LOSS Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
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
   myhandle=FileOpen(Symbol()+"_"+filename, FILE_CSV|FILE_WRITE|FILE_READ, ";");
   if(myhandle>0)
     {
      FileSeek(myhandle,0,SEEK_END);
      FileWrite(myhandle, mydata+" "+CurTime());
      FileClose(myhandle);
     }
  } 
  

  
int Crossed (double Lline1 , double Sline2)
   {
      static int last_direction = 0;
      static int current_direction = 0;
      
      if(Lline1>Sline2)current_direction = 1; //up
      if(Lline1<Sline2)current_direction = 2; //down

      if(current_direction != last_direction) //changed 
      {
            last_direction = current_direction;
            return (current_direction);
      }
   }

