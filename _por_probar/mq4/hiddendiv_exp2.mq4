//+------------------------------------------------------------------+
//|                                                hiddendiv-exp.mq4 |
//|                                  Nick Bilak, beluck[AT]gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Nick Bilak"
#property link      "http://metatrader.50webs.com/"
#include <stdlib.mqh>

extern int myMagic = 1;
extern int NumTrades = 3;
extern double TakeProfit = 110;
extern double StopLoss = 40;  
extern double BreakEvenStop = 350;  
extern double TrailingStop = 350;  

extern int    slippage=2;   	//slippage for market order processing
extern int    shift=1;			//shift to current bar, 

extern double Lots = 0.1;
extern double MaximumRisk = 5;
extern bool   FixedLot = true;

extern int    MFIperiod=3;

extern int    OrderTriesNumber=2; //to repeate sending orders when got some error

extern string    EAName="hiddendiv"; 

bool buysig,sellsig,closebuy,closesell; int lastsig,tries,at,at2;


void start()  {

   //---- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false) return;

   //---- check for signals
   CheckForSignals();

   if (CalculateCurrentOrders(Symbol())==0)     //---- calculate open orders by current symbol
      CheckForOpen();
   else {
      CheckForClose();
      BreakEvenStop();
      TrailStop();
   }
        
}

double LotsRisk(int StopLoss)  { 
   double lot=Lots;
//---- select lot size
   if (!FixedLot)
      lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk*0.001/StopLoss,1);
   else
      lot=Lots;
//---- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
}

//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int ord;
//----
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==symbol && OrderMagicNumber()==myMagic) ord++;
     }
//---- return orders volume
   return(ord);
}

//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForSignals() {
      
      buysig=false;
      sellsig=false;
      //indicators variables
      double mfi1 = iMFI(NULL,0,MFIperiod,shift);
      double mfi2=mfi1;
      int i=shift+1;
      if (mfi1>=100) {
         while (mfi2>=100) {
            mfi2 = iMFI(NULL,0,MFIperiod,i);
            i++;
         }
         while (mfi2<100) {
            mfi2 = iMFI(NULL,0,MFIperiod,i);
            i++;
         }
         i--;
         if (High[shift]<High[i]) {
             sellsig=true;
         }
      }
      if (mfi1<=0) {
         while (mfi2<=0) {
            mfi2 = iMFI(NULL,0,MFIperiod,i);
            i++;
         }
         while (mfi2>0) {
            mfi2 = iMFI(NULL,0,MFIperiod,i);
            i++;
         }
         i--;
         if (Low[shift]>Low[i]) {
             buysig=true;
         }
      }
            
      //closebuy=sellsig;
      //closesell=buysig;
}

void CheckForOpen() {
   int    res,tr, cnt;
//---- sell conditions

   if(sellsig && lastsig!=Time[0])  {
   //if(buysig && lastsig!=Time[0])  {
   for (cnt = 0; cnt < NumTrades; cnt++)
   {
	   res=OpenAtMarket(OP_SELL,LotsRisk(StopLoss));
      if (res<=0) Print("Error SELL order : ",ErrorDescription(GetLastError()));
      lastsig=Time[0];
      if (cnt == NumTrades - 1) return;
   }
   }
   
//---- buy conditions
   //if(sellsig && lastsig!=Time[0])  {
   if(buysig && lastsig!=Time[0])  {
   for (cnt = 0; cnt < NumTrades; cnt++)
   {
	   res=OpenAtMarket(OP_BUY,LotsRisk(StopLoss));
      if (res<=0) Print("Error BUY order : ",ErrorDescription(GetLastError()));
      lastsig = Time[0];
      if (cnt == NumTrades - 1) return;
   }
   }
}
  
  
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()  {
   bool bres; int tr;
   for(int i=OrdersTotal() - 1; i>= 0; i--)  {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)  break;
      if(OrderMagicNumber()!=myMagic || OrderSymbol()!=Symbol()) continue;
      //---- check order type 
      if(OrderType()==OP_BUY && closebuy) {
      //if(OrderType()==OP_BUY && closesell) {
         bres=CloseAtMarket(OrderTicket(),OrderLots());
         break;
      }
      if(OrderType()==OP_SELL && closesell)  {
      //if(OrderType()==OP_SELL && closebuy)  {
         bres=CloseAtMarket(OrderTicket(),OrderLots());
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

int OpenAtMarket(int mode,double lot) {
   int    res,tr,col;
   double openprice,sl,tp;
   tries=0;
   while (res<=0 && tries<OrderTriesNumber) {
      tr=0; while (tr<5 && !IsTradeAllowed()) { tr++; Sleep(2000); }
      RefreshRates();
      if (mode==OP_SELL) {
         openprice=Bid; 
         sl=openprice+StopLoss*Point;
         tp=openprice-TakeProfit*Point;
         col=Red;
      } else {
         openprice=Ask;
         sl=openprice-StopLoss*Point;
         tp=openprice+TakeProfit*Point;
         col=Blue;
      }
      res=OrderSend(Symbol(),mode,lot,openprice,slippage,sl,tp,EAName+myMagic,myMagic,0,col);
      tries++;
   }
   return(res);
}


bool CloseAtMarket(int ticket,double lot) {
   bool bres=false; int tr;
   tries=0;
   while (!bres && tries<OrderTriesNumber) {
      tr=0; while (tr<5 && !IsTradeAllowed()) { tr++; Sleep(2000); }
      RefreshRates();
      bres=OrderClose(ticket,lot,OrderClosePrice(),slippage,White);
      tries++;
   }
   if (!bres) Print("Error closing order : ",ErrorDescription(GetLastError()));
}

