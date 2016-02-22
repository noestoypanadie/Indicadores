//+------------------------------------------------------------------+
//|                                                Hans123Trader v9  |
//+------------------------------------------------------------------+
#include <stdlib.mqh>
#property copyright   "hans123"
#property link        "http://www.strategybuilderfx.com/forums/showthread.php?t=15439"
// programmed by fukinagashi
#import "Kernel32.dll"
   int CreateEventA(int attr, int bManualReset, int bInitialState, string lpName);
   int SetEvent(int hEvent);
   int WaitForSingleObject(int hEvent, int dwMilliseconds);
   int CloseHandle(int hEvent);
#import

extern int BeginSession1=6;
extern int LengthSession1=4;
extern int BeginSession2=10;
extern int LengthSession2=4;

extern double Lots = 0.5;

// 0 for GMT time and 1 for CET time
extern int OffsetToGMT = 0;

extern int ClsOnlUnprTX=1; // 1 = yes / 0 = no
extern int ProtectYourInvestments=1; // 1 = yes / 0 = no
extern int Type_TS_Calc=1; // 1 - classic / 2 - ATR / 3 - HalfVotality
extern double FactorTSCalculation = 0.5;

datetime bartime = 0;
double Slippage=3;
int OrderInterval = 8000;
int RetryConnect = 5;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init()
{
   if (!GlobalVariableCheck("tradeevent")) {
      int hEvent = CreateEventA(0, 0, 1, "HansMetaTraderEvent");
      GlobalVariableSet("tradeevent", hEvent);
   }
}

int deinit()
{
   if (GlobalVariableCheck("tradeevent")) {
      int hEvent = GlobalVariableGet("tradeevent");
      CloseHandle(hEvent);
      GlobalVariableDel("tradeevent");
   }
}

int start()
   {
   int cnt, ticket, err, i, j;
   int MagicNumber;
   double ts, tp, sl, LowestPrice, HighestPrice, Price;
   bool Order[5];
   string setup;
   datetime Validity=0;
   double TrailingStop;
   double TakeProfit;
   double InitialStopLoss;
   int PipsForEntry;
   int retry;
   
   int TimeZoneDiff= OffsetToGMT - 1;   

	MagicNumber = func_Symbol2Val(Symbol()); 

   setup="H123v9_" + Symbol();

   if (Symbol()=="GBPUSD") {
      PipsForEntry= 5;
      TrailingStop = 40;
      TakeProfit = 120; 
      InitialStopLoss=70;
    } else    if (Symbol()=="EURUSD") {
      PipsForEntry= 5;
      TrailingStop = 30;
      TakeProfit = 80;
      InitialStopLoss=60;
    } else    if (Symbol()=="USDCHF") {
      PipsForEntry= 10;
      TrailingStop = 30;
      TakeProfit = 120;
      InitialStopLoss=30;
    } else {      
      PipsForEntry= 5;
      TrailingStop = 40;
      TakeProfit = 120;
      InitialStopLoss=50;
    } 

   if (bartime == Time[0]) {
      return(0);
   } else {
      bartime = Time[0]; 
   }



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////// MODIFICATIONS ON OPEN ORDERS   ////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


   for(cnt=OrdersTotal();cnt>=0;cnt--)
   {
      if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)) {
      err = GetLastError();
  		if (err>1) { Print("Error selecting order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
      
      if(OrderType()==OP_BUY && OrderSymbol()==Symbol() && (OrderMagicNumber()==(MagicNumber+1) || OrderMagicNumber()==(MagicNumber+3))) {
      	if(TimeDay(OrderOpenTime())!=TimeDay(Time[0])) {
            if (ClsOnlUnprTX==1) {
               if(Bid-OrderOpenPrice()<Point*TrailingStop) {
                  OrderCloseExtended(OrderTicket(), Lots, Bid, 3, Red);
               }  
            } else {
         		 OrderCloseExtended(OrderTicket(), Lots, Bid, 3, Red);
         	}
            err = GetLastError();
      		if (err>1) { Print("Error closing buy order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
			} else if (TrailingStop>0) {
			   if (ProtectYourInvestments==1 && Bid-OrderOpenPrice()>Point*TrailingStop) {
			      ts = OrderOpenPrice();
			   } else {
			      if (Type_TS_Calc==1) {
                  ts = Bid-(Point*TrailingStop);
               } else if (Type_TS_Calc==2) {
                  ts = Low[0] - FactorTSCalculation * iATR(NULL,0,14,0);
               } else if (Type_TS_Calc==3) {
                  ts = Low[0] - (FactorTSCalculation *(High[0]-Low[0]));
               }
				}
				if (OrderStopLoss()<ts && Bid-OrderOpenPrice()>Point*TrailingStop) OrderModifyExtended(OrderTicket(),OrderOpenPrice(),ts,OrderTakeProfit(),0,White);
            err = GetLastError();
      		if (err>1) { Print("Error modifying buy order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
			}
      } else if(OrderType()==OP_SELL && OrderSymbol()==Symbol() && (OrderMagicNumber()==(MagicNumber+2) || OrderMagicNumber()==(MagicNumber+4))) {
      	if(TimeDay(OrderOpenTime())!=TimeDay(Time[0])) {
            if (ClsOnlUnprTX==1) {
               if((OrderOpenPrice()-Ask)<(Point*TrailingStop)) {
                  OrderCloseExtended(OrderTicket(), Lots, Ask, 3, Red);
               }
            } else {
         		 OrderCloseExtended(OrderTicket(), Lots, Ask, 3, Red);
         	}
            err = GetLastError();
      		if (err>1) { Print("Error closing Sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
			} else if (TrailingStop>0) {	
			   if (ProtectYourInvestments==1 && (OrderOpenPrice()-Ask)>(Point*TrailingStop)) {
			      ts = OrderOpenPrice();
			   } else {
			      if (Type_TS_Calc==1) {
                  ts = Ask+(Point*TrailingStop);
               } else if (Type_TS_Calc==2) {
                  ts = High[0] + FactorTSCalculation * iATR(NULL,0,14,0);
               } else if (Type_TS_Calc==3) {
                  ts = High[0] + (FactorTSCalculation *(High[0]-Low[0]));
               }
				}

				if (OrderStopLoss()>ts && (OrderOpenPrice()-Ask)>(Point*TrailingStop)) OrderModifyExtended(OrderTicket(),OrderOpenPrice(),ts,OrderTakeProfit(),0,White);
            err = GetLastError();
      		if (err>1) { Print("Error modifyin sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
			}
		}
		}
	}
			

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////// SETTING ORDERS                 ////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   if(AccountFreeMargin()<(1000*Lots)) return(0);  
   
	Validity=StrToTime(TimeYear(Time[0]) + "." + TimeMonth(Time[0]) + "." + TimeDay(Time[0]) + " 23:59")+(TimeZoneDiff*3600);

	
	for(i=1;i<5;i++) { Order[i]=false; }
	
   for(cnt=OrdersTotal();cnt>=0;cnt--) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
		
		err = GetLastError();
      
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==(MagicNumber+1)) {
      	Order[1]=true;
      } else if (OrderSymbol()==Symbol() && OrderMagicNumber()==(MagicNumber+2)) {
      	Order[2]=true;
      } else if (OrderSymbol()==Symbol() && OrderMagicNumber()==(MagicNumber+3)) {
      	Order[3]=true;
      } else if (OrderSymbol()==Symbol() && OrderMagicNumber()==(MagicNumber+4)) {
      	Order[4]=true;
      }
	}      	
	
	
	if (TimeHour(Time[0])==BeginSession1+LengthSession1+TimeZoneDiff && TimeMinute(Time[0])==0) {
		
		LowestPrice=Low[Lowest(NULL, 0, MODE_LOW, LengthSession1*60/Period(), 0)];
		HighestPrice=High[Highest(NULL, 0, MODE_HIGH, LengthSession1*60/Period(), 0)];
		
		Print("Determine Low: " + LowestPrice + " and High: " + HighestPrice + " for timephase " + TimeToStr(Time[240/Period()]) + " - " + TimeToStr(Time[0]));
		
		Price = HighestPrice+PipsForEntry*Point;
		
   	if (TakeProfit>0) {  tp=Price+TakeProfit*Point;
		} else { 				tp=0; }
	
		if (InitialStopLoss>0) { 	
         if((Price-InitialStopLoss*Point)<LowestPrice-PipsForEntry*Point) { 
            sl = LowestPrice-PipsForEntry*Point;
         } else {                                        
            sl = Price-InitialStopLoss*Point;
         }
		} else { 						sl=0; }

		if (!Order[1]) ticket=OrderSendExtended(Symbol(),OP_BUYSTOP,Lots,Price,Slippage,sl,tp,setup,(MagicNumber+1),Validity,Green);
      	   
		err = GetLastError();
		
		if (err==130) {
         ticket=OrderSendExtended(Symbol(),OP_BUY,Lots,Ask,Slippage,sl,tp,setup,(MagicNumber+1),0,Green);
      } else if (err>1) { Print("Error setting buy order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }
      
      retry = RetryConnect;
      while (err == 6 && retry > 0) {
          ticket=OrderSendExtended(Symbol(),OP_BUYSTOP,Lots,Price,Slippage,sl,tp,setup,(MagicNumber+1),Validity,Green);
          err = GetLastError();
          Sleep(3000);
          retry--;
      }
      
  		Price = LowestPrice-PipsForEntry*Point;

   	if (TakeProfit>0) {  tp=Price-TakeProfit*Point;
		} else { 				tp=0; }
		if (InitialStopLoss>0) { 	
         if((Price+InitialStopLoss*Point)>HighestPrice+PipsForEntry*Point) { 
            sl = HighestPrice+PipsForEntry*Point;
         } else {                                         
            sl = Price+InitialStopLoss*Point;
         }
		} else { 						sl=0; }

		if (!Order[2]) ticket=OrderSendExtended(Symbol(),OP_SELLSTOP,Lots,Price,Slippage,sl,tp,setup,(MagicNumber+2),Validity,Green); 
		err = GetLastError();
		
		if (err==130) {
         ticket=OrderSendExtended(Symbol(),OP_SELL,Lots,Bid,Slippage,sl,tp,setup,(MagicNumber+1),0,Green);
      } else if (err>1) { Print("Error setting sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }

      retry = RetryConnect;
      while (err == 6 && retry > 0) {
          ticket=OrderSendExtended(Symbol(),OP_SELLSTOP,Lots,Price,Slippage,sl,tp,setup,(MagicNumber+2),Validity,Green); 
          err = GetLastError();
          Sleep(3000);
          retry--;
      }
	}
	
	if (TimeHour(Time[0])==BeginSession2+LengthSession2+TimeZoneDiff && TimeMinute(Time[0])==0) {

		LowestPrice=Low[Lowest(NULL, 0, MODE_LOW, LengthSession2*60/Period(), 0)];
		HighestPrice=High[Highest(NULL, 0, MODE_HIGH, LengthSession2*60/Period(), 0)];
		
		Print("Determine Low: " + LowestPrice + " and High: " + HighestPrice + " for timephase " + TimeToStr(Time[240/Period()]) + " - " + TimeToStr(Time[0]));

		Price = HighestPrice+PipsForEntry*Point;

   	if (TakeProfit>0) {  tp=Price+TakeProfit*Point;
		} else { 				tp=0; }
	
		if (InitialStopLoss>0) { 	
         if((Price-InitialStopLoss*Point)<LowestPrice-PipsForEntry*Point) { 
            sl = LowestPrice-PipsForEntry*Point;
         } else {                                        
            sl = Price-InitialStopLoss*Point;
         }
		} else { 						sl=0; }

		if (!Order[3]) ticket=OrderSendExtended(Symbol(),OP_BUYSTOP,Lots,Price,Slippage,sl,tp,setup,(MagicNumber+3),Validity,Green); 

		err = GetLastError();
		
		if (err==130) {
         ticket=OrderSendExtended(Symbol(),OP_BUY,Lots,Ask,Slippage,sl,tp,setup,(MagicNumber+1),0,Green);
      } else if (err>1) { Print("Error setting buy order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }

      retry = RetryConnect;
      while (err == 6 && retry > 0) {
          ticket=OrderSendExtended(Symbol(),OP_BUYSTOP,Lots,Price,Slippage,sl,tp,setup,(MagicNumber+3),Validity,Green);
          err = GetLastError();
          Sleep(3000);
          retry--;
      }

  		Price = LowestPrice-PipsForEntry*Point;

   	if (TakeProfit>0) {  tp=Price-TakeProfit*Point;
		} else { 				tp=0; }
		if (InitialStopLoss>0) { 	
         if((Price+InitialStopLoss*Point)>HighestPrice+PipsForEntry*Point) { 
            sl = HighestPrice+PipsForEntry*Point;
         } else {                                         
            sl = Price+InitialStopLoss*Point;
         }
		} else { 						sl=0; }

		if (!Order[4]) ticket=OrderSendExtended(Symbol(),OP_SELLSTOP,Lots,Price,Slippage,sl,tp,setup,(MagicNumber+4),Validity,Green); 

		err = GetLastError();
		
		if (err==130) {
         ticket=OrderSendExtended(Symbol(),OP_SELL,Lots,Bid,Slippage,sl,tp,setup,(MagicNumber+1),0,Green);
      } else if (err>1) { Print("Error setting sell order [" + setup + "]: (" + err + ") " + ErrorDescription(err)); }

      retry = RetryConnect;
      while (err == 6 && retry > 0) {
          ticket=OrderSendExtended(Symbol(),OP_SELLSTOP,Lots,Price,Slippage,sl,tp,setup,(MagicNumber+4),Validity,Green); 
          err = GetLastError();
          Sleep(3000);
          retry--;
      }
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////// DIVERSE SUBROUTINES   /////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

int func_Symbol2Val(string symbol) {
	if(symbol=="AUDUSD") {	return(01);

	} else if(symbol=="CHFJPY") {	return(02);

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

int OrderSendExtended(string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment, int magic, datetime expiration=0, color arrow_color=CLR_NONE) {
   datetime OldCurTime;
   int timeout=60;
   int ticket;
   
   if (!IsTesting()) {
      MathSrand(LocalTime());
      Sleep(MathRand()/6);
   }

   OldCurTime=CurTime();
   while (!IsTradeAllowed()) {
      if(OldCurTime+timeout<=CurTime()) {
         Print("Error in OrderSendExtended(): Timeout encountered");
         return(0); 
      }
      Sleep(1000);
   }
   
   int hEvent = GlobalVariableGet("tradeevent");
   int ret = WaitForSingleObject(hEvent, 60000);  
   if (ret != 0) 
      return (0);
   ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic, expiration, arrow_color);
   Sleep(OrderInterval);
   SetEvent(hEvent);
   return(ticket);
}


bool OrderModifyExtended(int ticket, double price, double stoploss, double takeprofit, datetime expiration, color clr) {
   datetime OldCurTime;
   int timeout=60;
   bool ret=true;

   OldCurTime=CurTime();
   while (!IsTradeAllowed()) {
      if(OldCurTime+timeout<=CurTime()) {
         Print("Error in OrderSendExtended(): Timeout encountered");
         return(false); 
      }
      Sleep(1000);
   }
     
   int hEvent = GlobalVariableGet("tradeevent");
   if(WaitForSingleObject(hEvent, 60000) != 0) 
      return (false);
   ret = OrderModify(ticket, price, stoploss, takeprofit, expiration, clr); 
   Sleep(OrderInterval);     // sleep 10 seconds
   SetEvent(hEvent);
   return(ret);
}

bool OrderCloseExtended(int ticket,double lots, double price,int slippage,color clr) {
   datetime OldCurTime;
   int timeout=60;
   bool ret = true;

   OldCurTime=CurTime();
   while (!IsTradeAllowed()) {
      if(OldCurTime+timeout<=CurTime()) {
         Print("Error in OrderSendExtended(): Timeout encountered");
         return(false); 
      }
      Sleep(1000);
   }
     
   int hEvent = GlobalVariableGet("tradeevent");
   if (WaitForSingleObject(hEvent, 60000) != 0)
      return (false);
   ret = OrderClose(ticket, lots, price, slippage, clr);
   Sleep(OrderInterval);
   SetEvent(hEvent);
   return(ret);
} 