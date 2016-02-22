//+------------------------------------------------------------------+
//|                                                  EWOCCI_v3       |
//|                                                                  |
//| 10/23/06 Robert Hill                                             |
//|          Added Magic Number                                      |
//|          Added MoneyManagement for Mini or Standard accounts     |                                                        |
//|          Lost track of other additions but has trailing stop     |
//+------------------------------------------------------------------+

#include <stdlib.mqh>
#include <stderror.mqh> 

extern int MinWidth = 20;
extern int StopLoss = 40;
extern double Lots=1;
extern bool UseTrailingStop = true;
extern int TrailingStopType = 1;        // Type 1 moves stop immediately, Type 2 waits til value of TS is reached
extern double TrailingStop = 25;    // Change to whatever number of pips you wish to trail your position with.
extern int ProfitTarget = 50;
extern int Slippage = 3;
extern double BIG_JUMP=1000; //30.0;       // Check for too-big candlesticks (avoid them)
extern double DOUBLE_JUMP=1000; //55.0;
extern int SignalCandle=1;  //set to 1 if you want to get the cangle close 0 for current

//+---------------------------------------------------+
//|Money Management                                   |
//+---------------------------------------------------+
extern bool UseMoneyManagement = true; // Change to false to shutdown money management controls.
extern int MM_Type = 1;
//+---------------------------------------------------+
//|Money Management type 1                            |
//+---------------------------------------------------+
extern string StrSep1 = "-----MoneyManagementType 1 -----";
extern double     MMRisk=0.15;              // Risk Factor
extern double     LossMax=1000;             // Maximum Loss by 1 Lot
//+---------------------------------------------------+
//|Money Management type 2                            |
//+---------------------------------------------------+
extern string StrSep2 = "-----MoneyManagementType 2 -----";
extern bool AccountIsMini = true;      // Change to true if trading mini account
extern double TradeSizePercent = 15;      // Change to whatever percent of equity you wish to risk.
 double MaxLots = 100;
//+---------------------------------------------------+


  double ao ;
  double ao1;
   double MA5,MA35, EWO;
   double MA5prev,MA35prev, EWOprev;
  double cci;
  double cci1;
  double Lotsi;
int    MagicNumber;  // Magic number of the trades. must be unique to identify

double   PrevPrice=0, PrevHigh=0, PrevLow=0, Pivot=0, Price=0;
   bool TradeAllowed=false;
   // Bar handling
datetime bartime=0;                      // used to determine when a bar has moved
int      bartick=0;                       //Tick counter
int totalTries 		= 5; 
int retryDelay 		= 1000;
   
int init() 
{
    MagicNumber = 3000 + func_Symbol2Val(Symbol())*100 + func_TimeFrame_Const2Val(Period());
  
}

int start()
{
//{
 // bar counting
   if(bartime!=Time[0]) 
     {
      bartime=Time[0];
      bartick++; 
      TradeAllowed=true;
     }
  
// ao  =iAO (NULL,0,0);
// ao1 =iAO (NULL,0,1);

MA5=iMA(NULL,0,5,0,MODE_SMA,PRICE_MEDIAN,SignalCandle);
MA35=iMA(NULL,0,35,0,MODE_SMA,PRICE_MEDIAN,SignalCandle);
MA5prev=iMA(NULL,0,5,0,MODE_SMA,PRICE_MEDIAN,SignalCandle+1);
MA35prev=iMA(NULL,0,35,0,MODE_SMA,PRICE_MEDIAN,SignalCandle+1);
EWO=MA5-MA35;
EWOprev = MA5prev - MA35prev;

 cci =iCCI(NULL,0,55,PRICE_CLOSE,SignalCandle+0);
 cci1=iCCI(NULL,0,55,PRICE_CLOSE,SignalCandle+1);

PrevPrice = iClose(NULL,PERIOD_D1,SignalCandle+1);
PrevHigh  = iHigh(NULL,PERIOD_D1,SignalCandle+1);
PrevLow   = iLow(NULL,PERIOD_D1,SignalCandle+1);
Pivot = (PrevHigh + PrevLow + PrevPrice)/3;
Price = iClose(NULL,PERIOD_H1,1); //gets close of last closed candle




// Was there a sudden jump?  Ignore it...
  if((MathAbs(Open[1]-Open[0])/Point)>=BIG_JUMP) {
    return(0);
  }
  if((MathAbs(Open[2]-Open[1])/Point)>=BIG_JUMP) {
    return(0);
  }
  if((MathAbs(Open[3]-Open[2])/Point)>=BIG_JUMP) {
    return(0);
  }
  if((MathAbs(Open[4]-Open[3])/Point)>=BIG_JUMP) {
    return(0);
  }
  if((MathAbs(Open[5]-Open[4])/Point)>=BIG_JUMP) {
    return(0);
  }
  if((MathAbs(Open[2]-Open[0])/Point)>=DOUBLE_JUMP) {
    return(0);
  }
  if((MathAbs(Open[3]-Open[1])/Point)>=DOUBLE_JUMP) {
    return(0);
  }
  if((MathAbs(Open[4]-Open[2])/Point)>=DOUBLE_JUMP) {
    return(0);
  }
  if((MathAbs(Open[5]-Open[3])/Point)>=DOUBLE_JUMP) {
    return(0);
  }
   
  int NumTrades = 0;
  
  for (int i = 0; i < OrdersTotal(); i++)
  {
    OrderSelect(i, SELECT_BY_POS);
 
    if (OrderSymbol() == Symbol())
    {
      if (OrderType() == OP_BUY )       NumTrades++;
      if (OrderType() == OP_SELL )      NumTrades++;
    }
  }
  
  if (NumTrades == 0) 
  {
      if( TradeAllowed )
      {
          if (MM_Type == 1)
            Lotsi = MoneyManagement ( UseMoneyManagement, Lots, MMRisk, LossMax);
          else
            Lotsi = GetLots();
            
        if( EWO>0 && cci>=0 && Ask>Pivot && (EWOprev<0 || cci1<=0 || Price<Pivot)) 
        {
          OrderSend(Symbol(), OP_BUY, Lotsi, Ask, 2, Ask - StopLoss * Point, Ask + ProfitTarget * Point, 0); 
          return(0);
        }
        if( EWO > 0 && cci>=0 && Ask>Pivot && (EWOprev<0 || cci1<=0 || Price<Pivot)) 
        {
          OrderSend(Symbol(), OP_SELL, Lotsi, Bid, 2, Bid + StopLoss * Point, Bid - ProfitTarget * Point, 0); 
          return(0);
        }
     }
  }
  
  if (UseTrailingStop)
  {
    for (i = 0; i < OrdersTotal(); i++)
    {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);

      if ( OrderSymbol() == Symbol() )
      {
        if ( OrderType() == OP_BUY )
        {
               HandleTrailingStop(OP_BUY,OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
        }

        if ( OrderType() == OP_SELL)
        {
               HandleTrailingStop(OP_SELL,OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
	  	  }
	   }
    }
  }

  return(0);
}

//+------------------------------------------------------------------+
// ---- Money Management

double MoneyManagement ( bool flag, double Lots, double risk, double maxloss)
{
   Lotsi=Lots;
	    
   if ( flag ) Lotsi=NormalizeDouble(Lots*AccountFreeMargin()*risk/maxloss,1);   
     
   if (Lotsi<0.1) Lotsi=0.1;  
   return(Lotsi);
} 
//+------------------------------------------------------------------+
//| Get number of lots for this trade                                |
//+------------------------------------------------------------------+
double GetLots()
{
   double lot;
   
   if(UseMoneyManagement)
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
	Comment("unexpected Symbol");
	return(19);
}


