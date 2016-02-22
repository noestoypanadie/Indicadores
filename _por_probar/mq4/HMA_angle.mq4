//+------------------------------------------------------------------+
//|                                                    HMA_angle.mq4 |
//|                Copyright © 2006, Nick Bilak, beluck[AT]gmail.com |
//|                                    http://metatrader.50webs.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Nick Bilak"
#property link      "http://metatrader.50webs.com/"

//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 1
#property  indicator_color1  Aqua
//---- indicator parameters
extern int _maPeriod=20;
extern int price = PRICE_OPEN;
//---- indicator buffers
double e1[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- drawing settings
   SetIndexStyle(0,DRAW_LINE);
   SetIndexEmptyValue(0,0);
   if(
   	!SetIndexBuffer(0,e1)
      )
      Print("cannot set indicator buffers!");
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("HMA_angle("+_maPeriod+")");
//---- initialization done
   return(0);
   
  }

int start()
  {
   int i,limit;
   int counted_bars=IndicatorCounted();
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-_maPeriod-1-counted_bars;
	double hma1,hma2,y;
   for(i=limit; i>=0; i--) {
		hma1=iCustom(NULL,0,"HMA",_maPeriod,price,0,i);
		hma2=iCustom(NULL,0,"HMA",_maPeriod,price,0,i+1);
		y=MathAbs(hma1-hma2);
   	e1[i]=y;
   }
//---- done
   return(0);
  }
//+------------------------------------------------------------------+

