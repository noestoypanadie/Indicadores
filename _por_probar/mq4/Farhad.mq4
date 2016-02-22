//+------------------------------------------------------------------+
//|     Farhad.mq4 |
//|     Copyright © 2006, Farhad Farshad |
//|     http://www.rahbord-investment.com
//|     http://farhadfarshad.Com
//|     This EA is optimized to work on
//|     GBP/JPY ... if you want the optimized 
//|     EA s for any currency pair please
//|     mail me at: info@farhadfarshad.Com
//|     This is the first version of this EA. If
//|     you want the second edition (Farhad2.mq4) 
//|     with considerably better performance mail me.
//
//|     Enjoy a better automatic investment:) with at least 70% a month.
//+-----------------------------------------------------------------+
#property copyright "Copyright © 2006, Farhad Farshad"
#property link      "http://www.rahbord-investment.com"
#include <stdlib.mqh>

extern double lots         = 0.1;           // you can change the lot but be aware of margin. Its better to trade with 1/4 of your capital. 
extern double trailingStop = 15;            // trail stop in points
extern double takeProfit   = 20;            // recomended  no more than 20
extern double stopLoss     = 0;             // do not use s/l at all. Take it easy man. I'll guarantee your profit :)
extern double slippage     = 3;             // Could be higher with some brokers
extern string nameEA       = "Farhad";      // To "easy read" which EA place an specific order and remember me forever :)
extern int magicEA         = 110;        // Magic EA identifier. Allows for several co-existing EA with different input values

double macdHistCurrent, macdHistPrevious, macdSignalCurrent, macdSignalPrevious, highCurrent, lowCurrent;
double stochHistCurrent, stochHistPrevious, stochSignalCurrent, stochSignalPrevious;
double sarCurrent, sarPrevious,  momCurrent, momPrevious;
double maLongCurrent, maShortCurrent, maLongPrevious, maShortPrevious;
double realTP, realSL;
bool isBuying = false, isSelling = false, isBuyClosing = false, isSellClosing = false;
int cnt, ticket;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   return(0);
}

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   return(0);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
   // Check for invalid bars and takeprofit
   if(Bars < 200) {
      Print("Not enough bars for this strategy - ", nameEA);
      return(0);
   }
   calculateIndicators();                      // Calculate indicators' value   
   
   // Control open trades
   int totalOrders = OrdersTotal();
   int numPos = 0;
      
   for(cnt=0; cnt<totalOrders; cnt++) {        // scan all orders and positions...
      OrderSelect(cnt, SELECT_BY_POS);         // the next line will check for ONLY market trades, not entry orders
      if(OrderSymbol() == Symbol() && OrderType() <= OP_SELL && OrderMagicNumber() == magicEA) {   // only look for this symbol, and only orders from this EA      
         numPos++;
         
            if(trailingStop > 0) {             // Check trailing stop
               if(Bid-OrderOpenPrice() > trailingStop*Point) {
                  if(OrderStopLoss() < (Bid - trailingStop*Point)) {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-trailingStop*Point,OrderTakeProfit(),0,Blue);
                     //prtAlert("Farhad : Modifying BUY order");
                  }
               }
              
            if(trailingStop > 0) {             // Control trailing stop
               if(OrderOpenPrice() - Ask > trailingStop*Point) {
                  if(OrderStopLoss() == 0 || OrderStopLoss() > Ask + trailingStop*Point) {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+trailingStop*Point,OrderTakeProfit(),0,Red);
                    // prtAlert("Farhad : Modifying SELL order");
                  }
               }           
            } 
         }
      }
   }
   
   // If there is no open trade for this pair and this EA
   if(numPos < 1) {   
      if(AccountFreeMargin() < 300*lots) {
         Print("Not enough money to trade ", lots, " lots. Strategy:", nameEA);
         return(0);
      }
      if(isBuying && !isSelling && !isBuyClosing && !isSellClosing) {  // Check for BUY entry signal
         if(stopLoss > 0)
            realSL = Ask - stopLoss * Point;
         if(takeProfit > 0)
            realTP = Ask + takeProfit * Point;
         ticket = OrderSend(Symbol(),OP_BUY,lots,Ask,slippage,realSL,realTP,nameEA+" - Magic: "+magicEA+" ",magicEA,0,Red);  // Buy
         if(ticket < 0) {
            Print("OrderSend (" + nameEA + ") failed with error #" + GetLastError() + " --> " + ErrorDescription(GetLastError()));
         } else {
            prtAlert("Farhad : Buying"); 
         }
      }
      if(isSelling && !isBuying && !isBuyClosing && !isSellClosing) {  // Check for SELL entry signal
         if(stopLoss > 0)
            realSL = Bid + stopLoss * Point;
         if(takeProfit > 0)
            realTP = Bid - takeProfit * Point;
         ticket = OrderSend(Symbol(),OP_SELL,lots,Bid,slippage,realSL,realTP,nameEA+" - Magic: "+magicEA+" ",magicEA,0,Red); // Sell
         if(ticket < 0) {
            Print("OrderSend (" + nameEA + ") failed with error #" + GetLastError() + " --> " + ErrorDescription(GetLastError()));
         } else {
            prtAlert("Farhad : Selling"); 
         }
      }
   }
   return(0);
}

void calculateIndicators() {    // Calculate indicators' value   
   macdHistCurrent     = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_MAIN,0);   
   macdHistPrevious    = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_MAIN,1);   
   macdSignalCurrent   = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_SIGNAL,0); 
   macdSignalPrevious  = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_SIGNAL,1); 
   stochHistCurrent    = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,0);
   stochHistPrevious   = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,1);
   stochSignalCurrent  = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
   stochSignalPrevious = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);
   sarCurrent          = iSAR(NULL,0,0.02,0.2,0);           // Parabolic Sar Current
   sarPrevious         = iSAR(NULL,0,0.02,0.2,1);  //Parabolic Sar Previous
   momCurrent          = iMomentum(NULL,0,14,PRICE_OPEN,0); // Momentum Current
   momPrevious         = iMomentum(NULL,0,14,PRICE_OPEN,1); // Momentum Previous
   highCurrent         = iHigh(NULL,0,0);     //High price Current
   lowCurrent          = iLow(NULL,0,0);      //Low Price Current
   maLongCurrent       = iMA(NULL,0,21,1,MODE_SMMA,PRICE_TYPICAL,0); //Current Long Term Moving Average 
   maLongPrevious      = iMA(NULL,0,21,1,MODE_SMMA,PRICE_TYPICAL,1); //Previous Long Term Moving Average 
   maShortCurrent      = iMA(NULL,0,2,1,MODE_SMMA,PRICE_TYPICAL,0);  //Current Short Term Moving Average 
   maShortPrevious     = iMA(NULL,0,2,1,MODE_SMMA,PRICE_TYPICAL,1);  //Previous Long Term Moving Average 
   
   // Check for BUY, SELL, and CLOSE signal
   isBuying  = (sarCurrent<=Ask && sarPrevious>sarCurrent && momCurrent<100 && macdHistCurrent<macdSignalCurrent && stochHistCurrent<35);
   isSelling = (sarCurrent>=Bid && sarPrevious<sarCurrent && momCurrent>100 && macdHistCurrent>macdSignalCurrent && stochHistCurrent>60);
   isBuyClosing = false;
   isSellClosing = false;
}

void prtAlert(string str = "") {
   Print(Symbol() + " - " + str);
   Alert(Symbol() + " - " + str);
}


//+------------------------------------------------------------------+