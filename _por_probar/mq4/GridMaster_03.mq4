//+------------------------------------------------------------------+
//|                                                GridMaster_03.mq4 |
//	Name := GridMaster_03
//	Author := Copyright © 2005, Lifestatic, pip_seeker, autofx
//	Link := http://autoforex.biz
//	Notes:= This is a pure, 100% REACTIVE strategy, with no attempt at 
//         all to predict, anticipate or define a statistical edge.  
//         It limits grid size by keeping edges trimmed. This version 
//         (03) increases the profit target whenever an edge is trimmed.  
//         The ProfitIncrease input is used to indicate how much to 
//         increase the profit target.  The MaxProfitExit input is used
//	        to limit the profit target to the defined value. This version
//         also closes everything out once a day at 23:00 GMT.
//+------------------------------------------------------------------+

extern double	Lots = 1.0;
int	StopLoss = 0;
int	TakeProfit = 0;
// extern int	Trailing_Stop = 0;

// inputs;
extern int  ProfitEntry = 5; 		   // Open new trades if TotalProfit less than this value
extern int  ProfitExit = 100;       // Stop opening new trades and start closing them all if TotalProfit greater than this value
extern int  ProfitIncrease = 50;		// Dollar amount to increase profit target each time an edge is trimmed
extern int  MaxProfitExit = 500;		// Maximum profit target
extern int  MaxTrades = 50;		   // Number of Total Orders allowed
extern int  BalanceDelta = 20;      // Number of trades by which buys can exceed sells and vice versa
extern int  BucksPerPip = 1;
extern int  dFreeMargin = 1500;     // Least amount of acount margin to allow
extern int  Slippage = 2;			   // Permitted slippage for order entry
extern int  log = 0;                // Record for troubleshooting
extern string Version = "1.1";

int      MAGICGT = 20060912;
int      i, TotalOrders;
int      total, count;
double   ProfitTarget;
int      NumBuys,NumSells;
double   CumulativeBuyPrice,CumulativeSellPrice,ExitPrice;
double   BuyPL,SellPL,OverallPL;
double   HighestSell,LowestBuy,HighestBuy,LowestSell;
double   BuyNewLevel,SellNewLevel;
bool     CloseAll;
bool     EOD_close = false;
double   LargestMarginUsed,LargestFloatingLoss;
bool     CloseSwitch,CloseSellFirst,CloseBuyFirst;
double   LowestFreeMargin;
datetime TimeClock,TimeMin;
datetime LastTradeTime;
double   safety, target;
bool     LastTradeWasBuy,LastTradeWasSell;


int init() 
  {
   return(0);
  }

int start()
  {
//  Presets;

   if ((CurTime() - LastTradeTime) < 10)  return(0);
   if (AccountMargin() > LargestMarginUsed)    LargestMarginUsed   = AccountMargin();
   if (AccountProfit() < LargestFloatingLoss)  LargestFloatingLoss = AccountProfit();
   if (LowestFreeMargin == 0)                  LowestFreeMargin    = AccountFreeMargin();
   if (AccountFreeMargin() < LowestFreeMargin) LowestFreeMargin    = AccountFreeMargin();

   // check for end of trading day closeout
   if ((Hour() >= 23) && (EOD_close == false))
     {
      Print("Deleting Pending Orders");
      total=OrdersTotal();
      for(count=0; count<total; count++)
        {
         if(OrderSelect(count, SELECT_BY_POS, MODE_TRADES) == false) continue;
         if(OrderSymbol() != Symbol()) continue; // ignore trades other than the chart 

         if (log>0) Print("count ", count, " ticket ", OrderTicket(), " type ", OrderType());
         if (log>0) Print("Symbol ", Symbol(), " OrderSymbol ", OrderSymbol());

         if(OrderType()==OP_SELLLIMIT) OrderDelete(OrderTicket());
         if(OrderType()==OP_BUYLIMIT)  OrderDelete(OrderTicket());

         if(OrderType()==OP_SELLSTOP) OrderDelete(OrderTicket());
         if(OrderType()==OP_BUYSTOP)  OrderDelete(OrderTicket());
        }

      Print("Closing Open Positions");
      total=OrdersTotal();
      for(count=0; count<total; count++)
        {
         if(OrderSelect(count, SELECT_BY_POS, MODE_TRADES) == false) continue;
         if(OrderSymbol() != Symbol()) continue; // ignore trades other than the chart 

         if (log>0) Print("count ", count, " ticket ", OrderTicket(), " type ", OrderType());
         if (log>0) Print("Symbol ", Symbol(), " OrderSymbol ", OrderSymbol());
 
         if(OrderType()==OP_SELL) if (!OrderClose(OrderTicket(), OrderLots(), Ask, 3, Red)) 
                  Print ("Close error ", GetLastError());
         if(OrderType()==OP_BUY)  if (!OrderClose(OrderTicket(), OrderLots(), Bid, 3, Red)) 
                  Print ("Close error ", GetLastError());
        }

      EOD_close = true;    // flag that we have cleared the board
     }

   // Reset the End Of Day semaphore
   if ((Hour() < 23) && (EOD_close == true)) EOD_close = false;

   NumBuys = 0;
   NumSells = 0;
   CumulativeBuyPrice = 0.0;
   CumulativeSellPrice = 0.0;
   OverallPL = 0.0;

   TotalOrders = OrdersTotal();
   for (i=0; i<TotalOrders; i++)
     {
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if ((OrderSymbol() == Symbol()) && (OrderType() == OP_BUY))
           {
            NumBuys++;
            CumulativeBuyPrice += OrderOpenPrice();
           }

         if ((OrderSymbol() == Symbol()) && (OrderType() == OP_SELL))
           {
            NumSells++;
            CumulativeSellPrice += OrderOpenPrice();
           }
        }
     }

   if ((NumBuys > NumSells) && (NumSells > 0))
     {
      ExitPrice = CumulativeBuyPrice/NumBuys;
      while (OverallPL < ProfitTarget)
        {
         BuyPL  = ((BucksPerPip*NumBuys)/Point)*(ExitPrice - CumulativeBuyPrice/NumBuys);
         SellPL = ((BucksPerPip*NumSells)/Point)*(CumulativeSellPrice/NumSells - ExitPrice);
         ExitPrice += Point;
         OverallPL = BuyPL + SellPL;
        }
      if (ProfitTarget < ProfitExit) ProfitTarget = ProfitExit;

      Comment("Buy trades: ",NumBuys,", Sell trades: ",NumSells,
              "\nLargest Margin Used: ", LargestMarginUsed,", Largest Floating Loss: ", LargestFloatingLoss,", Lowest Free Margin: ", LowestFreeMargin,
              "\nBalance: ", AccountBalance(),", Equity: ", AccountEquity(),", AccountProfit: ", AccountProfit(),
              "\nHighestSell: ", HighestSell,", LowestBuy: ", LowestBuy,
              "\nHighestBuy: ",HighestBuy,", LowestSell: ", LowestSell,
              "\nGridSize: ", (HighestBuy-LowestSell)/Point," pips",
              "\nDollar Target: ", ProfitTarget,
              "\nLong Target: ", ExitPrice,
              "\n",(ExitPrice-Bid)/Point," pips from target");
     }
   else
      if ((NumSells > NumBuys) && (NumBuys > 0)) 
        {
         ExitPrice = CumulativeSellPrice/NumSells;
         while (OverallPL < ProfitTarget)
           {
            BuyPL  = ((BucksPerPip*NumBuys)/Point)*(ExitPrice - CumulativeBuyPrice/NumBuys);
            SellPL = ((BucksPerPip*NumSells)/Point)*(CumulativeSellPrice/NumSells - ExitPrice);
            ExitPrice -= Point;
            OverallPL = BuyPL + SellPL;
           }
         if (ProfitTarget < ProfitExit) ProfitTarget = ProfitExit;

         Comment("Buy trades: ",NumBuys,", Sell trades: ",NumSells,
                 "\nLargest Margin Used: ", LargestMarginUsed,", Largest Floating Loss: ", LargestFloatingLoss,", Lowest Free Margin: ", LowestFreeMargin,
                 "\nBalance: ", AccountBalance(),", Equity: ", AccountEquity(),", TotalProfit: ", AccountProfit(),
                 "\nHighestSell: ", HighestSell,", LowestBuy: ", LowestBuy,
                 "\nHighestBuy: ",HighestBuy,", LowestSell: ", LowestSell,
                 "\nGridSize: ", (HighestBuy-LowestSell)/Point," pips",
                 "\nDollar Target: ", ProfitTarget,
                 "\nLong Target: ", ExitPrice,
                 "\n",(ExitPrice-Bid)/Point," pips from target");
        }


   if ((CloseBuyFirst  == 1) || (CloseSellFirst == 1))
     {
      if (NumBuys  == 0) CloseBuyFirst  = 0;
      if (NumSells == 0) CloseSellFirst = 0;
     }
 
   // if Profit is positive, close all open positions;
   if ((AccountProfit() > ProfitTarget) && (CloseSwitch == 0))
     {
      CloseAll    = 1;
      CloseSwitch = 1;
  
      if (NumBuys  > NumSells) CloseSellFirst = 1;
      if (NumSells > NumBuys)  CloseBuyFirst  = 1;
     }

   if (TotalOrders == 0)
     {
      CloseAll    = 0;
      CloseSwitch = 0;
      ProfitTarget = ProfitExit;
     }

   if (CloseAll == 1)
     {
      TotalOrders = OrdersTotal();
      for (i=0; i<TotalOrders; i++)
        {
         if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
           {
            if (((OrderSymbol() == Symbol()) && (OrderType() == OP_BUY) && (CloseBuyFirst == 1)) ||
                ((CloseBuyFirst == 0) && (CloseSellFirst == 0)))
	           {
               if ((Bid-OrderOpenPrice()) < 0)
                 {
                  OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, LawnGreen);
                  return(0);
                 }
      
               if ((Bid-OrderOpenPrice()) > 0)
                 {
                  OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Gold);
                  return(0);	    
	              }
              }
    
            if (((OrderSymbol() == Symbol()) && (OrderType() == OP_SELL) && (CloseSellFirst == 1)) ||
                ((CloseBuyFirst == 0) && (CloseSellFirst == 0)))
              {
               if ((OrderOpenPrice()-Ask) < 0)
                 {
                  OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, HotPink);
                  return(0);
                 }

               if ((OrderOpenPrice()-Ask) > 0)
                 {
                  OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Gold);
                  return(0);
                 }
              }
           } // if OrderSelect()
        }    // for i=0 to OrdersTotal()
     }       // if CloseAll == 1

   if (CloseAll == 0) // If closing switch is set to 0, we can open new orders and adjust TPs/SLs
     {
      // Open First Trades;
      if ((NumBuys == 0) && (AccountFreeMargin() > dFreeMargin))
        {
         if (StopLoss == 0) safety = 0;
         else               safety = Bid - (StopLoss * Point);
         if (TakeProfit == 0) target = 0;
         else                 target = Ask + (TakeProfit * Point);
         if(log>0) Print("SL ", StopLoss, " safety ", safety, " TP ", TakeProfit, " target ", target );
         OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, safety, target, "", MAGICGT, 0, Blue);
         LastTradeWasBuy  = true;
         LastTradeWasSell = false;
         return(0);
        }

      if ((NumSells == 0) && (AccountFreeMargin() > dFreeMargin))
        {
         if (StopLoss == 0) safety = 0;
         else               safety = Ask + (StopLoss * Point);
         if (TakeProfit == 0) target = 0;
         else                 target = Bid - (TakeProfit * Point);
         if(log>0) Print("SL ", StopLoss, " safety ", safety, " TP ", TakeProfit, " target ", target );
         OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, safety, target, "", MAGICGT, 0, Red);
         LastTradeWasSell = true;
         LastTradeWasBuy  = false;
         return(0);
        }

      ////////////////////////////////////////////////////////
      // Determine Highest Buy and Lowest Sell;
      ////////////////////////////////////////////////////////
      LowestBuy   = 1000;
      HighestSell =    0;
      HighestBuy  =    0;
      LowestSell  = 1000;

      for (i=0; i<TotalOrders; i++)
        {
         if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
           {
            if (OrderSymbol() == Symbol())
              {
               if (OrderType() == OP_BUY)
                 {
                  if (OrderOpenPrice() < LowestBuy)  LowestBuy = OrderOpenPrice();
                  if (OrderOpenPrice() > HighestBuy) HighestBuy = OrderOpenPrice();
                 }
               if (OrderType() == OP_SELL)
                 {
                  if (OrderOpenPrice() < LowestSell)  LowestSell = OrderOpenPrice();
                  if (OrderOpenPrice() > HighestSell) HighestSell = OrderOpenPrice();
                 }
              }
           }
        } // for i = 0 to TotalOrders-1

      /////////////////////////////////////////
      //   If TotalOrders > MaxTrades, Close Highest Buy If Last Trade Was A Sell
      //   Or Close Lowest Sell If Last Trade Was A Buy
      //////////////////////////////////////////
      for (i=0; i<TotalOrders; i++)
        {
         if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
           {
            if ((LastTradeWasSell == true) &&
                (TotalOrders >  MaxTrades) &&
                (OrderSymbol() == Symbol()) &&
                (OrderType() == OP_BUY) &&
                (OrderOpenPrice() == HighestBuy))
              {
               ProfitTarget += ProfitIncrease;
               if (ProfitTarget > MaxProfitExit) ProfitTarget = MaxProfitExit;
               OrderClose( OrderTicket(), OrderLots(), Bid, Slippage, Violet);
               return(0);
              }

            if ((LastTradeWasBuy == true) &&
                (TotalOrders >  MaxTrades) &&
                (OrderSymbol() == Symbol()) &&
                (OrderType() == OP_SELL) &&
                (OrderOpenPrice() == LowestSell))
              {
               ProfitTarget += ProfitIncrease;
               if (ProfitTarget > MaxProfitExit) ProfitTarget = MaxProfitExit;
               OrderClose( OrderTicket(), OrderLots(), Ask, Slippage, Violet);
               return(0);
              }
           } // if OrderSelect()
        }    // for i = 0 to OrdersTotal()-1


      // BuyNewLevel, SellNewLevel;
      BuyNewLevel  = 0;
      SellNewLevel = 0;
      for (i=0; i<TotalOrders; i++)
        {
         if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
           {
            if (OrderSymbol() == Symbol())
              {
               if ((OrderType() == OP_BUY) && (OrderOpenPrice() == Ask)) BuyNewLevel  = 1;
               if ((OrderType() == OP_SELL) && (OrderOpenPrice() == Bid)) SellNewLevel  = 1;
              }
           }
        }  // for i = 0 to OrdersTotal-1

      ////////////////////////////////////////////////////////
      // Open additional trades on a grid
      ////////////////////////////////////////////////////////
      if ((Ask > LowestBuy) && (BuyNewLevel == 0) && (AccountProfit() < ProfitEntry) && 
          (NumBuys <= NumSells+BalanceDelta))
        {
         if (AccountFreeMargin() < dFreeMargin) return(0);
         LastTradeWasBuy  = true;
         LastTradeWasSell = false;
         if (StopLoss == 0) safety = 0;
         else               safety = Bid - (StopLoss * Point);
         if (TakeProfit == 0) target = 0;
         else                 target = Ask + (TakeProfit * Point);
         if(log>0) Print("SL ", StopLoss, " safety ", safety, " TP ", TakeProfit, " target ", target );
         OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, safety, target, "", MAGICGT, 0, Blue);
         return(0);
        }

      if ((Bid < HighestSell) && (SellNewLevel == 0) && (AccountProfit() < ProfitEntry) &&
          (NumSells <= NumBuys+BalanceDelta))
        {
         if (AccountFreeMargin() < dFreeMargin) return(0);
         LastTradeWasSell = true;
         LastTradeWasBuy  = false;
         if (StopLoss == 0) safety = 0;
         else               safety = Ask + (StopLoss * Point);
         if (TakeProfit == 0) target = 0;
         else                 target = Bid - (TakeProfit * Point);
         if(log>0) Print("SL ", StopLoss, " safety ", safety, " TP ", TakeProfit, " target ", target );
         OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, safety, target, "", MAGICGT, 0, Red);
         return(0);
        }
     }  // if CloseAll == 0
  }    // start()

// end EA


