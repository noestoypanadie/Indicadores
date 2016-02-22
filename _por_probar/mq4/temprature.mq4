//+------------------------------------------------------------------+
//|                                                         Temp.mq4 |
//|                       Copyright © 2005, MetaQuotes SoftwareCorp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"


#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Yellow
//---- input parameters


double day_high=0;
double day_low=0;
double yesterday_high=0;
double yesterday_open=0;
double yesterday_low=0;
double yesterday_close=0;
double today_open=0;
double today_high=0;
double today_low=0;
double rates_d1 [2] [6];
double Temp_High=0;
double Temp_Low=0;
double temp=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- 
SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(0,temp);


ArrayCopyRates(rates_d1, Symbol(), 0);


yesterday_close = rates_d1[1][4];
yesterday_open = rates_d1[1][1];
today_open = rates_d1[0][1];
yesterday_high = rates_d1[1][3];
yesterday_low = rates_d1[1][2];
day_high = rates_d1[0][3];
day_low = rates_d1[0][2];


SetIndexDrawBegin(0,temp);


//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    counted_bars=IndicatorCounted();
//---- 
Temp_High = (day_high-yesterday_high);
Temp_Low = (yesterday_low - day_low);


if (Temp_High > Temp_Low)
   temp=Temp_High;
else 
   temp=Temp_Low;   
//----
   return(temp);
  }
//+------------------------------------------------------------------+



