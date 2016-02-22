//+------------------------------------------------------------------+
//|                                             CorrelationBurst.mq4 |
//|                    Copyright © 2006, David W Honeywell 8/21/2006 |
//|             DavidHoneywell800@msn.com  transport.david@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, David W Honeywell 8/21/2006"
#property link      "DavidHoneywell800@msn.com  transport.david@gmail.com"

#property indicator_separate_window
#property indicator_level1 0.0000
#property indicator_buffers 4
#property indicator_color1 Red
#property indicator_color2 White
#property indicator_color3 DodgerBlue
#property indicator_color4 Aqua

extern int periods = 17;

double Pound[];
double Euro[];
double Swisse[];
double Yen[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators

   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,Pound);
   SetIndexLabel(0,"Val_0_Pound");
   
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,Euro);
   SetIndexLabel(1,"Val_1_Euro");
   
   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(2,Swisse);
   SetIndexLabel(2,"Val_2_Swisse");
   
   SetIndexStyle(3,DRAW_LINE);
   SetIndexBuffer(3,Yen);
   SetIndexLabel(3,"Val_3_Yen");

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
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
   int    i;

//---- 

   for (i=Bars-50; i>=0; i--)
      {
        
        double gbp = (iMA("GBPUSD",0,periods,0,MODE_LWMA,PRICE_WEIGHTED,i)-iMA("GBPUSD",0,periods,0,MODE_LWMA,PRICE_WEIGHTED,i+1));
        
        double eur = (iMA("EURUSD",0,periods,0,MODE_LWMA,PRICE_WEIGHTED,i)-iMA("EURUSD",0,periods,0,MODE_LWMA,PRICE_WEIGHTED,i+1));
        
        double chf = (iMA("USDCHF",0,periods,0,MODE_LWMA,PRICE_WEIGHTED,i)-iMA("USDCHF",0,periods,0,MODE_LWMA,PRICE_WEIGHTED,i+1));
        
        double jpy = ((iMA("USDJPY",0,periods,0,MODE_LWMA,PRICE_WEIGHTED,i)-iMA("USDJPY",0,periods,0,MODE_LWMA,PRICE_WEIGHTED,i+1))*2);
        
        Pound[i] = gbp*1000;
        
        Euro[i] = eur*1000;
        
        Swisse[i] = chf*1000;
        
        Yen[i] = jpy*10;
        
      }
   
//----
   return(0);
  }
//+------------------------------------------------------------------+