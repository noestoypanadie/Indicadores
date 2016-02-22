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
extern bool DoAlerts = false;
extern int AlertFromPips = 5;
extern int Periyod=7;
extern double Level=5;
extern bool JuiceLevelsVisible = true;
extern int JuiceStartPips = 5;
extern int JuiceStepPips = 5;
extern int JuiceLevelsNumber = 4;
extern color JuiceLevelColor = Silver;

//---- indicator buffers
double OsMAUpBuffer[];
double OsMADownBuffer[];
double OsMAValue;
double currentJuiceLevel;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- 2 additional buffers are used for counting.
   IndicatorBuffers(2);
//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,1);
   SetIndexDrawBegin(0,Level);
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+2);
//---- 2 indicator buffers mapping
   if(!SetIndexBuffer(0,OsMAUpBuffer) &&
      !SetIndexBuffer(1,OsMADownBuffer))
      Print("cannot set indicator buffers!");
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("Juice("+Periyod+","+Level+")");

//---- initialization done
   return(0);
  }

int SetLevelLines()
{
   string levelLabel;
   if(JuiceLevelsVisible)
   {
      SetLevelStyle(STYLE_DASH,1,JuiceLevelColor);
      for(int i=1; i<= JuiceLevelsNumber; i++)
      {
         
         currentJuiceLevel = (JuiceStartPips + (i-1)*JuiceStepPips)*Point;
         SetLevelValue(i,currentJuiceLevel);
         levelLabel = "Level "+i+": "+currentJuiceLevel;
         SetIndexLabel(i,levelLabel);
      }
   }else
   {
      for(i=1; i<= JuiceLevelsNumber; i++)
      {
         
         SetLevelValue(i,0.0);
         
      }
   }
}

//+------------------------------------------------------------------+
//| Moving Average of Oscillator                                     |
//+------------------------------------------------------------------+
int start()
{
//if ( Period != 15)  Alert ("Juice Is Recommended for 15 Min Chart only!!");
   int limit,i;
   int counted_bars=IndicatorCounted();
   double Juice;
   bool TurnOnAlert = true;
   
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
   Level = Level*Point;
   
  if (Period()==5 ) Level=Level/2;
  
  SetLevelLines();
 
//---- main loop
   for(i=0; i<limit; i++)
   {
      Juice=iStdDev  (NULL,0,Periyod,MODE_EMA,0,PRICE_CLOSE,i)-Level;
      if(Juice>0){
         OsMAUpBuffer[i]=Juice;
         OsMADownBuffer[i]=0;
      }else if(Juice<0){
         OsMADownBuffer[i]=Juice;
         OsMAUpBuffer[i]=0;
      }else{
         OsMAUpBuffer[i]=0;
         OsMADownBuffer[i]=0;
      }
   }
   
   if (DoAlerts)
   {
      if (Juice > AlertFromPips*Point && Period() == 5)
      {
         if (TurnOnAlert)
         {
            Alert("Juice above ",AlertFromPips*Point," for ", Symbol());
            PlaySound("Tick.wav");
            TurnOnAlert = false;
         }
      }
      else
      {
         TurnOnAlert = true;
      }
   }
      
//---- done
   return(0);
  }
//+------------------------------------------------------------------+

