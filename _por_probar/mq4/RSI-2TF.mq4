//+------------------------------------------------------------------+
//|                                                      RSI-2TF.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//|                                                                  |
//|                   29.10.2005 Модернизация Ким Игорь В. aka KimIV |
//|                                              http://www.kimiv.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"

#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_buffers 2
#property indicator_color1 DodgerBlue
#property indicator_color2 Yellow
#property indicator_level1 70
#property indicator_level2 30

//------- Внешние параметры индикатора -------------------------------
extern int RSI_Period_0 = 14;
extern int TF_1         = 60;
extern int RSI_Period_1 = 14;
extern int NumberOfBars = 1000;  // Количество баров обсчёта (0-все)

//------- Буферы индикатора ------------------------------------------
double RSIBuffer0[];
double RSIBuffer1[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void init() {
  string short_name;

  //---- indicator line
  SetIndexStyle (0, DRAW_LINE, STYLE_SOLID, 2);
  SetIndexBuffer(0, RSIBuffer0);
  SetIndexStyle (1, DRAW_LINE, STYLE_SOLID, 2);
  SetIndexBuffer(1, RSIBuffer1);
  //---- name for DataWindow and indicator subwindow label
  short_name="RSI("+RSI_Period_0+")";
  IndicatorShortName(short_name);
  SetIndexLabel(0,short_name);
  short_name="RSI("+RSI_Period_1+")";
  SetIndexLabel(1,short_name);

  SetIndexDrawBegin(0,RSI_Period_0);
  SetIndexDrawBegin(1,RSI_Period_1);
}

//+------------------------------------------------------------------+
//| Relative Strength Index                                          |
//+------------------------------------------------------------------+
void start() {
  int LoopBegin, sh, nsb;

 	if (NumberOfBars==0) LoopBegin=Bars-1;
  else LoopBegin=NumberOfBars-1;

  for (sh=LoopBegin; sh>=0; sh--) {
    nsb=iBarShift(NULL, TF_1, Time[sh], False);
    RSIBuffer0[sh]=iRSI(NULL, 0   , RSI_Period_0, PRICE_CLOSE, sh);
    RSIBuffer1[sh]=iRSI(NULL, TF_1, RSI_Period_1, PRICE_CLOSE, nsb);
  }
}
//+------------------------------------------------------------------+

