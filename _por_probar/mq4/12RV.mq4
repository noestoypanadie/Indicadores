//+------------------------------------------------------------------+
//|                                                    mikahekin.mq4 |
//|                       Copyright ?2004, MetaQuotes Software Corp. |
//|                                                http://www.sasara |
//|                              Modified by: Ronald Verwer/ROVERCOM |
//|                                                    version 1.0.4 |
//+------------------------------------------------------------------+
#property copyright "Copyright ?2004, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property  indicator_chart_window
#property  indicator_buffers 4
#property  indicator_color1  Silver
#property  indicator_color2  Yellow
#property  indicator_color3  Red
#property  indicator_color4  Blue
//---- input parameters
extern int KPeriod=3;
extern int DPeriod=3;
extern int JPeriod=7;

double ind_buffer1[];
double ind_buffer2[];
double ind_buffer3[];
double ind_buffer4[];
double LowesBuffer[];
double HighesBuffer[];

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   string short_name;
   IndicatorBuffers(6);
   SetIndexStyle(0,DRAW_HISTOGRAM, 0, 3);
   SetIndexStyle(1,DRAW_HISTOGRAM, 0, 3);
   SetIndexStyle(2,DRAW_ARROW, 0, 1);
   SetIndexStyle(3,DRAW_ARROW, 0, 1);
//----
   SetIndexDrawBegin(0,10);
   SetIndexDrawBegin(1,10);
   SetIndexDrawBegin(2,10);
   SetIndexDrawBegin(3,10);
//---- indicator buffers mapping
   SetIndexBuffer(0,ind_buffer1);
   SetIndexBuffer(1,ind_buffer2);
   SetIndexBuffer(2,ind_buffer3);
   SetIndexBuffer(3,ind_buffer4);
   SetIndexBuffer(4,HighesBuffer);
   SetIndexBuffer(5,LowesBuffer);

//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("mikahekin");
   SetIndexLabel(0,"Open");
   SetIndexLabel(1,"Close");
   SetIndexLabel(2,"High");
   SetIndexLabel(3,"Low");
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int start()
  {
   int    i,k,j;
   int    counted_bars=IndicatorCounted();
   double price;
   
//----
   if(Bars<=10) return(0);
//---- initial zero
   if(counted_bars<0)
   return (-1);
//---- minimums  counting
   i=Bars-KPeriod;
   if(counted_bars>KPeriod) i=Bars-counted_bars-1;
   while(i>=0)
     {
      double min=1000000;
      k=i+KPeriod-1;
      while(k>=i)
        {
         price=Low[k];
         if(min>price) min=price;
         k--;
        }
      LowesBuffer[i]=min;
      i--;
     }
//---- maximums counting
   i=Bars-DPeriod;
   if(counted_bars>DPeriod) i=Bars-counted_bars-1;
   while(i>=0)
     {
      double max=-100000;
      j=i+DPeriod-1;
      while(j>=i)
        {
         price=High[j];
         if(price>max) max=price;
         j--;
        }
      HighesBuffer[i]=max;
      i--;
     }
//---- mikahekin calcaulation
   i=Bars-JPeriod;
   if(counted_bars>JPeriod) i=Bars-counted_bars-1;
   while(i>=0)
     {
      double sumlow=0.0;
      double sumhigh=0.0;
      double sumopen=0.0;
      double sumclose=0.0;
      double close=0.0;
      double open=0.0;
      double high=0.0;
      double low=0.0;
      ind_buffer1[i]=open;
      ind_buffer2[i]=close;
      ind_buffer3[i]=high;
      ind_buffer4[i]=low;
      for(k=(i+JPeriod-1);k>=i;k--)
        {
          sumclose+=Close[k];
          close=sumclose/JPeriod;
          sumlow+= LowesBuffer[k];
          low= sumlow/JPeriod;
          sumhigh+=HighesBuffer[k];
          high=sumhigh/JPeriod;
          sumopen+=Open[k];
          open=sumopen/JPeriod;
        }

      ind_buffer3[i]=high;
      ind_buffer4[i]=low;
      ind_buffer1[i]=open;//open;
      ind_buffer2[i]=close;//open;
      
      i--;
     }
//----
   return(0);
  }
//+------------------------------------------------------------------+


