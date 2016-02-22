//+------------------------------------------------------------------+
//|                                               Correlation_v1.mq4 |
//|                           Copyright © 2006, TrendLaboratory Ltd. |
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |
//|                                       E-mail: igorad2004@list.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, TrendLaboratory Ltd."
#property link      "http://finance.groups.yahoo.com/group/TrendLaboratory"

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 DeepSkyBlue
#property indicator_maximum 1.05
#property indicator_minimum -1.05

//---- input parameters
extern string    Symbol1="GBPUSD";
extern string    Symbol2="EURUSD";
extern int       cPeriod=20;

//---- buffers
double Correlation[];
double DiffBuffer1[];
double DiffBuffer2[];
double PowDiff1[];
double PowDiff2[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   IndicatorBuffers(5);
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,Correlation);
   SetIndexBuffer(1,DiffBuffer1);
   SetIndexBuffer(2,DiffBuffer2);
   SetIndexBuffer(3,PowDiff1);
   SetIndexBuffer(4,PowDiff2);
//----
   string short_name="Correlation("+Symbol1+","+Symbol2+","+cPeriod+")";
   IndicatorShortName(short_name);
   SetIndexLabel(0,short_name);
   
   SetIndexDrawBegin(0,2*cPeriod);
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int shift,limit,counted_bars=IndicatorCounted();
   
   if ( counted_bars < 0 ) return(-1);
   if ( counted_bars ==0 ) limit=Bars-cPeriod-1;
   if ( counted_bars < 1 ) 
   for(int i=1;i<2*cPeriod;i++) Correlation[Bars-i]=0;    
      
   if(counted_bars>0) limit=Bars-counted_bars;
   limit--;
   
   for( shift=limit; shift>=0; shift--)
   {
//----
   DiffBuffer1[shift]=iClose(Symbol1,0,shift)-iMA(Symbol1,0,cPeriod,0,MODE_SMA,PRICE_CLOSE,shift);
   DiffBuffer2[shift]=iClose(Symbol2,0,shift)-iMA(Symbol2,0,cPeriod,0,MODE_SMA,PRICE_CLOSE,shift);
   PowDiff1[shift]=MathPow(DiffBuffer1[shift],2);
   PowDiff2[shift]=MathPow(DiffBuffer2[shift],2);
   
      double u=0,l=0,s=0;
      
      for( i = cPeriod-1 ;i >= 0 ;i--)
      {
      u += DiffBuffer1[shift+i]*DiffBuffer2[shift+i];
      l += PowDiff1[shift+i];
      s += PowDiff2[shift+i];
      }
      
   if(l*s >0) Correlation[shift]=u/MathSqrt(l*s);
   
  }
  
//----
   return(0);
  }
//+------------------------------------------------------------------+