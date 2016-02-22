//+------------------------------------------------------------------+
//|                                                lil_youngin86.mq4 |
//|                      Copyright © 2006, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Green
#property indicator_color2 Red
//---- input parameters
extern int       SMA_MED=55;
extern int       SMA_CLOSE=8;
//---- buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
//---- indicator buffers
double ExtGreenBuffer[];
double ExtRedBuffer[];
double ExtMABuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- additional buffers are used for counting
   IndicatorBuffers(5);
//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexBuffer(1,ExtMapBuffer2);
   IndicatorDigits(5);
   SetIndexDrawBegin(0,34);
   SetIndexDrawBegin(1,34);
//---- indicator buffers mapping
   SetIndexBuffer(0, ExtGreenBuffer);
   SetIndexBuffer(1, ExtRedBuffer);
   SetIndexBuffer(2, ExtMABuffer);
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("lil_youngin86   ");
//---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Awesome Oscillator                                               |
//+------------------------------------------------------------------+
int start()
  {
   int    limit;
   int    counted_bars=IndicatorCounted();
   double prev,current;
//---- check for possible errors
   if(counted_bars<0) return(-1);
   //---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
//---- macd counted in the 1-st additional buffer
   for(int i=0; i<limit; i++)
      ExtMABuffer[i]=iMA(NULL,0,SMA_MED,0,MODE_SMA,PRICE_MEDIAN,i)-iMA(NULL,0,SMA_CLOSE,0,MODE_SMA,PRICE_CLOSE,i);
//---- dispatch values between 2 buffers
   bool up=true;
   for(i=limit-1; i>=0; i--)
     {
      current=ExtMABuffer[i];
      prev=ExtMABuffer[i+1];
      if(current>prev) up=true;
      if(current<prev) up=false;
      if(!up)
        {
         ExtRedBuffer[i]=current;
         ExtGreenBuffer[i]=0.0;
        }
      else
        {
         ExtGreenBuffer[i]=current;
         ExtRedBuffer[i]=0.0;
        }
     }
//---- done
   return(0);
  }
//+------------------------------------------------------------------+

