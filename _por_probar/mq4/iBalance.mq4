//+------------------------------------------------------------------+
//|                                                      Balance.mq4 |
//|                           Copyright © 2006, Renato P. dos Santos |
//|                                     http://www.reniza.com/forex/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Renato P. dos Santos"
#property link      "http://www.reniza.com/forex/"

#property indicator_separate_window
#property indicator_buffers 1

//---- Indicator line properties
#property indicator_color1 DodgerBlue
#property indicator_width1 2
#property indicator_minimum 0

//---- Name for DataWindow and indicator subwindow label
string short_name="Balance";

//---- Buffers
double BalanceBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators

   SetIndexLabel(0,"Balance");
   SetIndexBuffer(0,BalanceBuffer);
   SetIndexStyle(0,DRAW_LINE);
   
   IndicatorDigits(2);
 

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
   int limit=Bars;
//----
   
   int pos;

   for(pos=limit;pos>=0;pos--) {
      BalanceBuffer[pos]=50000;
//      BalanceBuffer[pos]=AccountBalance();
   }

//----
   return(0);
  }
//+------------------------------------------------------------------+