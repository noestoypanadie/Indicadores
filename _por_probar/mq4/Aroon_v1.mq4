//+------------------------------------------------------------------+
//|                                         Custom Aroon_v1.mq4      |
//|                                                        rafcamara |
//|                                         Has corrected - Ramdass  |
//+------------------------------------------------------------------+
#property  copyright "rafcamara"
#property  link      "rafcamara@yahoo.com"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 2
#property  indicator_color1  DodgerBlue
#property  indicator_color2  Red

//---- indicator parameters
extern int AroonPeriod=10;
extern int CountBars=300;


//---- indicator buffers
double     AroonUpBuffer[];
double     AroonDnBuffer[];
int        HighBarBuffer;
int        LowBarBuffer;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   
   //---- 2 additional buffers are used for counting.
   IndicatorBuffers(2);
   SetIndexBuffer(0, AroonUpBuffer);
   SetIndexBuffer(1, AroonDnBuffer);

   //---- drawing settings
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1);
   IndicatorDigits(1);
   
   //---- indicator buffers mapping
   if(!SetIndexBuffer(0,AroonUpBuffer) && !SetIndexBuffer(1,AroonDnBuffer))
      Print("cannot set indicator buffers!");
   //---- name for DataWindow and indicator subwindow label
   IndicatorShortName("Aroon Up & Dn_v1("+AroonPeriod+")");
   //---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Aroon Up & Dn                                                    |
//+------------------------------------------------------------------+
int start()  
  {
   if (CountBars>=Bars) CountBars=Bars;
   SetIndexDrawBegin(0,Bars-CountBars+AroonPeriod+1);
   SetIndexDrawBegin(1,Bars-CountBars+AroonPeriod+1);
   double   AroonUp,AroonDn;
   int      ArPer,limit,i;     
   int      UpBarDif,DnBarDif;
//   int        HighBarBuffer;
//   int        LowBarBuffer;
   int      counted_bars=IndicatorCounted(); 
   ArPer=AroonPeriod;                  //Short name
   
   //---- check for possible errors
   if(counted_bars<0) return(-1);
   if(AroonPeriod<1) return(-1);      

   //---- initial zero
   if(counted_bars<1)
     {
      for(i=1;i<=ArPer;i++) AroonUpBuffer[CountBars-i]=0.0;
      for(i=1;i<=ArPer;i++) AroonDnBuffer[CountBars-i]=0.0;
     } 

   //---- last counted bar will be recounted
   //if(counted_bars>0) counted_bars--;
   limit=CountBars-AroonPeriod;

   //----Calculation---------------------------
   for( i=0; i<limit; i++)
   {
  	   HighBarBuffer = Highest(NULL,0,MODE_HIGH,ArPer,i);   //Periods from HH  	   
  	   LowBarBuffer = Lowest(NULL,0,MODE_LOW,ArPer,i);		  //Periods from LL

      UpBarDif = i-HighBarBuffer;	                       //Period substraction
      DnBarDif = i-LowBarBuffer;	                          //Period substraction
      
      AroonUpBuffer[i]=100+(100/ArPer)*(UpBarDif);            //Adjusted Aroon Up
      AroonDnBuffer[i]=100+(100/ArPer)*(DnBarDif);            //Adjusted Aroon Down
   }
   return(0);
  }
  