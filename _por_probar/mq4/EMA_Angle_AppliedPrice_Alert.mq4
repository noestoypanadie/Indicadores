//+------------------------------------------------------------------+
//|                                                    EMA_Angle.mq4 |
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
//|   Modified by MrPip                                              |
//|       Red for down                                               |
//|       Yellow for near zero                                       |
//|       Green for up                                               |
//|  10/15/05  MrPip                                                 |
//|            Corrected problem with USDJPY and optimized code      |
//|  10/23/05  Added other JPY crosses                               |   
//|                                                                  |
//+------------------------------------------------------------------+

#property  copyright "jpkfox"
#property  link      "http://www.strategybuilderfx.com/forums/showthread.php?t=15274&page=1&pp=8"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 3
#property  indicator_color1  LimeGreen
#property  indicator_color2  Yellow
#property  indicator_color3 FireBrick
//---- indicator parameters
extern int EMAPeriod=34;
extern int MAAppliedPrice = 0;//0=close, 1=open, 2=high, 3=low, 4=median(high+low)/2, 5=typical(high+low+close)/3, 6=weighted(high+low+close+close)/4
extern double AngleTreshold=15;
extern int StartEMAShift=4;
extern int EndEMAShift=0;
extern bool SoundON=true;
extern bool EmailON=false;

//---- indicator buffers
double UpBuffer[];
double DownBuffer[];
double ZeroBuffer[];
int flagval1 = 0;
int flagval2 = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
//---- 2 additional buffers are used for counting.
   IndicatorBuffers(3);
//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,2);

   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+2);

//---- 3 indicator buffers mapping
   if(!SetIndexBuffer(0,UpBuffer) &&
      !SetIndexBuffer(1,DownBuffer) &&
      !SetIndexBuffer(2,ZeroBuffer))
      Print("cannot set indicator buffers!");
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("EMA_Angle("+EMAPeriod+","+AngleTreshold+","+StartEMAShift+","+EndEMAShift+")");
//---- initialization done
   return(0);
}
//+------------------------------------------------------------------+
//| The angle for EMA                                                |
//+------------------------------------------------------------------+
int start()
{
   double fEndMA, fStartMA;
   double fAngle, mFactor, dFactor;
   int nLimit, i;
   int nCountedBars;
   double angle;
   int ShiftDif;
   string Sym;
 
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
   dFactor = 2*3.14159/180.0;
   mFactor = 100000.0;
   Sym = StringSubstr(Symbol(),3,3);
   if (Sym == "JPY") mFactor = 1000.0;
   ShiftDif = StartEMAShift-EndEMAShift;
   mFactor /= ShiftDif; 
//---- main loop
   for(i=0; i<nLimit; i++)
   {
      fEndMA=iMA(NULL,0,EMAPeriod,0,MODE_EMA,MAAppliedPrice,i+EndEMAShift);
      fStartMA=iMA(NULL,0,EMAPeriod,0,MODE_EMA,MAAppliedPrice,i+StartEMAShift);
      // 10000.0 : Multiply by 10000 so that the fAngle is not too small
      // for the indicator Window.
      fAngle = mFactor * (fEndMA - fStartMA)/2.0;
//      fAngle = MathArctan(fAngle)/dFactor;

      DownBuffer[i] = 0.0;
      UpBuffer[i] = 0.0;
      ZeroBuffer[i] = 0.0;
      
      if(fAngle > AngleTreshold)
      {
         if (i == 1 && flagval1==0)
         {
           flagval1=1;
           flagval2=0;
           if (SoundON) Alert("Slope is UP","\n Symbol=",Symbol()," Period=",Period());
           if (EmailON) SendMail("Slope is UP", "Symbol="+Symbol()+" Period="+Period());
         }
         UpBuffer[i] = fAngle;
      }
      else if (fAngle < -AngleTreshold)
      {
         if (i == 1 && flagval2==0)
         {
          flagval2=1;
          flagval1=0;
          if (SoundON) Alert("Slope is DOWN","\n Symbol=",Symbol()," Period=",Period());
          if (EmailON) SendMail("Slope is Down","Symbol="+Symbol()+" Period="+Period());
         }
         DownBuffer[i] = fAngle;
      }
      else ZeroBuffer[i] = fAngle;
   }

   return(0);
  }
//+------------------------------------------------------------------+

