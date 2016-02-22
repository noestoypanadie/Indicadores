//+-----------------------------------------+
//|GH.mq4   WPR for Multi Pair              |
//|Copyright © 2005, Gary Hensley           |
//+-----------------------------------------+
//
//		Modifications                                                         
//		-------------                                                       
//		DATE       	MOD #    	DESCRIPTION                		        
//		---------- 	-------- 	---------------------------------------------------------------
//		01 Jul 2005 1   		   GaryH: Converted Original M3 version of MultiPairWPR script.
//    18 Oct 2006 2           RobertH Added Trailing Stop function with type 1 and type 2
//                             type 2 should work the same as the original code
//    20 Oct 2006 3           Lingyu Jiang Added StopLoss re-calculation when trend direction has not changed

#property copyright "WPR for Multi Pair, Copyright © 2005, Gary Hensley"
//#property link      "http://www.metaquotes.net/"
#include <stdlib.mqh>
#include <stderror.mqh> 

#define MAGICMA  20050610

//---- input parameters
extern int     UsePct=0;
extern double  Lots = 1;
extern int     MaxLots=100;
extern int     StopLoss = 75;
extern bool    UseTrailingStop = true;
extern int     TrailingStopType = 2;        // Type 1 moves stop immediately, Type 2 waits til value of TS is reached
extern double  TrailingStop=20;
extern double  TakeProfit=100;
extern int     RecalSLRange = 8;
extern int     Slippage=3;
//---- global variables
int bsi=0;
int dir=0;
int vTrig=0;
int openorders=0;
string pair;
double vSL=0,vTP=0;
int dummy=0;
int totalTries = 5; 
int retryDelay = 1000;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   pair = Symbol();
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

//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int GetCurrentOrders()
  {
  //---- calc open OrderSelect
   int NumOrders=0;
   dir=0;
   for(int i=0;i<OrdersTotal();i++)
   {
//      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
       OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if( OrderSymbol()!=Symbol()) continue;
      if (OrderMagicNumber()!=MAGICMA) continue;
       NumOrders++;
       if(OrderType()==OP_BUY) dir=1;
       if(OrderType()==OP_SELL) dir=-1;
   }
   return (NumOrders);
}

//+------------------------------------------------------------------+
//| Calculate Lot Sizes                                              |
//+------------------------------------------------------------------+
int LotCalc(double Risk)
  {
   int vLots=0;
   if (UsePct >0 && Risk>0) vLots=MathFloor(AccountBalance()*(UsePct/100)/((Risk/MarketInfo (Symbol(), MODE_POINT))*10));
   if (UsePct >0 && Risk==0)  vLots = MathFloor(AccountBalance()*(UsePct/100)/1000);
   if (vLots>MaxLots) vLots=MaxLots;
   if (vLots<1) vLots=1;
   vLots=0.1;
   return(vLots);
}

//+------------------------------------------------------------------+
//| Close Open Position                                              |
//+------------------------------------------------------------------+
int CloseTrade()
{ 
  for(int i=0;i<OrdersTotal();i++)
  {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderMagicNumber()!=MAGICMA ) continue;
      if(OrderSymbol()!=Symbol()) continue;
      if(OrderType()==OP_BUY) OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,White);
      if(OrderType()==OP_SELL) OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,White);
  }
}

//+------------------------------------------------------------------+
//| Open Trade Position                                              |
//+------------------------------------------------------------------+
int OpenTrade()
  {
	double TP, SL;
	double myBid, myAsk;
		
  // int vLots=LotCalc(0);
      double vLots=Lots;

   if (bsi>0)
   {
		myAsk = MarketInfo(Symbol(),MODE_ASK);
		TP = 0;
		if (TakeProfit > 0) TP = myAsk + TakeProfit * Point;
		SL = 0;
		if (StopLoss > 0) SL = myAsk - StopLoss * Point;
      OrderSend(Symbol(),OP_BUY,vLots,myAsk,Slippage,SL,TP,"",MAGICMA,0,Blue);
    }
   if (bsi<0)
   {
   	myBid = MarketInfo(Symbol(),MODE_BID);
		TP = 0;
		if (TakeProfit > 0) TP = myBid - TakeProfit * Point;
		SL = 0;
		if (StopLoss > 0) SL = myBid + StopLoss * Point;
      OrderSend(Symbol(),OP_SELL,vLots,myBid,Slippage,SL,TP,"",MAGICMA,0,Red);
 }
}

//+------------------------------------------------------------------+
//| Buy/Sell Indicator                                               |
//+------------------------------------------------------------------+
int CalcBSI()
  {
  //---- calc current indicators
  int GU_Trig=1,EU_Trig=1,UC_Trig=1,UJ_Trig=1;
  if (iWPR("GBPUSD",0,14,0)<-50) GU_Trig=-1;
  if (iWPR("EURUSD",0,14,0)<-50) EU_Trig=-1;
  if (iWPR("USDCHF",0,14,0)<-50) UC_Trig=-1;
  if (iWPR("USDJPY",0,14,0)<-50) UJ_Trig=-1;
  vTrig=GU_Trig+EU_Trig-UC_Trig-UJ_Trig;
  
  //Print("GU_Trig:",GU_Trig,";EU_Trig:",EU_Trig,";UC_Trig:",UC_Trig,";UJ_Trig:",UJ_Trig);

  bsi=0;
  if (vTrig>2) bsi=1;
  if (vTrig<-2) bsi=-1;
  if (pair>"USD") bsi=bsi*(-1);

}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
 // if (Hour()<7) return(0);
  openorders = GetCurrentOrders();
  CalcBSI();
  Comment("Dir: ",dir,"\nBSI: ",bsi,"\nTrig: ",vTrig);
  if (openorders > 0)   HandleOpenTrades();

  openorders = GetCurrentOrders();
  //---- exit trades
  if (openorders > 0) return(0);
  
  //---- open trades
  
   if (bsi!=0) OpenTrade();
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
                   if(os - myAsk > pt) ModifyOrder(type, ticket,op,myAsk+pt,tp, Aqua);
                   break;
           case 2: pt = Point*TrailingStop;
                   if(op - myAsk > pt && os > myAsk+pt) ModifyOrder(type, ticket,op,myAsk+pt,tp, Aqua);
                   break;
          }
       }
       return(0);
    }
}


void HandleOpenTrades()
  {
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
 
      if(OrderMagicNumber()!=MAGICMA ) continue;
      if (OrderSymbol() != Symbol()) continue;
      
       if (OrderType() == OP_BUY )
       {
          if (bsi<0)
          {      
             OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, White);
             return(0);
          }
          else
          {
            if (UseTrailingStop)
            {
               HandleTrailingStop(OP_BUY,OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
            }
            if (bsi > 0 && Bid-OrderStopLoss() <= RecalSLRange*Point) {
               OrderModify(OrderTicket(), OrderOpenPrice(), Ask-StopLoss*Point, OrderTakeProfit(), 0);
            }
          }
        }
        if (OrderType() == OP_SELL )
        {
          if (bsi>0)
          {
            OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, White);
            return(0);
          }
          else
          {
            if (UseTrailingStop)
             {                
               HandleTrailingStop(OP_SELL,OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
             }
            if (bsi < 0 && OrderStopLoss()-Ask <= RecalSLRange*Point) {
               OrderModify(OrderTicket(), OrderOpenPrice(), Bid+StopLoss*Point, OrderTakeProfit(), 0);
            }
          }
          
        }    
   }
}