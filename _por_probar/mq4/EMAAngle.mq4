//+------------------------------------------------------------------+
//|                                                     EMAAngle.mq4 |
//|                                                           jpkfox |
//|                                                                  |
//| You can use this indicator to measure when the EMA angle is      |
//| "near zero". AngleTreshold determines when the angle for the     |
//| EMA is "about zero": This is when the value is between           |
//| [-AngleTreshold, AngleTreshold] (or when the histogram is red).  |
//|   EMAPeriod: EMA period                                          |
//|   AngleTreshold: The angle value is "about zero" when it is      |
//|     between the values [-AngleTreshold, AngleTreshold].          |      
//|   StartEMAShift: The starting point to calculate the             |   
//|     angle. This is a shift value to the left from the            |
//|     observation point. Should be StartEMAShift > EndEMAShift.    | 
//|   StartEMAShift: The ending point to calculate the               |
//|     angle. This is a shift value to the left from the            | 
//|     observation point. Should be StartEMAShift > EndEMAShift.    |
//|                                                                  |
//+------------------------------------------------------------------+

#property  copyright "jpkfox"
#property  link      "http://www.strategybuilderfx.com/forums/showthread.php?t=15274&page=1&pp=8"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 2
#property  indicator_color1  FireBrick
#property  indicator_color2  LimeGreen
//---- indicator parameters
extern int EMAPeriod=120;
extern double AngleTreshold=0.32;
extern int StartEMAShift=6;
extern int EndEMAShift=0;

//---- indicator buffers
double UpBuffer[];
double DownBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
//---- 2 additional buffers are used for counting.
   IndicatorBuffers(2);
//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2);
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+2);
//---- 3 indicator buffers mapping
   if(!SetIndexBuffer(0,UpBuffer) &&
      !SetIndexBuffer(1,DownBuffer))
      Print("cannot set indicator buffers!");
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("EMAAngle("+EMAPeriod+","+AngleTreshold+","+StartEMAShift+","+EndEMAShift+")");
//---- initialization done
   return(0);
}
//+------------------------------------------------------------------+
//| The angle for EMA                                                |
//+------------------------------------------------------------------+
int start()
{
   double fEndMA, fStartMA;
   double fAngle;
   int nLimit, i;
   int nCountedBars;
 
   if(EndEMAShift >= StartEMAShift)
   {
      Print("Error: EndEMAShift >= StartEMAShift");
      StartEMAShift = 6;
      EndEMAShift = 0;      
   }  
         
   nCountedBars = IndicatorCounted();
//---- check for possible errors
   if(nCountedBars<0) 
      return(-1);
//---- last counted bar will be recounted
   if(nCountedBars>0) 
      nCountedBars--;
   nLimit = Bars-nCountedBars;
 
//---- main loop
   for(i=0; i<nLimit; i++)
   {
      fEndMA=iMA(NULL,0,EMAPeriod,0,MODE_EMA,PRICE_MEDIAN,i+EndEMAShift);
      fStartMA=iMA(NULL,0,EMAPeriod,0,MODE_EMA,PRICE_MEDIAN,i+StartEMAShift);
      // 10000.0 : Multiply by 10000 so that the fAngle is not too small
      // for the indicator Window.
      fAngle = 10000.0 * (fEndMA - fStartMA)/(StartEMAShift-EndEMAShift);

      DownBuffer[i] = 0.0;
      UpBuffer[i] = 0.0;
      
      if(fAngle > AngleTreshold || fAngle < -AngleTreshold)
         DownBuffer[i] = fAngle;
      else
         UpBuffer[i] = fAngle;
   }

   return(0);
  }
//+------------------------------------------------------------------+

