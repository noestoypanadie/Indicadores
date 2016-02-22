//+------------------------------------------------------------------+
//| 5 Min RSI 12-period qual INDICATOR                               |
//+------------------------------------------------------------------+
#property copyright "Ron T"
#property link      "http://www.lightpatch.com"

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 White

//---- buffers
double ExtMapBuffer1[];




//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//|------------------------------------------------------------------|

int init()
  {
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0, ExtMapBuffer1);
   
   return(0);
  }


//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   int i;
   
   for( i=0; i<Bars; i++ ) ExtMapBuffer1[i]=0;

   return(0);
  }


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

// Current position if 55/45 or over/under. Does any of 
// the previous 'qual' period ever fall below55/above45? (last11)
//
// If qual*2 periods have been above55/below45
// then lets not try to transact any more (last22)
         

int start()
  {
   double   rsi=0;        // Relative Strength Indicator
   int      pos=Bars-100; // leave room for moving average periods
      
   while(pos>=0)
     {
      rsi=iRSI(Symbol(),0,28,PRICE_CLOSE,pos);
      ExtMapBuffer1[pos]=rsi;
 	   pos--;
     }

   return(0);
  }
//+------------------------------------------------------------------+