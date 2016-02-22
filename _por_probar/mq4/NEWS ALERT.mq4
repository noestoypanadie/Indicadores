//+------------------------------------------------------------------+
//|                                                   NEWS ALERT.mq4 |
//|                                                      Mico Yoshic |
//|                                              micoyoshic@mail.com |
//+------------------------------------------------------------------+
#property copyright "Mico Yoshic"
#property link      "www.micoyoshic.com"


//---- input parameters
extern double       NormalSpread=2;
extern double       NormalPipDistance=5;

double   sp,dt;


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  { 
    dt=(MarketInfo(Symbol(),MODE_STOPLEVEL))-((Ask-Bid)*10000);
    sp=(MarketInfo(Symbol(),MODE_ASK)-MarketInfo(Symbol(),MODE_BID))*10000;
    
    if (dt>NormalPipDistance) {
        Alert("The Minimum Distance from the Current Price is now ",dt," Pips for the ",Symbol()," and its BIGGER THAN NORMAL");
        }
        return(true);
    
    if (MarketInfo(Symbol(),MODE_ASK)-MarketInfo(Symbol(),MODE_BID)>NormalSpread*MarketInfo(Symbol(),MODE_POINT)) {
        Alert("The Spread for ",Symbol()," is now ",sp," and its BIGGER THAN NORMAL");
        }
        return(true);

   return(0);
  }
  

