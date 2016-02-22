//+------------------------------------------------------------------+
//|                                                     ross-exp.mq4 |
//|                Copyright © 2005, Nick Bilak, beluck[AT]gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Nick Bilak"
#property link      "http://metatrader.50webs.com/"
#include <stdlib.mqh>

extern int myMagic = 20051203;

extern double AllProfit = 100;
extern double AllLoss = 50;  
extern double TakeProfit = 100;
extern double StopLoss = 40;  
extern double TrailingStop = 15;

extern int    slippage=2;   	//slippage for market order processing
extern int    shift=0;			//shift to current bar, 

extern double Lots = 0.1;

extern int       AOLongLevel=60;
extern int       AOShortLevel=-30;

extern int       OrderTriesNumber=5;

bool buysig1,sellsig1,buysig2,sellsig2,buysig3,sellsig3,closeall,closeloss,closebuy,closesell; 
int lastsig,last,tries,a1,a2,a3,a4;
double openPrice1,openPrice2,openPrice3;
double openProfit,openLoss;

//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders()
  {
   int orders;
   openProfit=0;
   openLoss=0;
   for(int i=0;i<OrdersTotal();i++) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==myMagic) {
         orders++;
         if (OrderProfit()>0) openProfit+=OrderProfit(); else openLoss+=-OrderProfit();
      }
   }
   return(orders);
}

//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForSignals() {
      double ao1=iAO(NULL,0,shift);
      double ao2=iAO(NULL,0,shift+1);
      double ao3=iAO(NULL,0,shift+2);

      buysig1=false;
      buysig2=false;
      buysig3=false;
      sellsig1=false;
      sellsig2=false;
      sellsig3=false;
      if ((ao1>AOLongLevel*Point && ao2<=AOLongLevel*Point) || (ao1>AOShortLevel*Point && ao2<=AOShortLevel*Point)) {
         if (a1!=Time[0]) {
            Alert(Symbol()+Period()+" 0.AO - level cross up");
            a1=Time[0];
         }
      }
      if ((ao2>AOLongLevel*Point && ao3<=AOLongLevel*Point) || (ao2>AOShortLevel*Point && ao3<=AOShortLevel*Point) && ao1>ao2) {
         if (a2!=Time[0]) {
            a2=Time[0];
         }
         buysig1=true;
      }

      if ((ao1<AOLongLevel*Point && ao2>=AOLongLevel*Point) || (ao1<AOShortLevel*Point && ao2>=AOShortLevel*Point)) {
         if (a1!=Time[0]) {
            Alert(Symbol()+Period()+" 0.AO - level cross down");
            a1=Time[0];
         }
      }
      if ((ao2<AOLongLevel*Point && ao3>=AOLongLevel*Point) || (ao2<AOShortLevel*Point && ao3>=AOShortLevel*Point) && ao1<ao2) {
         if (a2!=Time[0]) {
            a2=Time[0];
         }
         sellsig1=true;
      }
      closeall=false;
      closeloss=false;
      if (openProfit>AllProfit) closeall=true;
      if (openLoss>AllLoss) closeloss=true;
}

void CheckForOpen() {
   int    res,tr;
//---- buy conditions
   if(CalculateCurrentOrders()==0 && buysig1 && last!=Time[0])  {
	   res=0;
	   tries=0;
		while (res<=0 && tries<OrderTriesNumber) {
		    tr=0;
          while(tr<7 && !IsTradeAllowed()) { tr++; Sleep(5000); }
		    RefreshRates();
          res=OrderSend(Symbol(),OP_BUY,Lots,Ask,slippage,Ask-StopLoss*Point,Ask+TakeProfit*Point,"ao1b",myMagic,0,Blue);
          Alert(Symbol()+Period()+" 1.AO-enter long 1 lot");
		    if (res<0) Print("Error opening BUY order : ",ErrorDescription(GetLastError()));
          tries++;
		}
		if (res>0) { last=Time[0]; openPrice1=Ask; }
      return;
   }
//---- sell conditions
   if(CalculateCurrentOrders()==0 && sellsig1 && last!=Time[0])  {
	   res=0;
	   tries=0;
		while (res<=0 && tries<OrderTriesNumber) {
		    tr=0;
          while(tr<7 && !IsTradeAllowed()) { tr++; Sleep(5000); }
		    RefreshRates();
          res=OrderSend(Symbol(),OP_SELL,Lots,Bid,slippage,Bid+StopLoss*Point,Bid-TakeProfit*Point,"ao1s",myMagic,0,Red);
          Alert(Symbol()+Period()+" 1.AO-enter short 1 lot");
		    if (res<0) Print("Error opening SELL order : ",ErrorDescription(GetLastError()));
		    tries++;
		}
		if (res>0) { last=Time[0]; openPrice1=Bid; }
      return;
   }
}
  
  
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()  {
   bool bres; int tr;
   for(int i=0;i<OrdersTotal();i++)  {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)  break;
      if(OrderMagicNumber()!=myMagic || OrderSymbol()!=Symbol()) continue;
      if (closeall) {
         bres=false;
         tries=0;
         while (!bres && tries<OrderTriesNumber) {
		      tr=0;
            while(tr<7 && !IsTradeAllowed()) { tr++; Sleep(5000); }
            RefreshRates();
            bres=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),slippage,White);
            Sleep(3000);
	         if (!bres) Print("Error closing order : ",ErrorDescription(GetLastError()));
	         tries++;
	      }
      }
      if (closeloss && OrderProfit()<0) {
         bres=false;
         tries=0;
	      while (!bres && tries<OrderTriesNumber) {
		      tr=0;
            while(tr<7 && !IsTradeAllowed()) { tr++; Sleep(5000); }
            RefreshRates();
            bres=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),slippage,White);
            Sleep(3000);
		      if (!bres) Print("Error closing order : ",ErrorDescription(GetLastError()));
		      tries++;
		   }
	   }
	}
}


void TickTrailing() {
   bool bres; int tr;
   double StopLoss;
      for (int i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != Symbol() || OrderMagicNumber() != myMagic )  continue;
         if ( OrderType() == OP_BUY ) {
            StopLoss = OrderStopLoss()+Point;
		      tr=0;
            while(tr<7 && !IsTradeAllowed()) { tr++; Sleep(5000); }
            bres=OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, White);
            Sleep(3000);
			   if (!bres) Print("Error Modifying BUY order : ",ErrorDescription(GetLastError()));
         }
   
         if ( OrderType() == OP_SELL ) {
            StopLoss = OrderStopLoss()-Point;
		      tr=0;
            while(tr<7 && !IsTradeAllowed()) { tr++; Sleep(5000); }
            bres=OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, Gold);
            Sleep(3000);
			   if (!bres) Print("Error Modifying SELL order : ",ErrorDescription(GetLastError()));
         }
      }
}

void TrailStop() {
   bool bres; int tr;
   double StopLoss;
   if ( TrailingStop > 2 ) {
      for (int i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != Symbol() || OrderMagicNumber() != myMagic )  continue;
         if ( OrderType() == OP_BUY ) {
            if ( Bid < OrderOpenPrice()+TrailingStop*Point )  continue;
            StopLoss = Bid-TrailingStop*Point;
            if ( StopLoss > OrderStopLoss() ) {
		            tr=0;
                  while(tr<7 && !IsTradeAllowed()) { tr++; Sleep(5000); }
                  bres=OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, White);
                  Sleep(3000);
					   if (!bres) Print("Error Modifying BUY order : ",ErrorDescription(GetLastError()));
            }
         }
   
         if ( OrderType() == OP_SELL ) {
            if ( Ask > OrderOpenPrice()-TrailingStop*Point )  continue;
            StopLoss = Ask+TrailingStop*Point;
            if ( StopLoss < OrderStopLoss() ) {
		            tr=0;
                  while(tr<7 && !IsTradeAllowed()) { tr++; Sleep(5000); }
                  bres=OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, Gold);
                  Sleep(3000);
					   if (!bres) Print("Error Modifying SELL order : ",ErrorDescription(GetLastError()));
            }
         }
      }
   }
   return;
}

void start()  {

   //---- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false) return;

   //---- check for signals
   CheckForSignals();

   //---- calculate open orders by current symbol
   if (CalculateCurrentOrders()==0) 
      CheckForOpen();
      
   if (CalculateCurrentOrders()>0) 
      CheckForClose();

   TickTrailing();     

   TrailStop();
}
//+------------------------------------------------------------------+