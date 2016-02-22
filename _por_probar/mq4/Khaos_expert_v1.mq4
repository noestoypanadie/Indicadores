//+------------------------------------------------------------------+
//|                                       Khaos_expert_v1.mq4        |
//|                                              Copyright © 2005    |
//|         Copyright © 2005, sgalaise                               |
//|                                                                  |
//|    Written by MrPip from idea of sgalaise                  |                                                    |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, sgajaise"
#property link      "http:/strategybuilderfx.com/"
#include <stdlib.mqh>

extern bool Debug = false;               // Change to true to allow print

//+---------------------------------------------------+
//|Account functions                                  |
//+---------------------------------------------------+
extern bool AccountIsMini = false;      // Change to true if trading mini account
//+---------------------------------------------------+
//|Money Management                                   |
//+---------------------------------------------------+
extern bool MoneyManagement = true; // Change to false to shutdown money management controls.
                                    // Lots = 1 will be in effect and only 1 lot will be open regardless of equity.
extern double Riskpercent = 5;      // Change to whatever percent of equity you wish to risk.
extern double DecreaseFactor = 3;   // Used to decrease lot size after a loss is experienced to protect equity.  Recommended not to change.
extern double StopLoss = 0;         // Maximum pips willing to lose per position.
extern double TrailingStop = 0;     // Change to whatever number of pips you wish to trail your position with.
extern double Margincutoff = 800;   // Expert will stop trading if equity level decreases to that level.
extern double Maxtrades = 10;       // Total number of positions on all currency pairs. You can change this number as you wish.
//+---------------------------------------------------+
//|Profit controls                                    |
//+---------------------------------------------------+
extern int TakeProfit = 0;          // Maximum profit level achieved.
extern int Slippage = 10;           // Possible fix for not getting filled or closed    
//+---------------------------------------------------+
//|Indicator Variables                                |
//| Change these to try your own system               |
//| or add more if you like                           |
//+---------------------------------------------------+
extern int FasterMode = 3; //0=sma, 1=ema, 2=smma, 3=lwma, 4 = lsma
extern int FastMAPeriod =   5;
extern int SlowerMode = 1; //0=sma, 1=ema, 2=smma, 3=lwma, 4 = lsma
extern int SlowMAPeriod =   120;

//---- filter parameters
extern bool UseJuice = false;
extern int JuicePeriod= 7;
extern int JuiceLevel= 4;

extern double Lots = 1;             // standard lot size. 
extern bool Turnon = true;          // Turns expert on, change to false and no trades will take place even if expert is enabled.

//+---------------------------------------------------+
//|General controls                                   |
//+---------------------------------------------------+
string OrderText = "";
double lotMM;
int TradesInThisSymbol;
datetime LastTime;
double Sl; 
double Tr;
bool OK2Buy, OK2Sell;              // determines if buy or sell trades are allowed
bool FlatMarket;
int NumBuys, NumSells;             // Number of buy and sell trades in this symbol
bool first_time = true;            // Used to check if first call to SilverTrend


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   int handle, err;
   
    string filename=Symbol()+TimeToStr(CurTime(),TIME_DATE) + ".txt";
    
//---- 
    if (Debug)
    {
      GlobalVariableSet("MyHandle",0);
      handle = FileOpen(filename,FILE_CSV|FILE_WRITE,"\t");
      if (!GlobalVariableCheck("MyHandle"))
      {
         err = GetLastError();
         Print("Error creating Global Variable MyHandle: (" + err + ") " + ErrorDescription(err)); 
      }
      GlobalVariableSet("MyHandle",handle); 
    }
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
     int handle;
 
    if (Debug)
    {
      handle = GlobalVariableGet("MyHandle");
      FileFlush(handle);
      FileClose(handle);
      GlobalVariableDel("MyHandle");  
    }
   return(0);
  }

//+------------------------------------------------------------------+
//| Write - writes string to debug file                              |
//+------------------------------------------------------------------+
int Write(string str)
{
   int handle;
   
   handle = GlobalVariableGet("MyHandle");
   FileWrite(handle,str,"\r\n"); 
}
  

//+------------------------------------------------------------------+
//| The functions from this point to the start function are where    |
//| changes are made to test other systems or strategies.            |
//|+-----------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Juice (std deviation limit) indicator                            |
//| by Shimodax, based on  "Juice.mq4 by Perky"                      |
//| original link "http://fxovereasy.atspace.com/index"              |
//| Modified by MrPip to only calculate current value                |
//+------------------------------------------------------------------+
double Juice(int shift, int period, int level)
{
   double osma= 0;

   osma= iStdDev(NULL,0, period, MODE_EMA, 0, PRICE_CLOSE,shift) - level*Point;
      
//   if (Debug)
//   {
//      Print("FXOE-Juice is ", osma);
//      Write(" FXOE-Juice is " + DoubleToStr(osma,6));
//   }

   return (osma); // return last computed value
}

//+------------------------------------------------------------------------+
//| LSMA - Least Squares Moving Average function calculation               |
//| LSMA_In_Color Indicator plots the end of the linear regression line    |
//+------------------------------------------------------------------------+

double LSMA(int Rperiod, int shift)
{
   int i;
   double sum;
   int length;
   double lengthvar;
   double tmp;
   double wt;

   length = Rperiod;
 
   sum = 0;
   for(i = length; i >= 1  ; i--)
   {
     lengthvar = length + 1;
     lengthvar /= 3;
     tmp = 0;
     tmp = ( i - lengthvar)*Close[length-i+shift];
     sum+=tmp;
    }
    wt = sum*6/(length*(length+1));
    
    return(wt);
}

//+------------------------------------------------------------------+
//| CheckExitCondition                                               |
//| Check if any exit condition is met                               |
//+------------------------------------------------------------------+
bool CheckExitCondition(string TradeType)
{
   bool YesClose;
   double fasterMAnow, slowerMAnow, fasterMAprevious, slowerMAprevious;
   double currentCAO, previousCAO;
   
   YesClose = false;
   if (FasterMode == 4)
   {
      fasterMAnow = LSMA(FastMAPeriod, 0);
      fasterMAprevious = LSMA(FastMAPeriod,1);
   }
   else
   {
      fasterMAnow = iMA(NULL, 0, FastMAPeriod, 0, FasterMode, PRICE_CLOSE, 0);
      fasterMAprevious = iMA(NULL, 0, FastMAPeriod, 0, FasterMode, PRICE_CLOSE, 1);
   }
   if (SlowerMode == 4)
   {
      slowerMAnow = LSMA(SlowMAPeriod, 0);
      slowerMAprevious = LSMA(SlowMAPeriod,1);
   }
   else
   {
      slowerMAnow = iMA(NULL, 0, SlowMAPeriod, 0, SlowerMode, PRICE_CLOSE, 0);
      slowerMAprevious = iMA(NULL, 0, SlowMAPeriod, 0, SlowerMode, PRICE_CLOSE, 1);
   }
   currentCAO = fasterMAnow - slowerMAnow;
   previousCAO = fasterMAprevious - slowerMAprevious;
   
   if (TradeType == "BUY")    // Check for cross down
   {
      if ((currentCAO < previousCAO) && currentCAO > 0)
      {
       YesClose = true;
      }
   }
   if (TradeType == "SELL")   // Check for cross up
   {
      if ((currentCAO > previousCAO) && currentCAO < 0)
      {
       YesClose =true;
      }
   }
          
//+------------------------------------------------------------------+
//| Friday Exits                                                     |
//+------------------------------------------------------------------+

//     if(DayOfWeek()==5 && Hour()>=20) YesClose = true;

     return (YesClose);
}

//+------------------------------------------------------------------+
//| CheckEntryCondition                                              |
//| Check if entry condition is met                                  |
//+------------------------------------------------------------------+
bool CheckEntryCondition(string TradeType)
{
   bool YesTrade;
   double fasterMAnow, slowerMAnow, fasterMAprevious, slowerMAprevious;
   double currentCAO, previousCAO;
   
   YesTrade = false;
   if (FasterMode == 4)
   {
      fasterMAnow = LSMA(FastMAPeriod, 0);
      fasterMAprevious = LSMA(FastMAPeriod,1);
   }
   else
   {
      fasterMAnow = iMA(NULL, 0, FastMAPeriod, 0, FasterMode, PRICE_CLOSE, 0);
      fasterMAprevious = iMA(NULL, 0, FastMAPeriod, 0, FasterMode, PRICE_CLOSE, 1);
   }
   if (SlowerMode == 4)
   {
      slowerMAnow = LSMA(SlowMAPeriod, 0);
      slowerMAprevious = LSMA(SlowMAPeriod,1);
   }
   else
   {
      slowerMAnow = iMA(NULL, 0, SlowMAPeriod, 0, SlowerMode, PRICE_CLOSE, 0);
      slowerMAprevious = iMA(NULL, 0, SlowMAPeriod, 0, SlowerMode, PRICE_CLOSE, 1);
   }
   currentCAO = fasterMAnow - slowerMAnow;
   previousCAO = fasterMAprevious - slowerMAprevious;
   if (TradeType == "BUY")  // Check for cross up
   {
      if ((currentCAO > previousCAO) && currentCAO < 0)
      {
       YesTrade = true;
      }
   }
   if (TradeType == "SELL")   // Check for cross down
   {
      if ((currentCAO < previousCAO) && currentCAO > 0)
      {
       YesTrade =true;
      }
   }
   return (YesTrade);
}
  
//+------------------------------------------------------------------+
//| Check if filters allow trades                                    |
//| Return 0 for flat market                                         |
//| return 1 for enough juice for trading                            |
//+------------------------------------------------------------------+
int CheckFilters()
{

   if (UseJuice)
   {
   
// Check if juice is ok for trading? 

      if (Juice(1, JuicePeriod, JuiceLevel) <= 0)  return(0);
   }
   return (1);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//---- 
   int Filter;
   bool ExitBuy, ExitSell, YesTrade;
   
	int MagicNumber = 3000 + func_Symbol2Val(Symbol())*100 + func_TimeFrame_Const2Val(Period()); 

   string setup="khaos_expert_v1" + Symbol() + "_" + func_TimeFrame_Val2String(func_TimeFrame_Const2Val(Period()));

// Check for input parameter errors

   if (UseJuice && Period()!=15)
   {   
     Alert ("Juice Is Recommended for 15 Min Chart only!!");
     return(0);
   }


//+------------------------------------------------------------------+
//| Check for Open Position                                          |
//+------------------------------------------------------------------+

     ExitBuy = CheckExitCondition("BUY");
     ExitSell = CheckExitCondition("SELL");
     HandleOpenPositions(MagicNumber, ExitBuy, ExitSell);
     
// Check if any open positions were not closed

     TradesInThisSymbol = CheckOpenPositions(MagicNumber);
     
//+------------------------------------------------------------------+
//| Check if OK to make new trades                                   |
//+------------------------------------------------------------------+


   if(AccountFreeMargin() < Margincutoff) {
     return(0);}
     
// Only allow 1 trade per Symbol

   if(TradesInThisSymbol > 0) {
     return(0);}
   if(CurTime() < LastTime) {
     return(0);}

// Money Management
// Moved after open positions are closed for more available margin
     
   if(MoneyManagement)
   {
     lotMM = LotsOptimized(MagicNumber);
   }
   else {
     lotMM = Lots; // Change mm to 0 if you want the Lots parameter to be in effect
   }
   
   OrderText = ""; //Must be blank before going into the main section
   
   
	if(CheckEntryCondition("BUY"))
	{
		OrderText = "BUY";
		if (Debug)
		{
         Print ("Buy  at ", TimeToStr(CurTime()), " for ", DoubleToStr(Ask,4) );
         Write ("Buy at " + TimeToStr(CurTime())+ " for " + DoubleToStr(Ask,4));
      }
		if (StopLoss>0) {
		 Sl = Ask-StopLoss*Point;
		} else {
		 Sl=0;
		}
		if (TakeProfit == 0) 
		    Tr = 0;
		else
		    Tr = Ask+TakeProfit*Point;
	}

   
	if(CheckEntryCondition("SELL"))
	{
		OrderText = "SELL";
		if (Debug)
		{
         Print ("Sell at ", TimeToStr(CurTime()), " for ", DoubleToStr(Bid,4) );
         Write ("Sell at " + TimeToStr(CurTime())+ " for " + DoubleToStr(Bid,4));
      }
		if (StopLoss>0) {
		 Sl = Bid+StopLoss*Point;
		} else {
		 Sl = 0;
		}
		if (TakeProfit == 0) 
		    Tr = 0;
		else
		    Tr = Bid-TakeProfit*Point;
	}
   if(OrderText != "" && TradesInThisSymbol == 0 && Turnon) 
   {

	   LastTime = DoTrades(OrderText,setup,MagicNumber, lotMM,Sl,Tr,CurTime());
      return(0);
   }
//----
   return(0);
  }

//+------------------------------------------------------------------+
//| Functions beyond this point should not need to be modified       |
//| Eventually will be placed in include file                        |
//+------------------------------------------------------------------+



//+-------------------------------------------+
//| DoTrades module cut from start            |
//|  No real changes                          |
//+-------------------------------------------+
datetime DoTrades(string OrdText, string SetupStr,int MagicNum,double lotM, double SSl, double TTr, datetime LstTime)
{
   double Min_OrderPrice;
   int err,tries;
   double dtries;
   int ticket;
   datetime lsttim;

   lsttim = LstTime;
   if(OrdText == "BUY")
   {
       Min_OrderPrice=MinOrderPrice(OP_BUY, MagicNum);
       if (Min_OrderPrice>0 && Min_OrderPrice<=Ask*1.05) {
          Print("Buy too expensive => MinOrderPrice= " + Min_OrderPrice + "  Ask=" + Ask);
       } else {
           tries = 0;
           while (tries < 3)
           {
              ticket = OrderSend(Symbol(),OP_BUY,lotM,Ask,Slippage,SSl,TTr,SetupStr,MagicNum,0,Green);
              if (Debug)
              {
                 dtries = tries;
                 Print ("Buy at ",TimeToStr(CurTime())," for ",Ask, " try:",tries);
                 Write ("Buy at " + TimeToStr(CurTime()) + " for " + DoubleToStr(Ask,4) + " try:" + DoubleToStr(dtries,0));
              }
              lsttim += 12;
              if (ticket <= 0) {
                tries++;
              } else tries = 3;
           }
           if(ticket<=0) {
              err = GetLastError();
              Alert("Error opening BUY order [" + SetupStr + "]: (" + err + ") " + ErrorDescription(err)); 
              if (Debug) Write("Error opening BUY order [" + SetupStr + "]: (" + err + ") " + ErrorDescription(err)); 
           }
           return(lsttim);
       }
   }
   else if(OrdText == "SELL")
   {
       Min_OrderPrice=MinOrderPrice(OP_SELL, MagicNum);
       if (Min_OrderPrice>0 && Min_OrderPrice<=Bid) {
          Print("Sell too expensive MinOrderPrice= " + Min_OrderPrice + "  Bid=" + Bid);
       } else {
          tries = 0;
          while (tries < 3)
          {
            ticket = OrderSend(Symbol(),OP_SELL,lotM,Bid,Slippage,SSl,TTr,SetupStr,MagicNum,0,Red);
            if (Debug)
            {
               dtries = tries;
               Print ("Sell at ",TimeToStr(CurTime())," for ",Bid, " try:",tries);
               Write ("Sell at " + TimeToStr(CurTime()) + " for " + DoubleToStr(Bid,4) + " try:" + DoubleToStr(dtries,0));
             }
            lsttim += 12;
            if (ticket <= 0)
            {
              tries++;
             }else tries = 3;
           }
              
            
          if(ticket<=0) {
             err = GetLastError();
             Alert("Error opening Sell order [" + SetupStr + "]: (" + err + ") " + ErrorDescription(err)); 
             if (Debug) Write("Error opening Sell order [" + SetupStr + "]: (" + err + ") " + ErrorDescription(err)); 
           }
           return(lsttim);
        }
    }
    return(lsttim);
}

//+------------------------------------------------------------------+
//| Check Open Position Controls                                     |
//+------------------------------------------------------------------+
  
int CheckOpenPositions(int MagicNumbers)
{
   int cnt, total, NumPositions;
   int NumBuyTrades, NumSellTrades;   // Number of buy and sell trades in this symbol
   
   NumBuyTrades = 0;
   NumSellTrades = 0;
   total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
     {
      if ( OrderSelect (cnt, SELECT_BY_POS) == false )  continue;
      if ( OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumbers)  continue;
      
      if((OrderType() == OP_BUY || OrderType() == OP_BUYSTOP) && (OrderSymbol()==Symbol()))
          {
             NumBuyTrades++;
          }
             
      if((OrderType() == OP_SELL || OrderType() == OP_SELLSTOP) && (OrderSymbol()==Symbol()))
          {
             NumSellTrades++;
          }
             
     }
     NumPositions = NumBuyTrades + NumSellTrades;
     return (NumPositions);
  }


//+------------------------------------------------------------------+
//| Handle Open Positions                                            |
//| Check if any open positions need to be closed or modified        |
//| Three attempts are made to close or modify                       |
//+------------------------------------------------------------------+
int HandleOpenPositions(int MagicNum, bool BuyExit, bool SellExit)
{
   int cnt, total;
   int CloseCnt, err;
   
   total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
     {
      if ( OrderSelect (cnt, SELECT_BY_POS) == false )  continue;
      if ( OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNum)  continue;
      
      if((OrderType() == OP_BUY || OrderType() == OP_BUYSTOP) && (OrderSymbol()==Symbol()))
          {
            
            if (BuyExit)
            {
   // try to close 3 Times
      
              CloseCnt = 0;
              while (CloseCnt < 3)
              {
                if (!OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,Violet))
                {
                 err=GetLastError();
                 Print(CloseCnt," Error closing order : (", err , ") " + ErrorDescription(err));
                 if (err > 0) CloseCnt++;
                }
                else
                {
                 CloseCnt = 3;
                }
               }
             }
             else
             {
              if(TrailingStop>0) 
               {                
                 if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                  {
                     CloseCnt=0;
                     while (CloseCnt < 3)
                     {
                     if (!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Aqua))
                     {
                        err=GetLastError();
                        if (err>0) CloseCnt++;
                     }
                     else CloseCnt = 3;
                     }
                  }
                 }
              }
             }
          }

      if((OrderType() == OP_SELL || OrderType() == OP_SELLSTOP) && (OrderSymbol()==Symbol()))
          {
            if (SellExit)
            {
            
   // try to close 3 Times
      
               CloseCnt = 0;
               while (CloseCnt < 3)
               {
                 if (!OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Violet))
                 {
                  err=GetLastError();
                  Print(CloseCnt," Error closing order : ",cnt," (", err , ") " + ErrorDescription(err));
                  if (err > 0) CloseCnt++;
                 }
                 else CloseCnt = 3;
               }
             }
             else
             {
  
   // try to modify 3 Times
      
                 if(TrailingStop>0)  
                 {                
                  if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                  {
                   if(OrderStopLoss()==0.0 || OrderStopLoss()>(Ask+Point*TrailingStop))
                   {
                     CloseCnt = 0;
                     while (CloseCnt < 3)
                     {
                       if (!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Aqua))
                       {
                         err=GetLastError();
                         if (err > 0) CloseCnt++;
                       }
                       else CloseCnt = 3;
                     }
                   }
                  }
                }
             }
       }
  }
}

     
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+

double LotsOptimized(int Mnr)
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
   int    tolosses=0;
//---- select lot size
   lot=NormalizeDouble(MathFloor(AccountFreeMargin()*Riskpercent/10000)/10,1);
   
//---- calculate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL || OrderMagicNumber()!=Mnr) continue;
         //----
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      for(i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(TimeDay(OrderCloseTime()) != TimeDay(CurTime())) continue;
         //----
         if(OrderProfit()<0) tolosses++;
        }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
  
  // lot at this point is number of standard lots
  
//  if (Debug) Print ("Lots in LotsOptimized : ",lot);
  
  // Check if mini or standard Account
  
  if(AccountIsMini)
  {
    lot = MathFloor(lot);
    lot = lot / 10;
    
// Use at least 1 mini lot

   if(lot<0.1) lot=0.1;

  }else
  {
    if (lot < 1.0) lot = 1.0;
    if (lot > 100) lot = 100;
  }

   return(lot);
  }

//+------------------------------------------------------------------+
//| Time frame interval appropriation  function                      |
//+------------------------------------------------------------------+

int func_TimeFrame_Const2Val(int Constant ) {
   switch(Constant) {
      case 1:  // M1
         return(1);
      case 5:  // M5
         return(2);
      case 15:
         return(3);
      case 30:
         return(4);
      case 60:
         return(5);
      case 240:
         return(6);
      case 1440:
         return(7);
      case 10080:
         return(8);
      case 43200:
         return(9);
   }
}

//+------------------------------------------------------------------+
//| Time frame string appropriation  function                               |
//+------------------------------------------------------------------+

string func_TimeFrame_Val2String(int Value ) {
   switch(Value) {
      case 1:  // M1
         return("PERIOD_M1");
      case 2:  // M1
         return("PERIOD_M5");
      case 3:
         return("PERIOD_M15");
      case 4:
         return("PERIOD_M30");
      case 5:
         return("PERIOD_H1");
      case 6:
         return("PERIOD_H4");
      case 7:
         return("PERIOD_D1");
      case 8:
         return("PERIOD_W1");
      case 9:
         return("PERIOD_MN1");
   	default: 
   		return("undefined " + Value);
   }
}

int func_Symbol2Val(string symbol) {
	if(symbol=="AUDCAD") {
		return(1);
	} else if(symbol=="AUDJPY") {
		return(2);
	} else if(symbol=="AUDNZD") {
		return(3);
	} else if(symbol=="AUDUSD") {
		return(4);
	} else if(symbol=="CHFJPY") {
		return(5);
	} else if(symbol=="EURAUD") {
		return(6);
	} else if(symbol=="EURCAD") {
		return(7);
	} else if(symbol=="EURCHF") {
		return(8);
	} else if(symbol=="EURGBP") {
		return(9);
	} else if(symbol=="EURJPY") {
		return(10);
	} else if(symbol=="EURUSD") {
		return(11);
	} else if(symbol=="GBPCHF") {
		return(12);
	} else if(symbol=="GBPJPY") {
		return(13);
	} else if(symbol=="GBPUSD") {
		return(14);
	} else if(symbol=="NZDUSD") {
		return(15);
	} else if(symbol=="USDCAD") {
		return(16);
	} else if(symbol=="USDCHF") {
		return(17);
	} else if(symbol=="USDJPY") {
		return(18);
	} else {
		Comment("unexpected Symbol");
		return(0);
	}
}

//+------------------------------------------------------------------+
//| Average price efficiency  function                               |
//+------------------------------------------------------------------+

double MinOrderPrice(int OType, int OMagicNumber) {
double MinPrice;

   if (OrderType()==OP_BUY) {
      MinPrice=1000000;
   } else {
      MinPrice=0;
   }
 
   for(int cnt=0;cnt<OrdersTotal();cnt++)
   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      
      if(OrderType()==OType && OrderSymbol()==Symbol() && OrderMagicNumber()==OMagicNumber) {
         if (OrderType()==OP_BUY) {
            if (OrderOpenPrice()<MinPrice) {
               MinPrice=OrderOpenPrice();
            }
         } else {
            if (OrderOpenPrice()>MinPrice) {
               MinPrice=OrderOpenPrice();
            }
         }
      }
   }
   if (MinPrice==1000000) MinPrice=0;
   return(MinPrice);
   
}

