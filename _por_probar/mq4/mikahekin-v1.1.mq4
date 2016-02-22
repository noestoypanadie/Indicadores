//+------------------------------------------------------------------+
//|                                                    mikahekin.mq4 |
//|                        Copyright 2004, MetaQuotes Software Corp. |
//|                                                http://www.sasara |
//|                              Modified by: Ronald Verwer/ROVERCOM |
//|                                                    version 1.0.2 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2004, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property  indicator_chart_window
#property  indicator_buffers 4
#property  indicator_color1  Silver//Violet
#property  indicator_color2  Yellow//LawnGreen
#property  indicator_color3  Red//Magenta
#property  indicator_color4  Blue
#property  indicator_width1 3
#property  indicator_width2 3
#property  indicator_width3 2
#property  indicator_width4 2

//---- input parameters
extern int KPeriod=3;
extern int DPeriod=3;
extern int JPeriod=7;

double ind_buffer1[],
       ind_buffer2[],
       ind_buffer3[],
       ind_buffer4[],
       HighesBuffer[],
       LowesBuffer[];

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   string short_name;
	IndicatorBuffers(6);
   SetIndexStyle(0,DRAW_HISTOGRAM, 0, 3);
   SetIndexStyle(1,DRAW_HISTOGRAM, 0, 3);
   SetIndexStyle(2,DRAW_ARROW, 0, 2);
   SetIndexStyle(3,DRAW_ARROW, 0, 2);
   SetIndexArrow(2,159);
   SetIndexArrow(3,159);
//----
   SetIndexDrawBegin(0,10);
   SetIndexDrawBegin(1,10);
   SetIndexDrawBegin(2,10);
   SetIndexDrawBegin(3,10);
   SetIndexDrawBegin(4,10);
   SetIndexDrawBegin(5,10);
//---- indicator buffers mapping
   SetIndexBuffer(0,ind_buffer1);
   SetIndexBuffer(1,ind_buffer2);
   SetIndexBuffer(2,ind_buffer3);
   SetIndexBuffer(3,ind_buffer4);
   SetIndexBuffer(4, HighesBuffer);
   SetIndexBuffer(5, LowesBuffer);
   
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
   if(counted_bars<0) return (-1);
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
      double sumlow=0,
             sumhigh=0,
             sumopen=0,
             sumclose=0,
             close=0,
             open=0,
             high=0,
             low=0;

      for(k=(i+JPeriod-1);k>=i;k--)
         {
         sumclose+=Close[k];
         sumlow+= LowesBuffer[k];
         sumopen+=Open[k];
         sumhigh+=HighesBuffer[k];
         }
      close=sumclose/JPeriod;
      low= sumlow/JPeriod;
      open=sumopen/JPeriod;
      high=sumhigh/JPeriod;
         
      ind_buffer1[i]=open;
      ind_buffer2[i]=close;

      if(open>close)
         {
         ind_buffer3[i]=high;
         ind_buffer4[i]=EMPTY_VALUE;
         }
      else
         {
         if(open<close)
            {
            ind_buffer4[i]=low;
            ind_buffer3[i]=EMPTY_VALUE;
            }
         else
            {
            ind_buffer3[i]=EMPTY_VALUE;
            ind_buffer4[i]=EMPTY_VALUE;
            }
         }
      i--;
      }
//----
   return(0);
   }
//+------------------------------------------------------------------+


