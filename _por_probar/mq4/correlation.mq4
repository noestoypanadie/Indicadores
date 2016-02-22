//+------------------------------------------------------------------+
//|                                                  correlation.mq4 |
//|                                                          ENG.A`ED|
//|                                      aed_al_nairab@hotmail.com   |
//+------------------------------------------------------------------+


#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 DeepSkyBlue
 
//---- input parameters
extern string    currency_1="EURUSD";
extern string    currency_2="EURGBP";
extern int       iPeriod=20;

//---- buffers
double correl[];
double hl[];
double h2[];
double hl_2[];
double h2_2[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   IndicatorBuffers(1);
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,correl);
   
//----
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
   int limit;
   double u,l;
   int counted_bars=IndicatorCounted();
   if(counted_bars<0) counted_bars=0;
   if(counted_bars>0) counted_bars--;
   limit=500-counted_bars;
//----
   for(int c = limit-iPeriod ;c >= 0 ;c--)
   {
   for(int m = limit-iPeriod ;m >= 0  ;m--)
   {
    hl[m]=iClose(currency_1,0,m)-iMA(currency_1,0,iPeriod,0,MODE_SMA,PRICE_CLOSE,m);
    h2[m]=iClose(currency_2,0,m)-iMA(currency_2,0,iPeriod,0,MODE_SMA,PRICE_CLOSE,m);
    hl_2[m]=MathPow(hl[m],2);
    h2_2[m]=MathPow(h2[m],2);
   }
   u=0;l=0;
   for(int i = iPeriod-1 ;i >= 0 ;i--)
   {
     u=hl[c+i]* h2[c+i]+u;
     l=hl_2[c+i]*h2_2[c+i]+l;
       
   }
   correl[c]=u/MathSqrt(l);
   Comment("correlation ","\n",currency_1,"&",currency_2,correl);
  }
  
//----
   return(0);
  }
//+------------------------------------------------------------------+