//+------------------------------------------------------------------+
//|                                            Hull_Style_ADX_v3.mq4 |
//+------------------------------------------------------------------+

//---- indicator settings

#property  indicator_separate_window

#property  indicator_buffers 4

#property  indicator_color1  White
#property  indicator_color2  LightSeaGreen
#property  indicator_color3  LimeGreen
#property  indicator_color4  Red

//---- indicator parameters

extern int ADX_Period           =  7;
extern int PlusDiMinusDi_Period = 14;
extern int Applied_Price        =  0; // 0 Close , 1 Open , 2 High , 3 Low , 4 Median , 5 Typical , 6 Weighted
extern int LineWidth            =  1;
extern int Ma_Of_Adx            =  8;
extern int MaOfAdx_Shift        =  0;
extern int Ma_Method            =  3; // 0 sma, 1 ema, 2 smma, 3 lwma

//---- indicator buffers

double MaBuffer[];

double adxbuffer[];

double plusdibuffer[];

double minusdibuffer[];

int    draw_begin0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int init()
 {

//---- indicator buffers mapping
  
//---- drawing settings
  
  draw_begin0 = ADX_Period+MathFloor(MathSqrt(ADX_Period));
  
  SetIndexEmptyValue(0,0.0000);
  SetIndexStyle(0,DRAW_LINE,STYLE_DOT,LineWidth);
  SetIndexBuffer(0,MaBuffer);
  SetIndexLabel(0,"ADX mode 0");
  SetIndexDrawBegin(0,draw_begin0);
  
  SetIndexEmptyValue(1,0.0000);
  SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,LineWidth);
  SetIndexBuffer(1,adxbuffer);
  SetIndexLabel(1,"ADX mode 1");
  SetIndexDrawBegin(1,draw_begin0);
  
  SetIndexEmptyValue(2,0.0000);
  SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,LineWidth);
  SetIndexBuffer(2,plusdibuffer);
  SetIndexLabel(2,"Plus-Di mode 2");
  SetIndexDrawBegin(2,draw_begin0);
  
  SetIndexEmptyValue(3,0.0000);
  SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,LineWidth);
  SetIndexBuffer(3,minusdibuffer);
  SetIndexLabel(3,"Minus-Di mode 3");
  SetIndexDrawBegin(3,draw_begin0);
  
//---- name for DataWindow and indicator subwindow label
  
  IndicatorShortName("Hull_Style_ADX_v3("+ADX_Period+")");
  
//---- initialization done
  return(0);
 }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int start()
 {
  int limit,i,shift;
  int counted_bars=IndicatorCounted();

//---- check for possible errors
  if(counted_bars<1)
   {
     for(i=1;i<=draw_begin0;i++) { MaBuffer[Bars-i]=0; adxbuffer[Bars-i]=0; plusdibuffer[Bars-i]=0; minusdibuffer[Bars-i]=0; }
   }

//---- last counted bar will be recounted
  if(counted_bars>0) counted_bars--;
  limit=Bars-counted_bars;

//-----------------------------------------------------------------------------------------------------------------
  
  for(i=0; i<limit; i++)
    { adxbuffer[i] = (iADX(Symbol(),0,MathFloor(ADX_Period/2),Applied_Price,MODE_MAIN,i)*2)
                        - iADX(Symbol(),0,ADX_Period,Applied_Price,MODE_MAIN,i); }
  for(i=0; i<limit; i++)
    { MaBuffer[i] = iMAOnArray(adxbuffer,0,Ma_Of_Adx,MaOfAdx_Shift,Ma_Method,i); }
  
//-----------------------------------------------------------------------------------------------------------------
  
  for(i=0; i<limit; i++)
    { plusdibuffer[i] = (iADX(Symbol(),0,MathFloor(PlusDiMinusDi_Period/2),Applied_Price,MODE_PLUSDI,i)*2)
                           - iADX(Symbol(),0,PlusDiMinusDi_Period,Applied_Price,MODE_PLUSDI,i); }

//-----------------------------------------------------------------------------------------------------------------
  
  for(i=0; i<limit; i++)
    { minusdibuffer[i] = (iADX(Symbol(),0,MathFloor(PlusDiMinusDi_Period/2),Applied_Price,MODE_MINUSDI,i)*2)
                            - iADX(Symbol(),0,PlusDiMinusDi_Period,Applied_Price,MODE_MINUSDI,i); }

//-----------------------------------------------------------------------------------------------------------------

//---- done
  return(0);
 }

