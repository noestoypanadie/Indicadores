//+------------------------------------------------------------------+
//|                                              BBStopLight.mq4     |
//|                           based on BBandWidthRatio.mq4 from Maji |
//|                                -- adapted by Gideon, August 2006 |
//| August 31, 2006 Robert Hill Fixed CPU usage problem              |
//+------------------------------------------------------------------+
#property copyright "BBStopLight"
#property link      "gideon@smolders.biz"

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 SlateGray
#property indicator_color2 DarkOrange // trading allowed
#property indicator_color3 Pink // run is over, no trading
#property indicator_color4 Black // no trading allowed


//---- input parameters
extern int       BB_Period=20;
extern double    Deviation=2.0;
extern double    Multiply=2000;
extern double    Zeroline=3;

double buf1[];
double buf2[];
double buf3[];
double buf4[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   SetIndexStyle(0, DRAW_NONE, 1, 2);
   IndicatorDigits(MarketInfo(Symbol(), MODE_DIGITS));
   SetIndexDrawBegin(0,BB_Period);
   SetIndexLabel(0,"BBandWidthRatio");
   SetIndexBuffer(0, buf1);
   
   SetIndexStyle(1, DRAW_HISTOGRAM, 1, 2);
   IndicatorDigits(MarketInfo(Symbol(), MODE_DIGITS));
   SetIndexDrawBegin(1,BB_Period);
   SetIndexLabel(1,"BBandWidthRatio");
   SetIndexBuffer(1, buf2);
   
   SetIndexStyle(2, DRAW_HISTOGRAM, 1, 2);
   IndicatorDigits(MarketInfo(Symbol(), MODE_DIGITS));
   SetIndexDrawBegin(2,BB_Period);
   SetIndexLabel(2,"BBandWidthRatio");
   SetIndexBuffer(2, buf3);
   
   SetIndexStyle(3, DRAW_HISTOGRAM, 1, 2);
   IndicatorDigits(MarketInfo(Symbol(), MODE_DIGITS));
   SetIndexDrawBegin(3,BB_Period);
   SetIndexLabel(3,"BBandWidthRatio");
   SetIndexBuffer(3, buf4);
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
   int i, j, Limit;
   double ave, sko, sum;
   int counted_bars=IndicatorCounted();
   double MA, Up, Dn;
   
   if(Bars<=BB_Period) return(0);
      
   if(counted_bars>0) counted_bars--;
   Limit=Bars-counted_bars-BB_Period;
   
   for (i=Limit; i>=0; i--) 
   {
    
    MA = iMA(NULL,0,BB_Period,0,MODE_LWMA,PRICE_OPEN,i);
    sum = 0;
    for (j=0; j<BB_Period; j++) sum+=Close[i+j];
    ave = sum / BB_Period;
    sum = 0;
    for (j=0; j<BB_Period; j++) sum+=(Close[i+j]-ave)*(Close[i+j]-ave);
    sko = MathSqrt(sum / BB_Period);

    Up = MA+(Deviation*sko);
    Dn = MA-(Deviation*sko);
    
    buf1[i] = (Multiply*(Deviation*sko)/MA);
    
    if (buf1[i]>0 && buf1[i]>buf1[i+1]) {
    buf2[i] = buf1[i];
    buf3[i] = 0;
    buf4[i] = 0;
    }
    if (buf1[i]>0 && buf1[i]<buf1[i+1]) {
    buf2[i] = 0;
    buf3[i] = buf1[i];
    buf4[i] = 0;
    }
    if (buf1[i]<0) {
    buf2[i] = 0;
    buf3[i] = 0;
    buf4[i] = buf1[i];
    }
  
   }
  
    return(0);
  
  }
//+------------------------------------------------------------------+

