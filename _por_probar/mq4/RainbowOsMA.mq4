//+------------------------------------------------------------------+
//|                                                         OsMA.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "colour update by thor@gmx.co.uk, Moneytec chat: thorr"

//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 4
#property  indicator_color1  Maroon
#property  indicator_color2  DarkGreen
#property  indicator_color3  Lime
#property  indicator_color4  OrangeRed
//---- indicator parameters
extern int FastEMA=8;
extern int SlowEMA=12;
extern int SignalSMA=9;
extern double thresh = 0.0001;
//---- indicator buffers
double     ind_buffer0[];
double     ind_buffer1[];
double     ind_buffer2[];
double     ind_buffer3[];
double     ind_brighthi[];
double     ind_brightlo[];
double     res;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- 2 additional buffers are used for counting.
   IndicatorBuffers(6);
//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(3,DRAW_HISTOGRAM,STYLE_SOLID,2);

   SetIndexDrawBegin(0,SignalSMA);
   SetIndexDrawBegin(1,SignalSMA);
   SetIndexDrawBegin(2,SignalSMA);
   SetIndexDrawBegin(3,SignalSMA);

   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+2);

//---- 4 indicator buffers mapping
   if(!SetIndexBuffer(0,ind_buffer0) &&
      !SetIndexBuffer(1,ind_buffer1) &&
      !SetIndexBuffer(2,ind_brighthi) &&
      !SetIndexBuffer(3,ind_brightlo) &&
      !SetIndexBuffer(4,ind_buffer2) &&
      !SetIndexBuffer(5,ind_buffer3))
      Print("cannot set indicator buffers!");
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("RainbowOsMA("+FastEMA+","+SlowEMA+","+SignalSMA+")");
//---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Moving Average of Oscillator                                     |
//+------------------------------------------------------------------+
int start()
  {
   int limit;
   int counted_bars=IndicatorCounted();

//---- check for possible errors
   if(counted_bars<0) return(-1);

//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;

//---- macd counted in the 1-st additional buffer
   for(int i=0; i<limit; i++)
      ind_buffer3[i]=iMA(NULL,0,FastEMA,0,MODE_EMA,PRICE_CLOSE,i)-iMA(NULL,0,SlowEMA,0,MODE_EMA,PRICE_CLOSE,i);

//---- signal line counted in the 2-nd additional buffer
   for(i=0; i<limit; i++)
      ind_buffer2[i]=iMAOnArray(ind_buffer3,Bars,SignalSMA,0,MODE_SMA,i);

//---- main loop
   for(i=limit-1; i>=0; i--)
     {
      res = ind_buffer3[i] - ind_buffer2[i];
      
      // Sort it out now...
      if (res < thresh && res > 0) {
         ind_buffer1[i] = res;
         ind_brighthi[i] = 0;
         continue;
      } else if (res > 0) {
         ind_brighthi[i] = res;
         ind_buffer1[i] = 0;         
      } else if (res > -thresh && res < 0) {
         ind_brightlo[i] = 0;
         ind_buffer0[i] = res;
         continue;
      } else if (res < 0)
         ind_brightlo[i] = res;
         ind_buffer0[i] = 0;
     }

   return(0);
  }