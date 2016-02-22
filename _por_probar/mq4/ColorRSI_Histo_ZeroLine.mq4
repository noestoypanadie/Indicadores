//+------------------------------------------------------------------+
//|                                      ColorRSI_Histo_ZeroLine.mq4 |
//|                Copyright © 2006 , David W Honeywell , 12/12/2006 |
//|                                     HellOnWheels.Trans@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006 , David W Honeywell , 12/12/2006"
#property link      "HellOnWheels.Trans@gmail.com"

#property indicator_separate_window

#property indicator_buffers 2

#property indicator_color1 Green
#property indicator_color2 Red

#property indicator_maximum  50.0
#property indicator_minimum -50.0

#property indicator_level1  10
#property indicator_level2 0.0
#property indicator_level3 -10

extern int IndicatorTime =  0;
extern int RSI_Periods   = 3;
extern int Applied_Price =  0;
extern int LineWidth     =  4;

double Buffer0[];
double Buffer1[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
 {
//---- indicators

IndicatorBuffers(2);

SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,LineWidth);
SetIndexEmptyValue(0,0.0);
SetIndexBuffer(0,Buffer0);

SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,LineWidth);
SetIndexEmptyValue(1,0.0);
SetIndexBuffer(1,Buffer1);

IndicatorShortName(" ColorRSI_Histo_ZeroLine ( "+RSI_Periods+" ) ");

//----
  return(0);
 }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
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
  int     counted_bars=IndicatorCounted();
  double  StaticValue, RSIValue, Finish;
  int     i;
  int     limit;

  limit = Bars-counted_bars;
  for(i=limit; i>0; i--)
  {
     StaticValue = 50.00000000;
     RSIValue = iRSI(Symbol(),IndicatorTime,RSI_Periods,Applied_Price,i);
     Finish = (StaticValue - RSIValue)*(-1);
     
     if (RSIValue > StaticValue)
     {
        Buffer0[i] = Finish;
        Buffer1[i] = 0.00000000;
     }
     if (RSIValue < StaticValue)
     {
        Buffer0[i] = 0.00000000;
        Buffer1[i] = Finish;
     }
  }

//----
  return(0);
 }
//+------------------------------------------------------------------+