//+------------------------------------------------------------------+
//|                                                        Juice.mq4 |
//|                                                          Perky_z |
//|                              http://fxovereasy.atspace.com/index |
//+------------------------------------------------------------------+
#property  copyright "perky"
#property  link      "http://fxovereasy.atspace.com/index"

//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 3
#property  indicator_color1  LimeGreen
#property  indicator_color2  Red
#property  indicator_color3  Orange
#property  indicator_width1 2
#property  indicator_width2 2
#property  indicator_width3 2
#property  indicator_level1 0.0
#property  indicator_level2 8.0
#property  indicator_level3 11.0
#property  indicator_level4 4.0

//---- indicator parameters
extern int period=7;
extern int thresholdLevel=8;
extern int soSoLevel=4;

double thresholdLevelPoint;
double soSoLevelPoint;

//---- indicator buffers
double GoodJuice[];
double BadJuice[];
double SoSoJuice[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID);
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID);

   SetIndexDrawBegin(0,period);
   SetIndexDrawBegin(1,period);
   SetIndexDrawBegin(2,period);

   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+2);

   SetIndexBuffer(0,GoodJuice);
   SetIndexBuffer(1,BadJuice);
   SetIndexBuffer(2,SoSoJuice);

   IndicatorDigits(2);

   thresholdLevelPoint = thresholdLevel * Point;
   soSoLevelPoint = soSoLevel * Point;

   SetLevelValue(0, 0.0);
   SetLevelValue(1, soSoLevel);
   SetLevelValue(2, thresholdLevel);
   
   IndicatorShortName("Juice("+period+","+DoubleToStr(thresholdLevelPoint,Digits)+")");

   return(0);
}

//+------------------------------------------------------------------+
//| Moving Average of Oscillator                                     |
//+------------------------------------------------------------------+
int start()
{
   int limit,i;
   int counted_bars=IndicatorCounted();
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
 
   for(i=limit; i>=0; i--)
   {
      double stddev = iStdDev(NULL,0,period,MODE_EMA,0,PRICE_CLOSE,i);
         
      if (stddev >= thresholdLevelPoint)
      {
         GoodJuice[i] = stddev / Point;
         BadJuice[i] = 0.0;
         SoSoJuice[i] = 0.0;
      }
      else if (stddev < soSoLevelPoint)
      {
         BadJuice[i] = stddev / Point;
         GoodJuice[i] = 0.0;
         SoSoJuice[i] = 0.0;
      }
      else
      {
         SoSoJuice[i] = stddev / Point;
         GoodJuice[i] = 0.0;
         BadJuice[i] = 0.0;
      }
   }

   return(0);
}


