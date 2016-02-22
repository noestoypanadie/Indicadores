//+------------------------------------------------------------------+
//| Objective: A line graph that plots total open orders drawdown or profit
//| 
//+------------------------------------------------------------------+

#property indicator_separate_window
#property indicator_buffers 1

#property indicator_color1 DarkGoldenrod
#property indicator_width1 2

double val1[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int init()
  {
   string short_name;
//---- indicator line
   IndicatorBuffers(1);
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,val1);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   ObjectsDeleteAll();
   return(0);
  }
  
//+------------------------------------------------------------------+
//| Start function                                        |
//+------------------------------------------------------------------+
int start()
  {   
   double drawdown,cnt;
   for(cnt=0;cnt<OrdersTotal();cnt++)
      {
      drawdown=OrderProfit();
      }
   
   for(int shift=Bars;shift>=0;shift--)
     {
     val1[shift]=drawdown;
     }
  
   return(0);
  }

//+------------------------------------------------------------------+