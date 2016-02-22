//+------------------------------------------------------------------+
//|     Farhad3.mq4 |
//|     Copyright © 2006, Farhad Farshad |
//|     http://www.rahbord-investment.com
//|     http://farhadfarshad.com
//|     This EA is optimized to work on
//|     GBP/JPY & GBP/USD & EUR/USD M1  TimeFrame ... if you want the optimized 
//|     EA s for any currency pair please
//|     mail me at: info@farhadfarshad.com
//|     This is the third version of this EA. If
//|     you want the fourth edition (MagicFarhad.mq4) 
//|     with considerably better performance mail me.
//|     (It's not free and it doesn't have trial version!)
//|     Enjoy a better automatic investment:) with at least 100% a month.
//|     If you get money from this EA please donate some to poor people of your country.
//+-----------------------------------------------------------------+
#property copyright "Copyright © 2006, Farhad Farshad"
#property link      "http://www.rahbord-investment.com"
#include <stdlib.mqh>

extern double lTakeProfit = 10;   // recomended  no more than 20
extern double sTakeProfit = 10;   // recomended  no more than 20
extern double takeProfit   = 10;            // recomended  no more than 20
extern double stopLoss     = 10;             // do not use s/l at all. Take it easy man. I'll guarantee your profit :)
extern int magicEA         = 112;        // Magic EA identifier. Allows for several co-existing EA with different input values
extern double lTrailingStop = 8;   // trail stop in points
extern double sTrailingStop = 8;   // trail stop in points
extern color clOpenBuy = Blue;  //Different colors for different positions
extern color clCloseBuy = Aqua;  //Different colors for different positions
extern color clOpenSell = Red;  //Different colors for different positions
extern color clCloseSell = Violet;  //Different colors for different positions
extern color clModiBuy = Blue;   //Different colors for different positions
extern color clModiSell = Red;   //Different colors for different positions
extern int Slippage = 2;
extern double Lots = 1;// you can change the lot but be aware of margin. Its better to trade with 1/4 of your capital. 
extern string nameEA        = "Farhad3.mq4";// To "easy read" which EA place an specific order and remember me forever :)
extern int SignalCandle = 0;



void deinit() {
   Comment("");
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start() {
// *****This line is for some reason very important. you'd better settle all your account at the end of day.*****

if (TimeHour(CurTime())==23)
{
 ClosePositions();
 return(0);
 }
  
   // Check for invalid bars and takeprofit
   if(Bars < 200) {
      Print("Not enough bars for this strategy - ", nameEA);
      return(0);
      }
    //Check for TakeProfit Conditions  
   if(lTakeProfit<10){
      Print("TakeProfit less than 10 on this EA with Magic -", magicEA );
      return(0);
   }
   if(sTakeProfit<10){
      Print("TakeProfit less than 10 on this EA with Magic -", magicEA);
      return(0);
   }
   if(AccountFreeMargin()<(1000*Lots)){
      Print("We have no money. Free Margin = ", AccountFreeMargin());
      return(0);
   }

   //Introducing new expressions
   
double faLow0=iLow(NULL,0,SignalCandle);
double faEMA1=iMA(NULL,0,9,0,MODE_EMA,PRICE_TYPICAL,SignalCandle);
double faHigh0=iHigh(NULL,0,SignalCandle);
double faEMA3=iMA(NULL,0,9,0,MODE_EMA,PRICE_OPEN,SignalCandle);

   //Buy Condition
   if (!takePositions()){

      if ((faLow0>faEMA1)){
         OpenBuy();
         return(0);
      }
//Sell Condition
      if ((faHigh0<faEMA3)){
         OpenSell();
         return(0);
      }
   }
   //Trailing Expressions
   TrailingPositionsBuy(lTrailingStop);
   TrailingPositionsSell(sTrailingStop);
   return (0);
}

bool takePositions() {
for (int i=0; i<OrdersTotal(); i++) {
if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) {
return(True);
}
} 
} 
return(false);
}
void TrailingPositionsBuy(int trailingStop) { 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) { 
            if (OrderType()==OP_BUY) { 
               if (Bid-OrderOpenPrice()>trailingStop*Point) { 
                  if (OrderStopLoss()<Bid-trailingStop*Point) 
                     ModifyStopLoss(Bid-trailingStop*Point); 
               } 
            } 
         } 
      } 
   } 
} 
void TrailingPositionsSell(int trailingStop) { 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) { 
            if (OrderType()==OP_SELL) { 
               if (OrderOpenPrice()-Ask>trailingStop*Point) { 
                  if (OrderStopLoss()>Ask+trailingStop*Point || 
OrderStopLoss()==0)  
                     ModifyStopLoss(Ask+trailingStop*Point); 
               } 
            } 
         } 
      } 
   } 
} 
void ModifyStopLoss(double ldStopLoss) { 
   bool fm;
   fm = OrderModify(OrderTicket(),OrderOpenPrice(),ldStopLoss,OrderTakeProfit(),0,CLR_NONE); 
  
} 

void OpenBuy() { 
   double ldStop, ldTake;
    
   ldStop = 0; 
   if (stopLoss > 0)ldStop = Ask - stopLoss * Point; 
   ldTake = 0;
   if (lTakeProfit > 0) ldTake = Ask+lTakeProfit*Point; 
   OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,ldStop,ldTake,nameEA,magicEA,0,clOpenBuy); 
    
} 
void OpenSell() { 
   double ldStop, ldTake; 

   ldStop = 0; 
   if (stopLoss > 0)ldStop = Bid + stopLoss * Point; 
   ldTake = 0;
   if (sTakeProfit > 0) ldTake = Bid-sTakeProfit*Point; 
   OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,ldStop,ldTake,nameEA,magicEA,0,clOpenSell); 
  
}
 
void ClosePositions(){ 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) { 
            if (OrderType()==OP_SELL) OrderClose(OrderTicket(),Lots,Ask,Slippage);
            if (OrderType()==OP_BUY) OrderClose(OrderTicket(),Lots,Bid,Slippage);
         } 
      } 
   } 
} 



