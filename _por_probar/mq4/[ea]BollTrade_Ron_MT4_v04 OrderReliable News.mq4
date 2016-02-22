//+------+
//|BollTrade
//+------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

#include <OrderReliable_V1_1_0.mqh>
#include <NewsTrackerV1_1.mqh>

// user input
extern double ProfitMade   =       8;    // how much money do you expect to make
extern double LossLimit    =      38;    // how much loss can you tolorate
extern double BDistance    =      15;    // plus how much
extern int    BPeriod      =      15;    // Bollinger period
extern double Deviation    =       2;    // Bollinger deviation
extern double Lots         =       1.0;  // how many lots to trade at a time 
extern bool   LotIncrease  =    false;   // grow lots based on balance = true
extern bool   logging      =    false;   // log data or not
extern bool   logerrs      =    false;   // log errors or not
extern bool   logtick      =    false;   // log tick data while orders open (or not)

// non-external flag settings
int    Slippage=2;                       // how many pips of slippage can you tolorate
bool   OneOrderOnly=true;               // one order at a time or not

// naming and numbering
int    MagicNumber  = 363636;            // allows multiple experts to trade on same account
string TradeComment = "_bolltrade_v03f.txt";   // comment so multiple EAs can be seen in Account History
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
   strNewsFileName = "AllNewsItems.csv"; // located in experts\files
	bCacheNews = !IsTesting();

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
      TradeAllowed=true;
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

	double ma = iMA(Symbol(),0,BPeriod,0,MODE_SMA,PRICE_OPEN,0);
	double stddev = iStdDev(Symbol(),0,BPeriod,0,MODE_SMA,PRICE_OPEN,0);   
   double bup = ma+Deviation*stddev;
   double bdn = ma-Deviation*stddev;

   string strNews; 
   datetime NewsTime;
   static bool bStopLossTightened = false;
   if (!NewsEvent(10,strNews,NewsTime)) 
   {
		Comment("");
		bStopLossTightened = false;
  	   // avoid buying if near news event
	   if(Close[0]-0.1*Point > bup+(BDistance*Point)) SELLme=true;
	   if(Close[0]+0.1*Point < bdn-(BDistance*Point))  BUYme=true;
	}
	else
	{
		Comment("Near news event: ",strNews," at server time ",TimeToStr(NewsTime));
		if (!bStopLossTightened) // tighten stops at beginning of news window
	   {
	   	for ( int nPosition=0 ; nPosition<OrdersTotal() ; nPosition++ )
   		{
      		OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
	      	if ( OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber)
		      {
   		      switch (OrderType())
      		   {
         		case OP_BUY: OrderModifyReliable(OrderTicket(),0,Ask-10*Point,OrderTakeProfit(),0); break;
	         	case OP_SELL: OrderModifyReliable(OrderTicket(),0,Bid+10*Point,OrderTakeProfit(),0); break;
   	      	}
      	   }
      	}
			bStopLossTightened = true;
      }
   }
  

   //+------------+
   //| End Insert |
   //+------------+

   //ENTRY LONG (buy, Ask) 
   if( (OneOrderOnly && OrdersPerSymbol==0 && BUYme)||(!OneOrderOnly && TradeAllowed && BUYme) )
     {
         if(LossLimit ==0) SL=0; else SL=NormalizeDouble(Ask-(LossLimit+10)*Point,Digits);
         if(ProfitMade==0) TP=0; else TP=NormalizeDouble(Ask+(ProfitMade+10)*Point,Digits);
         ticket=OrderSendReliableMKT(Symbol(),OP_BUY,Lots,NormalizeDouble(Ask,Digits),Slippage,SL,TP,TradeComment,MagicNumber,White);
         gle=OrderReliableLastErr();
         if(gle==0)
           {
            if(logging) logwrite(TradeComment,"BUY Ticket="+ticket+" Ask="+Ask+" Lots="+Lots+" SL="+SL+" TP="+TP);
            maxOEquity=0;
            minOEquity=0;
            EquityPos=0;
            EquityNeg=0;
            EquityZer=0;
            TradeAllowed=false;
           }
            else 
           {
            if(logerrs) logwrite(TradeComment,"-----ERROR-----  opening BUY order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle)); 
            Print("-----ERROR-----  opening BUY order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle)); 
           }
     }//BUYme
        

   //ENTRY SHORT (sell, Bid)
   if( (OneOrderOnly && OrdersPerSymbol==0 && SELLme)||(!OneOrderOnly && TradeAllowed && SELLme) )
     {
         if(LossLimit ==0) SL=0; else SL=NormalizeDouble(Bid+(LossLimit+10)*Point,Digits);
         if(ProfitMade==0) TP=0; else TP=NormalizeDouble(Bid-(ProfitMade+10)*Point,Digits);
         ticket=OrderSendReliableMKT(Symbol(),OP_SELL,Lots,NormalizeDouble(Bid,Digits),Slippage,SL,TP,TradeComment,MagicNumber,Red);
         gle=OrderReliableLastErr();
         if(gle==0)
           {
            if(logging) logwrite(TradeComment,"SELL Ticket="+ticket+" Bid="+Bid+" Lots="+Lots+" SL="+SL+" TP="+TP);
            maxOEquity=0;
            minOEquity=0;
            EquityPos=0;
            EquityNeg=0;
            EquityZer=0;
            TradeAllowed=false;
           }
            else 
           {
            if(logerrs) logwrite(TradeComment,"-----ERROR-----  opening SELL order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle));
            Print("-----ERROR-----  opening SELL order :"+gle+" ticket="+ticket+" "+ErrorDescription(gle));
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
            if(ProfitMade>0 && CurrentProfit+0.1*Point>=(ProfitMade*Point))
              {
                  OrderCloseReliable(OrderTicket(),OrderLots(),Bid,Slippage,White);
                  gle=OrderReliableLastErr();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"CLOSE BUY PROFIT Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                     if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                     if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                     if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                     if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                     if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                     break;
                    }
                   else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE BUY PROFIT Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                     Print("-----ERROR----- CLOSE BUY PROFIT Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                    }
              }//if
              

            //
            // Did we take a loss
            //====================
            //
            if( LossLimit>0 && CurrentProfit-0.1*Point<=(LossLimit*(-1)*Point)  )
              {
                  OrderCloseReliable(OrderTicket(),OrderLots(),NormalizeDouble(Bid,Digits),Slippage,White);
                  gle=OrderReliableLastErr();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"CLOSE BUY LOSS Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                     if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                     if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                     if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                     if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                     if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                     break;
                    }
                   else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE BUY LOSS Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                     Print("-----ERROR----- CLOSE BUY LOSS Bid="+Bid+" error="+gle+" "+ErrorDescription(gle));
                    }
              }//if
              
           } // if BUY


         if(OrderType()==OP_SELL)
           {

            CurrentProfit=OrderOpenPrice()-Ask;
            if(logtick) logwrite(TradeComment,"SELL CurrentProfit="+CurrentProfit/Point+" CurrentBasket="+CurrentBasket/Point);


            //
            // Did we make a profit
            //======================
            //
            if( ProfitMade>0 && CurrentProfit+0.1*Point>=(ProfitMade*Point) )
              {
                  OrderCloseReliable(OrderTicket(),OrderLots(),Ask,Slippage,Red);
                  gle=OrderReliableLastErr();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"CLOSE SELL PROFIT Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                     if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                     if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                     if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                     if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                     if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                     break;
                    }
                     else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE SELL PROFIT Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                     Print("-----ERROR----- CLOSE SELL PROFIT Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                    }
              }//if


            //
            // Did we take a loss
            //====================
            //
            if( LossLimit>0 && CurrentProfit-0.1*Point<=(LossLimit*(-1)*Point) )
              {
                  OrderCloseReliable(OrderTicket(),OrderLots(),NormalizeDouble(Ask,Digits),Slippage,Red);
                  gle=OrderReliableLastErr();
                  if(gle==0)
                    {
                     if(logging) logwrite(TradeComment,"CLOSE SELL LOSS Ticket="+OrderTicket()+" SL="+SL+" TP="+TP);
                     if(logging) logwrite(TradeComment,"MAX order equity "+maxOEquity);
                     if(logging) logwrite(TradeComment,"MIN order equity "+minOEquity);
                     if(logging) logwrite(TradeComment,"order equity positive ticks ="+EquityPos);
                     if(logging) logwrite(TradeComment,"order equity negative ticks ="+EquityNeg);
                     if(logging) logwrite(TradeComment,"order equity   zero   ticks ="+EquityZer);
                     break;
                    }
                     else 
                    {
                     if(logerrs) logwrite(TradeComment,"-----ERROR----- CLOSE SELL LOSS Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                     Print("-----ERROR----- CLOSE SELL LOSS Ask="+Ask+" error="+gle+" "+ErrorDescription(gle));
                    }
              }//if

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

