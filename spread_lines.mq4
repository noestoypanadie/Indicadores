//+--------------------------------------------------------------------+
//|                         Copyright 2015, MetaQuotes Software Corp.  |
//|                                             https://www.mql5.com   |
//| Indicator : Spread Lines                                           |                                                                  |
//| Author: file45 - https://www.mql5.com/en/users/file45/publications |
//+--------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

input color Ask_Line = MediumSeaGreen; // Ask Line Color
input color Bid_Line = Red; // Bid Line Color
input int Line_Width = 1; // Line Width : 1, 2, 3, 4, 5, 6, 7, .....
input string a = " *  *  *  *  * "; // Line Style effective only if Line Width = 1
input ENUM_LINE_STYLE Line_Style = 1; // Line Style
input string b = " *  *  *  *  * "; // N.O.T.E. -> For true chart spread only, SA must = 0
input string c = " *  *  *  *  * "; // Other broker spread  - chart spread = SA +/- value 
input int SA = 0; // SA - Spread  Adjuster
input bool CF = true; // Chart on Forground
input bool SAL = true; // Show Ask Line

int OnInit() 
{
   
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{ 
   ChartForegroundSet(CF,0);
   ChartAskSet(SAL,0);
  
   ObjectCreate(0, "ALine", OBJ_HLINE , 0,Time[0], 0);
   ObjectSet("ALine", OBJPROP_STYLE, Line_Style);
   ObjectSet("ALine", OBJPROP_COLOR, Ask_Line);
   ObjectSet("ALine", OBJPROP_WIDTH, Line_Width);
   ObjectSet("ALine", OBJPROP_PRICE1, Ask + SA*Point);
    
   ObjectCreate(0, "BLine", OBJ_HLINE , 0,Time[0], 0);
   ObjectSet("BLine", OBJPROP_STYLE, Line_Style);
   ObjectSet("BLine", OBJPROP_COLOR, Bid_Line);
   ObjectSet("BLine", OBJPROP_WIDTH, Line_Width);
   ObjectSet("BLine", OBJPROP_PRICE1, Bid);
  
   return(rates_total);
}

int deinit()
{
   ObjectDelete("ALine");
   ObjectDelete("BLine");
   
   return(0);
}  

bool ChartForegroundSet(const bool value,const long chart_ID=0)
{
//--- reset the error value
   ResetLastError();
//--- set property value
   if(!ChartSetInteger(chart_ID,CHART_FOREGROUND,0,value))
   {
      //--- display the error message in Experts journal
      Print(__FUNCTION__+", Error Code = ",GetLastError());
      return(false);
   }
//--- successful execution
   return(true);
  }
  
 bool ChartAskSet(const bool value,const long chart_ID=0)
{
//--- reset the error value
   ResetLastError();
//--- set property value
   if(!ChartSetInteger(chart_ID,CHART_SHOW_ASK_LINE,0,value))
   {
      //--- display the error message in Experts journal
      Print(__FUNCTION__+", Error Code = ",GetLastError());
      return(false);
   }
//--- successful execution
   return(true);
} 