//+------------------------------------------------------------------+
//|                                                   WoodiesCCI.mq4 |
//|                                                             Rosh |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "created by Luis Damiani; converted by Rosh; modified by Ron"
#property link      "http://www.metaquotes.net"

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_color1 Red
#property indicator_color2 White
#property indicator_color3 White
#property indicator_color4 White
#property indicator_color5 White
#property indicator_color6 White
#property indicator_color7 White
#property indicator_color8 White

// input parameters
extern int       A_period=6;    //Fast
extern int       B_period=14;
extern int       C_period=20;
extern int       D_period=25;
extern int       E_period=30;
extern int       F_period=35;
extern int       G_period=40;
extern int       H_period=45;
extern int       I_period=50;
extern int       num_bars=550;

// parameters
int shift=0;
bool initDone=true;
int bar=0;
int prevbars=0;
int startpar=0;
int cs=0;
int prevcs=0;
string commodt="nonono";
int frame=0;
int bars=0;


//---- buffers
double FastWoodieCCI[];
double HistoWoodieCCI[];

double SlowWoodieCCI[];
double SlowWoodieCCI2[];
double SlowWoodieCCI3[];
double SlowWoodieCCI4[];
double SlowWoodieCCI5[];
double SlowWoodieCCI6[];
double SlowWoodieCCI7[];
double SlowWoodieCCI8[];
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

   SetIndexStyle(1,DRAW_LINE,1,2);
   SetIndexBuffer(1,SlowWoodieCCI2);

   SetIndexStyle(1,DRAW_LINE,1,2);
   SetIndexBuffer(1,SlowWoodieCCI3);

   SetIndexStyle(1,DRAW_LINE,1,2);
   SetIndexBuffer(1,SlowWoodieCCI4);

   SetIndexStyle(1,DRAW_LINE,1,2);
   SetIndexBuffer(1,SlowWoodieCCI5);

   SetIndexStyle(1,DRAW_LINE,1,2);
   SetIndexBuffer(1,SlowWoodieCCI6);

   SetIndexStyle(1,DRAW_LINE,1,2);
   SetIndexBuffer(1,SlowWoodieCCI7);

   SetIndexStyle(1,DRAW_LINE,1,2);
   SetIndexBuffer(1,SlowWoodieCCI8);

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

//checksum used to see if parameters have been changed
cs= A_period+B_period+num_bars; 

//params haven't changed only need to calculate new bar
if ((cs==prevcs)&&(commodt==Symbol())&&(frame==(Time[4]-Time[5]))&&((Bars-prevbars)<2)) 
   startpar=Bars-prevbars; 
else 
   startpar=-1;

commodt=Symbol();
frame=Time[4]-Time[5];
prevbars = Bars;
prevcs = cs;

if (startpar==1 | startpar==0)  
   bar=startpar; 
else 
   initDone = true;

if (initDone)
   {
   FastWoodieCCI[num_bars-1]=0;
   SlowWoodieCCI[num_bars-1]=0;
   SlowWoodieCCI2[num_bars-1]=0;
   SlowWoodieCCI3[num_bars-1]=0;
   SlowWoodieCCI4[num_bars-1]=0;
   SlowWoodieCCI5[num_bars-1]=0;
   SlowWoodieCCI6[num_bars-1]=0;
   SlowWoodieCCI7[num_bars-1]=0;
   SlowWoodieCCI8[num_bars-1]=0;
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
   SlowWoodieCCI2[shift]=iCCI(NULL,0,C_period,PRICE_TYPICAL,shift);
   SlowWoodieCCI3[shift]=iCCI(NULL,0,D_period,PRICE_TYPICAL,shift);
   SlowWoodieCCI4[shift]=iCCI(NULL,0,E_period,PRICE_TYPICAL,shift);
   SlowWoodieCCI5[shift]=iCCI(NULL,0,F_period,PRICE_TYPICAL,shift);
   SlowWoodieCCI6[shift]=iCCI(NULL,0,G_period,PRICE_TYPICAL,shift);
   SlowWoodieCCI7[shift]=iCCI(NULL,0,H_period,PRICE_TYPICAL,shift);
   SlowWoodieCCI8[shift]=iCCI(NULL,0,I_period,PRICE_TYPICAL,shift);
   HistoWoodieCCI[shift]=iCCI(NULL,0,A_period,PRICE_TYPICAL,shift);  
   //SetIndexValue(shift,iCCIEx(A_period,PRICE_TYPICAL,shift));
   //SetIndexValue2(shift,iCCIEx(B_period,PRICE_TYPICAL,shift));
   };

//----
   return(0);
  }
//+------------------------------------------------------------------+