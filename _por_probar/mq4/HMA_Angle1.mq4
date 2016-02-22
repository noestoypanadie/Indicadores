//+------------------------------------------------------------------+
//|                                                    HMA_Angle.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2004, MetaQuotes Software Corp."
#property  link      "http://www.metaquotes.net/"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 3
#property  indicator_color1  Olive
#property  indicator_color2  FireBrick
#property  indicator_color3  Orange
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2

//---- indicator parameters
extern int HMA_Period=7;
extern double AngleTreshold=15;
extern int StartHMAShift=2;
extern int EndHMAShift=0;

//---- indicator buffers
double UpBuffer[];
double DownBuffer[];
double ZeroBuffer[];

//---- additional buffers

int        draw_begin0;

   double mFactor;
   int ShiftDif;
   string Sym;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicator buffers mapping

   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+1);

//---- 3 indicator buffers mapping
   if(!SetIndexBuffer(0,UpBuffer) &&
      !SetIndexBuffer(1,DownBuffer) &&
      !SetIndexBuffer(2,ZeroBuffer))
      Print("cannot set indicator buffers!");
//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID);
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID);
   draw_begin0=HMA_Period+MathFloor(MathSqrt(HMA_Period));
   SetIndexDrawBegin(0,draw_begin0);
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+1);
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("HMA_Angle("+HMA_Period+","+AngleTreshold+","+StartHMAShift+","+EndHMAShift+")");
   SetIndexLabel(0,"HMA Angle");
   if(EndHMAShift >= StartHMAShift)
   {
      Print("Error: EndHMAShift >= StartHMAShift");
      StartHMAShift = 6;
      EndHMAShift = 0;      
   }  
   mFactor = 100000.0;
   Sym = StringSubstr(Symbol(),3,3);
   if (Sym == "JPY") mFactor = 1000.0;
   ShiftDif = StartHMAShift-EndHMAShift;
   mFactor /= ShiftDif;
//---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int start()
  {
   double ma1, ma2;
   double fEndMA, fStartMA;
   double fAngle;
   int limit,i;
   double angle;
   int counted_bars=IndicatorCounted();
//---- check for possible errors
   if(counted_bars<0) 
      return(-1);
   if(counted_bars<1)
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
//---- main loop
   for(i=0; i<limit; i++)
   {
      fEndMA=iCustom(NULL, 0, "HMA",HMA_Period,0,i+EndHMAShift);
      fStartMA=iCustom(NULL, 0, "HMA",HMA_Period,0,i+StartHMAShift);
      // 10000.0 : Multiply by 10000 so that the fAngle is not too small
      // for the indicator Window.
      fAngle = mFactor * (fEndMA - fStartMA)/2.0;
//Print (mFactor, fEndMA, fStartMA, fAngle);
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

//---- done
   return(0);
  }

//+------------------------------------------------------------------+