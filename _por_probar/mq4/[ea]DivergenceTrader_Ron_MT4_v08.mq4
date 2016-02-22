/*
+--------+
|Divergence Trader
+--------+
*/


// variables declared here are GLOBAL in scope

#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// user input
extern double Lots=0.01;              // how many lots to trade at a time 
extern int    Fast_Period=7;
extern int    Slow_Period=88;
extern double DVBuySell=0.0011;
extern double DVStayOut=0.0073;
extern double ProfitMade=20;          // how much money do you expect to make
extern double LossLimit=115;          // how much loss can you tolorate
extern int    PLBreakEven=9999;       // set break even when this many pips are made (999=off)


// externals that don't need to be external
       int    Slippage=2;             // how many pips of slippage can you tolorate
       bool   FileData=false;         // write to file exery tick?

// naming and numbering
int      MagicNumber  = 200601182020; // allows multiple experts to trade on same account
string   TradeComment = "Divergence_07_";

// Bar handling
datetime bartime=0;                   // used to determine when a bar has moved
int      bartick=0;                   // number of times bars have moved
int      objtick=0;                   // used to draw objects on the chart
int      tickcount=0;

// Trade control
bool TradeAllowed=true;               // used to manage trades



//+-------------+
//| Custom init |
//|-------------+
// Called ONCE when EA is added to chart or recompiled

int init()
  {
   int    i;
   string o;
   
   //remove the old objects 
   for(i=0; i<Bars; i++) 
     {
      o=DoubleToStr(i,0);
      ObjectDelete("myx"+o);
      ObjectDelete("myz"+o);
     }
   objtick=0;

   ObjectDelete("Cmmt");
   ObjectCreate( "Cmmt", OBJ_TEXT, 0, Time[20], High[20]+(5*Point) );
   ObjectSetText("Cmmt","Divergence=X.XXXX",10,"Arial",White);

   Print("Init happened ",CurTime());
   Comment(" ");
  }

//+----------------+
//| Custom DE-init |
//+----------------+
// Called ONCE when EA is removed from chart

int deinit()
  {
   int    i;
   string o;
   //remove the old objects 
   
   for(i=0; i<Bars; i++) 
     {
      o=DoubleToStr(i,0);
      ObjectDelete("myx"+o);
      ObjectDelete("myz"+o);
     }
   objtick=0;
   
   Print("DE-Init happened ",CurTime());
   Comment(" ");
  }


//+-----------+
//| Main      |
//+-----------+
// Called EACH TICK and each Bar[]

int start()
  {

   double p=Point;
   double spread=Ask-Bid;
   double spread2=(Ask-Bid)+2*Point; // for setting unattended stoploss and takeprofit
   
   int      cnt=0;
   int      gle=0;
   int      OrdersPerSymbol=0;

   // file logging   
   int      iFileHandle;
  
   // stoploss and takeprofit and close control
   double SL=0;
   double TP=0;
   double CurrentProfit=0;
   
   // direction control
   bool BUYme=false;
   bool SELLme=false;
   
   
   // Trade stuff
   double diverge;
   double maF1, maS1;

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
        }
     }


   //+-----------------------------+
   //| Insert your indicator here  |
   //| And set either BUYme or     |
   //| SELLme true to place orders |
   //+-----------------------------+

   int    Fast_Price = PRICE_OPEN;
   int    Fast_Mode  = MODE_EMA;
   maF1=iMA(Symbol(),0,Fast_Period,0,Fast_Mode,Fast_Price,0);

   int    Slow_Price = PRICE_OPEN;
   int    Slow_Mode  = MODE_SMMA;
   maS1=iMA(Symbol(),0,Slow_Period,0,Slow_Mode,Slow_Price,0);

   diverge=(maF1-maS1);
   
   ObjectDelete("Cmmt");
   ObjectCreate("Cmmt", OBJ_TEXT, 0, Time[20], High[20]+(10*p));
   ObjectSetText("Cmmt","Divergence="+DoubleToStr(diverge,4),10,"Arial",White);
   if( diverge>= DVBuySell       && diverge<= DVStayOut       ) BUYme=true;
   if( diverge<=(DVBuySell*(-1)) && diverge>=(DVStayOut*(-1)) ) SELLme=true;
   
   if(FileData)
     {
      tickcount++;
      iFileHandle = FileOpen("eaDivergence07", FILE_CSV|FILE_READ|FILE_WRITE, ",");
      FileSeek(iFileHandle, 0, SEEK_END);
      FileWrite(iFileHandle, bartick, " ", tickcount, " ", diverge);
      FileFlush(iFileHandle);
      FileClose(iFileHandle);
     }

   //+------------+
   //| End Insert |
   //+------------+

   //ENTRY LONG (buy, Ask) 
   if(TradeAllowed && BUYme)
      {
       //Ask(buy, long)
      if(LossLimit ==0) SL=0; else SL=Ask-( (LossLimit +7)*Point );
      if(ProfitMade==0) TP=0; else TP=Ask+( (ProfitMade+7)*Point );
      OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,SL,TP,TradeComment,MagicNumber,White);
      gle=GetLastError();
      if(gle==0)
        {
         Print("BUY  Ask=",Ask," bartick=",bartick);
         ObjectCreate("myx"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], High[0]+(5*p));
         ObjectSetText("myx"+DoubleToStr(objtick,0),"B",15,"Arial",Red);
         bartick=0;
         TradeAllowed=false;
        }
         else 
        {
         Print("-----ERROR----- BUY  Ask=",Ask," error=",gle," bartick=",bartick);
        }
     }
        
   //ENTRY SHORT (sell, Bid)
   if(TradeAllowed && SELLme)
     {
      //Bid (sell, short)
      if(LossLimit ==0) SL=0; else SL=Bid+((LossLimit+7)*Point );
      if(ProfitMade==0) TP=0; else TP=Bid-((ProfitMade+7)*Point );
      OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,SL,TP,TradeComment,MagicNumber,Red);
      gle=GetLastError();
      if(gle==0)
        {
         Print("SELL Bid=",Bid," bartick=",bartick); 
         ObjectCreate("myx"+DoubleToStr(objtick,0), OBJ_TEXT, 0, Time[0], High[0]+(5*p));
         ObjectSetText("myx"+DoubleToStr(objtick,0),"S",15,"Arial",Red);
         bartick=0;
         TradeAllowed=false;
        }
         else 
        {
         Print("-----ERROR----- SELL Bid=",Bid," error=",gle," bartick=",bartick);
        }
     }

     
   // CLOSE order if profit target made
   for(cnt=OrdersTotal();cnt>=0;cnt--)
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
               SL=OrderOpenPrice()+(spread*2);
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

            // did we make our desired BUY profit
            // or did we hit the BUY LossLimit
            if((ProfitMade>0 && CurrentProfit>=(ProfitMade*p)) || (LossLimit>0 && CurrentProfit<=((LossLimit*(-1))*p))  )
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
               SL=OrderOpenPrice()-(spread*2);
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

            // did we make our desired SELL profit?
            if( (ProfitMade>0 && CurrentProfit>=(ProfitMade*p)) || (LossLimit>0 && CurrentProfit<=((LossLimit*(-1))*p))  )
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

