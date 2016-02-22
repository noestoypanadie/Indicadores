//+------------------------------------------------------------------+
//|                                     Your_Choice_MA_Cross_v1e.mq4 |
//|                                Copyright © 2006, transport.david |
//|                                        transport.david@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, transport.david"
#property link      "transport.david@gmail.com"

extern int UserAcceptsAllLiability = true;

extern int    magic        =   99;
extern double Lots         =  0.1;
extern int	  StopLoss     =   40;
extern int	  TakeProfit   =   240;
extern int    TrailingStop =   60;

extern int mafastperiod = 5;
extern int mafastshift  = 0;
extern int mafastmethod = 1; // use 0 through 3 for backtesting/optimizing , default = 1 ( MODE_EMA )
extern int mafastprice  = 0; // use 0 through 6 for backtesting/optimizing , default = 0 ( PRICE_CLOSE )

extern int maslowperiod = 8;
extern int maslowshift  = 0;
extern int maslowmethod = 1; // use 0 through 3 for optimizing , default = 1 ( MODE_EMA )
extern int maslowprice  = 1; // use 0 through 6 for optimizing , default = 1 ( PRICE_OPEN )

extern int EntryBar = 0; // This determines what bar the order is opened during . Default = 0
                         //  0 (zero) and the trade will open when the cross is first detected , current bar .
                         //  1 and the expert waits until the open of the bar After a cross .

extern int CloseBar = 1; // This determines what bar the order is Closed during . Default = 1 ( recommended )
                         //  0 (zero) and the trade will close when the cross is first detected , current bar .
                         //  1 and the expert waits until the open of the bar After a cross .

extern int ManualBuy  = 0; // default = 0
extern int ManualSell = 0; // default = 0

double prevtime, OpenTrades, OrderTime, openperiod, ofast1, ofast2, oslow1, oslow2, cfast1, cfast2, cslow1, cslow2,
       OpenCondition, CloseCondition, ManualSig;

//------------------------------------------------------------------------

int init()
 {
   return(0);
 }

//------------------------------------------------------------------------

int deinit()
 {
   Comment("");
   return(0);
 }

//------------------------------------------------------------------------

int start()
 { // A
  if (UserAcceptsAllLiability != true) return(0);
  if (UserAcceptsAllLiability == true)
   { // B
    
    int i;
    
    if (prevtime!=Time[0]) // if New Bar
     { 
       RefreshRates(); OrderTime = 0; prevtime=Time[0]; // RefreshRates , reset OrderTime , set prevtime to time 0 , 1 cycle at first tick of new bar .
      if  ( (ManualBuy != 0) || (ManualSell != 0) ) Alert("Reset Manual Condition To 0"); // Alert at opening of new bar if ManualBuy or ManualSell != 0 .
     }
    if ( (ManualBuy == 0) && (ManualSell == 0) ) { ManualSig = 0; }   // Reset ManualSig if Both ManualBuy & ManualSell = 0 .
    if ( (ManualBuy != 0) || (ManualSell != 0) ) { ManualSig = 100; } // Set ManualSig if Either ManualBuy or ManualSell != 0.
   
   // Count Open Trades and record OrderOpenTime --------------------------
    
    OpenTrades = 0; // reset OpenTrades for a fresh count .
    
    for(i = 0; i < OrdersTotal(); i++)
     { // 1
       OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      
      if ( (OrderSymbol() == Symbol()) && (OrderMagicNumber() == magic) && (OrderOpenTime() > 0) ) // check symbol , magic num and find latest trade time .
       { // 2
         OpenTrades++;
         OrderTime = OrderOpenTime();
       } // 2
     } // 1
     
    //- Control for Opening 1 Trade per Bar --------------------------------
     
     // If a trade has been placed during the current bar
     //    And it reaches TakeProfit
     //    And you remove then re-attach the expert
     //    the expert will Not have a record of the trade
     //    and Will place another trade During the current bar
     
     // If a trade has been placed during the current bar
     //    And it reaches TakeProfit
     //    And you do nothing
     //    the expert Will have a record of the trade
     //    and will Not place another trade during the current bar
     
     if (OrderTime >= Time[0]) // Open Order has occurred during this bar .
      { // 1
        openperiod = -10; // No more opening of trades allowed during this bar .
      } // 1
     if (OrderTime < Time[0]) // Open Order has occurred prior to this bar .
      { // 1
        openperiod =  10; // Opening of trades allowed during this bar .
      } // 1
     
    // Calculate Indicators -------------------------------------------------
     
     ofast1 = iMA(Symbol(), 0, mafastperiod, mafastshift, mafastmethod, mafastprice, 0 + EntryBar);
     ofast2 = iMA(Symbol(), 0, mafastperiod, mafastshift, mafastmethod, mafastprice, 1 + EntryBar);
     oslow1 = iMA(Symbol(), 0, maslowperiod, maslowshift, maslowmethod, maslowprice, 0 + EntryBar);
     oslow2 = iMA(Symbol(), 0, maslowperiod, maslowshift, maslowmethod, maslowprice, 1 + EntryBar);
     
     cfast1 = iMA(Symbol(), 0, mafastperiod, mafastshift, mafastmethod, mafastprice, 0 + CloseBar);
     cfast2 = iMA(Symbol(), 0, mafastperiod, mafastshift, mafastmethod, mafastprice, 1 + CloseBar);
     cslow1 = iMA(Symbol(), 0, maslowperiod, maslowshift, maslowmethod, maslowprice, 0 + CloseBar);
     cslow2 = iMA(Symbol(), 0, maslowperiod, maslowshift, maslowmethod, maslowprice, 1 + CloseBar);
     
    //- Create condition for Opening a trade --------------------------------
     
     if ((ofast1 > oslow1) && (ofast2 <= oslow2)) OpenCondition =  10; // Open Long
     if ((ofast1 < oslow1) && (ofast2 >= oslow2)) OpenCondition = -10; // Open Short
     if ((ofast1 > oslow1) && (ofast2 >= oslow2)) OpenCondition =   0; // Neutral
     if ((ofast1 < oslow1) && (ofast2 <= oslow2)) OpenCondition =   0; // Neutral
     
    //- Create condition for Closing a trade --------------------------------
     
     if ((cfast1 > cslow1) && (cfast2 <= cslow2)) CloseCondition =  10; // Close Short
     if ((cfast1 < cslow1) && (cfast2 >= cslow2)) CloseCondition = -10; // Close Long
     if ((ofast1 > oslow1) && (ofast2 >= oslow2)) CloseCondition =   0; // Neutral
     if ((ofast1 < oslow1) && (ofast2 <= oslow2)) CloseCondition =   0; // Neutral
     
    //- Comments ------------------------------------------------------------
     
     Comment(" OpenTrades:  ",OpenTrades," ,  OrderTime:  ",OrderTime,
        "\n"," Time[0]:  ",Time[0],//" ,   prevtime:  ",prevtime,
        "\n"," fast2:  ",ofast2," ,  fast1:  ",ofast1,
        "\n"," slow2:  ",oslow2," ,  slow1:  ",oslow1,
        "\n"," openperiod:  ",openperiod," ,  OpenCondition:  ",OpenCondition," ,  CloseCondition:  ",CloseCondition,
        "\n"," magic:  ",magic," ,   Lots:  ",Lots," ,   StopLoss:  ",StopLoss," ,   TakeProfit:  ",TakeProfit," ,   TrailingStop:  ",TrailingStop,
        "\n"," mafastperiod:  ",mafastperiod," ,   mafastshift:  ",mafastshift," ,   mafastmethod:  ",mafastmethod," ,   mafastprice:  ",mafastprice,
        "\n"," maslowperiod:  ",maslowperiod," ,   maslowshift:  ",maslowshift," ,   maslowmethod:  ",maslowmethod," ,   maslowprice:  ",maslowprice,
        "\n"," EntryBar:  ",EntryBar," ,   CloseBar:  ",CloseBar," ,   ManualBuy:  ",ManualBuy," ,   ManualSell:  ",ManualSell," ,   ManualSig:  ",ManualSig);
     
    // Open Trades ----------------------------------------------------------
     
     // Expert Open Long / Buy if no trades and EntryBar = 0 or EntryBar = 1
     if ( (OpenTrades <= 0)   &&
          (OpenCondition > 0) &&
          (openperiod >= 0)      )
      { // 1
        OrderSend(Symbol(),
                  OP_BUY,
                  Lots,
                  Ask,
                  3,
                  Ask-StopLoss*Point,
                  Ask+TakeProfit*Point,
                  "Your_Choice_MA_Cross_v1e",
                  magic,
                  0,
                  Aqua);
      } // 1
     
     // Expert Open Long / Buy if trades already open and EntryBar = 0 and CloseBar = 1 .
     if ( (OpenTrades != 0)   &&
          (OpenCondition > 0) &&
          (openperiod >= 0)   &&
          (EntryBar == 0)     &&
          (CloseBar == 1)        )
      { // 1
        OrderSend(Symbol(),
                  OP_BUY,
                  Lots,
                  Ask,
                  3,
                  Ask-StopLoss*Point,
                  Ask+TakeProfit*Point,
                  "Your_Choice_MA_Cross_v1e",
                  magic,
                  0,
                  Aqua);
      } // 1
     
     // Manual Open Long / Buy if extern int ManualBuy != 0 .
     if ( (ManualBuy != 0) &&
          (ManualSig == 0)    )
      { // 1
        OrderSend(Symbol(),
                  OP_BUY,
                  Lots,
                  Ask,
                  3,
                  Ask-StopLoss*Point,
                  Ask+TakeProfit*Point,
                  "Your_Choice_MA_Cross_v1e",
                  magic,
                  0,
                  White);
                  ManualSig = 100;
      } // 1
      
     // Expert Open Short / Sell if no trades and EntryBar = 0 or EntryBar = 1
     if ( (OpenTrades <= 0)   &&
          (OpenCondition < 0) &&
          (openperiod >= 0)      )
      { // 1
        OrderSend(Symbol(),
                  OP_SELL,
                  Lots,
                  Bid,
                  3,
                  Bid+StopLoss*Point,
                  Bid-TakeProfit*Point,
                  "Your_Choice_MA_Cross_v1e",
                  magic,
                  0,
                  Tomato);
      } // 1
     
     // Expert Open Short / Sell if trades already open and EntryBar = 0 and CloseBar = 1 .
     if ( (OpenTrades != 0)   &&
          (OpenCondition < 0) &&
          (openperiod >= 0)   &&
          (EntryBar == 0)     &&
          (CloseBar == 1)        )
      { // 1
        OrderSend(Symbol(),
                  OP_SELL,
                  Lots,
                  Bid,
                  3,
                  Bid+StopLoss*Point,
                  Bid-TakeProfit*Point,
                  "Your_Choice_MA_Cross_v1e",
                  magic,
                  0,
                  Tomato);
      } // 1
     
     // Manual Open Short / Sell if extern int ManualSell != 0 .
     if ( (ManualSell != 0) &&
          (ManualSig == 0)     )
      { // 1
        OrderSend(Symbol(),
                  OP_SELL,
                  Lots,
                  Bid,
                  3,
                  Bid+StopLoss*Point,
                  Bid-TakeProfit*Point,
                  "Your_Choice_MA_Cross_v1e",
                  magic,
                  0,
                  White);
                  ManualSig = 100;
      } // 1
     
    // Close Trades ---------------------------------------------------------
     
     for(i = 0; i < OrdersTotal(); i++)
      { // 1
        OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
       
       // Close Long / Buy
       if ( (OrderSymbol() == Symbol())   &&
            (OrderType() == OP_BUY)       &&
            (OrderMagicNumber() == magic) &&
            (OrderOpenTime() < Time[0])   &&
            (CloseCondition < 0)                  )
        { // 2
          OrderClose(OrderTicket(),
                     OrderLots(),
                     OrderClosePrice(),
                     0,
                     White);
                     OrderTime = 0;
                     openperiod =  10; // secondary reset of openperiod value , just in case .
        } // 2
       
       // Close Short / Sell
       if ( (OrderSymbol() == Symbol())   &&
            (OrderType() == OP_SELL)      &&
            (OrderMagicNumber() == magic) &&
            (OrderOpenTime() < Time[0])   &&
            (CloseCondition > 0)                  )
        { // 2
          OrderClose(OrderTicket(),
                     OrderLots(),
                     OrderClosePrice(),
                     0,
                     White);
                     OrderTime = 0;
                     openperiod =  10; // secondary reset of openperiod value , just in case .
        } // 2
      } // 1
     
    // Trailing Stop  ---------------------------------------------------------
     
     for(i = 0; i < OrdersTotal(); i++)
      { // 1
        OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
       
       // Trail Long / Buy
       if ( (OrderType() == OP_BUY) && (OrderMagicNumber() == magic) )
        { // 2
         if ( (OrderClosePrice() - OrderOpenPrice()) > (TrailingStop*Point) )
          { // 3
           if ( OrderStopLoss() < (OrderClosePrice() - TrailingStop*Point) )
            { // 4
              OrderModify(OrderTicket(),
                          OrderOpenPrice(),
                          OrderClosePrice() - TrailingStop*Point,
                          OrderTakeProfit(),
                          Orchid);
            } // 4
          } // 3
        } // 2
       
       // Trail Short / Sell
       if ( (OrderType() == OP_SELL) && (OrderMagicNumber() == magic) )
        { // 2
         if ( (OrderOpenPrice() - OrderClosePrice()) > (TrailingStop*Point) )
     	    { // 3
           if ( (OrderStopLoss() > (OrderClosePrice() + TrailingStop*Point)) ||
                (OrderStopLoss() == 0)                                          )
            { // 4
              OrderModify(OrderTicket(),
                          OrderOpenPrice(),
                          OrderClosePrice() + TrailingStop*Point,
                          OrderTakeProfit(),
                          Orchid);
            } // 4
     	    } // 3
  	     } // 2
  	   } // 1
  	
  	//+- End of trading control -----------------------------------------------------------------+
  	} // B if (UserAcceptsAllLiability == true)
  return(0);
 } // A init start()
   
//+- More Pips To You , Good Luck , See You @ http://finance.groups.yahoo.com/group/MetaTrader_Experts_and_Indicators/ -+