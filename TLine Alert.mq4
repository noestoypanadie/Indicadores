//+------------------------------------------------------------------+
//|                                                  HLine Alert.mq4 |
//+------------------------------------------------------------------+
#property copyright "raff1410@o2.pl"

#property indicator_chart_window
extern string TLineName="MyLine2";
extern color LineColor=Red; 
extern int LineStyle=STYLE_SOLID;
extern int AlertPipRange=5;
extern string AlertWav="alert.wav";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
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
      ObjectCreate(TLineName, OBJ_TREND, 0, Time[25], Bid, Time[0], Ask);
      ObjectSet(TLineName, OBJPROP_STYLE, LineStyle);
      ObjectSet(TLineName, OBJPROP_COLOR, LineColor);

      double val=ObjectGetValueByShift(TLineName, 0);
      if (Bid-AlertPipRange*Point <= val && Bid+AlertPipRange*Point >= val) PlaySound(AlertWav);

//----
//----
   return(0);
  }
//+------------------------------------------------------------------+