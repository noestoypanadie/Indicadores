//+------------------------------------------------------------------+
//|                                                        trade.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"

#include <stdlib.mqh>
#include <WinUser32.mqh>
//+------------------------------------------------------------------+
//| script "trading for all money"                                   |
//+------------------------------------------------------------------+
int start()
  {
//----
   double testarray[10];
   double manualSMA=0;
   for (int cnt=1; cnt<10; cnt++)
      {
      testarray[cnt-1]=Close[cnt];
      manualSMA=manualSMA+Close[cnt];
      //Print (testarray[cnt-1]);
      }

   manualSMA=manualSMA/9;

   Print("IMA:         ",DoubleToStr(iMA(NULL,0,9,0,MODE_SMA,PRICE_CLOSE,1),8));
   Print("IMAonarray:  ",DoubleToStr(iMAOnArray(testarray,0,9,0,MODE_SMA,0),8));
   Print("manualSMA:   ",DoubleToStr(manualSMA,8));


   return(0);
  }
//+------------------------------------------------------------------+