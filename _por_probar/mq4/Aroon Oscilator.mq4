//+------------------------------------------------------------------+
//|                                       Custom Aroon Oscilator.mq4 |
//|                                                        rafcamara |
//|                                                                  |
//+------------------------------------------------------------------+
#property  copyright "rafcamara"
#property  link      "rafcamara@yahoo.com"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 6
#property  indicator_color1  DodgerBlue
#property  indicator_color2  Red
#property  indicator_color3  Aqua
#property  indicator_color4  Pink

//---- indicator parameters
extern int AroonPeriod=14;
extern int Filter=50;

//---- indicator buffers
double     ind_buffer1[];
double     ind_buffer2[];
double     ind_buffer3[];
double     ind_buffer4[];

int        HighBarBuffer[];
int        LowBarBuffer[];
double     ArOscBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   //---- additional buffers are used for counting.
   IndicatorBuffers(7);
   SetIndexBuffer(4, HighBarBuffer);
   SetIndexBuffer(5, LowBarBuffer);
   SetIndexBuffer(6, ArOscBuffer);

   //---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(3,DRAW_HISTOGRAM,STYLE_SOLID,2);  
   SetIndexDrawBegin(0,200);
   SetIndexDrawBegin(1,200);
   SetIndexDrawBegin(2,200);
   SetIndexDrawBegin(3,200);
   
   IndicatorDigits(0);
   //-- indicator buffers mapping
   if(!SetIndexBuffer(0,ind_buffer1) && !SetIndexBuffer(1,ind_buffer2)
   && !SetIndexBuffer(2,ind_buffer3) && !SetIndexBuffer(3,ind_buffer4)
   && !SetIndexBuffer(4,HighBarBuffer) && !SetIndexBuffer(5,LowBarBuffer) 
   && !SetIndexBuffer(6,ArOscBuffer)
   )
      Print("cannot set indicator buffers!");
   //---- name for DataWindow and indicator subwindow label
   IndicatorShortName("Aroon Osc("+AroonPeriod+", "+Filter+")");
   //---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Aroon Oscilator                                                  |
//+------------------------------------------------------------------+
int start()
  {
   double   ArOsc;
   int      ArPer, HighBar=0,LowBar=0; 
   int      limit,i;
   bool     up,dn;
   int      counted_bars=IndicatorCounted();
   
   ArPer=AroonPeriod;
   //---- check for possible errors
   if(counted_bars<0) return(-1);
   
   //---- initial zero
   if(counted_bars<1)
     {
      for(i=1;i<=ArPer;i++) HighBarBuffer[Bars-i]=0.0;
      for(i=1;i<=ArPer;i++) LowBarBuffer[Bars-i]=0.0;
      for(i=1;i<=ArPer;i++) ArOscBuffer[Bars-i]=0.0;
     } 

   //---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;

   //----Calculation---------------------------
   for( i=0; i<limit; i++)
   {
  	   HighBarBuffer[i] = Highest(NULL,0,MODE_HIGH,ArPer,i); 	//Periods from HH  	   
  	   LowBarBuffer[i] = Lowest(NULL,0,MODE_LOW,ArPer,i);		//Periods from LL

  	   ArOscBuffer[i]= 100*(LowBarBuffer[i]-HighBarBuffer[i])/ArPer;		//Short formulation
      HighBarBuffer[i] = 0.0;   
  	   LowBarBuffer[i] = 0.0;
}

   //---- dispatch values between 2 buffers
   for(i=limit-1; i>=0; i--)
     {
      ArOsc=ArOscBuffer[i];
      if(ArOsc>Filter)
        {
         ind_buffer1[i]=ArOsc;
         ind_buffer2[i]=0.0;
         ind_buffer3[i]=0.0;
         ind_buffer4[i]=0.0;
               
        }       
      if(ArOsc<-Filter)
        {
         ind_buffer1[i]=0.0;
         ind_buffer2[i]=ArOsc;
         ind_buffer3[i]=0.0;
         ind_buffer4[i]=0.0;
        }
       if(ArOsc<=Filter && ArOsc>0)
       {
         ind_buffer1[i]=0.0;
         ind_buffer2[i]=0.0;
         ind_buffer3[i]=ArOsc;
         ind_buffer4[i]=0.0;
       }
       if(ArOsc>=-Filter && ArOsc<=0)
       {
         ind_buffer1[i]=0.0;
         ind_buffer2[i]=0.0;
         ind_buffer3[i]=0.0;
         ind_buffer4[i]=ArOsc;
       }
     }
   //---- done
   return(0);
  }