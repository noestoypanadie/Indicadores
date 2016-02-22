//+------------------------------------------------------------------+
//|                                         SmoothCandle S v1.00.mq4 |
//|                                 Copyright © 2005, Varus Henschke |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2005, Varus Henschke"

//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 4
#property  indicator_color1  Red
#property  indicator_color2  DimGray
#property  indicator_color3  DimGray
#property  indicator_color4  Blue

//---- indicator parameters
extern int SMA=5;

//---- indicator buffers
double     nOpen[];
double     nHigh[];
double     nLow[];
double     nClose[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicator line
   IndicatorBuffers(4);
   SetIndexStyle(0,DRAW_LINE);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexStyle(3,DRAW_LINE);
   
//---- line shifts when drawing
   SetIndexShift(0,SMA);
   SetIndexShift(1,SMA);
   SetIndexShift(2,SMA);
   SetIndexShift(3,SMA);

//---- indicator buffers mapping
   if(!SetIndexBuffer(0,nOpen) && !SetIndexBuffer(1,nHigh) && !SetIndexBuffer(2,nLow) && !SetIndexBuffer(3,nClose))
      Print("cannot set indicator buffers!");

//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("SmoothCandle S SMA ( "+SMA+" )");
   
//---- initialization done
   return(0);
  }
  
//+------------------------------------------------------------------+
//| Moving Averages of Candlestick                                   |
//+------------------------------------------------------------------+

int start()
  {
   int limit;
   int counted_bars=IndicatorCounted();
   
//---- check for possible errors
   if(counted_bars<0) return(-1);
   
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars-SMA-1;

   for(int i=SMA; i<limit; i++){    // Does not work if i=0 so included SetIndexShift above.  That does my head in.
   
      nOpen[i]  = 0;
      nHigh[i]  = 0;
      nLow[i]   = 0;
      nClose[i] = 0;
      
      for(int j=i-SMA; j<i; j++){
      
         nOpen[i]  = nOpen[i]  + (Open[j]  / SMA);
         nHigh[i]  = nHigh[i]  + (High[j]  / SMA);
         nLow[i]   = nLow[i]   + (Low[j]   / SMA);
         nClose[i] = nClose[i] + (Close[j] / SMA);
      }
      
   }
 
 //---- done
   return(0);
  }