//+------------------------------------------------------------------+
//|                                               Fractal ZigZag.mq4 |
//|                                                        ikovrigin |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ikovrigin"
#property link      ""

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Red
#property indicator_color2 Green
//---- input parameters
extern int       Level=2;
//---- buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_SECTION);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexEmptyValue(0,0.0);
   SetIndexStyle(1,DRAW_ARROW);
   SetIndexBuffer(1,ExtMapBuffer2);
   
     
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    counted_bars=IndicatorCounted();
//---- 
   

   int PU,PD,Trend=2;
   PU=0;
   PD=0;
   double FU,FD,F;
   FU=0;
   FD=0;
   int shift = Bars-Level;
   int n;
   if (shift>Level) shift=shift-Level-1;
   if (counted_bars==0)
   while (shift>Level-1)
   {
   ExtMapBuffer1[shift]=0;
   F=Low[shift];
   for (n=1; n<=Level; n++)
   {
     if (Low[shift+n]<Low[shift] || Low[shift-n]<Low[shift]) F=0;
   }
    if (F>0)
    {
      if (FD!=0)
      switch (Trend)
      {
        case 1:
           if (F<FD) 
           {
              ExtMapBuffer1[PU]=FU;
              Trend=2;
           }
           break;
        case 2:
           if (F>FD) 
           {
              ExtMapBuffer1[PD]=FD;
              Trend=1;
              if (PU>=PD)
              {
                FU=0;
                PU=0;
              }
           }
           break;
      }
      FD=F;
      PD=shift;
      ExtMapBuffer2[PD]=FD;
    }
    
    F=High[shift];
    for (n=1; n<=Level; n++)
    {
     if (High[shift+n]>High[shift] || High[shift-n]>High[shift]) F=0;    
    }
    if (F>0)
    {
      if (FU!=0) 
      switch (Trend)
      {
        case 1:
           if (F<FU )
           {
              ExtMapBuffer1[PU]=FU;
              Trend=2;
              if (PD>=PU)
              {
                FD=0;
                PD=0;
              }
           }
           break;
        case 2:
           if (F>FU)
           {
              ExtMapBuffer1[PD]=FD;
              Trend=1;
           }
           break;
      }
      FU=F;
      PU=shift;
      ExtMapBuffer2[PU]=FU;
    }
	shift--;
   }
   if (Trend==1) ExtMapBuffer1[PU]=FU; else ExtMapBuffer1[PD]=FD;
//----
   return(0);
  }
//+------------------------------------------------------------------+