//+------------------------------------------------------------------+
//|                                             HedgeTraderv1023.mq4 |
//|                                         Copyright © 2006, Kickas |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Kickas."
#property link      "http://"

//#property version      "1.023"
// DISCLAIMER ***** IMPORTANT NOTE ***** READ BEFORE USING ***** 
//
// The author has no pretentions as to the profitability of this system and does not 
// suggest the use of this EA other than for testing purposes in demo accounts.
// Use of this system is free, but you may not resell it, and is without any 
// garantee as to its suitability for any purpose.
// By using this program you implicitly acknowledge that you understand 
// what it does and agree that the author bears no responsibility for any losses.
// Before using, please also check with your broker that his systems are adapted 
// for the frequest trades associated with this expert.
//
//           HedgeTrader v1.00   - First Release -
// Changes - HedgeTrader v1.01 : Former version opened too many unwanted orders even if the code 
//                               didn't open these orders. The reason may be that Metatrader cannot 
//                               handle some function fast enough so I added the Time[] funcion 
//                               to prevent these unwanted orders. The nice effect is it seem 
//                               to generate more profit than before :)
// Changes - HedgeTrader v1.02 : Found some bugs and corrected them, adjusted some code and added 
//                               error functions to all tradingfunctions.
// Changes - HedgeTrader v1.021: Cleaned some code and restructed pointers for order and close functions.
// Changes - HedgeTrader v1.022: Changed Ask and Bid functions to MarketInfo(xxx) function for more safety.
// Changes - hedgeTrader v1.023: Partly rewritten and new strategy. Starting with hedging-pair. After an order closed by
//                               trailstoploss, an another with same direction as opened order will open.
//
extern int     Risk = 25;                    // Over 50 % risk not recommended.
extern double  Lots=0.1;                     // If MoneyManagement is off.
extern int     Slippage=3;                   // Slippage > 1 recommended.
extern bool    AccountIsMicro = false;       // If you use MicroAccount with minilots.
extern bool    UseMoneyManagement = true;    // MoneyManagement. More profit at the long run, but also more risk due to the equity maybe will fall.
extern bool    DuplicateOrders = false;       // If duplicateOrders is enabled it will open same type of order who is open after closed positive order. More risk but it 'can' generate more profit.
extern int     TakeProfit = 15;              // While hedging, this setting will wait until the profit pass the level before trailstoploss will activate.
extern int     TrailStopLoss = 10;            // Trailingstoploss will be active when profit reach TakeProfit. Profit will be reduced by stoploss. Setting like TP=12 and SL=8 will give minimum 12-8=4 pips in profit.
extern int     AllowPip = 3;                 // "Opposite stoploss" - how many pip(s) you want to allow before the opening the second order.
////////////////////////////////////////////////////
// Internal variables only, please do not change! //
////////////////////////////////////////////////////
bool    sell = false;
bool    buy = false;
double  LastHighestAsk = 0;
double  LastLowestBid = 0;
double  lotMM = 0;
double sl = 0;
int     i,MagicNumber,err,ticket;
string  comment ="HedgeTrader v1.023";
////////////////////////////////////////////////////

//+------------------------------------------------------------------+
//| Symbol_To_Value - Used by MagicNumber                            |
//+------------------------------------------------------------------+
int Symbol_To_Value(string symbol) 
{
	if     (symbol=="AUDCAD") { return(10); }
   else if(symbol=="AUDCHF") { return(11); }
   else if(symbol=="AUDJPY") { return(12); }
   else if(symbol=="AUDNZD") { return(13); }
	else if(symbol=="AUDUSD") { return(14); }
	else if(symbol=="CADCHF") { return(20); }
	else if(symbol=="CADJPY") { return(21); }
	else if(symbol=="CHFJPY") { return(30); }
	else if(symbol=="EURAUD") { return(40); }
	else if(symbol=="EURCAD") { return(41); }
	else if(symbol=="EURCHF") { return(42); }
	else if(symbol=="EURGBP") { return(43); }
	else if(symbol=="EURJPY") { return(44); }
   else if(symbol=="EURUSD") { return(45); }
	else if(symbol=="GBPAUD") { return(50); }
	else if(symbol=="GBPCAD") { return(51); }
	else if(symbol=="GBPCHF") { return(52); }
	else if(symbol=="GBPJPY") { return(53); }
	else if(symbol=="GBPUSD") { return(54); }
	else if(symbol=="NZDCHF") { return(60); }
	else if(symbol=="NZDJPY") { return(61); }
	else if(symbol=="NZDUSD") { return(62); }
	else if(symbol=="USDCAD") { return(70); }	
	else if(symbol=="USDCHF") { return(71); }
	else if(symbol=="USDJPY") { return(72); }
   else { Comment("unexpected Symbol"); }
}
//+------------------------------------------------------------------+
//| LotSize - Detemine the size of the Lot(s) if UseManagement is on.|
//+------------------------------------------------------------------+
double LotSize()
{
   if( AccountFreeMargin()/AccountBalance()<(Risk / 100) * 2 ) 
   {
      Print ("Not enough margin to order");
      return(0);
   }
   lotMM = (AccountFreeMargin() * Risk / 1000) / 100; 
         
   if (AccountIsMicro==false)
   {
      if (lotMM < 0.2)                    lotMM = 0.1;
      if ((lotMM > 0.2) && (lotMM < 0.3)) lotMM = 0.2;
      if ((lotMM > 0.3) && (lotMM < 0.4)) lotMM = 0.3;
      if ((lotMM > 0.4) && (lotMM < 0.5)) lotMM = 0.4;
      if ((lotMM > 0.5) && (lotMM < 0.6)) lotMM = 0.5;
      if ((lotMM > 0.6) && (lotMM < 0.7)) lotMM = 0.6;
      if ((lotMM > 0.7) && (lotMM < 0.8)) lotMM = 0.7;
      if ((lotMM > 0.8) && (lotMM < 0.9)) lotMM = 0.8;
      if ((lotMM > 0.9) && (lotMM < 1.0)) lotMM = 0.9;
      if ((lotMM > 1.0) && (lotMM < 1.5)) lotMM = 1;
      if ((lotMM > 1.5) && (lotMM < 2))   lotMM = 1.5;
      if (lotMM > 2) lotMM = (MathCeil(lotMM)-1);
      if (lotMM > 200) lotMM = 200;
   }
   else
   {
      if (lotMM < 0.02)                      lotMM = 0.01;
      if ((lotMM > 0.02) && (lotMM < 0.03))  lotMM = 0.02;        
      if ((lotMM > 0.03) && (lotMM < 0.1))   lotMM = 0.05;
      if ((lotMM > 0.1)  && (lotMM < 0.2))   lotMM = 0.1;
      if ((lotMM > 0.2)  && (lotMM < 0.5))   lotMM = 0.2;
      if ((lotMM > 0.5)  && (lotMM < 1))     lotMM = 0.5;
      if ((lotMM > 1)    && (lotMM < 1.5))   lotMM = 1;
      if ((lotMM > 1.5)  && (lotMM < 2))     lotMM = 1.5;
      if (lotMM > 2) lotMM = (MathCeil(lotMM)-1);
      if (lotMM > 100) lotMM = 100;  
   }
   return (lotMM);
}
//+------------------------------------------------------------------+
//| CountOrders - Counting the orders if avaliable.                  |
//+------------------------------------------------------------------+
int CountOrders(int MagicNO) 
{
   int total = OrdersTotal();   
   int extotal = 0; 
   int cnt;  
   for(cnt = 0 ; cnt < total ; cnt++)   
   {      
      OrderSelect(cnt, SELECT_BY_POS,MODE_TRADES);   
      if (OrderMagicNumber()==MagicNO)      
      extotal++;    
   }
   return (extotal);
}

int CheckOrder(int MagicNO)
{
   for (i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i, SELECT_BY_POS,MODE_TRADES);
      if (OrderMagicNumber() == MagicNO)
      {
         if (OrderType() == OP_BUY) return (OP_BUY);
         if (OrderType() == OP_SELL) return (OP_SELL);
      }
   }
}

//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
   MagicNumber = 10000 + Symbol_To_Value(Symbol())*100;
   
   if (CountOrders(MagicNumber) == 0) // No orders detected, open new buy and sell order - hedging.
   {
      RefreshRates();
      if (UseMoneyManagement == true) Lots = LotSize();
      MagicNumber = 10000 + Symbol_To_Value(Symbol())*100;
      
      ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,comment,MagicNumber,0,Blue);
      if (ticket < 1)
      {
         err = GetLastError();
         Print ("Error : ",err);
      }
      
      ticket = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,comment,MagicNumber,0,Red);   
      if (ticket < 1)
      {
         err = GetLastError();
         Print ("Error : ",err);
      }
            
      buy=false;
      sell=false;
   }
   else // Order(s) detected.
   {   
      for (i=0;i<OrdersTotal();i++)
      {
         OrderSelect(i,SELECT_BY_POS);
         if (OrderMagicNumber() == MagicNumber)
         {
            if (OrderType() == OP_BUY)
            {
               if (buy == false)
               {
                  if (OrderProfit() > 0)
                  {
                     if ((Bid - OrderOpenPrice()) > TakeProfit*Point)
                     {
                        if (OrderStopLoss() < (Bid - TrailStopLoss*Point))
                        {
                           sl = Bid - TrailStopLoss*Point;
                           ticket = OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,Pink);
                           if (ticket < 1)
                           {
                              err = GetLastError();
                              Print ("Error : ",err);
                              return(0);
                           }  
                        }
                     }
                  }
               }
            }
        
            if (OrderType() == OP_SELL)
            {
               if (sell == false)
               {
                  if (OrderProfit() > 0)
                  {
                     if ((OrderOpenPrice() - Ask) > TakeProfit*Point) 
                     {   
                        if (OrderStopLoss() == 0 || (Ask + TrailStopLoss*Point) < OrderStopLoss())
                        {
                           sl = Ask + TrailStopLoss*Point;
                           ticket = OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,Pink);
                           if (ticket < 1)
                           {
                              err = GetLastError();
                              Print ("Error : ",err);
                              return(0);
                           }
                        }
                     }
                  }
               }
            }         
                   
            if (CountOrders(MagicNumber) == 1)
            {
               if (CheckOrder(MagicNumber) == OP_BUY)
               {
                  if (DuplicateOrders == true)
                     buy = true;
                  else
                     sell = true;
               }
               else
               {
                  if (DuplicateOrders == true)
                     sell = true;
                  else
                     buy = true;
               }   
            
               if (buy == true)
               {
                  if (LastLowestBid > Bid || LastLowestBid == 0)
                     LastLowestBid = 0;
               
                  if ((Ask - LastLowestBid) > AllowPip*Point) // Order a new buy order. 
                  {
                  
                     if (UseMoneyManagement == true) Lots = LotSize();
                     MagicNumber = 10000 + Symbol_To_Value(Symbol())*100;
                     RefreshRates();
                     ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,comment,MagicNumber,0,Blue);
                     if (ticket < 1)
                     {
                        err = GetLastError();
                        Print ("Error : ",err);
                        return(0);
                     }
                     buy = false;
                     LastLowestBid = 0; 
                     return(0);
                  }
               }
         
               if (sell == true)
               {
                  if (LastHighestAsk < Ask)
                     LastHighestAsk = Ask;
               
                  if ((LastHighestAsk - Bid) > AllowPip*Point) // Order a new sell order. 
                  {
                  
                     if (UseMoneyManagement == true) Lots = LotSize();
                     MagicNumber = 10000 + Symbol_To_Value(Symbol())*100;
                     RefreshRates();
                     ticket = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,comment,MagicNumber,0,Red);      
                     if (ticket < 1)
                     {
                        err = GetLastError();
                        Print ("Error : ",err);
                        return(0);
                     }
                     sell = false;
                     LastHighestAsk = 0;
                     return(0);
                  }
               }
            }
         }
      }
   }
   return(0);   
}
//+------------------------------------------------------------------+