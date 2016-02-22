//+------------------------------------------------------------------+
//|                                                  Accelerator.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2004, MetaQuotes Software Corp."
#property  link      "http://www.metaquotes.net/"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 2
#property  indicator_color1  Green
#property  indicator_color2  Red
//---- indicator buffers
double     ind_buffer1[];
double     ind_buffer2[];
double     ind_buffer3[];
double     ind_buffer4[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- 2 additional buffers are used for counting.
   IndicatorBuffers(4);
//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,3);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,3);
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+2);
   SetIndexDrawBegin(0,38);
   SetIndexDrawBegin(1,38);
//---- 4 indicator buffers mapping
   if(!SetIndexBuffer(0,ind_buffer1) &&
      !SetIndexBuffer(1,ind_buffer2) &&
      !SetIndexBuffer(2,ind_buffer3) &&
      !SetIndexBuffer(3,ind_buffer4))
      Print("cannot set indicators\' buffers!");
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("AC");
//---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Accelerator/Decelerator Oscillator                               |
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
      ind_buffer3[i]=iMA(NULL,0,5,0,MODE_SMA,PRICE_MEDIAN,i)-iMA(NULL,0,34,0,MODE_SMA,PRICE_MEDIAN,i);
   //---- signal line counted in the 2-nd additional buffer
   for(i=0; i<limit; i++)
      ind_buffer4[i]=iMAOnArray(ind_buffer3,Bars,5,0,MODE_SMA,i);
   //---- dispatch values between 2 buffers
   bool up=true;
   for(i=limit-1; i>=0; i--)
     {
      current=ind_buffer3[i]-ind_buffer4[i];
      prev=ind_buffer3[i+1]-ind_buffer4[i+1];
      if(current>prev) up=true;
      if(current<prev) up=false;
      if(!up)
        {
         ind_buffer2[i]=current;
         ind_buffer1[i]=0.0;
        }
      else
        {
         ind_buffer1[i]=current;
         ind_buffer2[i]=0.0;
        }
     }
   //---- done
   return(0);
  }