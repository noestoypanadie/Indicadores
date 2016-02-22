//+------------------------------------------------------------------+
//|                            Volume with Custom Moving Average.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004, MetaQuotes Software Corp. Modified RonT"
#property link      "http://www.metaquotes.net/"

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 Red
#property indicator_color2 Green
#property indicator_color3 White
#property indicator_color4 Silver

// User input
extern int MA_Period=13;
extern int MA_Shift=0;
extern int MA_Method=0;

// Buffers
double VolBuffer1[];  // value down
double VolBuffer2[];  // value up
double VolBuffer3[];  // moving average
double VolBuffer4[];  // Top line 

//----
int ExtCountedBars=0;
int lastcolor=0;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   int    draw_begin;
   string short_name;

   // indicator buffers mapping, drawing settings and Shift
   
   // Histogram downArrow Red
   SetIndexBuffer(0,VolBuffer1);
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexShift(0,MA_Shift);

   // Histogram upArrow Green
   SetIndexBuffer(1,VolBuffer2); 
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexShift(1,MA_Shift);

   // Moving average line white
   SetIndexBuffer(2,VolBuffer3);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexShift(2,MA_Shift);

   // Top line
   SetIndexBuffer(3,VolBuffer4);
   SetIndexStyle(3,DRAW_LINE);
   SetIndexShift(3,MA_Shift);


   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS));

   if(MA_Period<2) MA_Period=2;
   draw_begin=MA_Period-1;

   switch(MA_Method)
     {
      case 1  : short_name="EMA(" ;  draw_begin=0; break;
      case 2  : short_name="SMMA(";                break;
      case 3  : short_name="LWMA(";                break;
      default : short_name="SMA(" ;  MA_Method=0;
     }
   IndicatorShortName(short_name+MA_Period+")");

   SetIndexDrawBegin(0,draw_begin);

   return(0);
  }


//+------------------------------------------------------------------+
//| Main                                                             |
//+------------------------------------------------------------------+
int start()
  {
  
   if(Bars<=MA_Period) return(0);
   ExtCountedBars=IndicatorCounted();

// check for possible errors
   if (ExtCountedBars<0) return(-1);

// last counted bar will be recounted
   if (ExtCountedBars>0) ExtCountedBars--;

   switch(MA_Method)
     {
      case 0 : sma();  break;
      case 1 : ema();  break;
      case 2 : smma(); break;
      case 3 : lwma();
     }
   return(0);
  }

//+------------------------------------------------------------------+
//| Simple Moving Average                                            |
//+------------------------------------------------------------------+
void sma()
  {
   double sum=0;
   int    i,pos=Bars-ExtCountedBars-1;

   // initial accumulation
   if(pos<MA_Period) pos=MA_Period;
   for(i=1;i<MA_Period;i++,pos--)
      sum+=Volume[pos];

   while(pos>=0)
     {
      // 2-period moving average for reference
            VolBuffer4[pos]=(Volume[pos]+Volume[pos+1]+Volume[pos+2])/3;

      sum+=Volume[pos];
      VolBuffer3[pos]=sum/MA_Period;
	   sum-=Volume[pos+MA_Period-1];
	   Vcolor(pos);
 	   pos--;
     }

   // zero initial bars
   if(ExtCountedBars<1)
      for(i=1;i<MA_Period;i++) VolBuffer1[Bars-i]=0;
  }



//+------------------------------------------------------------------+
//| Exponential Moving Average                                       |
//+------------------------------------------------------------------+
void ema()
  {
   double pr=2.0/(MA_Period+1);
   int    pos=Bars-2;

   if(ExtCountedBars>2) pos=Bars-ExtCountedBars-1;

   while(pos>=0)
     {
      if(pos==Bars-2) VolBuffer3[pos+1]=Volume[pos+1];
      VolBuffer3[pos]=Volume[pos]*pr+VolBuffer3[pos+1]*(1-pr);
      Vcolor(pos);
 	   pos--;
     }
  }



//+------------------------------------------------------------------+
//| Smoothed Moving Average                                          |
//+------------------------------------------------------------------+
void smma()
  {
   double sum=0;
   int    i,k,pos=Bars-ExtCountedBars+1;

   pos=Bars-MA_Period;
   if(pos>Bars-ExtCountedBars) pos=Bars-ExtCountedBars;
   while(pos>=0)
     {
      if(pos==Bars-MA_Period)
        {
         // initial accumulation
         for(i=0,k=pos;i<MA_Period;i++,k++)
           {
            sum+=Volume[k];
            // zero initial bars
            VolBuffer3[k]=0;
           }
        }
      else sum=VolBuffer3[pos+1]*(MA_Period-1)+Volume[pos];
      VolBuffer3[pos]=sum/MA_Period;
 	   pos--;
     }
  }



//+------------------------------------------------------------------+
//| Linear Weighted Moving Average                                   |
//+------------------------------------------------------------------+
void lwma()
  {
   double sum=0.0,lsum=0.0;
   double price;
   int    i,weight=0,pos=Bars-ExtCountedBars-1;
//---- initial accumulation
   if(pos<MA_Period) pos=MA_Period;
   for(i=1;i<=MA_Period;i++,pos--)
     {
      price=Volume[pos];
      sum+=price*i;
      lsum+=price;
      weight+=i;
     }
//---- main calculation loop
   pos++;
   i=pos+MA_Period;
   while(pos>=0)
     {
      VolBuffer3[pos]=sum/weight;
      if(pos==0) break;
      pos--;
      i--;
      price=Volume[pos];
      sum=sum-lsum+price*MA_Period;
      lsum-=Volume[i];
      lsum+=price;
     }
//---- zero initial bars
   if(ExtCountedBars<1)
      for(i=1;i<MA_Period;i++) VolBuffer3[Bars-i]=0;
  }



//+------------------------------------------------------------------+
//| Color depends on gain or loss and previous volume                |
//+------------------------------------------------------------------+
// 1 - histo down red
// 2 - histo up green
// 3 - line white

void Vcolor(int p)
  {
 
   if (Volume[p+1]>Volume[p])
     {
      VolBuffer1[p]=Volume[p];
      VolBuffer2[p]=0;
      lastcolor=Red;
     }

   if (Volume[p+1]<Volume[p])
     {
      VolBuffer1[p]=0;
      VolBuffer2[p]=Volume[p];
      lastcolor=Green;
     }        

   if (Volume[p+1]==Volume[p])
     {
      if ( lastcolor==Red )
        {
         VolBuffer1[p]=Volume[p];
         VolBuffer2[p]=0;
        }
      if ( lastcolor==Green )
        {
         VolBuffer1[p]=0;
         VolBuffer2[p]=Volume[p];
        }
     }
  }

//+------------------------------------------------------------------+

