//+------------------------------------------------------------------+
//|                                               RAVI FX Fisher.mq4 |
//|                         Copyright © 2005, Luis Guilherme Damiani |
//|                                      http://www.damianifx.com.br |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Luis Guilherme Damiani"
#property link      "http://www.damianifx.com.br"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 MediumSeaGreen
#property indicator_color2 MediumVioletRed
#property indicator_color3 MediumVioletRed
//---- input parameters
extern int       MAfast=4;
extern int       MAslow=49;
extern double trigger=0.07;
extern int       maxbars=500;

//---- buffers
double RAVIfxFishBuffer[];
double LoTrigBuff[];
double HiTrigBuff[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,RAVIfxFishBuffer);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,LoTrigBuff);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(2,HiTrigBuff);
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
      double MAValue=0;
      double IFish=0;
      //---- check for possible errors
      if(counted_bars<0) return(-1);
      int limit=Bars-counted_bars;
      if(limit>maxbars)limit=maxbars;
      if (limit>Bars-MAslow-1)limit=Bars-MAslow-1;   
      //---- 
      for (int shift = 0; shift<=limit;shift++)
      {
	     //if period >70 then {LoTrigger=-0.15;HiTrigger=0.15;}else {LoTrigger=-0.07;HiTrigger=0.07;};
	
	     MAValue = 100 * (iMA(NULL,0,MAfast,0,MODE_LWMA,PRICE_TYPICAL,shift) - iMA(NULL,0,MAslow,0,MODE_LWMA,PRICE_TYPICAL,shift))*iATR(NULL,0,MAfast,shift)
	              /iMA(NULL,0,MAslow,0,MODE_LWMA,PRICE_TYPICAL,shift)/iATR(NULL,0,MAslow,shift);
	     IFish=(MathExp(2*MAValue)-1)/(MathExp(2*MAValue)+1);
	    
	    
         RAVIfxFishBuffer[shift]=IFish;
         LoTrigBuff[shift]=-trigger;
         HiTrigBuff[shift]=trigger;
       }
   
//----
   return(0);
  }
//+------------------------------------------------------------------+