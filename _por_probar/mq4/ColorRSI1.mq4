//+------------------------------------------------------------------+
//|                                                     ColorRSI.mq4 |
//|                Copyright © 2006 , David W Honeywell , 12/12/2006 |
//|                                     HellOnWheels.Trans@gmail.com |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2006 , David W Honeywell , 12/12/2006"
#property link      "HellOnWheels.Trans@gmail.com"

#property indicator_separate_window

#property indicator_buffers 2

#property indicator_color1 Green
#property indicator_color2 Red

#property indicator_maximum 100.0
#property indicator_minimum   0.0

#property indicator_level1 70
#property indicator_level2 50
#property indicator_level3 30

extern int IndicatorTime =  0;
extern int RSI_Periods   = 3;
extern int Applied_Price =  0;
extern int LineWidth     =  4;
extern int ShowBars      =  1000;

double Buffer0[];
double Buffer1[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
 {
//---- indicators

SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,LineWidth);
SetIndexBuffer(0,Buffer0);

SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,LineWidth);
SetIndexBuffer(1,Buffer1);

IndicatorShortName(" ColorRSI ( "+RSI_Periods+" )");

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
  
  int limit=ShowBars;

//---- indicator calculation

    for(int i=limit; i>=0; i--)
    {
     double RSIValue=iRSI(Symbol(),IndicatorTime,RSI_Periods,Applied_Price,i);
    if (RSIValue > 50.00000000)
     {
       Buffer0[i] = RSIValue;
       Buffer1[i] = EMPTY_VALUE;
       if (Buffer0[i+1] == EMPTY_VALUE) Buffer0[i+1] = Buffer1[i+1]; 
     }
    else
     {
       Buffer0[i] = EMPTY_VALUE; 
       Buffer1[i] = RSIValue;
       if (Buffer1[i+1] == EMPTY_VALUE) Buffer1[i+1] = Buffer0[i+1]; 
     }
   }

//---- done
  
  return(0);
 }

//+------------------------------------------------------------------+