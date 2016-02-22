//+------------------------------------------------------------------+
//|                                               HMAchannel-exp.mq4 |
//|                                  Nick Bilak, beluck[AT]gmail.com |
//|v.1                                                               |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Nick Bilak"
#property link      "http://metatrader.50webs.com/"
#include <stdlib.mqh>

extern int myMagic = 1;

extern double TakeProfit = 700;
extern double StopLoss = 200;  
extern double BreakEvenStop = 5000;  
extern double TrailingStop = 5000;  

extern int    slippage=2;   	//slippage for market order processing
extern int    OrderTriesNumber=2; //to repeate sending orders when got some error

extern double Lots = 0.1;      //fixed lot size
extern double MinLot = 0.1;    //minimum lot size
extern double MaximumRisk = 5; //% risk. lot size will be calculated so that stoploss was equal to risk% of balance
extern bool   FixedLot = true; //trigger to use MM

extern string ip1="__HMA env__";
extern int _maPeriod=20;
extern double deviation = 0.5;
extern int price1 = PRICE_OPEN;
extern int price2 = PRICE_OPEN;
extern string ip2="__HMA angle__";
extern int _maPeriodA=20;
extern int priceA = PRICE_OPEN;

extern int    DirectionFilter=0; ///1 -> Only take long trades if HMA points up.
extern int    Angle=0; ///xxxx - Only take trade if angle is at least xxxx
                        //Steep angles usually go with strong trends.
extern int    OpenOutside=0; ///1 - Only take the trade if the price *opens* outside the channel
                              //When 0 we enter at a intraday cross of the channel.
extern int    ExitAtClose=0; ///1 - If we close at the wrong side of the channel we
                              //close the position. 0=use intraday cross.
extern int    FlatExit=0; //xxx; - Exit if the angle flattens by xxx deg Compared to the steepest angle recorded in this trade.

extern string    EAName="HMAchan"; 

bool buysig,sellsig,closebuy,closesell; //flags for signals
int lastsig,tries,at,at2;
double maxangle;

void start()  {

   //---- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false) return;
   
   int co=CalculateCurrentOrders(Symbol());
   if (co==0) maxangle=0;
   //---- check for signals
   CheckForSignals();

   if (co==0) {
      CheckForOpen();
   } else {
      CheckForClose();
      BreakEvenStop();
      TrailStop();
   }
        
}

double LotsRisk(int StopLoss)  { 
   double lot=Lots;
   if (!FixedLot)
      lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk*0.001/StopLoss,1);
   else
      lot=Lots;
   if(lot<MinLot) lot=MinLot;
   return(lot);
}

int CalculateCurrentOrders(string symbol)  {
   int ord;
   for(int i=0;i<OrdersTotal();i++)  {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==symbol && OrderMagicNumber()==myMagic) ord++;
   }
   return(ord);
}

void CheckForSignals() {
      //indicators variables

      double up0 = iCustom(NULL,0,"HMAenv",_maPeriod,deviation,price1,price2,0,0); 
      double up1 = iCustom(NULL,0,"HMAenv",_maPeriod,deviation,price1,price2,0,1); 
      double lo0 = iCustom(NULL,0,"HMAenv",_maPeriod,deviation,price1,price2,1,0); 
      double lo1 = iCustom(NULL,0,"HMAenv",_maPeriod,deviation,price1,price2,1,1); 
      double ang0 = iCustom(NULL,0,"HMA_angle",_maPeriodA,priceA,0,0); 
      maxangle = MathMax(maxangle,ang0);
      
      buysig=false;
      sellsig=false;

/*
extern int    DirectionFilter=0; ///1 -> Only take long trades if HMA points up.
extern int    Angle=0; ///xxxx - Only take trade if angle is at least xxxx
                        //Steep angles usually go with strong trends.
extern int    OpenOutside=0; ///1 - Only take the trade if the price *opens* outside the channel
                              //When 0 we enter at a intraday cross of the channel.
extern int    ExitAtClose=0; ///1 - If we close at the wrong side of the channel we
                              //close the position. 0=use intraday cross.
extern int    FlatExit=0; //xxx; - Exit if the angle flattens by xxx deg Compared to the steepest angle recorded in this trade.

*/
      //long entry signal condition
      if ( (DirectionFilter==0 || (DirectionFilter!=0 && up0>up1)) &&
           (ang0>=Angle*Point) && 
           ( (OpenOutside==0 && Close[0]>up0) || (OpenOutside!=0 && Close[1]>up1) )
            ) { 
          buysig=true;
      }
      //short entry signal
      if ( (DirectionFilter==0 || (DirectionFilter!=0 && up0<up1)) &&
           (ang0>=Angle*Point) && 
           ( (OpenOutside==0 && Close[0]<lo0) || (OpenOutside!=0 && Close[1]<lo1) )
            ) { 
          sellsig=true;
      }

      closebuy=false;
      closesell=false;
      //long exit signal
      if ( ((ExitAtClose==0 && Close[0]<lo0) || (ExitAtClose!=0 && Close[1]<lo1)) ||
           (FlatExit>0 && FlatExit*Point>=maxangle) ) { 
          closebuy=true;
      }
      //short exit signal
      if ( ((ExitAtClose==0 && Close[0]>up0) || (ExitAtClose!=0 && Close[1]>up1)) ||
           (FlatExit>0 && FlatExit*Point>=maxangle) ) { 
          closesell=true;
      }
}

void CheckForOpen() {
   int    res,tr;
   
//---- sell conditions
   if(sellsig && lastsig!=Time[0])  {
	   res=0;
	   tries=0;
		while (res<=0 && tries<OrderTriesNumber) {
          tr=0; while (tr<5 && !IsTradeAllowed()) { tr++; Sleep(2000); }
		    RefreshRates();
          res=OrderSend(Symbol(),OP_SELL,LotsRisk(StopLoss),Bid,slippage,Bid+StopLoss*Point,Bid-TakeProfit*Point,EAName,myMagic,0,Red);
		    if (res<0) Print("Error opening SELL order : ",ErrorDescription(GetLastError()));
		    tries++;
		}
	   //----
      lastsig=Time[0]; 
      return;
   }
//---- buy conditions
   if(buysig && lastsig!=Time[0])  {
	   res=0;
	   tries=0;
		while (res<=0 && tries<OrderTriesNumber) {
          tr=0; while (tr<5 && !IsTradeAllowed()) { tr++; Sleep(2000); }
		    RefreshRates();
          res=OrderSend(Symbol(),OP_BUY,LotsRisk(StopLoss),Ask,slippage,Ask-StopLoss*Point,Ask+TakeProfit*Point,EAName,myMagic,0,Blue);
          tries++;
		}
      lastsig = Time[0];
      return;
   }
}
  
  
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()  {
   bool bres; int tr;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)  break;
      if(OrderMagicNumber()!=myMagic || OrderSymbol()!=Symbol()) continue;
      //---- check order type 
      if(OrderType()==OP_BUY)
        {
         if (closebuy) {
            bres=false;
	         tries=0;
		      while (!bres && tries<OrderTriesNumber) {
               tr=0; while (tr<5 && !IsTradeAllowed()) { tr++; Sleep(2000); }
               RefreshRates();
               bres=OrderClose(OrderTicket(),OrderLots(),Bid,slippage,White);
			      if (!bres) Print("Error closing order : ",ErrorDescription(GetLastError()));
			      tries++;
			   }
		   }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if (closesell) {
            bres=false;
	         tries=0;
		      while (!bres && tries<OrderTriesNumber) {
               tr=0; while (tr<5 && !IsTradeAllowed()) { tr++; Sleep(2000); }
               RefreshRates();
               bres=OrderClose(OrderTicket(),OrderLots(),Ask,slippage,White);
			      if (!bres) Print("Error closing order : ",ErrorDescription(GetLastError()));
			      tries++;
			   }
		   }
         break;
        }
     }
}


void TrailStop() {
   bool bres;
   double StopLoss;
   if ( TrailingStop > 2 ) {
      for (int i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != Symbol() || OrderMagicNumber() != myMagic )  continue;
         if ( OrderType() == OP_BUY ) {
            if ( Bid < OrderOpenPrice()+TrailingStop*Point )  return;
            StopLoss = Bid-TrailingStop*Point;
            if ( StopLoss > OrderStopLoss() ) {
                  bres=OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, White);
					   if (!bres) Print("Error Modifying BUY order : ",ErrorDescription(GetLastError()));
            }
         }
   
         if ( OrderType() == OP_SELL ) {
            if ( Ask > OrderOpenPrice()-TrailingStop*Point )  return;
            StopLoss = Ask+TrailingStop*Point;
            if ( StopLoss < OrderStopLoss() ) {
                  bres=OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, Gold);
					   if (!bres) Print("Error Modifying SELL order : ",ErrorDescription(GetLastError()));
            }
         }
      }
   }
   return;
}

void BreakEvenStop() {
   bool bres;
   double StopLoss;
   if ( BreakEvenStop > 2 ) {
      for (int i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != Symbol() || OrderMagicNumber() != myMagic )  continue;
         if ( OrderType() == OP_BUY ) {
            if ( Bid < OrderOpenPrice()+BreakEvenStop*Point )  return;
            StopLoss = OrderOpenPrice();
            if ( StopLoss > OrderStopLoss() ) {
                  bres=OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, White);
					   if (!bres) Print("Error Modifying BUY order : ",ErrorDescription(GetLastError()));
            }
         }
   
         if ( OrderType() == OP_SELL ) {
            if ( Ask > OrderOpenPrice()-BreakEvenStop*Point )  return;
            StopLoss = OrderOpenPrice();
            if ( StopLoss < OrderStopLoss() ) {
                  bres=OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, Gold);
					   if (!bres) Print("Error Modifying SELL order : ",ErrorDescription(GetLastError()));
            }
         }
      }
   }
   return;
}


