//+------------------------------------------------------------------+
//|                                                Starter_v6.mq4    |
//|                                              Copyright © 2005    |
//|    Thanks to Starter, Maloma, Amir, Fukinagashi, Forex_trader,   |
//|    kmrunner, and all other strategybuilderFx members that        |
//|    contributed to the success of this expert.                    |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Strategybuilderfx members"
#property link      "http:/strategybuilderfx.com/"
#include <stdlib.mqh>
//+---------------------------------------------------+
//|Account functions                                  |
//+---------------------------------------------------+
extern int AccountIsMini = 0;       // Change to 1 if trading mini account
extern int LiveTrading = 0;         // Change to 1 if trading live.
//+---------------------------------------------------+
//|Money Management                                   |
//+---------------------------------------------------+
extern int mm = 0;                  // Change to 0 if you want to shutdown money management controls. Lots = 1 will be in effect and only 1 lot will be open regardless of equity.
extern double Riskpercent = 10; // 12     // Change to whatever percent of equity you wish to risk.
extern double DecreaseFactor = 3;   // Used to decrease lot size after a loss is experienced to protect equity.  Recommended not to change.
extern double StopLoss = 35;        // Maximum pips willing to lose per position.
extern double TrailingStop = 0;     // Change to whatever number of pips you wish to trail your position with.
extern int MaximumLosses = 3;       // Maximum number of losses per day willing to experience.
extern double Margincutoff = 800;   // Expert will stop trading if equity level decreases to that level.
extern double Maxtrades = 4;       // Total number of positions on all currency pairs. You can change this number as you wish.
//+---------------------------------------------------+
//|Profit controls                                    |
//+---------------------------------------------------+
extern int TakeProfit = 11;         // Maximum profit level achieved.    
extern double Stop = 0;             // Minimum profit level achieved and usually achieved target.
//+---------------------------------------------------+
//|Indicator Variables                                |
//+---------------------------------------------------+
extern double MAPeriod=120;         // Moving average period.
extern double MAPeriod2=40;         // Moving average period 2.
extern double Lots = 1;             // standard lot size. 
extern int Turnon = 1;              // Turns expert on, change to 0 and no trades will take place even if expert is enabled.
//+---------------------------------------------------+
//|General controls                                   |
//+---------------------------------------------------+
string OrderText = "";
double lotMM;
int TradesInThisSymbol;
int cnt=0, total;
datetime LastTime;
double Sl;
double Tr;
int ticket;
int trstop = 0;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
//----
   return(0);
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
   lot=NormalizeDouble(MathFloor(AccountBalance()*Riskpercent/10000)/10,1);
   
//---- calcuulate number of losses orders without a break
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
        if (tolosses >= MaximumLosses) trstop=1;
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
  if(lot > 1) 
      lot = MathFloor(lot);

  if(AccountIsMini==1) 
      lot = lot * 10;
//---- return lot size
   if(lot<0.1) lot=0.1;
  if(LiveTrading == 1)
  {
    if (AccountIsMini == 0 && lot < 1.0) 
         lot = 1.0;
  }
  if(lot > 100)
         lot = 100;
         
   if (AccountNumber()!=13528) {
      lot=1;
   }         

   return(lot);
  } 
  
  
//+------------------------------------------------------------------+
//| LaGuerre function calculation                                    |
//+------------------------------------------------------------------+

double LaGuerre(double gamma, int shift)
{
	double RSI;
	double L0[100];
	double L1[100];
	double L2[100];
	double L3[100];
	double CU, CD;

	for (int i=shift+99; i>=shift; i--)
	{
		L0[i] = (1.0 - gamma)*Close[i] + gamma*L0[i+1];
		L1[i] = -gamma*L0[i] + L0[i+1] + gamma*L1[i+1];
		L2[i] = -gamma*L1[i] + L1[i+1] + gamma*L2[i+1];
		L3[i] = -gamma*L2[i] + L2[i+1] + gamma*L3[i+1];

		CU = 0;
		CD = 0;
		if (L0[i] >= L1[i])  CU = L0[i] - L1[i];
		else 		 		CD = L1[i] - L0[i];
		
		if (L1[i] >= L2[i])  CU = CU + L1[i] - L2[i];
		else 		 		CD = CD + L2[i] - L1[i];
		if (L2[i] >= L3[i])  CU = CU + L2[i] - L3[i];
		else 		 		CD = CD + L3[i] - L2[i];

		if (CU + CD != 0)		RSI = CU / (CU + CD);
	}
   return(RSI);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//---- 
   double Laguerre;
   double Laguerreprevious;
   double Alpha;
   double MA, MAprevious, Min_OrderPrice;
   double MA2,MAprevious2;
   int donttrade, allexit, err;
trstop = 0;

	int MagicNumber = 3000 + func_Symbol2Val(Symbol())*100 + func_TimeFrame_Const2Val(Period()); 

   string setup="sv6" + Symbol() + "_" + func_TimeFrame_Val2String(func_TimeFrame_Const2Val(Period()));
   
if(mm == 1)
{
  lotMM = LotsOptimized(MagicNumber);
}
else {
  lotMM = Lots; // Change mm to 0 if you want the Lots parameter to be in effect
}
//+------------------------------------------------------------------+
//| Condition statements                                             |
//+------------------------------------------------------------------+

  Laguerre=LaGuerre(0.7, 0);
  Laguerreprevious=LaGuerre(0.7, 1);
  Alpha=iCCI(NULL, 0, 14, PRICE_CLOSE, 0);
  MA=iMA(NULL,0,MAPeriod,0,MODE_EMA,PRICE_MEDIAN,0);
  MAprevious=iMA(NULL,0,MAPeriod,0,MODE_EMA,PRICE_MEDIAN,1);
  MA2=iMA(NULL,0,MAPeriod2,0,MODE_EMA,PRICE_MEDIAN,0);
  MAprevious2=iMA(NULL,0,MAPeriod2,0,MODE_EMA,PRICE_MEDIAN,1);

   donttrade = 0;
   allexit = 0;
   
//+------------------------------------------------------------------+
//| Friday Exits                                                     |
//+------------------------------------------------------------------+

//   if(DayOfWeek()==5 && Hour()>=18) donttrade=1;
//   if(DayOfWeek()==5 && Hour()>=20) allexit=1;
   
//+------------------------------------------------------------------+
//| Open Position Controls                                          |
//+------------------------------------------------------------------+

   total=OrdersTotal();
   TradesInThisSymbol = 0;
   for(cnt=0;cnt<total;cnt++)
     {
      if ( OrderSelect (cnt, SELECT_BY_POS) == false )  continue;
      if ( OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber)  continue;
      
      if((OrderType() == OP_BUY || OrderType() == OP_BUYSTOP) && (OrderSymbol()==Symbol()))
          {
             TradesInThisSymbol++;
            if(Laguerre>0.9 || allexit==1)
                {
                 OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // close position
                 return(0); // exit
                }
            // check for stop
            if(Stop>0)  
              {                 
               if(Bid-OrderOpenPrice()>=Point*Stop)
                 {
                   OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // close position
                   return(0);
                 }
              }
             if(TrailingStop>0) 
               {                
                if(Bid-OrderOpenPrice()>Point*TrailingStop)
                  {
                   if(OrderStopLoss()<Bid-Point*TrailingStop)
                     {
                      OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Aqua);
                      return(0);
                     }
                  }
               }
          }
      if((OrderType() == OP_SELL || OrderType() == OP_SELLSTOP) && (OrderSymbol()==Symbol()))
          {
             TradesInThisSymbol++;
            if(Laguerre<0.1 || allexit==1)
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close position
               return(0); // exit
              }
            // check for stop
            if(Stop>0)  
              {                 
               if(OrderOpenPrice()-Ask>=Point*Stop)
                 {
                   OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close position
                   return(0);
                 }
              }
             if(TrailingStop>0)  
               {                
                if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                  {
                   if(OrderStopLoss()==0.0 || 
                      OrderStopLoss()>(Ask+Point*TrailingStop))
                     {
                      OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Aqua);
                      return(0);
                     }
                  }
               }
          }
     }
     
     
//+------------------------------------------------------------------+
//| New Position Controls                                            |
//+------------------------------------------------------------------+


if(AccountFreeMargin() < Margincutoff) {
   return(0);}
if(TradesInThisSymbol > Maxtrades) {
   return(0);}
if(CurTime() < LastTime) {
   return(0);}
   
OrderText = ""; //Must be blank before going into the main section

	// Is current bar a bull candle?
	if((Turnon == 1) && (Laguerreprevious<=0) && (Laguerre<=0) && (MA>MAprevious) && (MA2>MAprevious2)&& (Alpha<-5) && donttrade==0) 
	{
		OrderText = "BUY";
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

	// Is current bar a bear candle?
	if((Turnon == 1) && (Laguerreprevious>=1) && (Laguerre>=1) && (MA<MAprevious) && (MA2<MAprevious2) && (Alpha>5) && donttrade==0)
	{
		OrderText = "SELL";
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
   if(OrderText != "" && trstop == 0 && TradesInThisSymbol <= 0) 
   {

	   LastTime = CurTime();
           if(OrderText == "BUY")
           {
               Min_OrderPrice=MinOrderPrice(OP_BUY, MagicNumber);
               if (Min_OrderPrice>0 && Min_OrderPrice<=Ask*1.05) {
                  Print("Buy too expensive => MinOrderPrice= " + Min_OrderPrice + "  Ask=" + Ask);
               } else {
                  Print(Symbol() + " OP_BUY " + lotMM + " " + Ask + " " + Sl + " " + Tr);
	              ticket = OrderSend(Symbol(),OP_BUY,lotMM,Ask,3,Sl,Tr,setup,MagicNumber,0,Green);
                  if (!IsTesting()) PlaySound("expert.wav");
	              LastTime += 12;
                 if(ticket<=0) {
                     err = GetLastError();
                     Print("Error opening BUY order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); 
                     if (!IsTesting()) PlaySound("alert2.wav");
                 }
                 return(0);
               }
           }
            else if(OrderText == "SELL")
            {
               Min_OrderPrice=MinOrderPrice(OP_SELL, MagicNumber);
         
               if (Min_OrderPrice>0 && Min_OrderPrice>=Bid) {
                  Print("Sell too expensive MinOrderPrice= " + Min_OrderPrice + "  Bid=" + Bid);
               } else {
                  Print(Symbol() + " OP_SELL " + lotMM + " " + Bid + " " + Sl + " " + Tr);
                  ticket = OrderSendExtended(Symbol(),OP_SELL,lotMM,Bid,3,Sl,Tr,setup,MagicNumber,0,Red);
                  if (!IsTesting()) PlaySound("expert.wav");
                  LastTime += 12;
                 if(ticket<=0) {
                     err = GetLastError();
                     Print("Error opening Sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); 
                     if (!IsTesting()) PlaySound("alert2.wav");
                 }
                  return(0);
               }
            }
      return(0);
   }
//----
   return(0);
  }

//+------------------------------------------------------------------+
//| Time frame interval appropriation  function                               |
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
	if(symbol=="AUDUSD") {	return(01);

	} else if(symbol=="CHFJPY") {	return(10);

	} else if(symbol=="EURAUD") {	return(10);
	} else if(symbol=="EURCAD") {	return(11);
	} else if(symbol=="EURCHF") {	return(12);
	} else if(symbol=="EURGBP") {	return(13);
	} else if(symbol=="EURJPY") {	return(14);
	} else if(symbol=="EURUSD") {	return(15);

	} else if(symbol=="GBPCHF") {	return(20);
	} else if(symbol=="GBPJPY") {	return(21);
	} else if(symbol=="GBPUSD") { return(22);


	} else if(symbol=="USDCAD") {	return(40);
	} else if(symbol=="USDCHF") {	return(41);
	} else if(symbol=="USDJPY") {	return(42);


	} else if(symbol=="GOLD") {	return(90);
	} else {	Comment("unexpected Symbol"); return(0);
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

int OrderSendExtended(string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment, int magic, datetime expiration=0, color arrow_color=CLR_NONE) {
   datetime OldCurTime;
   int timeout=30;

   OldCurTime=CurTime();
   while (GlobalVariableCheck("InTrade") && !IsTradeAllowed()) {
      if(OldCurTime+timeout<=CurTime()) {
         Print("Error in OrderSendExtended(): Timeout encountered");
         return(0); 
      }
      Sleep(1000);
   }
     
   GlobalVariableSet("InTrade", CurTime());  // set lock indicator
   ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic, expiration, arrow_color);
   GlobalVariableDel("InTrade");   // clear lock indicator
   return(ticket);
}