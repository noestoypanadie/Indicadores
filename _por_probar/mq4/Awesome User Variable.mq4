//+------------------------------------------------------------------+
//|                                                      Awesome.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2005, MetaQuotes Software Corp."
#property  link      "http://www.metaquotes.net/"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 3
#property  indicator_color1  Black
#property  indicator_color2  Green
#property  indicator_color3  Red

//---- external variables
//iMA(Symbol(),mafasttimeframe,mafastperiod,mafastshift,mafastmode,mafastappliedprice,i)-
//iMA(Symbol(),maslowtimeframe,maslowperiod,maslowshift,maslowmode,maslowappliedprice,i)
double mafast,maslow;
extern int mafasttimeframe    =0;
extern int mafastperiod       =5;
extern int mafastshift        =0;
extern int mafastmode         =0;//0 sma 1 ema 2 smma 3 lwma
extern int mafastappliedprice =4;
/* PRICE_CLOSE    0 Close price. 
   PRICE_OPEN     1 Open price. 
   PRICE_HIGH     2 High price. 
   PRICE_LOW      3 Low price. 
   PRICE_MEDIAN   4 Median price, (high+low)/2. 
   PRICE_TYPICAL  5 Typical price, (high+low+close)/3. 
   PRICE_WEIGHTED 6 Weighted close price, (high+low+close+close)/4.*/
extern int maslowtimeframe    =0;
extern int maslowperiod       =34;
extern int maslowshift        =0;
extern int maslowmode         =0;// 0 sma 1 ema 2 smma 3 lwma
extern int maslowappliedprice =4; 



//---- indicator buffers
double     ExtBuffer0[];
double     ExtBuffer1[];
double     ExtBuffer2[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   //---- drawing settings
   SetIndexStyle(0,DRAW_NONE);
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexStyle(2,DRAW_HISTOGRAM);
   IndicatorDigits(Digits+1);
   SetIndexDrawBegin(0,34);
   SetIndexDrawBegin(1,34);
   SetIndexDrawBegin(2,34);
//---- 3 indicator buffers mapping
   SetIndexBuffer(0,ExtBuffer0);
   SetIndexBuffer(1,ExtBuffer1);
   SetIndexBuffer(2,ExtBuffer2);
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("AO UV");
   SetIndexLabel(1,NULL);
   SetIndexLabel(2,NULL);
//---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Awesome Oscillator                                               |
//+------------------------------------------------------------------+
int start()
  {
   int    limit;
   int    counted_bars=IndicatorCounted();
   double prev,current;
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
//---- macd
   for(int i=0; i<limit; i++)
      ExtBuffer0[i]=iMA(NULL,0,5,0,MODE_SMA,PRICE_OPEN,i)-iMA(NULL,0,34,0,MODE_SMA,PRICE_OPEN,i);
//---- dispatch values between 2 buffers
   bool up=true;
   for(i=limit-1; i>=0; i--)
     {
      current=ExtBuffer0[i];
      prev=ExtBuffer0[i+1];
      if(current>prev) up=true;
      if(current<prev) up=false;
      if(!up)
        {
         ExtBuffer2[i]=current;
         ExtBuffer1[i]=0.0;
        }
      else
        {
         ExtBuffer1[i]=current;
         ExtBuffer2[i]=0.0;
        }
     }
//---- done
   return(0);
  }