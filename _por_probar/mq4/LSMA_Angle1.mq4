//+------------------------------------------------------------------+
//|                                                   LSMA_Angle.mq4 |
//|                                                           MrPip  |
//|                                                                  |
//| You can use this indicator to measure when the LSMA angle is     |
//| "near zero". AngleTreshold determines when the angle for the     |
//| LSMA is "about zero": This is when the value is between          |
//| [-AngleTreshold, AngleTreshold] (or when the histogram is red).  |
//|   LSMAPeriod: LSMA period                                        |
//|   AngleTreshold: The angle value is "about zero" when it is      |
//|     between the values [-AngleTreshold, AngleTreshold].          |      
//|   StartLSMAShift: The starting point to calculate the            |   
//|     angle. This is a shift value to the left from the            |
//|     observation point. Should be StartEMAShift > EndEMAShift.    | 
//|   EndLSMAShift: The ending point to calculate the                |
//|     angle. This is a shift value to the left from the            | 
//|     observation point. Should be StartEMAShift > EndEMAShift.    |
//|                                                                  |
//|   Modified by MrPip from EMAAngle by jpkfox                      |                                              |
//|       Red for down                                               |
//|       Yellow for near zero                                       |
//|       Green for up                                               |   
//|                                                                  |
//+------------------------------------------------------------------+

#property  copyright "Robert L. Hill aka MrPip"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 3
#property  indicator_color1  LimeGreen
#property  indicator_color2  Yellow
#property  indicator_color3 FireBrick
//---- indicator parameters
extern int LSMAPeriod=25;
extern double AngleTreshold=15.0;
extern int StartLSMAShift=4;
extern int EndLSMAShift=0;

//---- indicator buffers
double UpBuffer[];
double DownBuffer[];
double ZeroBuffer[];

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
   IndicatorShortName("LSMAAngle("+LSMAPeriod+","+AngleTreshold+","+StartLSMAShift+","+EndLSMAShift+")");
//---- initialization done
   return(0);
}

//+------------------------------------------------------------------------+
//| LSMA - Least Squares Moving Average function calculation               |
//| LSMA_In_Color Indicator plots the end of the linear regression line    |
//+------------------------------------------------------------------------+

double LSMA(int Rperiod, int shift)
{
   int i;
   double sum;
   int length;
   double lengthvar;
   double tmp;
   double wt;

   length = Rperiod;
 
   sum = 0;
   for(i = length; i >= 1  ; i--)
   {
     lengthvar = length + 1;
     lengthvar /= 3;
     tmp = 0;
     tmp = ( i - lengthvar)*Close[length-i+shift];
     sum+=tmp;
    }
    wt = sum*6/(length*(length+1));
    
    return(wt);
}


//+------------------------------------------------------------------+
//| The angle for LSMA                                               |
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
 
   if(EndLSMAShift >= StartLSMAShift)
   {
      Print("Error: EndLSMAShift >= StartLSMAShift");
      StartLSMAShift = 6;
      EndLSMAShift = 0;      
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
   ShiftDif = StartLSMAShift-EndLSMAShift;
   mFactor /= ShiftDif; 
 
//---- main loop
   for(i=0; i<nLimit; i++)
   {
      fEndMA=LSMA(LSMAPeriod,i+EndLSMAShift);
      fStartMA=LSMA(LSMAPeriod,i+StartLSMAShift);
      // 10000.0 : Multiply by 10000 so that the fAngle is not too small
      // for the indicator Window.
      fAngle = mFactor * (fEndMA - fStartMA)/2;
//      fAngle = MathArctan(fAngle)/dFactor;

      DownBuffer[i] = 0.0;
      UpBuffer[i] = 0.0;
      ZeroBuffer[i] = 0.0;
      
      if(fAngle > AngleTreshold)
         UpBuffer[i] = fAngle;
      else if (fAngle < -AngleTreshold)
         DownBuffer[i] = fAngle;
      else ZeroBuffer[i] = fAngle;
   }

   return(0);
  }
//+------------------------------------------------------------------+

