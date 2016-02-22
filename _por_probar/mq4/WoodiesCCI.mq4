//+------------------------------------------------------------------+
//|                                                   WoodiesCCI.mq4 |
//|                                                             Rosh |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "created by Luis Damiani; converted by Rosh"
#property link      "http://www.metaquotes.net"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Red
#property indicator_color2 White
#property indicator_color3 DarkGray
//---- input parameters
extern int       A_period=14;
extern int       B_period=6;
extern int       num_bars=550;
// parameters
int shift=0;
bool initDone=true; // было init
int bar=0;
int prevbars=0;
int startpar=0;  // было start
int cs=0;
int prevcs=0;
string commodt="nonono";
int frame=0;
int bars=0;

//---- buffers
double FastWoodieCCI[];
double SlowWoodieCCI[];
double HistoWoodieCCI[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,FastWoodieCCI);
   SetIndexStyle(1,DRAW_LINE,1,2);
   SetIndexBuffer(1,SlowWoodieCCI);
   SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexBuffer(2,HistoWoodieCCI);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//---- TODO: add your code here
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    counted_bars=IndicatorCounted();
//---- TODO: add your code here
cs= A_period+B_period+num_bars; //checksum used to see if parameters have been changed
if ((cs==prevcs)&&(commodt==Symbol())&&(frame==(Time[4]-Time[5]))&&((Bars-prevbars)<2)) startpar=Bars-prevbars; else startpar=-1;  //params haven't changed only need to calculate new bar
commodt=Symbol();
frame=Time[4]-Time[5];
prevbars = Bars;
prevcs = cs;
if (startpar==1 | startpar==0)  bar=startpar; else initDone = true;

if (initDone)
   {
   FastWoodieCCI[num_bars-1]=0;
   SlowWoodieCCI[num_bars-1]=0;
   HistoWoodieCCI[num_bars-1]=0;  
   //SetIndexValue(num_bars-1, 0);
   //SetIndexValue2(num_bars-1, 0);
   bar=num_bars-2;
   initDone=false;
   };

//SetLoopCount(0);
for (shift = bar;shift>=0;shift--)
   {
   FastWoodieCCI[shift]=iCCI(NULL,0,B_period,PRICE_TYPICAL,shift);
   SlowWoodieCCI[shift]=iCCI(NULL,0,A_period,PRICE_TYPICAL,shift);
   HistoWoodieCCI[shift]=iCCI(NULL,0,A_period,PRICE_TYPICAL,shift);  
   //SetIndexValue(shift,iCCIEx(A_period,PRICE_TYPICAL,shift));
   //SetIndexValue2(shift,iCCIEx(B_period,PRICE_TYPICAL,shift));
   };

//----
   return(0);
  }
//+------------------------------------------------------------------+