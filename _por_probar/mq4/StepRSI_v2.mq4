//+------------------------------------------------------------------+
//|                                                   StepRSI_v2.mq4 |
//+------------------------------------------------------------------+

#property indicator_separate_window
#property indicator_minimum 20
#property indicator_maximum 80
#property indicator_buffers 3
#property indicator_color1 Orange
#property indicator_color2 SkyBlue
#property indicator_color3 Magenta
//---- input parameters
extern int PeriodRSI=14;
extern int StepSizeFast=5;
extern int StepSizeSlow=15;
//extern int HighLow=0;
//---- indicator buffers
double Line1Buffer[];
double Line2Buffer[];
double Line3Buffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
  int init()
  {
   string short_name;
//---- indicator line
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1);
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1);
   SetIndexBuffer(0,Line1Buffer);
   SetIndexBuffer(1,Line2Buffer);
   SetIndexBuffer(2,Line3Buffer);
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS));
//---- name for DataWindow and indicator subwindow label
   short_name="StepRSI("+PeriodRSI+","+StepSizeFast+","+StepSizeSlow+")";
   IndicatorShortName(short_name);
   SetIndexLabel(0,"RSI");
   SetIndexLabel(1,"StepRSI fast");
   SetIndexLabel(2,"StepRSI slow");
//----
   SetIndexDrawBegin(0,1);
   SetIndexDrawBegin(1,1);
   SetIndexDrawBegin(2,1);
//----
   return(0);
  }

//+------------------------------------------------------------------+
//| StepRSI_v2                                                         |
//+------------------------------------------------------------------+
int start()
  {
   int shift,ftrend,strend;
   double fmin0,fmax0,fmin1,fmax1,smin0,smax0,smin1,smax1,RSI0;

   
   for(shift=Bars-1;shift>=0;shift--)
   {	
   RSI0=iRSI(NULL,0,PeriodRSI,PRICE_CLOSE,shift);
   
	  fmax0=RSI0+2*StepSizeFast;
	  fmin0=RSI0-2*StepSizeFast;
	  	    
	  if (RSI0>fmax1)  ftrend=1; 
	  if (RSI0<fmin1)  ftrend=-1;

	  if(ftrend>0 && fmin0<fmin1) fmin0=fmin1;
	  if(ftrend<0 && fmax0>fmax1) fmax0=fmax1;
	  
	  smax0=RSI0+2*StepSizeSlow;
	  smin0=RSI0-2*StepSizeSlow;
		
	  if (RSI0>smax1)  strend=1; 
	  if (RSI0<smin1)  strend=-1;

	  if(strend>0 && smin0<smin1) smin0=smin1;
	  if(strend<0 && smax0>smax1) smax0=smax1;
	    
	  
	  Line1Buffer[shift]=RSI0;
	  
	  if (ftrend>0) Line2Buffer[shift]=fmin0+StepSizeFast;
	  if (ftrend<0) Line2Buffer[shift]=fmax0-StepSizeFast;
	  
	  if (strend>0) Line3Buffer[shift]=smin0+StepSizeSlow;
	  if (strend<0) Line3Buffer[shift]=smax0-StepSizeSlow;
	  
	  fmin1=fmin0;
	  fmax1=fmax0;
	  smin1=smin0;
	  smax1=smax0;
	 }
	return(0);	
 }
