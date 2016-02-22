//+------------------------------------------------------------------+
//|                                                         T3MA.mq4 |
//|                                     Copyright © 2005, Nick Bilak |
//|                                        http://www.forex-tsd.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Nick Bilak"
#property link      "http://www.forex-tsd.com/"

//---- indicator settings
#property  indicator_chart_window
#property  indicator_buffers 1
#property  indicator_color1  Aqua
//---- indicator parameters
extern int Periods=12;
//---- indicator buffers
double e1[];
double e2[];
double e3[];
double e4[];
double e5[];
double e6[];
double e7[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   IndicatorBuffers(7);
//---- drawing settings
   SetIndexStyle(0,DRAW_LINE);
   SetIndexDrawBegin(0,Periods);
   if(
   	!SetIndexBuffer(0,e7) &&
      !SetIndexBuffer(1,e2) &&
      !SetIndexBuffer(2,e3) &&
      !SetIndexBuffer(3,e4) &&
      !SetIndexBuffer(4,e5) &&
      !SetIndexBuffer(4,e6) &&
   	!SetIndexBuffer(5,e1)
      )
      Print("cannot set indicator buffers!");
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("T3MA("+Periods+")");
//---- initialization done
   return(0);
   
  }
//+------------------------------------------------------------------+
//| Moving Average of Oscillator                                     |
//+------------------------------------------------------------------+
int start()
  {
   int i,limit;
   int counted_bars=IndicatorCounted();
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-Periods-1-counted_bars;

//---- main loop
   for(i=limit; i>=0; i--) {
   	e1[i]=iMA(NULL,0,Periods,0,MODE_EMA,PRICE_CLOSE,i);
   }
   for(i=limit; i>=0; i--) {
   	e2[i]=iMAOnArray(e1,0,Periods,0,MODE_EMA,i);
   }
   for(i=limit; i>=0; i--) {
   	e3[i]=iMAOnArray(e2,0,Periods,0,MODE_EMA,i);
   }
   for(i=limit; i>=0; i--) {
   	e4[i]=iMAOnArray(e3,0,Periods,0,MODE_EMA,i);
   }
   for(i=limit; i>=0; i--) {
   	e5[i]=iMAOnArray(e4,0,Periods,0,MODE_EMA,i);
   }
   for(i=limit; i>=0; i--) {
   	e6[i]=iMAOnArray(e5,0,Periods,0,MODE_EMA,i);
   }
	double a=0.8;
	double c1=-a*a*a;
	double c2=3*a*a+3*a*a*a;
	double c3=-6*a*a-3*a-3*a*a*a;
	double c4=1+3*a+a*a*a+3*a*a;
	//T3MA=c1*e6+c2*e5+c3*e4+c4*e3;
   for(i=limit; i>=0; i--) {
   	e6[i]=iMAOnArray(e5,0,Periods,0,MODE_EMA,i);
   	e7[i]=c1*e6[i]+c2*e5[i]+c3*e4[i]+c4*e3[i];
   }
//---- done
   return(0);
  }
//+------------------------------------------------------------------+

