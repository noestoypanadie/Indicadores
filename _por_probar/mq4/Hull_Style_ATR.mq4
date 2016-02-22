//+------------------------------------------------------------------+
//|                                               Hull_Style_ATR.mq4 |
//+------------------------------------------------------------------+

//---- indicator settings

#property  indicator_separate_window

#property  indicator_buffers 2

#property  indicator_color1  LightSeaGreen

#property  indicator_color2  Purple

//---- indicator parameters

extern int ATR_Period          = 14;
extern int SignalLine_Period   = 21;
extern int SignalLineShift     =  3;
extern int SignalLineMa_Method =  0; // 0 SMA , 1 EMA , 2 SMMA , 3 LWMA

//---- indicator buffers

double preatrbuffer[];
double finalatrbuffer[];

int    draw_begin0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int init()
 {

//---- indicator buffers mapping
  
//---- drawing settings
  
  draw_begin0 = ATR_Period+MathFloor(MathSqrt(ATR_Period));
  
  SetIndexEmptyValue(0,0.0000);
  SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1);
  SetIndexBuffer(0,preatrbuffer);
  SetIndexLabel(0,"Hull_ATR");
  SetIndexDrawBegin(0,draw_begin0);
  
  SetIndexEmptyValue(1,0.0000);
  SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1);
  SetIndexBuffer(1,finalatrbuffer);
  SetIndexLabel(1," ("+SignalLine_Period+") Period Ma of Hull_ATR");
  SetIndexDrawBegin(1,draw_begin0);
  
  
//---- name for DataWindow and indicator subwindow label
  
  IndicatorShortName("Hull_Style_ATR("+ATR_Period+")");
  
  
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
     for(i=1;i<=draw_begin0;i++) { finalatrbuffer[Bars-i]=0; preatrbuffer[Bars-i]=0; }
   }

//---- last counted bar will be recounted
  if(counted_bars>0) counted_bars--;
  limit=Bars-counted_bars;

//-----------------------------------------------------------------------------------------------------------------

//---- preadxbuffer
  
  for(i=0; i<limit; i++)
    { preatrbuffer[i] = (iATR(Symbol(), 0, MathFloor(ATR_Period/2), i)*2) - iATR(Symbol(), 0, ATR_Period, i); }

//---- finaladxbuffer
  
  for(i=0; i<limit; i++)
    { finalatrbuffer[i]=iMAOnArray(preatrbuffer,0,MathFloor(MathSqrt(SignalLine_Period)),SignalLineShift,SignalLineMa_Method,i); }

//-----------------------------------------------------------------------------------------------------------------

//---- done
  return(0);
 }

