//+------------------------------------------------------------------+
//|                                          Schaff Trend Cycle.mq4  |
//|                                       Ramdass - Conversion only  |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2004, FostarFX."
#property  link      "mail: fostar_fx@yahoo.com"

#property indicator_separate_window
#property indicator_minimum -10
#property indicator_maximum 110
#property indicator_buffers 1
#property indicator_color1 DarkOrchid

#property indicator_level2 20
#property indicator_level3 80

//---- input parameters
extern int MAShort=12;
extern int MALong=50;
extern double Cycle=10;
extern int CountBars=300;
//---- buffers
double MA[];
double ST[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//   string short_name;
//---- indicator line
   IndicatorBuffers(2);
   SetIndexBuffer(0, MA);
   SetIndexBuffer(1, ST);
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2,DarkOrchid);

//----
//----
   return(0);
  }

//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
  int shift=0;
//---- TODO: add your code here   
   for (shift=0;shift<=Bars-1;shift++)
   {
      ObjectDelete("vline1"+Time[shift]); 
      ObjectDelete("vline2"+Time[shift]); 
   }
//----
   return(0);
}
  
  
//+------------------------------------------------------------------+
//| Schaff Trend Cycle                                               |
//+------------------------------------------------------------------+
int start()
  {
   SetIndexDrawBegin(0,Bars-CountBars+MALong+MAShort+1);
   int shift,u,counted_bars=IndicatorCounted();
   double MCD, LLV, HHV, MA_Short, MA_Long, sum ,prev, smconst;
   int n, i, s;
   bool check_begin=false, check_begin_MA=false;
   double MCD_Arr[100];

   if(Bars<=MALong) return(0);
 if (CountBars==0) CountBars=Bars;
//---- initial zero
   if(counted_bars<MALong+MAShort)
   {
      for(i=1;i<=MALong;i++) MA[Bars-i]=0.0;
      for(i=1;i<=MALong;i++) ST[Bars-i]=0.0;
   }
//----
   shift=CountBars-MALong-1;
//   if(counted_bars>=MALong) shift=Bars-counted_bars-1;
   
   check_begin = false;
   check_begin_MA = false;
   n = 1;
   s = 1;
   smconst = 2 / (1 + Cycle/2);

   while(shift>=0)
     {
   MA_Short = iMA(NULL,0,MAShort,0, MODE_EMA, PRICE_TYPICAL, shift);
	MA_Long = iMA(NULL,0,MALong,0, MODE_EMA, PRICE_TYPICAL, shift);
	MCD_Arr[n] = MA_Short - MA_Long;
	MCD = MA_Short - MA_Long;

	if (n >= Cycle)  
	{	
		n = 1; check_begin = true;	} else {n = n + 1;}
	
	if (check_begin)  
	{
		for (i = 1; i<=Cycle; i++)
		{	
			if (i == 1) {LLV = MCD_Arr[i];}
			else {
				if (LLV > MCD_Arr[i]) LLV = MCD_Arr[i];
			}
			
			if (i == 1) {HHV = MCD_Arr[i];}
			else {
				if (HHV < MCD_Arr[i]) HHV = MCD_Arr[i];
			}					
		}
		ST[shift] = ((MCD - LLV)/(HHV - LLV))*100 + 0.01;
		s = s + 1;
		if (s >= (Cycle)/2)
		{ 
			s = 1;
			check_begin_MA = true;
		}
	}	else {ST[shift] = 0;}
	if (check_begin_MA) {	
		prev = MA[shift + 1];
		MA[shift] = smconst * (ST[shift] - prev) + prev;	}
      if (MA[shift]>20 && MA[shift+1]<20)
      {            
            ObjectCreate("vline1"+Time[shift], OBJ_VLINE, 0, Time[shift], 0);
            ObjectSet("vline1"+Time[shift], OBJPROP_WIDTH,3);
            ObjectSet("vline1"+Time[shift], OBJPROP_STYLE, STYLE_SOLID);
            ObjectSet("vline1"+Time[shift], OBJPROP_COLOR, LimeGreen);
         }          
         if (MA[shift+1]>80 && MA[shift]<80)
      {            
            ObjectCreate("vline2"+Time[shift], OBJ_VLINE, 0, Time[shift], 0);
            ObjectSet("vline2"+Time[shift], OBJPROP_WIDTH,3);
            ObjectSet("vline2"+Time[shift], OBJPROP_STYLE, STYLE_SOLID);
            ObjectSet("vline2"+Time[shift], OBJPROP_COLOR, Red);
            
         }            
      Comment( MA[shift],MA[shift+1]);
      shift--;
      
     }

   return(0);
  }
//+------------------------------------------------------------------+