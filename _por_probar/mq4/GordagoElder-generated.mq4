//+------------------------------------------------------------------+
//|                                       GordagoElder-generated.mq4 |
//|                                                               RT |
//|                       http://www.gordago.com/?act=strategy&num=1 |
//+------------------------------------------------------------------+
#property copyright "RT"
#property link      "http://www.gordago.com/?act=strategy&num=1"

// User input
extern double    lStopLoss=17.0;
extern double    sStopLoss=46.0;
extern double    lTrailingStop=18.0;
extern double    sTrailingStop=22.0;
extern double    Lots=0.1;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
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
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   int cnt, ticket;

   if(Bars<100)                        {Print("bars less than 100");     return(0);}
   if(lStopLoss<10)                    {Print("StopLoss less than 10");  return(0);}
   if(sStopLoss<10)                    {Print("StopLoss less than 10");  return(0);}
   if(AccountFreeMargin()<(1000*Lots)) {Print("We have no Free Margin"); return(0);}

   
   // 1) H1 timeframe (1 hour)
   // At this stage necessary to reveal the long-term trend. 
   // For this use checking the following conditions: 
   //
   // The MACD histogram moves upwards. Moreover signal will be the most 
   // strong if this Forex indicator turned round upwards being below its zero line.
   
   double diMACD0=iMACD(Symbol(),60,13,30,0,PRICE_CLOSE,MODE_MAIN,0);
   double diMACD1=iMACD(Symbol(),60,13,30,0,PRICE_CLOSE,MODE_MAIN,1);

   // 2) M15 timeframe (15 minutes).
   // For profitable buy, it is necessary not only to buy toward trend. 
   // It is necessary to buy on recoil, when under the total trend to 
   // increasing on the market was formed small recoil - a price little 
   // was lowered, and there is possibility to buy more cheaply. 
   // We shall use the indicator Stohastik:
   // 
   // Stohastik is found below oversell level but herewith has turned upstairs.

   double diStochastic5=iStochastic(Symbol(),15,2,0,3,MODE_EMA,PRICE_CLOSE,MODE_MAIN,0);
   double diStochastic6=iStochastic(Symbol(),15,2,0,3,MODE_EMA,PRICE_CLOSE,MODE_MAIN,1);

   // 3) M1 timeframe (1 minute)
   // On Elder's trade tactic third screen is used for optimum entry in deal. 
   // It is necessary to set the sliding signal on buying, when price will 
   // rise above high of the previous candle.

   double diClose7=iClose(Symbol(),1,0);
   double diHigh8=iHigh(Symbol(),1,1);



   double diMACD2=iMACD(NULL,60,13,30,0,PRICE_CLOSE,MODE_MAIN,1);
   double diStochastic3=iStochastic(NULL,15,2,0,3,MODE_EMA,PRICE_CLOSE,MODE_MAIN,0);
   double d4=(36);
   double diMACD9=iMACD(NULL,60,14,56,0,PRICE_CLOSE,MODE_MAIN,0);
   double diMACD10=iMACD(NULL,60,14,56,0,PRICE_CLOSE,MODE_MAIN,1);
   double diMACD11=iMACD(NULL,60,14,56,0,PRICE_CLOSE,MODE_MAIN,1);
   double diStochastic12=iStochastic(NULL,15,1,0,3,MODE_EMA,PRICE_CLOSE,MODE_MAIN,0);
   double d13=(66);
   double diStochastic14=iStochastic(NULL,15,1,0,3,MODE_EMA,PRICE_CLOSE,MODE_MAIN,0);
   double diStochastic15=iStochastic(NULL,15,1,0,3,MODE_EMA,PRICE_CLOSE,MODE_MAIN,1);
   double diClose16=iClose(NULL,1,0);
   double diLow17=iLow(NULL,1,1);

   
   return(0);
  }
//+------------------------------------------------------------------+