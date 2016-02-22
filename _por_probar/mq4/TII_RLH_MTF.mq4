//+------------------------------------------------------------------+
//|                                                  TII_RLH_MTF.mq4 |
//+------------------------------------------------------------------+

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Blue
#property indicator_level1 20
#property indicator_level2 50
#property indicator_level3 80


//---- input parameters
/*************************************************************************
PERIOD_M1   1
PERIOD_M5   5
PERIOD_M15  15
PERIOD_M30  30 
PERIOD_H1   60
PERIOD_H4   240
PERIOD_D1   1440
PERIOD_W1   10080
PERIOD_MN1  43200
You must use the numeric value of the timeframe that you want to use
when you set the TimeFrame' value with the indicator inputs.
---------------------------------------
MODE_SMA    0 Simple moving average, 
MODE_EMA    1 Exponential moving average, 
MODE_SMMA   2 Smoothed moving average, 
MODE_LWMA   3 Linear weighted moving average. 
You must use the numeric value of the MA Method that you want to use
when you set the 'ma_method' value with the indicator inputs.

**************************************************************************/
extern int TimeFrame=30;

extern int Major_Period = 24;
extern int Major_MaMode = 4; //0=sma, 1=ema, 2=smma, 3=lwma, 4=lsma
extern int Major_PriceMode = 0;//0=close, 1=open, 2=high, 3=low, 4=median(high+low)/2, 5=typical(high+low+close)/3, 6=weighted(high+low+close+close)/4
extern int Minor_Period = 12;
//extern color LevelColor = Silver;
//extern int BuyLevel = 20;
//extern int MidLevel = 50;
//extern int SellLevel = 80;

double ExtMapBuffer1[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   
//---- indicator line
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexStyle(0,DRAW_LINE);
   
//---- name for DataWindow and indicator subwindow label   
   switch(TimeFrame)
   {
      case 1 : string TimeFrameStr="Period_M1"; break;
      case 5 : TimeFrameStr="Period_M5"; break;
      case 15 : TimeFrameStr="Period_M15"; break;
      case 30 : TimeFrameStr="Period_M30"; break;
      case 60 : TimeFrameStr="Period_H1"; break;
      case 240 : TimeFrameStr="Period_H4"; break;
      case 1440 : TimeFrameStr="Period_D1"; break;
      case 10080 : TimeFrameStr="Period_W1"; break;
      case 43200 : TimeFrameStr="Period_MN1"; break;
      default : TimeFrameStr="Current Timeframe";
   } 
   //IndicatorShortName("WPR ("+WilliamsPeriod+") "+TimeFrameStr);
   IndicatorShortName(" TII_RLH_MTF  ,  Major ~ Minor ( "+Major_Period+" , "+Minor_Period+" )  , "+TimeFrameStr);  
  }
//----
   return(0);

int start()
  {
   datetime TimeArray[];
   int    i,shift,limit,y=0,counted_bars=IndicatorCounted();
    
// Plot defined timeframe on to current timeframe   
   ArrayCopySeries(TimeArray,MODE_TIME,Symbol(),TimeFrame); 
   
   limit=Bars-counted_bars;
   for(i=0,y=0;i<limit;i++)
   {
   if (Time[i]<TimeArray[y]) y++; 
   
 /***********************************************************   
   Add your main indicator loop below.  You can reference an existing
      indicator with its iName  or iCustom.
   Rule 1:  Add extern inputs above for all neccesary values   
   Rule 2:  Use 'TimeFrame' for the indicator timeframe
   Rule 3:  Use 'y' for the indicator's shift value
 **********************************************************/  
     
   ExtMapBuffer1[i]=iCustom(Symbol(),TimeFrame,"TII_RLH",Major_Period
                                                        ,Major_MaMode
                                                        ,Major_PriceMode
                                                        ,Minor_Period
                                                        //,LevelColor
                                                        //,BuyLevel
                                                        //,MidLevel
                                                        //,SellLevel
                                                        ,0,y);
   
   
   }  
          
//FIX for display
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if (TimeFrame>Period()) {
     int PerINT=TimeFrame/Period()+1;
     datetime TimeArr[]; ArrayResize(TimeArr,PerINT);
     ArrayCopySeries(TimeArr,MODE_TIME,Symbol(),Period()); 
     for(i=0;i<PerINT+1;i++) {if (TimeArr[i]>=TimeArray[0]) {
//----
 /************************************************ by Raff   
    Refresh buffers:         buffer[i] = buffer[0];
 ********************************************************/  

   ExtMapBuffer1[i]=ExtMapBuffer1[0]; 
   

//----
   } } }
//+++++++++++++++++++++++++++++++++++++++++++++++++++
//END of fix
   return(0);
  }
//+------------------------------------------------------------------+