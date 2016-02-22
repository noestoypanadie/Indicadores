//+--------+
//|GoldFish|
//+--------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"


// user input
extern double ProfitMade   =       5;    // how much money do you expect to make
extern double LossLimit    =      16;    // how much loss can you tolorate
extern double Lots         =       1;    // how many lots to trade at a time 
extern bool   logging      =   false;    // log data or not
extern bool   logerrs      =   false;    // log errors or not
extern bool   logtick      =   false;    // log tick data while orders open (or not)

// non-external flag settings
int    Slippage=2;                       // how many pips of slippage can you tolorate

// naming and numbering
int    MagicNumber         = 200608201949;
string TradeComment        = "GoldFish_12.txt";
double StartingBalance     =       0;    // lot size control if LotIncrease == true
bool   LotIncrease         =   true ;    // grow lots based on balance = true

// Bar handling
datetime bartime=0;                      // used to determine when a bar has moved
int      bartick=0;                      // number of times bars have moved

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

// double down logic
double        lotsize=0.1;

// Direction control for the flopping fish
// trade direction reversal
bool   FSell=false;      // where to go next
bool   FBuy=true;        // for Future Buy/Sell


/*
Notes
==============
string mySymbol = StringSubstr(Symbol(),0,6); // In case of m at end for mini account
==============
ObjectCreate(“MyLabel”,OBJ_LABEL, 0, 0, 0 );
ObjectSet    (“MyLabel”,OBJPROP_CORNER, 1);
ObjectSet    (“MyLabel”,OBJPROP_XDISTANCE, 15 );
ObjectSet    (“MyLabel”,OBJPROP_YDISTANCE, 15 );

Then you just set your object text property to the label, size, font and colour you want
ObjectSetText( "MyLabel", "jsfero@otenet.gr"  , 10, "Times New Roman", Yellow ); 

Don’t forget to kill the object at some point (probably in DeInit())
ObjectDelete("MyLabel");
==============
*/



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
   int      OrdersPending=0;
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
     }

   // Lot increasement based on AccountBalance when expert is started
   // this will trade 1.0, then 1.1, then 1.2 etc as account balance grows
   // or 0.9 then 0.8 then 0.7 as account balance shrinks 
   if(LotIncrease)
     {
      Lots=NormalizeDouble(AccountBalance()/StartingBalance,2);
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
         if(OrderType()==OP_BUYSTOP) {OrdersPending++;}
         if(OrderType()==OP_SELLSTOP){OrdersPending++;}
        }
     }
   
   // keep some statistics
   if(OrdersPerSymbol>maxOrders) maxOrders=OrdersPerSymbol;

     
   //+-----------------------------+
   //| Insert your indicator here  |
   //| And set either BUYme or     |
   //| SELLme true to place orders |
   //+-----------------------------+

   if(FSell) SELLme=true;
   if(FBuy)   BUYme=true;
   
   //+------------+
   //| End Insert |
   //+------------+

   //ENTRY LONG (buy, Ask) 
   if(OrdersPerSymbol==0 && BUYme)
     {
      if(LossLimit ==0) SL=0; else SL=Ask-((LossLimit+10)*Point );
      if(ProfitMade==0) TP=0; else TP=Ask+((ProfitMade+10)*Point );
      ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,SL,TP,TradeComment,MagicNumber,White);
      gle=GetLastError();
      if(gle==0)
        {
         if(logging) logwrite(TradeComment,"BUY Ticket="+ticket+" Ask="+Ask+" Lots="+Lots+" SL="+SL+" TP="+TP);
         maxOEquity=0;
         minOEquity=0;
         EquityPos=0;
         EquityNeg=0;
         EquityZer=0;
        }
         else 
        {
         if(logerrs) logwrite(TradeComment,"-----ERROR-----  opening BUY order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle)); 
        }
     }//BUYme
        

   //ENTRY SHORT (sell, Bid)
   if(OrdersPerSymbol==0 && SELLme)
    {
      if(LossLimit ==0) SL=0; else SL=Bid+((LossLimit+10)*Point );
      if(ProfitMade==0) TP=0; else TP=Bid-((ProfitMade+10)*Point );
      ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,SL,TP,TradeComment,MagicNumber,Red);
      gle=GetLastError();
      if(gle==0)
        {
         if(logging) logwrite(TradeComment,"SELL Ticket="+ticket+" Bid="+Bid+" Lots="+Lots+" SL="+SL+" TP="+TP);
         maxOEquity=0;
         minOEquity=0;
         EquityPos=0;
         EquityNeg=0;
         EquityZer=0;
        }
         else 
        {
         if(logerrs) logwrite(TradeComment,"-----ERROR-----  opening SELL order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle));
        }
      }//SELLme

     
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
            CurrentProfit=Bid-OrderOpenPrice() ;
            if(logtick) logwrite(TradeComment,"BUY  CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);

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
                  if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                  if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                  if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                  if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                  if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                  if (FBuy==true && FSell==false)
                    {
                     FBuy=false; FSell=true;
                     return(0);
                    }
                  if (FBuy==false && FSell==true)
                    {
                     FBuy=true; FSell=false;
                     return(0);
                    }
                 }
                else 
                 {
                  if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE BUY PROFIT Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
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
                  if (FBuy==true && FSell==false)
                    {
                     FBuy=false; FSell=true;
                     return(0);
                    }
                  if (FBuy==false && FSell==true)
                    {
                     FBuy=true; FSell=false;
                     return(0);
                    }
                  if(logging) logwrite(TradeComment,"CLOSE BUY LOSS Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                  if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                  if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                  if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                  if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                  if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                 }
                else 
                 {
                  if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE BUY LOSS Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                 }
              }
              
           } // if BUY


         if(OrderType()==OP_SELL)
           {

            CurrentProfit=OrderOpenPrice()-Ask;
            if(logtick) logwrite(TradeComment,"SELL CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);

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
                  if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                  if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                  if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                  if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                  if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                  if (FBuy==true && FSell==false)
                    {
                     FBuy=false; FSell=true;
                     return(0);
                    }
                  if (FBuy==false && FSell==true)
                    {
                     FBuy=true; FSell=false;
                     return(0);
                    }
                 }
                  else 
                 {
                  if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE SELL PROFIT Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
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
                  if (FBuy==true && FSell==false)
                    {
                     FBuy=false; FSell=true;
                     return(0);
                    }
                  if (FBuy==false && FSell==true)
                    {
                     FBuy=true; FSell=false;
                     return(0);
                    }
                  if(logging) logwrite(TradeComment,"CLOSE SELL LOSS Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                  if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                  if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                  if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                  if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                  if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                 }
                  else 
                 {
                  if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE SELL LOSS Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                 }
                 
              }


           } //if SELL
           
        } // if(OrderSymbol)
        
     } // for

  } // start()


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


