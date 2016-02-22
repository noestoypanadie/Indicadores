//+------------------------------------------------------------------+
//|                                          MACD SampleTraining.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//| This expert will be used as a starting point to learn how to     |
//| write program code for an EA in a progressive and modular method |
//| This EA has comments added to show where possible functions      |
//| could be used to make the EA more modular.                       |
//| For now, beginning programmers need to trust that this is a good |
//| way to develop an EA.                                            |
//| Once a function is completed and proven to work it becomes       |
//| easier to modify the function when a better method is found      |
//| without needing to find all of the places the function is used.  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Define inputs to the expert                                      |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Inputs used by all experts                                       |
//+------------------------------------------------------------------+
extern double TakeProfit = 50;   // How many pips movement before trade is closed
extern double Lots = 0.1;        // How many lots to use for each trade
extern double TrailingStop = 30; // Using standard trailing stop how many pips for trail

//+------------------------------------------------------------------+
//| Inputs unique to this expert                                     |
//| These are usually the inputs to indicators for determining       |
//| when to place a trade.                                           | 
//+------------------------------------------------------------------+
extern double MACDOpenLevel=3;   // Open a trade when MACD is above this level
extern double MACDCloseLevel=2;  // Close a trade when MACD drops below this level
extern double MATrendPeriod=26;  // Period for the MA used to determine trend

//+------------------------------------------------------------------+
//| Define global variables                                          |
//+------------------------------------------------------------------+

int start()
  {
   double MacdCurrent, MacdPrevious, SignalCurrent;
   double SignalPrevious, MaCurrent, MaPrevious;
   int cnt, ticket, total;
//+-------------------------------------------------------------------+
//|                                                                   |
//| initial data checks                                               |
//| it is important to make sure that the expert works with a normal  |
//| chart and the user did not make any mistakes setting external     |
//| variables (Lots, StopLoss, TakeProfit,                            |
//| TrailingStop) in our case, we check TakeProfit                    |
//| on a chart of less than 100 bars                                  |
//+-------------------------------------------------------------------+

   if(Bars<100)
     {
      Print("bars less than 100");
      return(0);  
     }
//+-------------------------------------------------------------------+
//| What about when we do not want to use TakeProfit to exit a trade? |
//| In other words TakeProfit = 0                                     |
//+-------------------------------------------------------------------+
   if(TakeProfit<10)
     {
      Print("TakeProfit less than 10");
      return(0);  // check TakeProfit
     }
//+-------------------------------------------------------------------+
//| End of Initial Data Checks                                        |
//+-------------------------------------------------------------------+
//+-------------------------------------------------------------------+
//| Begin of Order Entry                                              |
//+-------------------------------------------------------------------+
// to simplify the coding and speed up access
// data are put into internal variables
   MacdCurrent=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
   MacdPrevious=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
   SignalCurrent=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0);
   SignalPrevious=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
   MaCurrent=iMA(NULL,0,MATrendPeriod,0,MODE_EMA,PRICE_CLOSE,0);
   MaPrevious=iMA(NULL,0,MATrendPeriod,0,MODE_EMA,PRICE_CLOSE,1);

// OrdersTotal() tells you how many orders are open but not how many for this currency pair

   total=OrdersTotal();
   if(total<1) 
     {
      // no opened orders identified
//+-------------------------------------------------------------------+
//| check if we have enough money to place a trade                    |
//+-------------------------------------------------------------------+
      if(AccountFreeMargin()<(1000*Lots))
        {
         Print("We have no money. Free Margin = ", AccountFreeMargin());
         return(0);  
        }
//+-------------------------------------------------------------------+
//| check for long position (BUY) possibility                         |
//+-------------------------------------------------------------------+
// check for long position (BUY) possibility
//
// A buy is made when all of the following rules are met.
// 1. the MACD is below 0
// 2. there is a fresh MACD cross up
// 3.  MACD is above the Open Level used as an input to the EA
//     MathAbs(MacdCurrent) means use MACD without the + or - sign
//     So MathAbs(2) and MathAbs(-2) both return the value of 2
// 4. MA shows the trend is up
//
// The idea of using rules will be explained in more detail
// when the EA is optimized for speed

      if(MacdCurrent<0 && MacdCurrent>SignalCurrent && MacdPrevious<SignalPrevious &&
         MathAbs(MacdCurrent)>(MACDOpenLevel*Point) && MaCurrent>MaPrevious)
        {
         ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,Ask+TakeProfit*Point,"macd sample",16384,0,Green);

// Check if the trade was placed successfully

         if(ticket>0)
           {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
           }
         else Print("Error opening BUY order : ",GetLastError()); 
         return(0); 
        }
//+-------------------------------------------------------------------+
//| check for short position (SELL) possibility                       |
//+-------------------------------------------------------------------+
// A sell is made when all of the following rules are met.
// 1. the MACD is above 0
// 2. there is a fresh MACD cross down
// 3. MACD is above the Open Level used as an input to the EA
// 4. MA shows the trend is down

      if(MacdCurrent>0 && MacdCurrent<SignalCurrent && MacdPrevious>SignalPrevious && 
         MacdCurrent>(MACDOpenLevel*Point) && MaCurrent<MaPrevious)
        {
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,Bid-TakeProfit*Point,"macd sample",16384,0,Red);
// Check if the trade was placed successfully
         if(ticket>0)
           {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
           }
         else Print("Error opening SELL order : ",GetLastError()); 
         return(0); 
        }
      return(0);
     }
//+-------------------------------------------------------------------+
//| End of Order Entry                                                |
//+-------------------------------------------------------------------+
     
//+-------------------------------------------------------------------+
//| Begin Handle Open Orders                                          |
//+-------------------------------------------------------------------+
   // it is important to enter the market correctly, 
   // but it is more important to exit it correctly...   
   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL &&   // check for opened position 
         OrderSymbol()==Symbol())  // check for symbol
        {
         if(OrderType()==OP_BUY)   // long position is opened
           {
//+-------------------------------------------------------------------+
//|   should buy trade be closed?                                     |
//+-------------------------------------------------------------------+
// A buy is closed when all of the following rules are met.
// 1. the MACD is above 0
// 2. there is a fresh MACD cross down
// 3. MACD is above the Close Level used as an input to the EA
           
            if(MacdCurrent>0 && MacdCurrent<SignalCurrent && MacdPrevious>SignalPrevious &&
               MacdCurrent>(MACDCloseLevel*Point))
                {
                 OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // close position
                 return(0); // exit
                }
//+-------------------------------------------------------------------+
//| check for trailing stop                                           |
//+-------------------------------------------------------------------+
            if(TrailingStop>0)  
              {                 
//+-------------------------------------------------------------------+
// This is a standard trailing stop method
// No move of the StopLoss is made until the movement of the
// price exceeds the value of the TrailingStop
// This usually benefits the broker.
// How often have you used a limit order to capture 30 pips and seen
// price reverse at 25 pips only to close the trade for a loss.
// With this type of trailing stop and default of 30
// the StopLoss would have never been modified
// There are other methods of trailing stops that will help this
// situation that will be presented when this becomes a function
//+-------------------------------------------------------------------+

               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                     return(0);
                    }
                 }
              }
           }
         else // go to short position
           {
//+-------------------------------------------------------------------+
//|   should sell trade be closed?                                    |
//+-------------------------------------------------------------------+
// A sell is closed when all of the following rules are met.
// 1. the MACD is below 0
// 2. there is a fresh MACD cross up
// 3. MACD is above the Close Level used as an input to the EA
//    Note use of MathAbs here

            if(MacdCurrent<0 && MacdCurrent>SignalCurrent &&
               MacdPrevious<SignalPrevious && MathAbs(MacdCurrent)>(MACDCloseLevel*Point))
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close position
               return(0); // exit
              }
//+-------------------------------------------------------------------+
//| check for trailing stop                                           |
//+-------------------------------------------------------------------+

            if(TrailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
                     return(0);
                    }
                 }
              }
           }
        }
     }
//+-------------------------------------------------------------------+
//| End Handle Open Orders                                            |
//+-------------------------------------------------------------------+
   return(0);
  }
// the end.