//+------------------------------------------------------------------+
//|                                                     MA_Angle.mq4 |
//| Modified from code for EMA_Angle by jpkfox                       |
//|                                                                  |
//| You can use this indicator to measure when the MA angle is       |
//| "near zero". AngleTreshold determines when the angle for the     |
//| MA is "about zero": This is when the value is between            |
//| [-AngleTreshold, AngleTreshold] (or when the histogram is red).  |
//|   MAPeriod: MA period                                            |
//|   AngleTreshold: The angle value is "about zero" when it is      |
//|     between the values [-AngleTreshold, AngleTreshold].          |      
//|   StartMAShift: The starting point to calculate the              |   
//|     angle. This is a shift value to the left from the            |
//|     observation point. Should be StartMAShift > EndMAShift.      | 
//|   EndMAShift: The ending point to calculate the                  |
//|     angle. This is a shift value to the left from the            | 
//|     observation point. Should be StartMAShift > EndMAShift.      |
//|                                                                  |
//|   Modified by MrPip                                              |
//|       Red for down                                               |
//|       Yellow for near zero                                       |
//|       Green for up                                               |
//|  10/15/05  MrPip                                                 |
//|            Corrected problem with USDJPY and optimized code      |
//|  10/23/05  Added other JPY crosses                               |   
//|                                                                  |
//|   8/1/2006 Modified to use any MA including LSMA                 |                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#property  copyright "MrPip and jpkfox"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 3
#property  indicator_color1  LimeGreen
#property  indicator_color2  Yellow
#property  indicator_color3 FireBrick
//---- indicator parameters
extern int MAPeriod=34;
extern int MA_Type = 1; //0=SMA, 1=EMA, 2=SMMA, 3=LWMA, 4=LSMA
extern int MA_AppliedPrice = 4;//0=close, 1=open, 2=high, 3=low, 4=median(high+low)/2, 5=typical(high+low+close)/3, 6=weighted(high+low+close+close)/4
extern double AngleTreshold=15;
extern int StartMAShift=4;
extern int EndMAShift=0;

int MA_Mode;
string strMAType;

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
switch (MA_Type)
   {
      case 1: strMAType="EMA"; MA_Mode=MODE_EMA; break;
      case 2: strMAType="SMMA"; MA_Mode=MODE_SMMA; break;
      case 3: strMAType="LWMA"; MA_Mode=MODE_LWMA; break;
      case 4: strMAType="LSMA"; break;
      default: strMAType="SMA"; MA_Mode=MODE_SMA; break;
   }
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName(strMAType+"_Angle("+MAPeriod+","+AngleTreshold+","+StartMAShift+","+EndMAShift+")");
//---- initialization done
   return(0);
}

//+------------------------------------------------------------------+
//| LSMA with PriceMode                                              |
//| PrMode  0=close, 1=open, 2=high, 3=low, 4=median(high+low)/2,    |
//| 5=typical(high+low+close)/3, 6=weighted(high+low+close+close)/4  |
//+------------------------------------------------------------------+

double LSMA(int Rperiod, int prMode, int shift)
{
   int i;
   double sum, pr;
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
     switch (prMode)
     {
     case 0: pr = Close[length-i+shift];break;
     case 1: pr = Open[length-i+shift];break;
     case 2: pr = High[length-i+shift];break;
     case 3: pr = Low[length-i+shift];break;
     case 4: pr = (High[length-i+shift] + Low[length-i+shift])/2;break;
     case 5: pr = (High[length-i+shift] + Low[length-i+shift] + Close[length-i+shift])/3;break;
     case 6: pr = (High[length-i+shift] + Low[length-i+shift] + Close[length-i+shift] + Close[length-i+shift])/4;break;
     }
     tmp = ( i - lengthvar)*pr;
     sum+=tmp;
    }
    wt = sum*6/(length*(length+1));
    
    return(wt);
}

//+------------------------------------------------------------------+
//| The angle for MA                                                |
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
 
   if(EndMAShift >= StartMAShift)
   {
      Print("Error: EndMAShift >= StartMAShift");
      StartMAShift = 6;
      EndMAShift = 0;      
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
   ShiftDif = StartMAShift-EndMAShift;
   mFactor /= ShiftDif; 
//---- main loop
   for(i=0; i<nLimit; i++)
   {
      if (MA_Type == 4)
      {
        fEndMA=LSMA(MAPeriod,MA_AppliedPrice, i+EndMAShift);
        fStartMA=LSMA(MAPeriod,MA_AppliedPrice, i+StartMAShift);
      }
      else
      {
        fEndMA=iMA(NULL,0,MAPeriod,0,MA_Mode,MA_AppliedPrice,i+EndMAShift);
        fStartMA=iMA(NULL,0,MAPeriod,0,MA_Mode,MA_AppliedPrice,i+StartMAShift);
      }
      // 10000.0 : Multiply by 10000 so that the fAngle is not too small
      // for the indicator Window.
      fAngle = mFactor * (fEndMA - fStartMA)/2.0;
//      fAngle = MathArctan(fAngle)/dFactor;

      DownBuffer[i] = 0.0;
      UpBuffer[i] = 0.0;
      ZeroBuffer[i] = 0.0;
      
      if(fAngle > AngleTreshold)
      {
         UpBuffer[i] = fAngle;
      }
      else if (fAngle < -AngleTreshold)
      {
         DownBuffer[i] = fAngle;
      }
      else ZeroBuffer[i] = fAngle;
   }

   return(0);
  }
//+------------------------------------------------------------------+

