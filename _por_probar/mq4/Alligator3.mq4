//+------------------------------------------------------------------+
//|                                                    Alligator.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"

#property indicator_separate_window
#property indicator_buffers 4
//#property indicator_color1 Blue
#property indicator_color2 Red
//#property indicator_color3 Lime
//---- input parameters
extern int JawsPeriod=5;
extern int JawsShift=0;
extern int TeethPeriod=8;
extern int TeethShift=0;
extern int LipsPeriod=5;
extern int LipsShift=0;
extern int trend=0;
extern int trendShift=0;
//---- indicator buffers
double ExtBlueBuffer[];
double ExtRedBuffer[];
double ExtLimeBuffer[];
double TrendBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- line shifts when drawing
   SetIndexShift(0,JawsShift);
   SetIndexShift(1,TeethShift);
   SetIndexShift(2,LipsShift);
   SetIndexShift(3,trendShift);
//---- first positions skipped when drawing
   SetIndexDrawBegin(0,JawsShift+JawsPeriod);
   SetIndexDrawBegin(1,TeethShift+TeethPeriod);
   SetIndexDrawBegin(2,LipsShift+LipsPeriod);
   SetIndexDrawBegin(3,trend);
//---- 3 indicator buffers mapping
   SetIndexBuffer(0,ExtBlueBuffer);
   SetIndexBuffer(1,ExtRedBuffer);
   SetIndexBuffer(2,ExtLimeBuffer);
   SetIndexBuffer(3,TrendBuffer);
//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexStyle(3,DRAW_LINE);
//---- index labels
   SetIndexLabel(0,"Gator Jaws");
   SetIndexLabel(1,"Gator Teeth");
   SetIndexLabel(2,"Gator Lips");
   SetIndexLabel(3,"trend");
//---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Bill Williams' Alligator                                         |
//+------------------------------------------------------------------+
int start()
  {
   int limit;
   int counted_bars=IndicatorCounted();
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
//---- main loop
   for(int i=0; i<limit; i++)
     {
      //---- ma_shift set to 0 because SetIndexShift called abowe
      ExtBlueBuffer[i]=iBullsPower(NULL, 0, 6,PRICE_TYPICAL,i);
      ExtRedBuffer[i]=iBearsPower(NULL, 0, 6,PRICE_TYPICAL,i);//iBearsPower(NULL, 0, 11,PRICE_CLOSE,i)+;iBullsPower(NULL, 0, 11,PRICE_CLOSE,i);
      ExtLimeBuffer[i]=ExtRedBuffer[i]+ExtBlueBuffer[i];

    }
//---- done
   return(0);
  }
//+------------------------------------------------------------------+

