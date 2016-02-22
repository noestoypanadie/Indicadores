//+------------------------------------------------------------------+
//|                                           PerkyProNrtr_v3.mq4    |
//|                      perky Aint no turkey (most of the time)     |
//|                                                                  |
//| 10/18/2006 Robert Hill                                           |
//|                                                                  |
//|         Version 1.2                                              |
//|            Cleaned up code for easier modification and speed     |
//|            by making more modular and calling custom indicators  |
//|            only where needed.                                    |
//|                                                                  |
//|         Version 1.3                                              |
//|            Added Money Management, Trailing Stop function        |
//|             and Magic Number                                     |
//|            Added code to use correct value for StopLoss          |
//|             and to normalize all price data sent to server       |
//|            Uses current price from MarketInfo                    |
//|             instead of Bid and Ask                               | 
//|                                                                  |
//|  10/20/2006 Perky                                                |
//|                                                                  | 
//|            Version 1.4                                           |
//|            Added check (optional) to check condition of          |  
//|            indicators - and to wait for a change of status       |
//|            before mmencing trading - so it just doesnt           |
//|            jump into  a trade on opening expert.                 |
//|                                                                  |                  
//+------------------------------------------------------------------+

// Version 1.3 
#include <stdlib.mqh>
#include <stderror.mqh> 

 bool Debug = false;
//+---------------------------------------------------+
//|Account functions                                  |
//+---------------------------------------------------+
extern bool AccountIsMini = true;      // Change to true if trading mini account
//+---------------------------------------------------+
//|Money Management                                   |
//+---------------------------------------------------+
extern bool MoneyManagement = true; // Change to false to shutdown money management controls.
                                    // Lots = 1 will be in effect and only 1 lot will be open regardless of equity.
extern double TradeSizePercent = 10;      // Change to whatever percent of equity you wish to risk.
extern double Lots = 0.1;             // standard lot size. 
double MaxLots = 100;
 
//+---------------------------------------------------+
//|Profit controls                                    |
//+---------------------------------------------------+
extern double StopLoss = 80;        // Maximum pips willing to lose per position.
 double Margincutoff = 800;   // Expert will stop trading if equity level decreases to that level.
extern bool UseTrailingStop = true;
extern int TrailingStopType = 1;        // Type 1 moves stop immediately, Type 2 waits til value of TS is reached
extern double TrailingStop = 25;    // Change to whatever number of pips you wish to trail your position with.
extern int TakeProfit = 0;          // Maximum profit level achieved.
extern int Slippage = 3;           // Possible fix for not getting filled or closed    

extern int SignalCandle=1;

    bool TradeAllowed=false;
   
double lotMM;
int MagicNumber;
string setup = "";
int totalTries = 5; 
int retryDelay = 1000;

int init() 
{
	MagicNumber = 4000 + func_Symbol2Val(Symbol())*100 + func_TimeFrame_Const2Val(Period()); 
   setup="ProSimple " + Symbol() + "_" + func_TimeFrame_Val2String(func_TimeFrame_Const2Val(Period()));
//  if (Period() != PERIOD_M30)
//  {
   // Alert("Please run on M30 chart");
//  }
}

bool BuySignal()
{
   double proup,prodownb4;

     proup  =iCustom(Symbol(),Period(),"Prosource",0,SignalCandle); //up
     prodownb4=iCustom(Symbol(),Period(),"Prosource",1,SignalCandle+1);//down 
     
     if (proup<9999 && prodownb4<9999) return(true);
       
     return(false);
}


bool SellSignal()
{
   double prodown,proupb4;
   
     prodown = iCustom(Symbol(),Period(),"Prosource",1,SignalCandle);//down 
     proupb4  =iCustom(Symbol(),Period(),"Prosource",0,SignalCandle+1); //up
     
     if (prodown<9999 && proupb4<9999)   return(true);
     
     return(false);
     
 }

bool BuyExitSignal()
{
   double proup;
   
     proup  =iCustom(Symbol(),Period(),"Prosource",0,SignalCandle); //up
     
     if( proup > 9999) return(true);
     return(false); 

 }

bool SellExitSignal()
{
   double prodown;
   
     prodown=iCustom(Symbol(),Period(),"Prosource",1,SignalCandle);//down 
     
     if( prodown>9999) return(true);
     return(false); 
 }

 
int start()
{
   // Bar handling
datetime bartime=0;                      // used to determine when a bar has moved
int      bartick=0;                       //Tick counter
// bar counting
   if(bartime!=Time[0]) 
     {
      bartime=Time[0];
      bartick++; 
      TradeAllowed=true;
     }

//+------------------------------------------------------------------+
//| Check for Open Position                                          |
//+------------------------------------------------------------------+
  
  
  if (CheckOpenPositions() > 0) HandleOpenPositions();
  
//+------------------------------------------------------------------+
//| Check if OK to make new trades                                   |
//+------------------------------------------------------------------+


   if(AccountFreeMargin() < Margincutoff) return(0);
   
// Only allow 1 trade per Symbol

  if (CheckOpenPositions() > 0) return(0);
   
  lotMM = GetLots();
  if( TradeAllowed && BuySignal())  
  {
	  OpenBuyOrder();
     TradeAllowed=false;
     return(0);
  }
     
  if(TradeAllowed && SellSignal()) 
  {
     OpenSellOrder();
     TradeAllowed=false;
  }
  
  return(0);
}

//+------------------------------------------------------------------+
//| OpenBuyOrder                                                     |
//| If Stop Loss or TakeProfit are used the values are calculated    |
//| for each trade                                                   |
//+------------------------------------------------------------------+
void OpenBuyOrder()
{
   int ticket;
   int cnt, err, digits;
   double myStopLoss = 0, myTakeProfit = 0, myPrice = 0;
   
   myPrice = MarketInfo(Symbol(), MODE_ASK);
   myStopLoss = 0;
   if ( StopLoss > 0 ) myStopLoss = myPrice - StopLoss * Point ;
	if (myStopLoss != 0) ValidStopLoss(OP_BUY, myStopLoss); 
   myTakeProfit = 0;
   if (TakeProfit>0) myTakeProfit = myPrice + TakeProfit * Point;
      
	// Normalize all price / stoploss / takeprofit to the proper # of digits.
   digits = MarketInfo(Symbol(), MODE_DIGITS);
	if (digits > 0) 
	{
		myPrice = NormalizeDouble(myPrice, digits);
	   myStopLoss = NormalizeDouble(myStopLoss, digits);
		myTakeProfit = NormalizeDouble(myTakeProfit, digits); 
	}
	
   
   OrderSend(Symbol(),OP_BUY,lotMM,myPrice,Slippage,myStopLoss,myTakeProfit,setup,MagicNumber,0,LimeGreen); 
	if (ticket > 0)
	{
		if (OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
		{
		  if (Debug) Print("BUY order opened : ", OrderOpenPrice());
		}
	}
	else
	{
		err = GetLastError();
      Print("Error opening BUY order : (" + err + ") " + ErrorDescription(err));
   }
}

//+------------------------------------------------------------------+
//| OpenSellOrder                                                    |
//| If Stop Loss or TakeProfit are used the values are calculated    |
//| for each trade                                                   |
//+------------------------------------------------------------------+
void OpenSellOrder()
{
   int ticket;
   int cnt, err, digits;
   double myStopLoss = 0, myTakeProfit = 0, myPrice = 0;
   
   myPrice = MarketInfo(Symbol(), MODE_BID);
   myStopLoss = 0;
   if ( StopLoss > 0 ) myStopLoss = myPrice + StopLoss * Point ;
	if (myStopLoss != 0) ValidStopLoss(OP_SELL, myStopLoss); 

   myTakeProfit = 0;
   if (TakeProfit > 0) myTakeProfit = myPrice - TakeProfit * Point;
       
	// Normalize all price / stoploss / takeprofit to the proper # of digits.
	digits = MarketInfo(Symbol(), MODE_DIGITS);
	if (digits > 0) 
	{
	   myPrice = NormalizeDouble(myPrice, digits);
	   myStopLoss = NormalizeDouble(myStopLoss, digits);
	   myTakeProfit = NormalizeDouble(myTakeProfit, digits); 
	}
	
   ticket=OrderSend(Symbol(),OP_SELL,lotMM,myPrice,Slippage,myStopLoss,myTakeProfit,setup,MagicNumber,0,Red); 
	if (ticket > 0)
	{
		if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) 
			{
			  if (Debug) Print("SELL order opened : ", OrderOpenPrice());
			}
	}
	else
	{
			err = GetLastError();
         Print("Error opening SELL order : (" + err + ") " + ErrorDescription(err));
   }
	return(0);
}

//+------------------------------------------------------------------+
//| Check Open Position Controls                                     |
//+------------------------------------------------------------------+
int CheckOpenPositions()
{
   int cnt, total, NumPositions;
   int NumBuyTrades, NumSellTrades;   // Number of buy and sell trades in this symbol
   
   NumBuyTrades = 0;
   NumSellTrades = 0;
   total=OrdersTotal();
   for(cnt=OrdersTotal()-1;cnt>=0;cnt--)
     {
      OrderSelect (cnt, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol() != Symbol()) continue;
      if ( OrderMagicNumber() != MagicNumber)  continue;
      
      if(OrderType() == OP_BUY )  NumBuyTrades++;
      if(OrderType() == OP_SELL ) NumSellTrades++;
             
     }
     NumPositions = NumBuyTrades + NumSellTrades;
     return (NumPositions);
  }

//+------------------------------------------------------------------+
//| Modify Open Position Controls                                    |
//|  Try to modify position 3 times                                  |
//+------------------------------------------------------------------+
bool ModifyOrder(int nOrderType, int ord_ticket,double op, double price,double tp, color mColor = CLR_NONE)
{
    int cnt, err;
    double myStop;
    
    myStop = ValidStopLoss (nOrderType, price);
    cnt=0;
    while (cnt < totalTries)
    {
       if (OrderModify(ord_ticket,op,myStop,tp,0,mColor))
       {
         return(true);
       }
       else
       {
          err=GetLastError();
          if (err > 1) Print(cnt," Error modifying order : (", ord_ticket , ") " + ErrorDescription(err), " err ",err);
          if (err>0) cnt++;
          Sleep(retryDelay);
       }
    }
    return(false);
}

// 	Adjust stop loss so that it is legal.
double ValidStopLoss(int cmd, double sl)
{
   
   if (sl == 0) return(0.0);
   
   double mySL, myPrice;
   double dblMinStopDistance = MarketInfo(Symbol(),MODE_STOPLEVEL)*MarketInfo(Symbol(), MODE_POINT);
   
   mySL = sl;
   
// Check if SlopLoss needs to be modified

   switch(cmd)
   {
   case OP_BUY:
      myPrice = MarketInfo(Symbol(), MODE_BID);
	   if (myPrice - sl < dblMinStopDistance) 
		mySL = myPrice - dblMinStopDistance;	// we are long
		break;
      
   case OP_SELL:
      myPrice = MarketInfo(Symbol(), MODE_ASK);
	   if (sl - myPrice < dblMinStopDistance) 
		mySL = myPrice + dblMinStopDistance;	// we are long

   }
   return(NormalizeDouble(mySL,MarketInfo(Symbol(), MODE_DIGITS)));
}


//+------------------------------------------------------------------+
//| HandleTrailingStop                                               |
//| Type 1 moves the stoploss without delay.                         |
//| Type 2 waits for price to move the amount of the trailStop       |
//| before moving stop loss then moves like type 1                   |
//| Type 3 uses up to 3 levels for trailing stop                     |
//|      Level 1 Move stop to 1st level                              |
//|      Level 2 Move stop to 2nd level                              |
//|      Level 3 Trail like type 1 by fixed amount other than 1      |
//| Possible future types                                            |
//| Type 4 uses 2 for 1, every 2 pip move moves stop 1 pip           |
//| Type 5 uses 3 for 1, every 3 pip move moves stop 1 pip           |
//+------------------------------------------------------------------+
int HandleTrailingStop(int type, int ticket, double op, double os, double tp)
{
    double pt, TS=0, myAsk, myBid;
    double bos,bop,opa,osa;
    
    switch(type)
    {
       case OP_BUY:
       {
		 myBid = MarketInfo(Symbol(),MODE_BID);
       switch(TrailingStopType)
       {
        case 1: pt = Point*StopLoss;
                if(myBid-os > pt)
                 ModifyOrder(type, ticket,op,myBid-pt,tp, Aqua);
                break;
        case 2: pt = Point*TrailingStop;
                if(myBid-op > pt && os < myBid - pt)
                 ModifyOrder(type, ticket,op,myBid-pt,tp, Aqua);
                break;
       }
       return(0);
       break;
       }
    case  OP_SELL:
    {
		myAsk = MarketInfo(Symbol(),MODE_ASK);
       switch(TrailingStopType)
       {
        case 1: pt = Point*StopLoss;
                if(os - myAsk > pt)
                 ModifyOrder(type, ticket,op,myAsk+pt,tp, Aqua);
                break;
        case 2: pt = Point*TrailingStop;
                if(op - myAsk > pt && os > myAsk+pt)
                 ModifyOrder(type, ticket,op,myAsk+pt,tp, Aqua);
                break;
       }
    }
    return(0);
    }
}

//+------------------------------------------------------------------+
//| Handle Open Positions                                            |
//| Check if any open positions need to be closed or modified        |
//+------------------------------------------------------------------+
int HandleOpenPositions()
{
   int cnt;
   
   for(cnt=OrdersTotal()-1;cnt>=0;cnt--)
   {
      OrderSelect (cnt, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol() != Symbol()) continue;
      if ( OrderMagicNumber() != MagicNumber)  continue;
      
      if(OrderType() == OP_BUY)
      {
            
         if ( BuyExitSignal())
          {
               OrderClose(OrderTicket(),OrderLots(),Bid, Slippage, Violet);
          }
          else
          {
            if (UseTrailingStop)
            {
               HandleTrailingStop(OP_BUY,OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
            }
          }
      }

      if(OrderType() == OP_SELL)
      {
          if (SellExitSignal())
          {
             OrderClose(OrderTicket(),OrderLots(),Ask, Slippage, Violet);
          }
          else
          {
             if(UseTrailingStop)  
             {                
               HandleTrailingStop(OP_SELL,OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
             }
          }
       }
   }
}

     
//+------------------------------------------------------------------+
//| Get number of lots for this trade                                |
//+------------------------------------------------------------------+
double GetLots()
{
   double lot;
   
   if(MoneyManagement)
   {
     lot = LotsOptimized();
   }
   else
   {
     lot = Lots;
   }
   
   if(AccountIsMini)
   {
     if (lot < 0.1) lot = 0.1;
   }
   else
   {
     if (lot >= 1.0) lot = MathFloor(lot); else lot = 1.0;
   }
   if (lot > MaxLots) lot = MaxLots;
   
   return(lot);
}

//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+

double LotsOptimized()
  {
   double lot=Lots;
//---- select lot size
   lot=NormalizeDouble(MathFloor(AccountFreeMargin()*TradeSizePercent/10000)/10,1);
   
  
  // lot at this point is number of standard lots
  
//  if (Debug) Print ("Lots in LotsOptimized : ",lot);
  
  // Check if mini or standard Account
  
  if(AccountIsMini)
  {
    lot = MathFloor(lot*10)/10;
    
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
   string mySymbol = StringSubstr(symbol,0,6);
	if(mySymbol=="AUDCAD") return(1);
	if(mySymbol=="AUDJPY") return(2);
	if(mySymbol=="AUDNZD") return(3);
	if(mySymbol=="AUDUSD") return(4);
	if(mySymbol=="CHFJPY") return(5);
	if(mySymbol=="EURAUD") return(6);
	if(mySymbol=="EURCAD") return(7);
	if(mySymbol=="EURCHF") return(8);
	if(mySymbol=="EURGBP") return(9);
	if(mySymbol=="EURJPY") return(10);
	if(mySymbol=="EURUSD") return(11);
	if(mySymbol=="GBPCHF") return(12);
	if(mySymbol=="GBPJPY") return(13);
	if(mySymbol=="GBPUSD") return(14);
	if(mySymbol=="NZDUSD") return(15);
	if(mySymbol=="USDCAD") return(16);
	if(mySymbol=="USDCHF") return(17);
	if(mySymbol=="USDJPY") return(18);
	return(19);
}

 
//+------------------------------------------------------------------+