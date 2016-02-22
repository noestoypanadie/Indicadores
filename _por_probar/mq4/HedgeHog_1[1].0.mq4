//+------------------------------------------------------------------+
//|                                                 HedgeHog 1.0.mq4 |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""

#include <stdlib.mqh>
#include <WinUser32.mqh>

//---- input parameters
extern int     BrokerOffsetToGMT       = 0; // InterbankFX.com TimeZone GMT+0
                                            // Change to your server's timezone (in GMT)
extern double    Lots=1;
extern int       TakeProfit=14;
extern int       SL=50;
extern int       TS_Mode=2;       // 0 = disabled, 1 = Fixed SL, 2 = ATR
extern int       TS_Trigger=5;
extern int       TS_Sensitivity=5;
extern int       ATR_Period=14;


string           expert_name = "HedgeHog 1.0";
int              bars_count = 0;
int              magicnum;


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   magicnum = 1000 + GetTimeframeConstant(Period()) + GetSymbolConstant(Symbol());
   return(0);
  }
  
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
  
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
 
  // control open orders
  int ticket = OrderTicketByMagicNum(magicnum);
  ControlTrailingStop(ticket);


  // check for entry ( enough money > safe mode off > signal given > enter) 
  if (AccountFreeMargin()<(1000*Lots))
  {
    Print("Error: We don't have enough money. Free Margin = ", AccountFreeMargin());
    return(0);
  }

   // check for begining of Day
    
    if (TimeHour(Time[0])==0+BrokerOffsetToGMT && TimeMinute(Time[0])==0) 
    { 
       EnterSell();  
       EnterBuy();
    }

  return(0);
}


//+------------------------------------------------------------------+
//| Buy                                                              |
//+------------------------------------------------------------------+
int EnterBuy()
{
 
  // Calculate true SL
  double TrueSL;
  double yesterdayclose = Close[1];
  if (SL > 0) TrueSL = Ask-(SL*Point);
    
  int ret = OrderSendEx(Symbol(), OP_BUY, Lots, yesterdayclose, TrueSL, Ask+TakeProfit*Point, expert_name + Symbol() + Period(), magicnum, 0, Yellow);
  return(ret);
}


//+------------------------------------------------------------------+
//| Sell                                                             |
//+------------------------------------------------------------------+
int EnterSell()
{

  // Calculate true SL
  double TrueSL;
  double yesterdayclose = Close[1];
  if (SL > 0) TrueSL = Bid+(SL*Point);
    
  // Send order
  int ret = OrderSendEx(Symbol(), OP_SELL, Lots ,yesterdayclose, TrueSL, Bid-TakeProfit*Point, expert_name + Symbol() + Period(), magicnum, 0, Yellow);
  return(ret);
  
}

//+------------------------------------------------------------------+
//| Control trailing stop                                            |
//+------------------------------------------------------------------+
void ControlTrailingStop(int ticket)
{
  if (ticket == 0 || TS_Mode == 0) return;
  
  double ts;
  if (OrderSelectEx(ticket, SELECT_BY_TICKET, MODE_TRADES)==false) return;
  if (OrderType() == OP_BUY)
  {
    switch (TS_Mode)
    {
      case 1: ts = Bid-(Point*SL); break;
      case 2: ts = Low[0] - (0.5 * iATR(NULL,0,ATR_Period,0)); break;
    }
    if ((ts >= OrderStopLoss() + TS_Sensitivity*Point) && (Bid >= OrderOpenPrice() + TS_Trigger*Point )) 
    {
      OrderModify(ticket, OrderOpenPrice(), ts, OrderTakeProfit(), 0);
    }
    
  }else if(OrderType() == OP_SELL){
  
    switch (TS_Mode)
    {
      case 1: ts = Ask+(Point*SL); break;
      case 2: ts = High[0] + (0.5 * iATR(NULL,0,ATR_Period,0)); break;
    }
    if ((ts <= OrderStopLoss() - TS_Sensitivity*Point) && (Ask <= OrderOpenPrice() - TS_Trigger*Point))
    {
      OrderModify(ticket, OrderOpenPrice(), ts, OrderTakeProfit(), 0);
    }
  }
  
}

//+------------------------------------------------------------------+
//| Extended OrderSend() for used in multiple pairs                  |
//+------------------------------------------------------------------+
int OrderSendEx(string symbol, int cmd, double volume, double price, double stoploss, double takeprofit, string comment, int magic, datetime expiration=0, color arrow_color=CLR_NONE) 
{
   datetime OldCurTime;
   int timeout=5;
   
   if (!IsTesting()) {
      MathSrand(LocalTime());
      Sleep(MathRand()/6);
   }

   OldCurTime=CurTime();
   while (GlobalVariableCheck("InTrade") && !IsTradeAllowed()) {
      if(OldCurTime+timeout <= CurTime()) {
         Print("Error in OrderSendEx(): Timeout encountered");
         return(0); 
      }
      Sleep(1000);
   }
     
   GlobalVariableSet("InTrade", CurTime());  // set lock indicator
   int ticket = OrderSend(symbol, cmd, volume, price, 0, stoploss, takeprofit, comment, magic, expiration, arrow_color);
   GlobalVariableDel("InTrade");   // clear lock indicator
   return(ticket);
}


//+------------------------------------------------------------------+
//| Extended OrderSelect()                                           |
//+------------------------------------------------------------------+
bool OrderSelectEx(int index, int select, int pool = MODE_TRADES)
{
  if (OrderSelect(index,select,pool)==true)
  {
    return(true);
  }else{
    Print("Error: Order #", index ," cannot be selected.");
  }
}


//+------------------------------------------------------------------+
//| Get order ticket by magic number                                 |
//+------------------------------------------------------------------+
int OrderTicketByMagicNum(int magic_number) {

  for(int i=0;i<OrdersTotal();i++)
  {
    if (OrderSelectEx(i, SELECT_BY_POS) == false) continue;
    if (OrderMagicNumber() == magic_number) return(OrderTicket());
  }   
      
}


//+------------------------------------------------------------------+
//| Time frame interval appropriation function                       |
//+------------------------------------------------------------------+
int GetTimeframeConstant(int chart_period) {
   switch(chart_period) {
      case 1:  // M1
         return(50);
      case 5:  // M5
         return(100);
      case 15:
         return(150);
      case 30:
         return(200);
      case 60:
         return(250);
      case 240:
         return(300);
      case 1440:
         return(350);
      case 10080:
         return(400);
      case 43200:
         return(450);
   }
}


//+------------------------------------------------------------------+
//| Symbol to index                                                  |
//+------------------------------------------------------------------+
int GetSymbolConstant(string symbol) {

	if(symbol=="EURUSD") {	return(1);
	} else if(symbol=="GBPUSD") { return(2);
	} else if(symbol=="USDCHF") {	return(3);
	} else if(symbol=="USDJPY") {	return(4);
	} else if(symbol=="USDCAD") {	return(5);
	} else if(symbol=="AUDUSD") {	return(6);
	} else if(symbol=="CHFJPY") {	return(7);
	} else if(symbol=="EURAUD") {	return(8);
	} else if(symbol=="EURCAD") {	return(9);
	} else if(symbol=="EURCHF") {	return(10);
	} else if(symbol=="EURGBP") {	return(11);
	} else if(symbol=="EURJPY") {	return(12);
  } else if(symbol=="GBPCHF") {	return(13);
	} else if(symbol=="GBPJPY") {	return(14);
	} else if(symbol=="GOLD") {	return(15);
	} else {Print("Error: Unexpected symbol."); return(0);
	}
}

