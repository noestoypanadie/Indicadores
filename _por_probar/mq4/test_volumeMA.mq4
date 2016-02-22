//+------------------------------------------------------------------+
//| Volume with moving average                                       |
//+------------------------------------------------------------------+
#property copyright "RonT"
#property link      "http://www.lightpatch.com/"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Red
#property indicator_color2 Green
#property indicator_color3 White

//---- indicator parameters
extern int MA_Period=13;

//---- indicator buffers
double VolBuffer1[];  // value down
double VolBuffer2[];  // value up
double VolBuffer3[];  // moving average

//----
int ExtCountedBars=0;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   int    draw_begin;
   string short_name;

//---- indicator buffers mapping
   SetIndexBuffer(0,VolBuffer1); // histo down red
   SetIndexBuffer(1,VolBuffer2); // histo up green
   SetIndexBuffer(2,VolBuffer3); // line white


//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexStyle(2,DRAW_LINE);

   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS));

   if(MA_Period<2) MA_Period=13;
   draw_begin=MA_Period-1;

//---- indicator short name
   short_name="SMA(";
   IndicatorShortName(short_name+MA_Period+")");
   SetIndexDrawBegin(0,draw_begin);

   return(0);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
   if(Bars<=MA_Period) return(0);
   ExtCountedBars=IndicatorCounted();

//---- check for possible errors
   if (ExtCountedBars<0) return(-1);

//---- last counted bar will be recounted
   if (ExtCountedBars>0) ExtCountedBars--;

//+------------------------------------------------------------------+
//| Simple Moving Average                                            |
//+------------------------------------------------------------------+

   double sum=0;
   int    i,pos=Bars-ExtCountedBars-1;
   int    lastcolor=0;

//---- initial accumulation
   if(pos<MA_Period) pos=MA_Period;
   for(i=1;i<MA_Period;i++,pos--)
      sum+=Volume[pos];

//---- main calculation loop

   // 1 - histo down red
   // 2 - histo up green
   // 3 - line white

   while(pos>=0)
     {
      if (Volume[pos+1]>Volume[pos])
        {
         VolBuffer1[pos]=Volume[pos];
         VolBuffer2[pos]=0;
         lastcolor=Red;
        }

      if (Volume[pos+1]<Volume[pos])
        {
         VolBuffer1[pos]=0;
         VolBuffer2[pos]=Volume[pos];
         lastcolor=Green;
        }        

      if (Volume[pos+1]==Volume[pos])
        {
         if ( lastcolor==Red )
           {
            VolBuffer1[pos]=Volume[pos];
            VolBuffer2[pos]=0;
           }
         if ( lastcolor==Green )
           {
            VolBuffer1[pos]=0;
            VolBuffer2[pos]=Volume[pos];
           }
        }        

      sum+=Volume[pos];
      VolBuffer3[pos]=sum/MA_Period;
	   sum-=Volume[pos+MA_Period-1];

 	   pos--;
     }

//---- zero initial bars
   if(ExtCountedBars<1)
      for(i=1;i<MA_Period;i++) VolBuffer1[Bars-i]=0;
  }

//+------------------------------------------------------------------+

