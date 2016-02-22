//+------------------------------------------------------------------+
//|                                                   DayTrading.mq4 |
//|                               Copyright © 2005, NazFunds Company |
//|                                          http://www.nazfunds.com |
//|                                Translated/updated to MT4: Turcol |
//|                 Use it on 5 min charts with 20/pips profit limit |
//|        Do not place any stop loss. No worries, check the results |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, NazFunds Company"
#property link      "http://www.nazfunds.com"
#include <stdlib.mqh>

extern double lots         = 0.1;           // 
extern double trailingStop = 15;            // trail stop in points
extern double takeProfit   = 20;            // recomended  no more than 20
extern double stopLoss     = 0;             // do not use s/l
extern double slippage     = 3;             // Could be higher with some brokers
extern string nameEA       = "DayTrading";  // To "easy read" which EA place an specific order
extern int magicEA         = 19000;         // Magic EA identifier. Allows for several co-existing EA with different input values

double macdHistCurrent, macdHistPrevious, macdSignalCurrent, macdSignalPrevious;
double stochHistCurrent, stochHistPrevious, stochSignalCurrent, stochSignalPrevious;
double sarCurrent, sarPrevious, momCurrent, momPrevious;
double realTP, realSL;
bool isBuying = false, isSelling = false, isClosing = false;
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
         if(OrderType() == OP_BUY) {           // Check for close signal for bought trade
            if(isSelling || isClosing) {
               OrderClose(OrderTicket(),OrderLots(),Bid,slippage,Violet);   // Close bought trade
               prtAlert("Day Trading: Closing BUY order");
            }         
            if(trailingStop > 0) {             // Check trailing stop
               if(Bid-OrderOpenPrice() > trailingStop*Point) {
                  if(OrderStopLoss() < (Bid - trailingStop*Point)) {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-trailingStop*Point,OrderTakeProfit(),0,Blue);
                     prtAlert("Day Trading: Modifying BUY order");
                  }
               }
            }
         } else {                              // Check sold trade for close signal
            if(isBuying || isClosing) {
               OrderClose(OrderTicket(),OrderLots(),Ask,slippage,Violet);
               prtAlert("Day Trading: Closing SELL order");
            }
            if(trailingStop > 0) {             // Control trailing stop
               if(OrderOpenPrice() - Ask > trailingStop*Point) {
                  if(OrderStopLoss() == 0 || OrderStopLoss() > Ask + trailingStop*Point) {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+trailingStop*Point,OrderTakeProfit(),0,Red);
                     prtAlert("Day Trading: Modifying SELL order");
                  }
               }           
            } 
         }
      }
   }
   
   // If there is no open trade for this pair and this EA
   if(numPos < 1) {   
      if(AccountFreeMargin() < 1000*lots) {
         Print("Not enough money to trade ", lots, " lots. Strategy:", nameEA);
         return(0);
      }
      if(isBuying && !isSelling && !isClosing) {  // Check for BUY entry signal
         if(stopLoss > 0)
            realSL = Ask - stopLoss * Point;
         if(takeProfit > 0)
            realTP = Ask + takeProfit * Point;
         ticket = OrderSend(Symbol(),OP_BUY,lots,Ask,slippage,realSL,realTP,nameEA+" - Magic: "+magicEA+" ",magicEA,0,Red);  // Buy
         if(ticket < 0) {
            Print("OrderSend (" + nameEA + ") failed with error #" + GetLastError() + " --> " + ErrorDescription(GetLastError()));
         } else {
            prtAlert("Day Trading: Buying"); 
         }
      }
      if(isSelling && !isBuying && !isClosing) {  // Check for SELL entry signal
         if(stopLoss > 0)
            realSL = Bid + stopLoss * Point;
         if(takeProfit > 0)
            realTP = Bid - takeProfit * Point;
         ticket = OrderSend(Symbol(),OP_SELL,lots,Bid,slippage,realSL,realTP,nameEA+" - Magic: "+magicEA+" ",magicEA,0,Red); // Sell
         if(ticket < 0) {
            Print("OrderSend (" + nameEA + ") failed with error #" + GetLastError() + " --> " + ErrorDescription(GetLastError()));
         } else {
            prtAlert("Day Trading: Selling"); 
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
   sarPrevious         = iSAR(NULL,0,0.02,0.2,1);           // Parabolic Sar Previuos
   momCurrent          = iMomentum(NULL,0,14,PRICE_OPEN,0); // Momentum Current
   momPrevious         = iMomentum(NULL,0,14,PRICE_OPEN,1); // Momentum Previous
   
   // Check for BUY, SELL, and CLOSE signal
   isBuying  = (sarCurrent<=Ask && sarPrevious>sarCurrent && momCurrent<100 && macdHistCurrent<macdSignalCurrent && stochHistCurrent<35);
   isSelling = (sarCurrent>=Bid && sarPrevious<sarCurrent && momCurrent>100 && macdHistCurrent>macdSignalCurrent && stochHistCurrent>60);
   isClosing = false;
}

void prtAlert(string str = "") {
   Print(Symbol() + " - " + str);
   Alert(Symbol() + " - " + str);
   // SpeechText(addSpaces(Symbol()) + " - " + str,SPEECH_ENGLISH);
   // SendMail(Symbol(),str);
}

//string addSpaces(string str = "") {
//   int length = StringLen(str);
//   string sp  = "";
//   for(int i=0; i<length; i++)
//      sp = sp + StringSubstr(str,i,1) + " ";
//   return (sp);
//}
//+------------------------------------------------------------------+