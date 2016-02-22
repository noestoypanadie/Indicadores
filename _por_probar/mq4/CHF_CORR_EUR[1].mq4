//+------------------------------------------------------------------+
//|                               Correlation USDCHF/EURUSD .mq4 |
//|                                  Copyright © 2005, Yuri Makarov. |
//|                                       http://mak.tradersmind.com |
//+------------------------------------------------------------------+
//Correlates  chf prive ON eur 1 min chart
// if chf bar (1 min) is greater than 3 pips it recommends sell/buy eur
//

#property copyright "Copyright © 2005, Perky_z."
#property link      "Perky_z@yahoo.com"

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 OrangeRed

extern string Curency = "CHF";

double UsdChf[],UsdChfO[];
double Idx[];
double diff,diff1;
int init()
{
   IndicatorShortName(Curency);
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,Idx);
   return(0);
}

void start()
{
   //I've put the period statement in - this means that
   // you can get close for other periods onto the current chart
   ArrayCopySeries(UsdChf,MODE_CLOSE,"USDCHF",PERIOD_M1);
   ArrayCopySeries(UsdChfO,MODE_OPEN,"USDCHF",PERIOD_M1); 
  

   int counted_bars=IndicatorCounted();
   double USD;

   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
   int limit=Bars-counted_bars;
   for(int i=0; i<limit; i++)
   {
      
      
      diff=(UsdChf[i]-UsdChfO[i]);
      diff1=(UsdChf[i+1]-UsdChfO[i+1]);
     // Comment("Before",diff1,"\nnow    ",diff);
       if (Curency == "CHF") Idx[i] = UsdChf[i]; 
      if  (diff<=-0.0006 && diff<0)
      {
      Comment("diff ",diff," Buy EUR ",Ask," ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS));
      Alert ("USDCHF ",diff," Difference BUY EURUSD");
      }
      if (diff>=0.0006 && diff>0)  
      {
      Comment("diff ",diff," Sell EUR ",Bid," ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS));
      Alert ("USDCHF ",diff," Difference SELL EURUSD");
      }
      if (Curency == "CHF") Idx[i] = UsdChf[i]; 
      
   }
}


