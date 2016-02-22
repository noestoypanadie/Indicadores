//+------------------------------------------------------------------+
//|                                                        Utils.mq4 |
//|                             Copyright © 2006, Paul Hampton-Smith |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Paul Hampton-Smith"
#property link      ""
#property library

// Store this file in experts\libraries and compile
// Needs utils.mqh in experts\include
// Incorporate into EA's with command   #include <utls.mqh>

#include <stdlib.mqh>

int nRetries = 5;
int nRetryDelay = 1000;

bool NewBar()
{
   static int lastBars;
   if (lastBars != Bars)
   {
      lastBars = Bars;
      return(true);
   } 
   else
   {
      return(false);
   }
}

int OpenOrders(int nSystemID = 0)
{
   int nCount = 0;
   for ( int nPosition=0 ; nPosition<OrdersTotal() ; nPosition++ )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()==Symbol() && // same symbol
         ( OrderType() == OP_BUY || OrderType() == OP_SELL ) &&
         (OrderMagicNumber() == nSystemID || nSystemID == 0) ) // same system
      {
         nCount++;
      }
   }
   return(nCount);
}

int OpenStopOrders(int nSystemID = 0)
{
   int nCount = 0;
   for ( int nPosition=0 ; nPosition<OrdersTotal() ; nPosition++ )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()==Symbol() && // same symbol
         ( OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP ) &&
         (OrderMagicNumber() == nSystemID || nSystemID == 0) ) // same system
      {
         nCount++;
      }
   }
   return(nCount);
}

void DeleteStopOrders(int nSystemID = 0)
{
   // note the shift of nPosition++ to lower in the for loop because it is not needed if an order has been deleted
   for ( int nPosition=0 ; nPosition<OrdersTotal() ; )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()==Symbol() && // same symbol
         ( OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP ) &&
         (OrderMagicNumber() == nSystemID || nSystemID == 0) ) // same system
      {
         SecureOrderDelete(OrderTicket());
      }
      else
      {
         nPosition++;
      }
   }
}

int FindOrder(int cmd, int nSystemID)
{
   for ( int nPosition=0 ; nPosition<OrdersTotal() ; nPosition++ )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()==Symbol() && // same symbol
         ( OrderType() == cmd) &&
         OrderMagicNumber() == nSystemID) // same system
      {
         return(OrderTicket());
      }
   }
}

string DayOfWeekToString(int nDayOfWeek)
{
   switch(nDayOfWeek)
   {
      case 0: return("Sunday");
      case 1: return("Monday");
      case 2: return("Tuesday");
      case 3: return("Wednesday");
      case 4: return("Thursday");
      case 5: return("Friday");
      case 6: return("Saturday");
      default: Alert("Invalid day of week ",nDayOfWeek," in function DayOfWeekToString");
   }
   return("");
}

double ATRTrailingStop(int nOrderType, int nATRlen, double dblATRmult)
{
   double dblATR = iATR(OrderSymbol(),0,nATRlen,0);
   double dblStop, dblTightestStop;
   
   switch(nOrderType)
   {
      case OP_BUY:
         dblStop = Bid - dblATRmult * dblATR;
         // can't be any closer than tightest stop allowed on the market
         dblTightestStop = Bid - MarketInfo(Symbol(),MODE_STOPLEVEL) * Point;
         if ( dblStop > dblTightestStop ) dblStop = dblTightestStop;
         break;
         
      case OP_SELL:
         dblStop = Ask + dblATRmult * dblATR;
         // can't be any closer than tightest stop allowed on the market
         dblTightestStop = Ask + MarketInfo(Symbol(),MODE_STOPLEVEL) * Point;
         if ( dblStop < dblTightestStop ) dblStop = dblTightestStop;
         break;
      
      default: Alert("Invalid nOrdertype ",nOrderType," in function ATRTrailingStop");
   }
   return(dblStop);
}

double MEMATrailingStop(int nOrderType, int nATRlen, double dblATRmult, double dblAccel)
{
   double dblATR = iATR(OrderSymbol(),0,nATRlen,0);
   double dblStopLoss = OrderStopLoss();
   double dblNewStopLoss, dblTightestStop;
   double tmp; 
   
   switch(nOrderType)
   {
      case OP_BUY:
         // can't be any closer than tightest stop allowed on the market
         dblTightestStop = Bid - MarketInfo(Symbol(),MODE_STOPLEVEL) * Point;
 
     		tmp = High[0] - dblATRmult*dblATR - dblStopLoss;
     		if (tmp > 0.0)
     		{
            dblNewStopLoss = dblStopLoss + dblAccel*tmp;
     		}
         if ( dblNewStopLoss > dblTightestStop ) dblNewStopLoss = dblTightestStop;
         break;
         
      case OP_SELL:
         // can't be any closer than tightest stop allowed on the market
         dblTightestStop = Ask + MarketInfo(Symbol(),MODE_STOPLEVEL) * Point;
 
     		tmp = Low[0] + dblATRmult*dblATR - dblStopLoss;
     		if (tmp < 0.0)
     		{
            dblNewStopLoss = dblStopLoss + dblAccel*tmp;
     		}
         if ( dblNewStopLoss < dblTightestStop ) dblNewStopLoss = dblTightestStop;
         break;
      
      default: Alert("Invalid nOrdertype ",nOrderType," in function ATRTrailingStop");
   }
   return(dblNewStopLoss);
}

      
int CompletedOrdersSince(datetime dt, int nSystemID)
{
   int nCount = 0;
   for ( int nPosition=0 ; nPosition<HistoryTotal() ; nPosition++ )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_HISTORY);
      if ( OrderSymbol()==Symbol() && // same symbol
         OrderMagicNumber() == nSystemID &&  // same system
         ( OrderType() == OP_BUY || OrderType() == OP_SELL ) && 
         OrderCloseTime() >= dt)
      {
         nCount++;
      }
   }
   return(nCount);
}

string TimeString(int hour, int minute)
{
   // used to create "05" instead of "5"
   if (minute<0 || minute>59 || hour<0 || hour>23) Alert("Incorrect parameters ",hour,":",minute," in TimeString");
   
   string strHourPad;
   if (hour >= 0 && hour <= 9) strHourPad = "0";
   else strHourPad = "";
   
   string strMinutePad;
   if (minute >= 0 && minute <= 9) strMinutePad = "0";
   else strMinutePad = "";

   return(StringConcatenate(strHourPad,hour,":",strMinutePad,minute));
}

double LastClosedOrderProfit(int nOrderType, int nSystemID)
{
   int nCount = 0;
   for ( int nPosition=HistoryTotal() ; nPosition>=0 ; nPosition-- )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_HISTORY);
      if ( OrderSymbol()==Symbol() && // same symbol
         OrderMagicNumber() == nSystemID &&  // same system
         ( OrderType() == OP_BUY || OrderType() == OP_SELL ) )
       
      {
         return(OrderProfit());
      }
   }
   return(0.0);
}

double HighLowTrailingStop(bool bLong, int nLookBack)
{
   double dblStop, dblTightestStop;
   if (bLong)
   {
      // Lowest low, minus one point to stay away from support lines
      dblStop = Low[ Lowest(OrderSymbol(),0,MODE_LOW,nLookBack) ] - Point;
      // can't be any closer than tightest stop
      dblTightestStop = Bid - MarketInfo(Symbol(),MODE_STOPLEVEL) * Point;
      if ( dblStop > dblTightestStop ) dblStop = dblTightestStop;
   }
   else
   { // short
      // Highest high, plus one point to stay away from support lines
      dblStop = High[ Highest(OrderSymbol(),0,MODE_HIGH,nLookBack) ] + Point;
      // can't be any closer than tightest stop
      dblTightestStop = Ask + MarketInfo(Symbol(),MODE_STOPLEVEL) * Point;
      if ( dblStop < dblTightestStop ) dblStop = dblTightestStop;
   }
   return(dblStop);
}

void CloseAllAtEndOfWeek(int nSystemID = 0)
{
   // exit all if time is 17:00 UTC Fridays
   if ( !(TimeDayOfWeek(Time[0]) == 5 && TimeHour(Time[0]) == 17) ) return;
   
   for ( int nPosition=0 ; nPosition<OrdersTotal() ; )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()==Symbol() && // same symbol
         (OrderMagicNumber() == nSystemID || nSystemID == 0) &&  // same system
         ( OrderType() == OP_BUY || OrderType() == OP_SELL ) )
      {
         Print("End of week close ", TimeToStr(Time[0]));
         switch(OrderType())
         {
         case OP_BUY:
            OrderClose(OrderTicket(), OrderLots(), Bid, 0, Purple);
            return;
               
         case OP_SELL:
            OrderClose(OrderTicket(), OrderLots(), Ask, 0, Purple);
            return;

         case OP_BUYSTOP:
            OrderDelete(OrderTicket());
            return;

         case OP_SELLSTOP:
            OrderDelete(OrderTicket());
            return;
         } // switch
      }
      else
      {
         nPosition++;
      }
   }
}

datetime WeeklyExpirationTime(int nExitDay, int nExitHour, int nExitMinute)
{
   datetime dtNow = CurTime();
   datetime dtMidnightToday = (dtNow/86400)*86400;
   int nDaysToExit = nExitDay - TimeDayOfWeek(dtNow);

   datetime dtExitTime = dtMidnightToday + nDaysToExit*86400 + nExitHour*3600 + nExitMinute*60;
   return(dtExitTime);
}

void AdjustTrailingStops(int nTrailingStop, int nSystemID = 0)
{
   for ( int nPosition=0 ; nPosition<OrdersTotal() ; nPosition++ )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()==Symbol() && (OrderMagicNumber() == 0 || OrderMagicNumber() == nSystemID) ) // same symbol and system
      {
         switch(OrderType())
         {
         case OP_BUY:
            // adjust long trailing stop up if possible
            if (Bid - nTrailingStop*Point > OrderStopLoss() )
            {
               OrderModify(OrderTicket(),OrderOpenPrice(),Ask - nTrailingStop*Point,OrderTakeProfit(),0,Green);
            }
            break;
               
         case OP_SELL:
            // adjust short trailing stop down if possible
            if (Ask + nTrailingStop*Point < OrderStopLoss() || OrderStopLoss() == 0.0 )
            {
               OrderModify(OrderTicket(),OrderOpenPrice(),Bid + nTrailingStop*Point,OrderTakeProfit(),0,Red);
            }
         } // switch
      } 
   }
}

bool OrderOfTypeExists(int nOrderType, int nSystemID = 0)
{
   for ( int nPosition=0 ; nPosition<OrdersTotal() ; nPosition++ )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()==Symbol()
         && (OrderMagicNumber() == 0 || OrderMagicNumber() == nSystemID)
         && OrderType() == nOrderType ) // same symbol, system & type
      {
         return(true);
      }
   }
}
   
datetime ServerTime(datetime UTC)
{
   // Uses global variable UTCtoServerTimeInMinutes to convert UTC to server time.
   // this enables different instances of MT4 using different brokers to 
   // run EAs with idential time settings
   if (!GlobalVariableCheck("UTCtoServerTimeInMinutes"))
   {
      Alert("Please set global variable UTCtoServerTimeInMinutes");
      return(0);
   }
   return(UTC+60*GlobalVariableGet("UTCtoServerTimeInMinutes"));
}
   
   
void CloseOrdersAfterDuration(int nSeconds, int nSystemID = 0)
{
   for ( int nPosition=0 ; nPosition<OrdersTotal() ;  )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()==Symbol() && 
         (OrderMagicNumber() == nSystemID || nSystemID == 0) &&
         Time[0] > OrderOpenTime() + nSeconds)
      {
         switch (OrderType())
         {
         case OP_BUY: SecureOrderClose(OrderTicket(), OrderLots(), Bid, 5, Purple); break;
         case OP_SELL: SecureOrderClose(OrderTicket(), OrderLots(), Ask, 5, Purple); break;
         }
      }
      else
      {
         nPosition++;
      }
   }
}

void CloseOrdersAtTime(datetime dt, int nSystemID = 0)
{
   // note the shift of nPosition++ to lower in the for loop because it is not needed if an order has been closed
   for ( int nPosition=0 ; nPosition<OrdersTotal() ; )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()==Symbol() && 
         (OrderMagicNumber() == nSystemID || nSystemID == 0) &&
         CurTime() > dt)
      {
         switch (OrderType())
         {
         case OP_BUY: SecureOrderClose(OrderTicket(), OrderLots(), Bid, 5, Purple); break;
         case OP_SELL: SecureOrderClose(OrderTicket(), OrderLots(), Ask, 5, Purple); break;
         }
      }
      else
      {
         nPosition++;
      }
   }
}

void DeleteStopOrdersAtTime(datetime dt, int nSystemID = 0)
{
   // note the shift of nPosition++ to lower in the for loop because it is not needed if an order has been deleted
   for ( int nPosition=0 ; nPosition<OrdersTotal() ; )
   {
      SecureOrderSelect(nPosition, SELECT_BY_POS);
      if ( OrderSymbol()==Symbol() && 
         (OrderMagicNumber() == nSystemID || nSystemID == 0) &&
         CurTime() > dt &&
         (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP))
      {
         SecureOrderDelete(OrderTicket());
      }
      else
      {
         nPosition++;
      }
   }
}

int SecureOrderSend( string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment, int magic=0, datetime expiration=0, color arrow_color=CLR_NONE)
{
   if (cmd == OP_SELL || cmd == OP_SELLLIMIT || cmd == OP_BUY || cmd == OP_BUYLIMIT)
   {
      Alert(CmdToStr(cmd)," not implemented yet in SecureOrderSend");
      return(-1);
   }
   
   for (int nTry = 0 ; nTry < nRetries ; nTry++)
   {
      double dblMinStopDistance = MarketInfo(Symbol(),MODE_STOPLEVEL)*Point;
      if (cmd == OP_BUYSTOP)
      {
         price = MathMax(Ask+dblMinStopDistance+Point,price);
         if (stoploss == 0)
            stoploss = price-dblMinStopDistance-Point;
         else
            stoploss = MathMin(price-dblMinStopDistance-Point, stoploss);
         
      }
      else if (cmd == OP_SELLSTOP)
      {
         if (price == 0) 
            price = Bid-dblMinStopDistance-Point;
         else 
            price = MathMin(Bid-dblMinStopDistance-Point,price);
         stoploss = MathMax(price+dblMinStopDistance+Point, stoploss);
      }
      
      price = NormalizeDouble(price,Digits);
      stoploss = NormalizeDouble(stoploss,Digits);
      takeprofit = NormalizeDouble(takeprofit,Digits);
      int nTicket = OrderSend( symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic, expiration, arrow_color);
      int nLastError = GetLastError();
      Print(ErrorDescription(nLastError)," for SecureOrderSend(",CmdToStr(cmd),"): Ask ",Ask," Bid ",Bid," MinStop ",dblMinStopDistance," price ", price," stoploss ",stoploss," takeprofit ", takeprofit);
      if (nLastError == 0) return(nTicket);
      Sleep(nRetryDelay);
   }
   return(-1);
}

bool SecureOrderClose( int ticket, double lots, double price, int slippage, color Color=CLR_NONE)
{
   for (int nTry = 0 ; nTry < nRetries ; nTry++)
   {
      OrderClose(ticket, lots, price, slippage, Color);
      int nLastError = GetLastError();
      Print(ErrorDescription(nLastError)," for SecureOrderClose. price ",price);
      if (nLastError == 0) return(true);
      Sleep(nRetryDelay);
   }
   return(false);
}

bool SecureOrderDelete(int ticket)
{
   for (int nTry = 0 ; nTry < nRetries ; nTry++)
   {
      OrderDelete(ticket);
      int nLastError = GetLastError();
      Print(ErrorDescription(nLastError)," for SecureOrderDelete");
      if (nLastError == 0) return(true);
      Sleep(nRetryDelay);
   }
   return(false);
}

bool SecureOrderSelect( int index, int select, int pool=MODE_TRADES) 
{
   for (int nTry = 0 ; nTry < nRetries ; nTry++)
   {
      OrderSelect( index, select, pool);
      int nLastError = GetLastError();
      if (nLastError == 0 && OrderTicket() != 0) return(true);
      else Print(ErrorDescription(nLastError)," for SecureOrderSelect");
   }
   return(false);
}

string CmdToStr(int cmd)
{
   switch(cmd)
   {
   case OP_BUY: return("OP_BUY");
   case OP_SELL: return("OP_SELL");
   case OP_BUYSTOP: return("OP_BUYSTOP");
   case OP_SELLSTOP: return("OP_SELLSTOP");
   case OP_BUYLIMIT: return("OP_BUYLIMIT");
   case OP_SELLLIMIT: return("OP_SELLLIMIT");
   default: return("OP_UNKNOWN");
   }
}      
       
double ClosestStopLoss(int cmd, double dblPrice)
{
   double dblMinStopDistance = MarketInfo(Symbol(),MODE_STOPLEVEL)*Point;
   
   switch(cmd)
   {
   case OP_BUY:
   case OP_BUYLIMIT:
   case OP_BUYSTOP:
      return(NormalizeDouble(dblPrice-dblMinStopDistance,Digits));
      
   case OP_SELL:
   case OP_SELLLIMIT:
   case OP_SELLSTOP:
      return(NormalizeDouble(dblPrice+dblMinStopDistance,Digits));

   default:
      Alert("Invalid cmd ",cmd," in MinStopLoss");
   }
}
       
double ClosestBuySellStopPrice(int cmd)
{
   double dblMinStopDistance = MarketInfo(Symbol(),MODE_STOPLEVEL)*Point;
   
   switch(cmd)
   {
   case OP_BUYSTOP:
      return(Ask+dblMinStopDistance);
      
   case OP_SELLSTOP:
      return(Bid-dblMinStopDistance);
      
   default:
      Alert("Invalid cmd ",CmdToStr(cmd)," in ClosestBuySellStopPrice");
   }
   return(0);
}
    
    
void CloseAfterPeak(int nTrailingStop, int nSlippage, int nSystemID = 0, datetime AfterTime = 0)
{
   // client side stoploss. If internet connection is broken this will fail! 
   // Ensure that initial stop is also set to control risk
   static double dblMinAsk = 999;
   static double dblMaxBid = 0;

   for ( int nPosition=0 ; nPosition<OrdersTotal() ; nPosition++ )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()==Symbol() && (OrderMagicNumber() == 0 || OrderMagicNumber() == nSystemID) ) // same symbol and system
      {
         if (AfterTime == 0 || CurTime() > AfterTime)
         {
            dblMaxBid = MathMax(dblMaxBid, Bid);
            dblMinAsk = MathMin(dblMinAsk, Ask);
            
            switch(OrderType())
            {
            case OP_BUY:
               if (Bid <= dblMaxBid - nTrailingStop*Point)
               {
                  Print("Close Buy order after peak of ",dblMaxBid," Bid ",Bid," TrailingStop ", nTrailingStop);
                  if (SecureOrderClose( OrderTicket(), OrderLots(), Bid, nSlippage, Turquoise)) dblMaxBid = 0;
               }
               break;
               
            case OP_SELL:
               if (Ask >= dblMinAsk + nTrailingStop*Point)
               {
                  Print("Close Sell order after peak of ",dblMinAsk," Ask ",Ask," TrailingStop ", nTrailingStop);
                  if (SecureOrderClose( OrderTicket(), OrderLots(), Ask, nSlippage, Coral)) dblMinAsk = 999;
               }
               break;
            }
         } 
      }
   }
}
   