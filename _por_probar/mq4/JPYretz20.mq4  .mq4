//+------------------------------------------------------------------+
//|                                                   JPYretz20.mq4  |
//|         for JPY only due to nature of SAR identifier calculation |
//|  as usual, no profit guarantee yet, any improvement are welcomed |
//|      deretz@...                                            |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006"
#property link      "http://www.   .com"
#include <stdlib.mqh>

extern double lots         = 0.1;           //
extern double trailingStop = 15;             // trail stop in points
extern double takeProfit   = 20;            // recomended  no more than 20
extern double stopLoss     = 200;             // do not use s/l if you feel it is ok
extern double slippage     = 3;             // Use 3 -5 slippage, if more then forget it as the spread will kill them
extern string nameEA       = "JPYretz20";  // To "easy read" which EA place anspecific order
extern int magicEA         = 192192;         // Magic EA identifier. Allows forseveral co-existing EA with different input values
extern int tframe          = 5 ;            // timeframe M5 is recommended

double macdHistCurrent, macdHistPrevious, macdSignalCurrent, macdSignalPrevious;
double stochHistCurrent, stochHistPrevious, stochSignalCurrent,stochSignalPrevious;
double sarCurrent, sarPrevious, momCurrent, momPrevious,Btime;
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
    if(Bars < 100) {
       Print("Not enough bars for this strategy - ", nameEA);
       return(0);
    }
    calculateIndicators();                      // Calculate indicators' value

    // Control open trades
    int totalOrders = OrdersTotal();
    int numPos = 0;

//----
Comment("   Account  :   ",AccountNumber(),"---",AccountName(),
"\n","Bar open time:", TimeToStr(iTime(NULL,5,0),TIME_SECONDS)," Last Tick Time:",TimeToStr(CurTime(),TIME_SECONDS),
"\n"," Differences in time ",CurTime()-iTime(NULL,5,0),"sec. Open only after5Min bar is >= 180 sec ( 3min)",
"\n","PSar diff 0.1 to execute-- PsarNow=",sarCurrent," PSarPrecious=",sarPrevious," Sar DIff=",(sarCurrent-sarPrevious));
//+------------------------------------------------------------------+

    for(cnt=0; cnt<totalOrders; cnt++) {        // scan all orders and positions...
       OrderSelect(cnt, SELECT_BY_POS);         // the next line will check for ONLY market trades, not entry orders
       if(OrderSymbol() == Symbol() && OrderType() <= OP_SELL &&
OrderMagicNumber() == magicEA) {   // only look for this symbol, and only ordersfrom this EA
          numPos++;
          if(OrderType() == OP_BUY) {           // Check for close signal for bought trade
             if(isSelling || isClosing) {
                OrderClose(OrderTicket(),OrderLots(),Bid,slippage,Violet);   //Close bought trade
                prtAlert("JPYretz20: Closing BUY order");
             }
             if(trailingStop > 0) {             // Check trailing stop
                if(Bid-OrderOpenPrice() > trailingStop*Point) {
                   if(OrderStopLoss() < (Bid - trailingStop*Point)) {
                     
OrderModify(OrderTicket(),OrderOpenPrice(),Bid-trailingStop*Point,OrderTakeProfit(),0,Blue);
                      prtAlert("JPYretz20: Modifying BUY order");
                   }
                }
             }
          } else {                              // Check sold trade for close signal
             if(isBuying || isClosing) {
                OrderClose(OrderTicket(),OrderLots(),Ask,slippage,Violet);
                prtAlert("JPYretz20: Closing SELL order");
             }
             if(trailingStop > 0) {             // Control trailing stop
                if(OrderOpenPrice() - Ask > trailingStop*Point) {
                   if(OrderStopLoss() == 0 || OrderStopLoss() > Ask +
trailingStop*Point) {
                     
OrderModify(OrderTicket(),OrderOpenPrice(),Ask+trailingStop*Point,OrderTakeProfit(),0,Red);
                      prtAlert("JPYretz20: Modifying SELL order");
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
          ticket =
OrderSend(Symbol(),OP_BUY,lots,Ask,slippage,realSL,realTP,nameEA+" - Magic:"+magicEA+" ",magicEA,0,Red);  // Buy
          if(ticket < 0) {
             Print("OrderSend (" + nameEA + ") failed with error #" +
GetLastError() + " --> " + ErrorDescription(GetLastError()));
          } else {
             prtAlert("JPYretz20: Buying");
          }
       }
       if(isSelling && !isBuying && !isClosing) {  // Check for SELL entry signal
          if(stopLoss > 0)
             realSL = Bid + stopLoss * Point;
          if(takeProfit > 0)
             realTP = Bid - takeProfit * Point;
          ticket =
OrderSend(Symbol(),OP_SELL,lots,Bid,slippage,realSL,realTP,nameEA+" - Magic:"+magicEA+" ",magicEA,0,Red); // Sell
          if(ticket < 0) {
             Print("OrderSend (" + nameEA + ") failed with error #" +
GetLastError() + " --> " + ErrorDescription(GetLastError()));
          } else {
             prtAlert("JPYretz20: Selling");
          }
       }
    }
    return(0);
}

void calculateIndicators() {    // Calculate indicators' value
    macdHistCurrent     = iMACD(NULL,tframe,12,26,9,PRICE_OPEN,MODE_MAIN,0);
    macdHistPrevious    = iMACD(NULL,tframe,12,26,9,PRICE_OPEN,MODE_MAIN,1);
    macdSignalCurrent   = iMACD(NULL,tframe,12,26,9,PRICE_OPEN,MODE_SIGNAL,0);
    macdSignalPrevious  = iMACD(NULL,tframe,12,26,9,PRICE_OPEN,MODE_SIGNAL,1);
    stochHistCurrent    = iStochastic(NULL,tframe,5,3,3,MODE_SMA,0,MODE_MAIN,0);
    stochHistPrevious   = iStochastic(NULL,tframe,5,3,3,MODE_SMA,0,MODE_MAIN,1);
    stochSignalCurrent  =
iStochastic(NULL,tframe,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
    stochSignalPrevious =
iStochastic(NULL,tframe,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);
    sarCurrent          = iSAR(NULL,tframe,0.02,0.2,0);           // ParabolicSar Current
    sarPrevious         = iSAR(NULL,tframe,0.02,0.2,1);           // ParabolicSar Previuos
    momCurrent          = iMomentum(NULL,tframe,14,PRICE_OPEN,0); // MomentumCurrent
    momPrevious         = iMomentum(NULL,tframe,14,PRICE_OPEN,1); // Momentum Previous
    Btime               = CurTime()-iTime(NULL,5,0);// Differences of Bar OpenTime against current tiem, to get sar confirmation only after 3/4 of Bartime

    // Check for BUY, SELL, and CLOSE signal
    isBuying  = (Btime>=180 && sarCurrent<=Ask && (sarPrevious-sarCurrent)>=0.1
&& sarPrevious>sarCurrent && momCurrent<100 && macdHistCurrent<macdSignalCurrent
&& stochHistCurrent<35);
    isSelling = (Btime>=180 && sarCurrent>=Bid && (sarCurrent-sarPrevious)>=0.1
&& sarPrevious<sarCurrent && momCurrent>100 && macdHistCurrent>macdSignalCurrent
&& stochHistCurrent>60);
    isClosing = false;
}

void prtAlert(string str = "") {
    Print(Symbol() + " - " + str);
    Alert(Symbol() + " - " + str);

}



//+------------------------------------------------------------------+