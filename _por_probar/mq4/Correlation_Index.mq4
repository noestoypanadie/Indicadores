//+------------------------------------------------------------------+
//|                                            Correlation_Index.mq4 |
//|                                Copyright © 2006, albedo@email.it |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, albedo@email.it"
#property indicator_separate_window
//#property indicator_minimum -1
//#property indicator_maximum 1
#property indicator_buffers 1
#property indicator_color1 Red
extern int R_Period=13;
double R[];
double EurUsd[],UsdJpy[],AudUsd[],UsdCad[],UsdChf[],GbpUsd[];
//----
int ExtCountedBars=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   int    draw_begin;
   string short_name;
//---- drawing settings
   SetIndexStyle(1,DRAW_LINE);
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS));
   if(R_Period<2) R_Period=13;
   draw_begin=R_Period-1;
         short_name="R(";
   IndicatorShortName(short_name+R_Period+")");
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,R);
   
  return(0);
  }

int start()
  {
   ArrayCopySeries(EurUsd,MODE_CLOSE,"EURUSD");
   ArrayCopySeries(GbpUsd,MODE_CLOSE,"GBPUSD");
   ArrayCopySeries(AudUsd,MODE_CLOSE,"AUDUSD");
   ArrayCopySeries(UsdChf,MODE_CLOSE,"USDCHF");
   ArrayCopySeries(UsdJpy,MODE_CLOSE,"USDJPY");
   ArrayCopySeries(UsdCad,MODE_CLOSE,"USDCAD");
   
   if(Bars<=R_Period) return(0);
   ExtCountedBars=IndicatorCounted();
   if (ExtCountedBars<0) return(-1);
   if (ExtCountedBars>0) ExtCountedBars--;
//----
   double sumX=0;
   double sumY=0;
   double sumXY=0;
   double sumX2=0;
   double sumY2=0;
   int    a,b,c,d,e,acc=Bars-ExtCountedBars-1;
   if(acc<R_Period) acc=R_Period;
   
   for(a=1;a<R_Period;a++,acc--)      sumY+=UsdChf[acc];
   for(b=1;b<R_Period;b++,acc--)      sumX+=EurUsd[acc];
   for(c=1;c<R_Period;c++,acc--)      sumXY+=EurUsd[acc]*UsdChf[acc];   
   for(d=1;d<R_Period;d++,acc--)      sumX2+=MathPow(EurUsd[acc],2);
   for(e=1;e<R_Period;e++,acc--)      sumY2+=MathPow(UsdChf[acc],2);   

   while(acc>=0)
     {
      sumY+=UsdChf[acc];
      sumX+=EurUsd[acc];
      sumXY+=EurUsd[acc]*UsdChf[acc];
      sumX2+=MathPow(EurUsd[acc],2);
      sumY2+=MathPow(UsdChf[acc],2);

      double tmp = MathSqrt((sumX2-(MathPow(sumX,2)/R_Period))*(sumY2-(MathPow(sumY,2)/R_Period)));
      if (tmp == 0) tmp = Point;     
      R[acc]=(sumXY-((sumX*sumY)/R_Period))/ tmp;
//    The R correlation factor formula is correct, so why in the hell this indicator
//    shows alway a null value? >-(	   
	   
	   sumY-=UsdChf[acc+R_Period-1];
	   sumX-=EurUsd[acc+R_Period-1];
	   sumXY-=EurUsd[acc+R_Period-1]*UsdChf[acc+R_Period-1];
	   sumX2-=MathPow(EurUsd[acc+R_Period-1],2);
	   sumY2-=MathPow(UsdChf[acc+R_Period-1],2);

 	   acc--;
     }

   return(0);
  }

