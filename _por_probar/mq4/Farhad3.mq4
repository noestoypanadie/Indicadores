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
double macdHistCurrent, macdHistPrevious, macdSignalCurrent, macdSignalPrevious, highCurrent, lowCurrent;
double stochHistCurrent, stochHistPrevious, stochSignalCurrent, stochSignalPrevious;
double sarCurrent, sarPrevious,  momCurrent, momPrevious;
double maLongCurrent, maShortCurrent, maLongPrevious, maShortPrevious;
double realTP, realSL;
int cnt, ticket;
bool isBuying = false, isSelling = false, isBuyClosing = false, isSellClosing = false;




void deinit() {
   Comment("");
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start() {
// *****This line is for some reason very important. you'd better settle all your account at the end of day.*****
/*if (Hour()==24) {
OrderClose(Symbol
(),Lots,Ask,Slippage);
}
*/  
   // Check for invalid bars and takeprofit
   if(Bars < 200) {
      Print("Not enough bars for this strategy - ", nameEA);
      return(0);
      }
      /*
       if(isBuying && !isSelling && !isBuyClosing && !isSellClosing) {  // Check for BUY entry signal
         if(stopLoss > 0)
            realSL = Ask - stopLoss * Point;
         if(takeProfit > 0)
            realTP = Ask + takeProfit * Point;
         ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,realSL,realTP,nameEA+" - Magic: "+magicEA+" ",magicEA,0,Red);  // Buy
         if(ticket < 0) {
            Print("OrderSend (" + nameEA + ") failed with error #" + GetLastError() + " --> " + ErrorDescription(GetLastError()));
         } else {
             
         }
      }
      if(isSelling && !isBuying && !isBuyClosing && !isSellClosing) {  // Check for SELL entry signal
         if(stopLoss > 0)
            realSL = Bid + stopLoss * Point;
         if(takeProfit > 0)
            realTP = Bid - takeProfit * Point;
         ticket = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,realSL,realTP,nameEA+" - Magic: "+magicEA+" ",magicEA,0,Red); // Sell
         if(ticket < 0) {
            Print("OrderSend (" + nameEA + ") failed with error #" + GetLastError() + " --> " + ErrorDescription(GetLastError()));
         } else {
             
         }
      
   }
   return(0);
   */
    calculateIndicators();                      // Calculate indicators' value 
    //Check for TakeProfit Conditions  
   if(lTakeProfit<10){
      Print("TakeProfit less than 10 on this EA with Magic -", magicEA );
      return(0);
   }
   if(sTakeProfit<10){
      Print("TakeProfit less than 10 on this EA with Magic -", magicEA);
      return(0);
   }
   //Introducing new expressions
double faLow0=iLow(NULL,0,0);
double faEMA1=iMA(NULL,0,9,0,MODE_EMA,PRICE_TYPICAL,0);
double faEMA2=iMAOnArray(faEMA1,0,9,0,MODE_EMA,0);
double faEMA4=iMAOnArray(faEMA2,0,9,0,MODE_EMA,0);
double faHigh0=iHigh(NULL,0,0);
double faEMA3=iMA(NULL,0,9,0,MODE_EMA,PRICE_OPEN,0);
double stochHistCurrent    = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,0);
double sarCurrent          = iSAR(NULL,0,0.002,0.2,0);           // Parabolic Sar Current
double sarPrevious         = iSAR(NULL,0,0.002,0.2,1);  //Parabolic Sar Previous
   if(AccountFreeMargin()<(1000*Lots)){
      Print("We have no money. Free Margin = ", AccountFreeMargin());
      return(0);
   }
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
if (OrderSymbol()==Symbol()) {
return(True);
}
} 
} 
return(false);
}
void TrailingPositionsBuy(int trailingStop) { 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol()) { 
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
         if (OrderSymbol()==Symbol()) { 
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
   fm = OrderModify(OrderTicket(),OrderOpenPrice
(),ldStopLoss,OrderTakeProfit(),0,CLR_NONE); 
  
} 

void OpenBuy() { 
   double ldLot, ldStop, ldTake; 
   string lsComm; 
   ldLot = GetSizeLot(); 
   ldStop = 0; 
   ldTake = GetTakeProfitBuy(); 
   lsComm = GetCommentForOrder(); 
   OrderSend(Symbol
(),OP_BUY,ldLot,Ask,Slippage,ldStop,ldTake,lsComm,0,0,clOpenBuy); 
    
} 
void OpenSell() { 
   double ldLot, ldStop, ldTake; 
   string lsComm; 

   ldLot = GetSizeLot(); 
   ldStop = 0; 
   ldTake = GetTakeProfitSell(); 
   lsComm = GetCommentForOrder(); 
   OrderSend(Symbol
(),OP_SELL,ldLot,Bid,Slippage,ldStop,ldTake,lsComm,0,0,clOpenSell); 
  
} 
string GetCommentForOrder() { return(nameEA); } 
double GetSizeLot() { return(Lots); } 
double GetTakeProfitBuy() { return(Ask+lTakeProfit*Point); } 
double GetTakeProfitSell() { return(Bid-sTakeProfit*Point); } 

  void calculateIndicators() {  
    // Calculate indicators' value   
   macdHistCurrent     = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_MAIN,0);   
   macdHistPrevious    = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_MAIN,1);   
   macdSignalCurrent   = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_SIGNAL,0); 
   macdSignalPrevious  = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_SIGNAL,1); 
   stochHistCurrent    = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,0);
   stochHistPrevious   = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,1);
   stochSignalCurrent  = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
   stochSignalPrevious = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);
   sarCurrent          = iSAR(NULL,0,0.002,0.2,0);           // Parabolic Sar Current
   sarPrevious         = iSAR(NULL,0,0.002,0.2,1);  //Parabolic Sar Previous
   momCurrent          = iMomentum(NULL,0,14,PRICE_OPEN,0); // Momentum Current
   momPrevious         = iMomentum(NULL,0,14,PRICE_OPEN,1); // Momentum Previous
   highCurrent         = iHigh(NULL,0,0);     //High price Current
   lowCurrent          = iLow(NULL,0,0);      //Low Price Current
   maLongCurrent       = iMA(NULL,0,21,1,MODE_SMMA,PRICE_TYPICAL,0); //Current Long Term Moving Average 
   maLongPrevious      = iMA(NULL,0,21,1,MODE_SMMA,PRICE_TYPICAL,1); //Previous Long Term Moving Average 
   maShortCurrent      = iMA(NULL,0,2,1,MODE_SMMA,PRICE_TYPICAL,0);  //Current Short Term Moving Average 
   maShortPrevious     = iMA(NULL,0,2,1,MODE_SMMA,PRICE_TYPICAL,1);  //Previous Long Term Moving Average 
   
   // Check for BUY, SELL, and CLOSE signal
   isBuying  = false;
   isSelling = false;
   isBuyClosing = false;
   isSellClosing = false;
}