//+-----------------------------------+
//| Use on EURUSD 1hour charts only!! |
//+-----------------------------------+
#property copyright "Jan Vanman  vanman@absamail.co.za"
#property link      "http://www.metaquotes.ru"


//+------------------------------------------------------------------+
//|  External Variables                                              |
//+------------------------------------------------------------------+

extern double Lots = 1;
extern double StopLoss = 0;
extern double TakeProfit = 200;
extern double TrailingStop = 40;

extern int    Slippage=2;
extern int    lot=1;
extern double mini=0.1;
extern double main=1.0;
extern int    back=15;
extern int    MAFastPeriod=16;
extern int    MASlowPeriod=60;


int start()
  {
   int cnt=0;
   int mode=0;
   int FastMa=0, FastMa2=0, FastMa5=0;
   int SlowMa=0, SlowMa2=0, SlowMa5=0;

   if (Bars<200)        { Print("Bars less than 200");       return(0); }
   if (TrailingStop<10) {Print("TrailingStop less than 10"); return(0); }
   if (TakeProfit<10)   {Print("TakeProfit less than 10");   return(0); }


   // setup values
   FastMa =iMA(MAFastPeriod,MODE_EMA,0);
   FastMa2=iMA(MAFastPeriod,MODE_EMA,2);
   FastMa5=iMA(MAFastPeriod,MODE_EMA,5);

   SlowMa =iMA(MASlowPeriod,MODE_EMA,0);
   SlowMa2=iMA(MASlowPeriod,MODE_EMA,2);
   SlowMa5=iMA(MASlowPeriod,MODE_EMA,5);

   // Error checking
   if(Bars<100)                        {Print("Bars less than 100"); return(0);}
   if(AccountFreeMargin()<(1000*Lots)) {Print("We have no money");   return(0);}


   // if there are no open positions and orders
   if (TotalTrades<1)
     {
      lot=ceil(freemargin/300)*mini;
      if freemargin>5000 then
        {
         lot=ceil(freemargin/3000);
        };
      If FreeMargin<100 then Exit;  // not enough money
      // there are no open positions - check the BUY option
      // the opening condition:
      // if EMA(16) crosses EMA(60) upwards
      // and the current bar is bullish (Close>Open), we place
      // waiting order BUY LIMIT 15 pips below the execution
      // price for more optimal entering into the market
//    If FastMa>SlowMa and FastMa2<SlowMa2 and FastMa5<SlowMa5 and Close>Open then
      If (FastMa-SlowMa)>=Point and (SlowMa2-FastMa2)>=Point and (SlowMa5-FastMa5)>=Point and Close>Open then
        {
         // try to place a waiting order at the (Ask-15) points price
         // with maximum slippage 2 points,
         // while not setting  Stop Loss and setting Take Profit
         // 200 points above the opening price.
         // at the chart an upward green arrow appears
     
         SetOrder(OP_BUYLIMIT,Lot,Ask-back*Point,Slippage,0,Ask+(TakeProfit-back)*Point,RED);
         Exit; // now we exit as we are not allowed to operate the account in the nearest 10 sec
        };
        
      // the opening SELL condition:
      // if EMA(16) crosses EMA(60) downwards
      // and the current bar is bearish (Close<Open), than we place
      // a waiting order SELL LIMIT 15 points above
      // the execution price for more optimal entering the market
      If (SlowMa-FastMa)>=Point and (FastMa2-SlowMa2)>=Point and (FastMa5-SlowMa5)>=Point and Close<Open then
        {
         // try to place 1 lot order at Bid+15 points price
         // with 2 points maximum slippage,
         // when not setting  Stop Loss and setting  Take Profit
         // 200 points below opening price.
         // on the chart the downward red arrow will appear
         SetOrder(OP_SELLLIMIT,Lot,Bid+back*Point,Slippage,0,Bid-(TakeProfit-back)*Point,RED);
         Exit;
        };
        
   // all we need to check in the empty terminal 
   // we have checked already, now we exit
   Exit;
  };  //If TotalTrades<1 then


// here is the code of checking of the positions opened earlier
// (the placed orders will be checked 
// in the other block, now we check the already opened positions)


for cnt=1 to TotalTrades
  {
   mode=OrderValue(cnt,VAL_TYPE);
   If mode=OP_BUY then   // if the already opened position were BUY
     {
      // lets check if EMA(16) has crossed EMA(60) downwards?
      If (iMA(MAFastPeriod,MODE_EMA,0) < iMA(MASlowPeriod,MODE_EMA,0) and
         iMA(MAFastPeriod,MODE_EMA,2) > iMA(MASlowPeriod,MODE_EMA,2) and
         iMA(MAFastPeriod,MODE_EMA,5) > iMA(MASlowPeriod,MODE_EMA,5)) then
        {
         // try to close the position at current Bid price 
         CloseOrder(OrderValue(cnt,VAL_TICKET),OrderValue(cnt,VAL_LOTS),Bid,Slippage,RED);
         Exit;
        };

      // Here we check the trailing stop at open position.
      // Trailing stop ( Stop Loss) of the BUY position is being
      // kept at level 40 points below the market.

      // If the profit (current Bid-OpenPrice) more than TrailingStop (40) pips
      If (Bid-OrderValue(cnt,VAL_OPENPRICE))>(TrailingStop*Point) then
        {
         // we have won already not less than 'TrailingStop' pips!
         If OrderValue(cnt,VAL_STOPLOSS)<(Bid-TrailingStop*Point) then
           {
            // move the trailing stop (Stop Loss) to the level 'TrailingStop' from the market
            ModifyOrder(OrderValue(cnt,VAL_TICKET),OrderValue(cnt,VAL_OPENPRICE), Bid-Point*TrailingStop,OrderValue(cnt,VAL_TAKEPROFIT),Red);
            Exit;
           };
        }; //If (Bid-OrderValue(cnt,VAL_OPENPRICE))>(TrailingStop*Point)
     }; //If mode=OP_BUY then


   If mode=OP_SELL then   // if the already opened position were SELL
     {
      // check if EMA(16) has crossed already EMA(60) upwards?
      If (iMA(MAFastPeriod,MODE_EMA,0) > iMA(MASlowPeriod,MODE_EMA,0) and iMA(MAFastPeriod,MODE_EMA,2) < iMA(MASlowPeriod,MODE_EMA,2) and iMA(MAFastPeriod,MODE_EMA,5) < iMA(MASlowPeriod,MODE_EMA,5))
        {
         // try to close the position at current Ask price
         CloseOrder(OrderValue(cnt,VAL_TICKET),OrderValue(cnt,VAL_LOTS),Ask,Slippage,RED);
         Exit;
        };

      // Here we check the trailing stop at open position.
      // Trailing stop ( Stop Loss) of the BUY position is being
      // kept at level 40 points below the market.


      // If the profit (current Bid-OpenPrice) more than TrailingStop (40) pips
      If (OrderValue(cnt,VAL_OPENPRICE)-Ask)>(TrailingStop*Point) then
        {
         // we have won already not less than 'TrailingStop' pips!
         If OrderValue(cnt,VAL_STOPLOSS)>(Ask+TrailingStop*Point) or
            OrderValue(cnt,VAL_STOPLOSS)=0 then
           {
            // move the trailing stop (Stop Loss) to the level 'TrailingStop' from the market
            ModifyOrder(OrderValue(cnt,VAL_TICKET),OrderValue(cnt,VAL_OPENPRICE), Ask+Point*TrailingStop,OrderValue(cnt,VAL_TAKEPROFIT),Red);
            Exit;
           };
        }; //If (OrderValue(cnt,VAL_OPENPRICE)-Ask)>(TrailingStop*Point)
     };  //If mode=OP_SELL


   // there is one very important point - the control
   // over the waiting orders.  An order cannot be valid more than 0.5 hour. 
   // After which It should be canceled  
   // For that purpose we compare current time 
   // and time the order is placed
   If mode>OP_SELL then  // this is a waiting order!
         {
      // check how long it exists in the trading terminal
      // time is counted in seconds:
      // 10 minutes = 600 seconds, 30 minutes = 1800, 1 hour = 3600, 1 day = 86400
      If (CurTime-OrderValue(cnt,VAL_OPENTIME))>1800 then
        {
         DeleteOrder(OrderValue(cnt,VAL_TICKET),RED);
         Exit;
        };
     };
  };//for cnt=1 to TotalTrades

// the end
//Adapted from "Trend Follower" from InterbankFX.com
//by JF van Niekerk



