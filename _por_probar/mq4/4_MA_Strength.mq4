//+----------------------------------------------------------------------+
//|                                                    4_MA_Strength.mq4 |
//|        Copyright © 2006 , kurkafund on 11/05/2006 by David Honeywell |
//|                      kurkafund@yahoo.com , transport.david@gmail.com |
//+----------------------------------------------------------------------+

#property copyright "Copyright © 2006, Custom Built For kurkafund on 11/05/2006 by David Honeywell"
#property link      "kurkafund@yahoo.com , transport.david@gmail.com"

//+--------------------------------------------------------------------------------------------------------------------+
//|                            Custom Built For kurkafund on 11/05/2006 by David Honeywell , transport.david@gmail.com |
//+--------------------------------------------------------------------------------------------------------------------+

#property indicator_separate_window

#property indicator_buffers 2

#property indicator_color1 Lime
#property indicator_color2 MediumVioletRed

#property indicator_level1 0.0000

//---- input parameters

extern int ChartTimePeriod = 60;

extern int Ma1_Period = 8; // Averaging period for calculation.
extern int Ma1_Shift  = 0; // MA shift. Indicators line offset relate to the chart by timeframe.
extern int Ma1_Method = 1; // MA method. It can be any of the Moving Average method enumeration value. 0=sma, 1=ema, 2=smma, 3=lwma
extern int Ma1_Price  = 0; // Applied price. It can be any of Applied price enumeration values. 0=close, 1=open, 2=high, 3=low, 4=median, 5=typical, 6=weightedclose

extern int Ma2_Period = 24; // Averaging period for calculation.
extern int Ma2_Shift  = 0; // MA shift. Indicators line offset relate to the chart by timeframe.
extern int Ma2_Method = 1; // MA method. It can be any of the Moving Average method enumeration value. 0=sma, 1=ema, 2=smma, 3=lwma
extern int Ma2_Price  = 0; // Applied price. It can be any of Applied price enumeration values. 0=close, 1=open, 2=high, 3=low, 4=median, 5=typical, 6=weightedclose

extern int Ma3_Period = 72; // Averaging period for calculation.
extern int Ma3_Shift  = 0; // MA shift. Indicators line offset relate to the chart by timeframe.
extern int Ma3_Method = 1; // MA method. It can be any of the Moving Average method enumeration value. 0=sma, 1=ema, 2=smma, 3=lwma
extern int Ma3_Price  = 0; // Applied price. It can be any of Applied price enumeration values. 0=close, 1=open, 2=high, 3=low, 4=median, 5=typical, 6=weightedclose

extern int Ma4_Period = 216; // Averaging period for calculation.
extern int Ma4_Shift  = 0; // MA shift. Indicators line offset relate to the chart by timeframe.
extern int Ma4_Method = 1; // MA method. It can be any of the Moving Average method enumeration value. 0=sma, 1=ema, 2=smma, 3=lwma
extern int Ma4_Price  = 0; // Applied price. It can be any of Applied price enumeration values. 0=close, 1=open, 2=high, 3=low, 4=median, 5=typical, 6=weightedclose

extern int ShowDays   = 22;

double prevtime;

//---- buffers

double TopStrength[];
double BottomStrength[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int init()
  {
//---- indicators
   
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexEmptyValue(0,0.0);
   SetIndexLabel(0,"iCustom mode 0 TopStrength");
   SetIndexBuffer(0,TopStrength);
   
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexEmptyValue(1,0.0);
   SetIndexLabel(1,"iCustom mode 1 BottomStrength");
   SetIndexBuffer(1,BottomStrength);
   
   IndicatorShortName("4_MA_Strength(ChartTimePeriod ( "+ChartTimePeriod+" ) MA ( "+Ma1_Period+" | "+Ma2_Period+" | "+Ma3_Period+" | "+Ma4_Period+" ) ");
   
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
   int    i;
//---- 
   
      double ShowBars = ((1440/Period())*ShowDays);
   
   for (i=ShowBars; i>=0; i--)
    {
      
      double MA1, MA2, MA3, MA4;
      double ustrength1 = 0, ustrength2 = 0, ustrength3 = 0, ustrength4 = 0, ustrength5 = 0, ustrength6 = 0;
      double dstrength1 = 0, dstrength2 = 0, dstrength3 = 0, dstrength4 = 0, dstrength5 = 0, dstrength6 = 0;
      
      double Ma1_0   = iMA(Symbol(), ChartTimePeriod, Ma1_Period, Ma1_Shift, Ma1_Method, Ma1_Price, i)*1000;
      double Ma2_0   = iMA(Symbol(), ChartTimePeriod, Ma2_Period, Ma2_Shift, Ma2_Method, Ma2_Price, i)*1000;
      double Ma3_0   = iMA(Symbol(), ChartTimePeriod, Ma3_Period, Ma3_Shift, Ma3_Method, Ma3_Price, i)*1000;
      double Ma4_0   = iMA(Symbol(), ChartTimePeriod, Ma4_Period, Ma4_Shift, Ma4_Method, Ma4_Price, i)*1000;
      
      if ( Ma1_0 > Ma2_0 ) ustrength1 =  0.25;
      if ( Ma1_0 > Ma2_0 ) dstrength1 = -0.25;
      
      if ( Ma1_0 > Ma2_0 && Ma1_0 > Ma3_0 ) ustrength2 =  0.50;
      if ( Ma1_0 < Ma2_0 && Ma1_0 < Ma3_0 ) dstrength2 = -0.50;
      
      if ( Ma1_0 > Ma2_0 && Ma1_0 > Ma3_0 && Ma1_0 > Ma4_0 ) ustrength3 =  0.75;
      if ( Ma1_0 < Ma2_0 && Ma1_0 < Ma3_0 && Ma1_0 < Ma4_0 ) dstrength3 = -0.75;
      
      if ( Ma1_0 > Ma2_0 && Ma1_0 > Ma3_0 && Ma1_0 > Ma4_0 && Ma2_0 > Ma3_0 ) ustrength4 =  1.00;
      if ( Ma1_0 < Ma2_0 && Ma1_0 < Ma3_0 && Ma1_0 < Ma4_0 && Ma2_0 < Ma3_0 ) dstrength4 = -1.00;
      
      if ( Ma1_0 > Ma2_0 && Ma1_0 > Ma3_0 && Ma1_0 > Ma4_0 && Ma2_0 > Ma3_0 && Ma2_0 > Ma4_0 ) ustrength5 =  1.25;
      if ( Ma1_0 < Ma2_0 && Ma1_0 < Ma3_0 && Ma1_0 < Ma4_0 && Ma2_0 < Ma3_0 && Ma2_0 < Ma4_0 ) dstrength5 = -1.25;
      
      if ( Ma1_0 > Ma2_0 && Ma1_0 > Ma3_0 && Ma1_0 > Ma4_0 && Ma2_0 > Ma3_0 && Ma2_0 > Ma4_0 && Ma3_0 > Ma4_0 ) ustrength6 =  1.50;
      if ( Ma1_0 < Ma2_0 && Ma1_0 < Ma3_0 && Ma1_0 < Ma4_0 && Ma2_0 < Ma3_0 && Ma2_0 < Ma4_0 && Ma3_0 > Ma4_0 ) dstrength6 = -1.50;
      
      TopStrength[i]    = ustrength1 + ustrength2 + ustrength3 + ustrength4 + ustrength5 + ustrength6;
      BottomStrength[i] = dstrength1 + dstrength2 + dstrength3 + dstrength4 + dstrength5 + dstrength6;
    
    }
    
    
//----
   return(0);
  }
//+------------------------------------------------------------------+