//+------------------------------------------------------------------+
//|                                                        Juice.mq4 |
//|                                                          Perky_z |
//|                              http://fxovereasy.atspace.com/index |
//+------------------------------------------------------------------+
#property  copyright "perky"
#property  link      "http://fxovereasy.atspace.com/index"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 2
#property  indicator_color1  LimeGreen
#property  indicator_color2  FireBrick
//---- indicator parameters
extern int Periyod=7;
extern double Level=0.0004;

//---- indicator buffers
double OsMAUpBuffer[];
double OsMADownBuffer[];
double OsMABuffer[];
double MACDBuffer[];
double SignalBuffer[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- 2 additional buffers are used for counting.
   IndicatorBuffers(5);
//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,1);
   SetIndexDrawBegin(0,Level);
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+2);
//---- 3 indicator buffers mapping
   if(!SetIndexBuffer(0,OsMAUpBuffer) &&
      !SetIndexBuffer(1,OsMADownBuffer) &&
      !SetIndexBuffer(2,OsMABuffer) &&
      !SetIndexBuffer(3,MACDBuffer) &&
      !SetIndexBuffer(4,SignalBuffer))
      Print("cannot set indicator buffers!");
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("Juice("+Periyod+","+Level+")");
//---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Moving Average of Oscillator                                     |
//+------------------------------------------------------------------+
int start()
{
//if ( Period != 15)  Alert ("Juice Is Recommended for 15 Min Chart only!!");

 
  if (Symbol()=="USDJPY") Level=0.040;
  if (Symbol()=="EURJPY") Level=0.040;
  if (Symbol()=="GBPJPY") Level=0.040;
   int limit,i;
   int counted_bars=IndicatorCounted();
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
if (Level== 0.0004 && Period()==5 ) Level=0.0002;

 
//---- main loop
   for(i=0; i<limit; i++){
      OsMABuffer[i]=iStdDev  (NULL,0,Periyod,MODE_EMA,0,PRICE_CLOSE,i)-(Level);
      
      if(OsMABuffer[i]>0){
         OsMAUpBuffer[i]=OsMABuffer[i];
         OsMADownBuffer[i]=0;
      }else if(OsMABuffer[i]<0){
         OsMADownBuffer[i]=OsMABuffer[i];
         OsMAUpBuffer[i]=0;
      }else{
         OsMAUpBuffer[i]=0;
         OsMADownBuffer[i]=0;
      }
   }
//---- done
   return(0);
  }
//+------------------------------------------------------------------+

