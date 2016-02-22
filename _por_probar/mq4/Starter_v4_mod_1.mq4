//+------------------------------------------------------------------+
//|                                                Starter_v4.mq4    |
//|                                          Copyright © 2005, GCM   |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, GCM"
#property link      "http://"
#include <stdlib.mqh>

extern int TakeProfit = 0;
extern double Lots = 1;
extern double TrailingStop = 0;
extern double StopLoss = 0;
extern int mm = 1;
extern double Riskpercent = 5;
extern int AccountIsMini = 0;
extern int LiveTrading = 1;
extern double DecreaseFactor = 3;
extern double Margincutoff = 800;
extern int Turnon = 1;
extern int MaximumLosses = 5;
extern double Stop = 5;
extern double MAPeriod=120;
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
double LotsOptimized(int Mnr)
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
   int    tolosses=0;

//---- select lot size
   lot=NormalizeDouble(MathCeil(AccountBalance()*Riskpercent/10000)/10,1);
   
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
      lot = MathCeil(lot);

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

   return(lot);
  } 
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
   int donttrade, allexit, err;
trstop = 0;

	int MagicNumber = 3000 + func_Symbol2Val(Symbol())*100 + func_TimeFrame_Const2Val(Period()); 

   string setup="s4m1_" + Symbol() + "_" + func_TimeFrame_Val2String(func_TimeFrame_Const2Val(Period()));

if(mm == 1)
{
  lotMM = LotsOptimized(MagicNumber);
}
else {
  lotMM = Lots; // Change mm to 0 if you want the Lots parameter to be in effect
}
  Laguerre=LaGuerre(0.7, 0);
  Laguerreprevious=LaGuerre(0.7, 1);
  Alpha=iCCI(NULL, 0, 14, PRICE_CLOSE, 0);
  MA=iMA(NULL,0,MAPeriod,0,MODE_EMA,PRICE_MEDIAN,0);
  MAprevious=iMA(NULL,0,MAPeriod,0,MODE_EMA,PRICE_MEDIAN,1);
   donttrade = 0;
   allexit = 0;
   
   
   if(DayOfWeek()==5 && Hour()>=18) donttrade=1;
   if(DayOfWeek()==5 && Hour()>=20) allexit=1;
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

if(AccountFreeMargin() < Margincutoff) {
   return(0);}
if(TradesInThisSymbol > 0) {
   return(0);}
if(CurTime() < LastTime) {
   return(0);}
   
OrderText = ""; //Must be blank before going into the main section

	// Is current bar a bull candle?
	if((Turnon == 1) && (Laguerreprevious<=0) && (Laguerre<=0) && (MA>MAprevious) && (Alpha<-5) && donttrade==0) 
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
	if((Turnon == 1) && (Laguerreprevious>=1) && (Laguerre>=1) && (MA<MAprevious) && (Alpha>5) && donttrade==0)
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
   if(OrderText != "" && trstop == 0 && TradesInThisSymbol == 0) 
   {

	   LastTime = CurTime();
           if(OrderText == "BUY")
           {
               Min_OrderPrice=MinOrderPrice(OP_BUY, MagicNumber);
               if (Min_OrderPrice>0 && Min_OrderPrice<=Ask*1.05) {
                  Print("Buy too expensive => MinOrderPrice= " + Min_OrderPrice + "  Ask=" + Ask);
               } else {
	              ticket = OrderSend(Symbol(),OP_BUY,lotMM,Ask,3,Sl,Tr,setup,MagicNumber,0,Green);
	              LastTime += 12;
                 if(ticket<=0) {
                     err = GetLastError();
                     Alert("Error opening BUY order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); 
                 }
                 return(0);
               }
           }
            else if(OrderText == "SELL")
            {
               Min_OrderPrice=MinOrderPrice(OP_SELL, MagicNumber);
         
               if (Min_OrderPrice>0 && Min_OrderPrice<=Bid) {
                  Print("Buy too expensive MinOrderPrice= " + Min_OrderPrice + "  Bid=" + Bid);
               } else {
                  ticket = OrderSend(Symbol(),OP_SELL,lotMM,Bid,3,Sl,Tr,setup,MagicNumber,0,Red);
                  LastTime += 12;
                 if(ticket<=0) {
                     err = GetLastError();
                     Alert("Error opening Sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); 
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

int func_TimeFrame_Const2Val(int Constant ) {
   switch(Constant) {
      case 1:  // M1
         return(1);
      case 5:  // M1
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
	if(symbol=="USDCHF") {
		return(1);
	} else if(symbol=="GBPUSD") {
		return(2);
	} else if(symbol=="EURUSD") {
		return(3);
	} else if(symbol=="USDJPY") {
		return(4);
	} else if(symbol=="AUDUSD") {
		return(5);
	} else if(symbol=="USDCAD") {
		return(6);
	} else {
		Comment("unexpected Symbol");
	}
}

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

