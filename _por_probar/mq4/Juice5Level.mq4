//+------------------------------------------------------------------+
//|                                                        Juice.mq4 |
//|                                                          Perky_z |
//|                              http://fxovereasy.atspace.com/index |
//|                                   Modified by MrPip and traden4x |        
//+------------------------------------------------------------------+
#property  copyright "perky"
#property  link      "http://fxovereasy.atspace.com/index"

//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 5
#property  indicator_color1  Red
#property  indicator_color2  Yellow
#property  indicator_color3  Magenta
#property  indicator_color4  Orange
#property  indicator_color5  LimeGreen
#property  indicator_width1 2
#property  indicator_width2 2
#property  indicator_width3 2
#property  indicator_width4 2
#property  indicator_width5 2

//---- indicator parameters
extern int period=7;
extern int LowLevel=3;
extern int MedLevel=6;
extern int HighLevel=10;
extern int ExtremeLevel=15;

double LowLevelPoint;
double MedLevelPoint;
double HighLevelPoint;
double ExtremeLevelPoint;


//---- indicator buffers
double LowJuice[];
double Med1Juice[];
double Med2Juice[];
double HighJuice[];
double ExtremeJuice[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID);
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID);
   SetIndexStyle(3,DRAW_HISTOGRAM,STYLE_SOLID);
   SetIndexStyle(4,DRAW_HISTOGRAM,STYLE_SOLID);
//   SetIndexStyle(5,DRAW_HISTOGRAM,STYLE_SOLID);

   SetIndexDrawBegin(0,period);
   SetIndexDrawBegin(1,period);
   SetIndexDrawBegin(2,period);
   SetIndexDrawBegin(3,period);
   SetIndexDrawBegin(4,period);
//   SetIndexDrawBegin(5,period);

//   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS));

   SetIndexBuffer(0,LowJuice);
   SetIndexBuffer(1,Med1Juice);
   SetIndexBuffer(2,Med2Juice);
   SetIndexBuffer(3,HighJuice);
   SetIndexBuffer(4,ExtremeJuice);
//   SetIndexBuffer(5,SoSoJuice);

   IndicatorDigits(2);

   LowLevelPoint = LowLevel * Point;
   MedLevelPoint = MedLevel * Point;
   HighLevelPoint = HighLevel * Point;
   ExtremeLevelPoint = ExtremeLevel * Point;
   
   SetLevelValue(0, 0.0);
   SetLevelValue(1, LowLevel);
   SetLevelValue(2, MedLevel);
   SetLevelValue(3, HighLevel);
   SetLevelValue(4, ExtremeLevel);
   
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
      IndicatorShortName("Juice5Level("+period+") " + DoubleToStr(NormalizeDouble(stddev / Point,2),2) + " ");
         
      if (stddev <= LowLevelPoint)
      {
         LowJuice[i] = stddev / Point;
         Med1Juice[i] = 0.0;
         Med2Juice[i] = 0.0;
         HighJuice[i] = 0.0;
         ExtremeJuice[i] = 0.0;        
      }
      else if ((stddev > LowLevelPoint) && (stddev <= MedLevelPoint))
      {
         Med1Juice[i] = stddev / Point;
         LowJuice[i] = 0.0;
         Med2Juice[i] = 0.0;
         HighJuice[i] = 0.0;
         ExtremeJuice[i] = 0.0; 
      }
      else if ((stddev > MedLevelPoint) && (stddev <= HighLevelPoint))
      {
         Med2Juice[i] = stddev / Point;
         LowJuice[i] = 0.0;
         Med1Juice[i] = 0.0;
         HighJuice[i] = 0.0;
         ExtremeJuice[i] = 0.0; 
      }
      else if ((stddev > HighLevelPoint) && (stddev <= ExtremeLevelPoint))
      {
         HighJuice[i] = stddev / Point;
         LowJuice[i] = 0.0;
         Med1Juice[i] = 0.0;
         Med2Juice[i] = 0.0;
         ExtremeJuice[i] = 0.0; 
      }
      else 
      {
         ExtremeJuice[i] = stddev / Point;
         LowJuice[i] = 0.0;
         Med1Juice[i] = 0.0;
         Med2Juice[i] = 0.0;
         HighJuice[i] = 0.0; 
      }
   }

   return(0);
}


