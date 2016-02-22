//+------------------------------------------------------------------+
//|                                   CS-MAofVolume-w-Voluometer.mq4 |
//|                                  Copyright © 2006, Cubesteak and |
//|                                                others with their |
//|                                          respective code pieces. |
//|                                                                  |
//|   This indicator provides various types                          |
//|   of moving averages of volume.  There are two special features  |
//|   that are unique to this CS Volume indicator.                   |
//|
//|   1. There is a configurable auto calculating volume level set   |
//|      that provides a horizontal filter for if the volume is      |
//|      high or low based upon your configured timeframe and % lev. |
//|                                                                  |
//|   2. There is also a neat feature that I've dubbed a Voluometer. |
//|      This is basically a way to tell if the volume of the        |
//|      current bar is faster, slower or on pace with the volume of |
//|      the previous. The idea was introduced to me by my friend    |
//|      Ben of the MT_E_and_I Yahoo group, so many thanks to him.   |
//|                                                                  |
//| www.cubesteak.net                                                |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Cubesteak, et al"
#property link      "http://www.cubesteak.net/"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Red
#property indicator_color2 Green
#property indicator_color3 White

// User input
extern string IndiOptions = "****** Indicator Options ******";
extern int MA_Period=7;
extern int MA_Shift=0;
extern string MAMethods0 = "*** 0 = SMA, 1 = EMA ***";
extern string MAMethods2 = "*** 2 = SMMA, 3 = LWMA ***";
extern string MAMethods4 = "*** 4 = JMA ***";
extern int MA_Method=1;
extern string JMAOptions = "****** JMA Options *******";
extern int JMAPhase = 5;
extern string FL = "****** Filter Level ******";
extern bool   ShowFilterLevel = true;
extern int    LevelAvgDays = 90;        // Set to number of days back to calculate the level on
                                         // setting to -1 uses "Bars"
extern double LevelPercentage = 60.0;    // sets the indicator level to a % of the MA of the volume average buffer
extern int    LevelMAMethod = 1;         // same as above.                                                    

extern string VoluometerOptions = "****** Voluometer Options ******";
extern string VoluometerMethodDescription1 = "** 1 = Single Bar Compare***";
extern string VoluometerMethodDescription2 = "** 2 = MA compare ***";
extern int VoluometerMethod = 1;  // Set to 1 for simple volume of last bar.
                                  // Set to 2 for the MA of Volume with shift of 1.
extern int VoluometerPointSize = 10;   // size of Voluometer notification.

// Buffers
double VolBuffer1[];  // value down
double VolBuffer2[];  // value up
double VolBuffer3[];  // moving average

//----
int ExtCountedBars=0;
int lastcolor=0;
string WindowName;
datetime VoluometerBeginning;
string MethodName = "";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   int    draw_begin;
   string short_name;


   // indicator buffers mapping, drawing settings and Shift
   
   // Histogram downArrow Red
   SetIndexBuffer(0,VolBuffer1);
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexShift(0,MA_Shift);
   SetIndexLabel(0,"Volume Decreasing");

   // Histogram upArrow Green
   SetIndexBuffer(1,VolBuffer2); 
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexShift(1,MA_Shift);
   SetIndexLabel(1,"Volume Increasing");

   // Moving average line white
   SetIndexBuffer(2,VolBuffer3);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexShift(2,MA_Shift);


   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS));

   if(MA_Period<2) MA_Period=2;
   draw_begin=MA_Period-1;

   switch(MA_Method)
     {
      case 1  : short_name="EMA of Volume (Period:" ;  draw_begin=0; break;
      case 2  : short_name="SMMA of Volume (Period:";                break;
      case 3  : short_name="LWMA of Volume (Period:";                break;
      case 4  : short_name="JMA of Volume (Period:";                break;      
      default : short_name="SMA of Volume (Period:" ;  MA_Method=0;
     }
   switch(MA_Method)
     {
      case 1  : MethodName="EMA "; break;
      case 2  : MethodName="SMMA "; break;
      case 3  : MethodName="LWMA "; break;
      case 4  : MethodName="JMA ";  break;      
      default : MethodName="SMA "; break;
     }

   IndicatorShortName(short_name+MA_Period+")");
   WindowName = short_name+MA_Period+")";

   SetIndexDrawBegin(0,draw_begin);
   SetIndexLabel(2,short_name);

   SetLevelValue(0,0);
   SetLevelStyle(0,0,CLR_NONE);
   ObjectDelete("MAofVolLev");


   return(0);
  }


//+------------------------------------------------------------------+
//| Main                                                             |
//+------------------------------------------------------------------+
int start()
  {
  
   if(Bars<=MA_Period) return(0);
   ExtCountedBars=IndicatorCounted();
   int limit=Bars-ExtCountedBars-1; 
   if (limit==Bars-1){int reset=-1;int set=JJMASeries(1,0,0,0,0,0,0,0,reset);if((reset!=0)||(set!=0))return(-1);}


// check for possible errors
   if (ExtCountedBars<0) return(-1);

// last counted bar will be recounted
   if (ExtCountedBars>0) ExtCountedBars--;

   switch(MA_Method)
     {
      case 0 : sma();  break;
      case 1 : ema();  break;
      case 2 : smma(); break;
      case 3 : lwma(); break;
      case 4 : {
                  // This can't be done in a function call efficiently because of the JMA's
                  // nature of needing several iterations prior to accuracy.  If a function was
                  // used, it would need to recalc the entire series each tick, rather than just
                  // adding to the already computed series.
                  //
                  for(int x=limit;x>=0;x--)
                  {
                  double Series = Volume[x];
                  reset=1;VolBuffer3[x]=JJMASeries(0,0,Bars-1,limit,JMAPhase,MA_Period,Series,x,reset);if(reset!=0)return(-1);
                  Vcolor(x);
                  if (ShowFilterLevel) VolumeFilterLevel();
                  }
               }      
     }
   Voluometer();
   return(0);
  }



//+------------------------------------------------------------------+
//| void Voluometer()                                                |
//+------------------------------------------------------------------+

void Voluometer()
{
   double  Voluometer=0;
   double VolumeBenchmark;
   VoluometerBeginning = Time[0];
   if (VoluometerMethod == 1) VolumeBenchmark = Volume[1];
   else if (VoluometerMethod > 1) VolumeBenchmark = VolBuffer3[1];
   else if (VoluometerMethod < 1) { VolumeBenchmark = Volume[1]; Alert ("Wrong Configuration of Voluometer Method, defaulting to 1 bar.");}
   double VolumeBenchmarkInterval = MathRound(VolumeBenchmark / 10);
   int GrossSeconds = Period()*60;
   int IntervalSeconds = GrossSeconds / 10;
   
   int ElapsedSeconds = CurTime() - VoluometerBeginning;

   int CurrentInterval = ElapsedSeconds / IntervalSeconds;
   
   if (CurrentInterval == 0) Voluometer = 0;
   else if (CurrentInterval > 0)
   {
      Voluometer = (Volume[0]/(VolumeBenchmarkInterval*CurrentInterval));
   }
   
   if (VoluometerMethod == 1) string VolMethod = "One Bar ";
   else if (VoluometerMethod > 1)
   {
      VolMethod = MethodName;
   }

   // Voluometer Label
   ObjectCreate("Voluometer", OBJ_LABEL, WindowFind(WindowName), 0, 0);
   ObjectSetText("Voluometer",VolMethod+"Voluometer:",VoluometerPointSize, "Arial Bold", Bisque);
   ObjectSet("Voluometer", OBJPROP_CORNER, 0);
   ObjectSet("Voluometer", OBJPROP_XDISTANCE, 5);
   ObjectSet("Voluometer", OBJPROP_YDISTANCE, 17);
   
   // Voluometer Reading
   color VoluometerColor = Tan;
   string VoluometerReading = "No Reading";
   if (Voluometer > 1.1)
   {
      VoluometerColor = Yellow;
      VoluometerReading = "FAST";
   }
   else if (Voluometer  < (0.9) && (Voluometer != 0))
   {
      VoluometerColor = Tomato;
      VoluometerReading = "SLOW";
   }
   else if ((Voluometer < 1.1) && Voluometer > (0.9))
   {
      VoluometerColor = DarkOrange;
      VoluometerReading = "On Par";
   }
   else if (Voluometer == 0)
   {
      VoluometerColor = Tan;
      VoluometerReading = "No Reading";
   }
   ObjectCreate("VoluometerReading", OBJ_LABEL, WindowFind(WindowName), 0, 0);
   ObjectSetText("VoluometerReading","Speed:"+VoluometerReading+" Ratio:"+Voluometer,VoluometerPointSize, "Arial Bold", VoluometerColor);
   ObjectSet("VoluometerReading", OBJPROP_CORNER, 0);
   ObjectSet("VoluometerReading", OBJPROP_XDISTANCE, 5);
   ObjectSet("VoluometerReading", OBJPROP_YDISTANCE, 34);
   
}

//+------------------------------------------------------------------+
//| VolumeFilterLevel()                                              |
//+------------------------------------------------------------------+
void VolumeFilterLevel()
{
   int LevelMAPeriod;

   if (LevelAvgDays == (-1)) LevelMAPeriod = Bars;
   else
   {
      switch(Period())
      {
         case 1:        LevelMAPeriod = LevelAvgDays*(1440); break;
         case 5:        LevelMAPeriod = LevelAvgDays*(1440/5); break;
         case 15:       LevelMAPeriod = LevelAvgDays*(1440/15); break;
         case 30:       LevelMAPeriod = LevelAvgDays*(1440/30); break;
         case 60:       LevelMAPeriod = LevelAvgDays*(1440/60); break;
         case 240:      LevelMAPeriod = LevelAvgDays*(1440/240); break;
         case 1440:     LevelMAPeriod = LevelAvgDays; break;
         default :      LevelMAPeriod = Bars;
      }
   }
   double MyBuffer[];
   int BufSize = ArraySize(VolBuffer3);
   ArrayResize(MyBuffer,BufSize);
   ArrayCopy(MyBuffer,VolBuffer3);
   SetLevelValue(0,0);
   SetLevelStyle(0,0,CLR_NONE);
   ObjectDelete("MAofVolLev");
   double LevValue = 0;
   LevValue = MathRound( (iMAOnArray(MyBuffer,0,LevelMAPeriod,0,LevelMAMethod,0) * (LevelPercentage/100)) );              
   SetLevelValue(0,LevValue);
   SetLevelStyle(2,1,Yellow);
   int IntLevelValue = LevValue;
   ObjectCreate("MAofVolLev", OBJ_LABEL, WindowFind(WindowName), 0, 0);
   ObjectSetText("MAofVolLev","Volume Filter Level:"+IntLevelValue,10, "Arial", Yellow);
   ObjectSet("MAofVolLev", OBJPROP_CORNER, 1);
   ObjectSet("MAofVolLev", OBJPROP_XDISTANCE, 5);
   ObjectSet("MAofVolLev", OBJPROP_YDISTANCE, 5);
}

  
//+------------------------------------------------------------------+
//| Simple Moving Average                                            |
//+------------------------------------------------------------------+
void sma()
  {
   double sum=0;
   int    i,pos=Bars-ExtCountedBars-1;

   // initial accumulation
   if(pos<MA_Period) pos=MA_Period;
   for(i=1;i<MA_Period;i++,pos--)
      sum+=Volume[pos];

   while(pos>=0)
     {
      sum+=Volume[pos];
      VolBuffer3[pos]=sum/MA_Period;
   sum-=Volume[pos+MA_Period-1];
   Vcolor(pos);
    pos--;
     }

   // zero initial bars
   if(ExtCountedBars<1)
      for(i=1;i<MA_Period;i++) VolBuffer1[Bars-i]=0;

   if (ShowFilterLevel) VolumeFilterLevel();

  }



//+------------------------------------------------------------------+
//| Exponential Moving Average                                       |
//+------------------------------------------------------------------+
void ema()
  {
   double pr=2.0/(MA_Period+1);
   int    pos=Bars-2;

   if(ExtCountedBars>2) pos=Bars-ExtCountedBars-1;

   while(pos>=0)
     {
      if(pos==Bars-2) VolBuffer3[pos+1]=Volume[pos+1];
      VolBuffer3[pos]=Volume[pos]*pr+VolBuffer3[pos+1]*(1-pr);
      Vcolor(pos);
    pos--;
     }

   if (ShowFilterLevel) VolumeFilterLevel();

  }



//+------------------------------------------------------------------+
//| Smoothed Moving Average                                          |
//+------------------------------------------------------------------+
void smma()
  {
   double sum=0;
   int    i,k,pos=Bars-ExtCountedBars+1;

   pos=Bars-MA_Period;
   if(pos>Bars-ExtCountedBars) pos=Bars-ExtCountedBars;
   while(pos>=0)
     {
      if(pos==Bars-MA_Period)
        {
         // initial accumulation
         for(i=0,k=pos;i<MA_Period;i++,k++)
           {
            sum+=Volume[k];
            // zero initial bars
            VolBuffer3[k]=0;
           }
        }
      else sum=VolBuffer3[pos+1]*(MA_Period-1)+Volume[pos];
      VolBuffer3[pos]=sum/MA_Period;
    pos--;
     }
  if (ShowFilterLevel) VolumeFilterLevel();

  }



//+------------------------------------------------------------------+
//| Linear Weighted Moving Average                                   |
//+------------------------------------------------------------------+
void lwma()
  {
   double sum=0.0,lsum=0.0;
   double price;
   int    i,weight=0,pos=Bars-ExtCountedBars-1;
//---- initial accumulation
   if(pos<MA_Period) pos=MA_Period;
   for(i=1;i<=MA_Period;i++,pos--)
     {
      price=Volume[pos];
      sum+=price*i;
      lsum+=price;
      weight+=i;
     }
//---- main calculation loop
   pos++;
   i=pos+MA_Period;
   while(pos>=0)
     {
      VolBuffer3[pos]=sum/weight;
      if(pos==0) break;
      pos--;
      i--;
      price=Volume[pos];
      sum=sum-lsum+price*MA_Period;
      lsum-=Volume[i];
      lsum+=price;
     }
//---- zero initial bars
   if(ExtCountedBars<1)
      for(i=1;i<MA_Period;i++) VolBuffer3[Bars-i]=0;

  if (ShowFilterLevel) VolumeFilterLevel();
  }



//+------------------------------------------------------------------+
//| Color depends on gain or loss and previous volume                |
//+------------------------------------------------------------------+
// 1 - histo down red
// 2 - histo up green
// 3 - line white

void Vcolor(int p)
  {
 
   if (Volume[p+1]>Volume[p])
     {
      VolBuffer1[p]=Volume[p];
      VolBuffer2[p]=0;
      lastcolor=Red;
     }

   if (Volume[p+1]<Volume[p])
     {
      VolBuffer1[p]=0;
      VolBuffer2[p]=Volume[p];
      lastcolor=Green;
     }        

   if (Volume[p+1]==Volume[p])
     {
      if ( lastcolor==Red )
        {
         VolBuffer1[p]=Volume[p];
         VolBuffer2[p]=0;
        }
      if ( lastcolor==Green )
        {
         VolBuffer1[p]=0;
         VolBuffer2[p]=Volume[p];
        }
     }
  }

//+------------------------------------------------------------------+
//
//

//

//

//

//+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
//|                                                   JJMASeries.mqh |
//|                 JMA code: Copyright © 2005, Weld, Jurik Research |
//|                                          http://weld.torguem.net |
//|          MQL4+JJMASeries: Copyright © 2005,     Nikolay Kositsin |
//|                                   Khabarovsk, violet@mail.kht.ru |
//+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
#property copyright "Nikolay Kositsin"
#property link "violet@mail.kht.ru"
  /*
  SSSSSS <<< Функция JJMASeries >>> SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS

  ----------------------------- Назначение -------------------------------

  Функция JJMASeries предназначена для использования алгоритма JMA при написании любых индикаторов теханализа, для замены расчёта
  классического усреднения на этот алгоритм. Данная версия файла не поддерживает экспертов.
  Файл следует положить в папку (директорию): MetaTrader\experts\include\

  -------------------------- input parameters ----------------------------

  nJMAnumber - порядковый номер обращения к функции JJMASeries. (0, 1, 2, 3 и.т.д....)
  nJMAdinJ - параметр, позволяющий изменять параметры nJMALength и nJMAPhase на каждом баре. 0 - запрет изменения параметров, любое другое значение - разрешение.
  nJMAMaxBar - Максимальное значение, которое может принимать номер расчитываемого бара(bar). Обычно равно Bars-1;
  nJMAlimit - Количество ещё не подсчитанных баров плюс один или номер поседнего неподсчитанного бара, Обычно равно: Bars-IndicatorCounted()-1;
  nJMALength - глубина сглаживания
  nJMAPhase  - параметр, изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
  dJMAseries - Входной  параметр, по которому производится расчёт функции JJMASeries;
  nJMAbar - номер расчитываемого бара, параметр должен изменяться оператором цикла от максимального значения к нулевому.
  nJMAreset - параметр, при значении которого равным -1 происходит введение и инициализация внутренних переменных функции JJMASeries.

  ------------------------- output parameters ----------------------------

  JJMASeries() - значение функции dJMAJMA.
  nJMAreset - параметр, возвращающий по ссылке значение, отличинное от 0 , если произошла ошибка в расчёте функции,
   0, если расчёт прошёл нормально. Этот параметр может быть только переменной, но не значением!!!

  --------------------- Механизм обращения к функции ---------------------

  Перед обращениями к функции JJMASeries , когда количество уже подсчитанных баров равно 0, следует ввести и инициализировать
  внутренние переменные функции, для этого необходимо обратиться к функции со следующими параметрами:
  reset=-1; dJMAJMASeries(0,MaxJMAnumber+1,0,0,0,0,0,0,reset);
  необходимо сделать параметр nJMAnumber(MaxJMAnumber) равным количеству обращений к функции JJMASeries,  то есть на единицу больше, чем
  максимальный nJMAnumber. А параметру nJMAreset присвоить через переменную reset значение -1(В саму функцию подставлять -1 нельзя!
  Только через параметр). Остальным параметрам присвоить 0. При написании индикаторов и экспертов с использованием функции JJMASeries, не
  рекомендуется переменным давать имена начинающиеся с nJMA... или dJMA...

  --------------------- Пример обращения к функции -----------------------
int start()
{
int reset,counted_bars=IndicatorCounted();
//----+ check for possible errors
if (counted_bars<0) return (-1);
int limit=Bars-counted_bars-1;
//----+ введение и инициализация внутренних переменных функции JJMASeries (одно обращение к функции, параметры nJMAPhase и nJMALength не меняются )
if (limit==Bars-1){reset=-1;int set=JdJMAJMASeries(0,1,0,0,0,0,0,0,reset);if((reset==1)||(set!=0))return(-1);reset=1;}
//----+обращение к функции JJMASeries для расчёта буфера Ind_Buffer[]
for(int x=limit;x>=0;x--)
 (
  reset=1;
  Series=Close[x];
  Ind_Buffer[x]=JJMASeries(0,0,Bars-1,limit,Phase,Length,Series,x,reset);
  if (reset!=0)return(-1);
 }
return(0);
}
//----+ определение функции JJMASeries
#include <JJMASeries.mqh>

  */
//SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
//+++++++++++++++++++++++++++++++++++++++++++++++++++++ <<< JJMASeries >>> ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
//SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+

double JJMASeries
(int nJMAnumber,int nJMAdin,int nJMAMaxBar,int nJMAlimit,int nJMAPhase,int nJMALength,double dJMAseries,int nJMAbar,int& nJMAreset)
{
if(nJMAreset==-1)
{
//----++ <<< Введение и инициализация переменных >>> +SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
static double dJMAf18[1],dJMAf38[1],dJMAfA0,dJMAfA8[1],dJMAfC0[1],dJMAfC8[1],dJMAs8[1],dJMAs18[1],dJMAvv,dJMAv1[1],dJMAv2[1];
static double dJMAv3[1],dJMAv4,dJMAf90[1],dJMAf78[1],dJMAf88[1],dJMAf98[1],dJMAJMA[1],dJMAlist[1][128],dJMAring1[1][128];
static double dJMAring2[1][11],dJMAbuffer[1][62],dJMAmem1[1][8],dJMAmem3[1][128],dJMAmem4[1][128],dJMAmem5[1][11],dJMAmem8[1][128];
static double dJMAKg[1],dJMAPf[1],dJMAs20,dJMAs10,dJMAfB0,dJMAfD0,dJMAf8,dJMAf60,dJMAf20,dJMAf28,dJMAf30,dJMAf40,dJMAf48,dJMAf58;
static double dJMAf68,dJMAf70;
static int nJMAs28[1],nJMAs30[1],nJMAs38[1],nJMAs40[1],nJMAv5,nJMAv6,nJMAfE0,nJMAfD8,nJMAfE8,nJMAval,nJMAs48[1],nJMAs58,nJMAs60;
static int nJMAs68,nJMAf0[1],nJMAaa,nJMAtemp,nJMAsize,nJMAs50[1],nJMAs70[1],nJMALP2[1],nJMALP1[1],nJMAcountR1[1],nJMAcountR2[1];
static int nJMAcountL[1],nJMAii,nJMAjj,nJMAn,nJMAm,nJMAmem2[1][9],nJMAmem6[1][128],nJMAmem7[1][11],nJMAmem9[1][128];
//--+
nJMAm=nJMAnumber;
if(ArrayResize(dJMAlist,   nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAring1,  nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAring2,  nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAbuffer, nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAmem1,   nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(nJMAmem6,   nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(nJMAmem2,   nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(nJMAmem7,   nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAmem3,   nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAmem8,   nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAmem4,   nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(nJMAmem9,   nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAmem5,   nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(nJMAcountR1,nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(nJMAcountR2,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(nJMAcountL ,nJMAm)==0){nJMAreset=1;return(0);}
//--+
if(ArrayResize(dJMAKg, nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAPf, nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAf18,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAf38,nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAfA8,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAfC0,nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAfC8,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAs8, nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAs18,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAJMA,nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(nJMAs50,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(nJMAs70,nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(nJMALP2,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(nJMALP1,nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(nJMAs38,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(nJMAs40,nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(nJMAs48,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAv1, nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAv2, nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAv3, nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAf90,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAf78,nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(dJMAf88,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(dJMAf98,nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(nJMAs28,nJMAm)==0){nJMAreset=1;return(0);}if(ArrayResize(nJMAs30,nJMAm)==0){nJMAreset=1;return(0);}
if(ArrayResize(nJMAf0, nJMAm)==0){nJMAreset=1;return(0);}
//--+
ArrayInitialize(dJMAlist,0.0);ArrayInitialize(dJMAring1,0.0);ArrayInitialize(dJMAring2,0.0);ArrayInitialize(dJMAbuffer,0.0);
ArrayInitialize(dJMAmem1,0.0);ArrayInitialize(nJMAmem2,0   );ArrayInitialize(dJMAmem3,0.0 );ArrayInitialize(dJMAmem4,  0.0);
ArrayInitialize(dJMAmem5,0.0);ArrayInitialize(nJMAmem6,0   );ArrayInitialize(nJMAmem7,0   );ArrayInitialize(dJMAmem8,  0.0);
ArrayInitialize(nJMAmem9,0  );ArrayInitialize(nJMAcountR1,0);ArrayInitialize(nJMAcountR2,0);ArrayInitialize(nJMAcountL,0  );
//--+
ArrayInitialize(dJMAKg,0.0 );ArrayInitialize(dJMAPf,0.0 );ArrayInitialize(dJMAf18,0.0);ArrayInitialize(dJMAf38,0.0);
ArrayInitialize(dJMAfA8,0.0);ArrayInitialize(dJMAfC0,0.0);ArrayInitialize(dJMAfC8,0.0);ArrayInitialize(dJMAs8, 0.0);
ArrayInitialize(dJMAs18,0.0);ArrayInitialize(dJMAJMA,0.0);ArrayInitialize(nJMAs50,0  );ArrayInitialize(nJMAs70,0  );
ArrayInitialize(nJMALP2,0  );ArrayInitialize(nJMALP1,0  );ArrayInitialize(nJMAs38,0  );ArrayInitialize(nJMAs40,0  );
ArrayInitialize(nJMAs48,0  );ArrayInitialize(dJMAv1, 0  );ArrayInitialize(dJMAv2, 0  );ArrayInitialize(dJMAv3, 0  );
ArrayInitialize(dJMAf90,0.0);ArrayInitialize(dJMAf78,0.0);ArrayInitialize(dJMAf88,0.0);ArrayInitialize(dJMAf98,0.0);
ArrayInitialize(nJMAs28,0  );ArrayInitialize(nJMAs30,0  );ArrayInitialize(nJMAf0, 1  );
nJMAreset=0;return(0.0);
//----++SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
}
nJMAn=nJMAnumber;
if (nJMAbar> nJMAMaxBar){nJMAreset=0;return(0.0);}
if((nJMAbar==nJMAMaxBar)||(nJMAdin!=0))
{
//----++ <<< Расчёт коэффициентов  >>> +SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
double Dr,Ds,Dl;
if(nJMALength < 1.0000000002) Dr = 0.0000000001;
else Dr= (nJMALength - 1.0) / 2.0;
if((nJMAPhase >= -100)&&(nJMAPhase <= 100))dJMAPf[nJMAn] = nJMAPhase / 100.0 + 1.5;
if (nJMAPhase > 100) dJMAPf[nJMAn] = 2.5;
if (nJMAPhase < -100) dJMAPf[nJMAn] = 0.5;
Dr = Dr * 0.9; dJMAKg[nJMAn] = Dr/(Dr + 2.0);
Ds=MathSqrt(Dr);Dl=MathLog(Ds); dJMAv1[nJMAn]= Dl;dJMAv2[nJMAn] = dJMAv1[nJMAn];
if((dJMAv1[nJMAn] / MathLog(2.0)) + 2.0 < 0.0) dJMAv3[nJMAn]= 0.0;
else dJMAv3[nJMAn]=(dJMAv2[nJMAn]/MathLog(2.0))+ 2.0;
dJMAf98[nJMAn]= dJMAv3[nJMAn];
if( dJMAf98[nJMAn] >= 2.5 ) dJMAf88[nJMAn] = dJMAf98[nJMAn] - 2.0;
else dJMAf88[nJMAn]= 0.5;
dJMAf78[nJMAn]= Ds * dJMAf98[nJMAn]; dJMAf90[nJMAn]= dJMAf78[nJMAn] / (dJMAf78[nJMAn] + 1.0);
//----++SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
}
if(nJMAbar==nJMAMaxBar)
{
//----+-------------------------------------------------------------+
nJMAf0[nJMAn]=1; nJMAs28[nJMAn]=63; nJMAs30[nJMAn]=64;
for(int kk=0;kk<=nJMAs28[nJMAn];kk++)dJMAlist[nJMAn][kk]=-1000000.0;
for(kk=nJMAs30[nJMAn]; kk<=127; kk++)dJMAlist[nJMAn][kk]= 1000000.0;
//----+-------------------------------------------------------------+
}
//--+
if((nJMAbar==nJMAlimit)&&(nJMAlimit<nJMAMaxBar)&&(Time[nJMAlimit+1]!=nJMAmem2[nJMAn][00]))
{
//----+ <<< Восстановление значений переменных >>> +ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss+
if(Time[nJMAlimit+1]!=nJMAmem2[nJMAn][01]){nJMAreset=1;return(0);}
//--+
for(nJMAii=nJMAcountL [nJMAn]-1;nJMAii>=0;nJMAii--){nJMAtemp=nJMAmem9[nJMAn][nJMAii];dJMAlist [nJMAn][nJMAtemp]=dJMAmem8[nJMAn][nJMAii];}
for(nJMAii=nJMAcountR1[nJMAn]-1;nJMAii>=0;nJMAii--){nJMAtemp=nJMAmem6[nJMAn][nJMAii];dJMAring1[nJMAn][nJMAtemp]=dJMAmem4[nJMAn][nJMAii];}
for(nJMAii=nJMAcountR2[nJMAn]-1;nJMAii>=0;nJMAii--){nJMAtemp=nJMAmem7[nJMAn][nJMAii];dJMAring2[nJMAn][nJMAtemp]=dJMAmem5[nJMAn][nJMAii];}
//--+
dJMAfC0[nJMAn]=dJMAmem1[nJMAn][00];dJMAfC8[nJMAn]=dJMAmem1[nJMAn][01];dJMAfA8[nJMAn]=dJMAmem1[nJMAn][02];dJMAs8 [nJMAn]=dJMAmem1[nJMAn][03];
dJMAf18[nJMAn]=dJMAmem1[nJMAn][04];dJMAf38[nJMAn]=dJMAmem1[nJMAn][05];dJMAs18[nJMAn]=dJMAmem1[nJMAn][06];dJMAJMA[nJMAn]=dJMAmem1[nJMAn][07];
nJMAs38[nJMAn]=nJMAmem2[nJMAn][02];nJMAs48[nJMAn]=nJMAmem2[nJMAn][03];nJMAs50[nJMAn]=nJMAmem2[nJMAn][04];nJMALP1[nJMAn]=nJMAmem2[nJMAn][05];
nJMALP2[nJMAn]=nJMAmem2[nJMAn][06];nJMAs40[nJMAn]=nJMAmem2[nJMAn][07];nJMAs70[nJMAn]=nJMAmem2[nJMAn][08];
//----+sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss+
}
nJMAcountR1[nJMAn]=0;nJMAcountR2[nJMAn]=0;nJMAcountL[nJMAn]=0;
//----+
if (nJMALP1[nJMAn]<61){nJMALP1[nJMAn]++; dJMAbuffer[nJMAn][nJMALP1[nJMAn]]=dJMAseries;}
if (nJMALP1[nJMAn]>30)
{
//++++++++++++++++++
if (nJMAf0[nJMAn] != 0)
{
nJMAf0[nJMAn] = 0; nJMAv5 = 0;
for( nJMAii=0; nJMAii<=29; nJMAii++) if (dJMAbuffer[nJMAn][nJMAii+1] != dJMAbuffer[nJMAn][nJMAii]){ nJMAv5 = 1; break; }
nJMAfD8 = nJMAv5*30;
if (nJMAfD8 == 0) dJMAf38[nJMAn] = dJMAseries; else dJMAf38[nJMAn] = dJMAbuffer[nJMAn][1];
dJMAf18[nJMAn] = dJMAf38[nJMAn];
if (nJMAfD8 > 29) nJMAfD8 = 29;
}
else nJMAfD8 = 0;
for(nJMAii=nJMAfD8; nJMAii>=0; nJMAii--)
{
nJMAval=31-nJMAii;
if (nJMAii == 0) dJMAf8 = dJMAseries; else dJMAf8 = dJMAbuffer[nJMAn][nJMAval];
dJMAf28 = dJMAf8 - dJMAf18[nJMAn]; dJMAf48 = dJMAf8 - dJMAf38[nJMAn];
if (MathAbs(dJMAf28) > MathAbs(dJMAf48)) dJMAv2[nJMAn] = MathAbs(dJMAf28); else dJMAv2[nJMAn] = MathAbs(dJMAf48);
dJMAfA0 = dJMAv2[nJMAn]; dJMAvv = dJMAfA0 + 0.0000000001; //{1.0e-10;}
if (nJMAs48[nJMAn] <= 1) nJMAs48[nJMAn] = 127; else nJMAs48[nJMAn] = nJMAs48[nJMAn] - 1;
if (nJMAs50[nJMAn] <= 1) nJMAs50[nJMAn] = 10;  else nJMAs50[nJMAn] = nJMAs50[nJMAn] - 1;
if (nJMAs70[nJMAn] < 128) nJMAs70[nJMAn] = nJMAs70[nJMAn] + 1;
dJMAs8[nJMAn] = dJMAs8[nJMAn] + dJMAvv - dJMAring2[nJMAn][nJMAs50[nJMAn]];
if(nJMAbar==0)
{
//--+ <<< Сохранение значений для восстановления буфера >>> +ssssssssssss+
dJMAmem5[nJMAn][nJMAcountR2[nJMAn]]=dJMAring2[nJMAn][nJMAs50[nJMAn]];
nJMAmem7[nJMAn][nJMAcountR2[nJMAn]]=nJMAs50[nJMAn];nJMAcountR2[nJMAn]++;
//--++sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss+
}
dJMAring2[nJMAn][nJMAs50[nJMAn]] = dJMAvv;
if (nJMAs70[nJMAn] > 10) dJMAs20 = dJMAs8[nJMAn] / 10.0; else dJMAs20 = dJMAs8[nJMAn] / nJMAs70[nJMAn];
if (nJMAs70[nJMAn] > 127)
{
dJMAs10 = dJMAring1[nJMAn][nJMAs48[nJMAn]];
if(nJMAbar==0)
{
//--+ <<< Сохранение значений для восстановления буфера >>> +ssssssssssss+
dJMAmem4[nJMAn][nJMAcountR1[nJMAn]]=dJMAring1[nJMAn][nJMAs48[nJMAn]];
nJMAmem6[nJMAn][nJMAcountR1[nJMAn]]=nJMAs48[nJMAn];nJMAcountR1[nJMAn]++;
//--++sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss+
}
dJMAring1[nJMAn][nJMAs48[nJMAn]] = dJMAs20; nJMAs68 = 64; nJMAs58 = nJMAs68;
while (nJMAs68 > 1)
{
if (dJMAlist[nJMAn][nJMAs58] < dJMAs10){nJMAs68 = nJMAs68 *0.5; nJMAs58 = nJMAs58 + nJMAs68;}
else 
if (dJMAlist[nJMAn][nJMAs58]<= dJMAs10) nJMAs68 = 1; else{nJMAs68 = nJMAs68 *0.5; nJMAs58 = nJMAs58 - nJMAs68;}
}
}
else
{
if(nJMAbar==0)
{
//--+ <<< Сохранение значений для восстановления буфера >>> +ssssssssssss+
dJMAmem4[nJMAn][nJMAcountR1[nJMAn]]=dJMAring1[nJMAn][nJMAs48[nJMAn]];
nJMAmem6[nJMAn][nJMAcountR1[nJMAn]]=nJMAs48[nJMAn];nJMAcountR1[nJMAn]++;
//--++sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss+
}
dJMAring1[nJMAn][nJMAs48[nJMAn]] = dJMAs20;
if  (nJMAs28[nJMAn] + nJMAs30[nJMAn] > 127){nJMAs30[nJMAn] = nJMAs30[nJMAn] - 1; nJMAs58 = nJMAs30[nJMAn];}
else{nJMAs28[nJMAn] = nJMAs28[nJMAn] + 1; nJMAs58 = nJMAs28[nJMAn];}
if  (nJMAs28[nJMAn] > 96) nJMAs38[nJMAn] = 96; else nJMAs38[nJMAn] = nJMAs28[nJMAn];
if  (nJMAs30[nJMAn] < 32) nJMAs40[nJMAn] = 32; else nJMAs40[nJMAn] = nJMAs30[nJMAn];
}
nJMAs68 = 64; nJMAs60 = nJMAs68;
while (nJMAs68 > 1)
{
if (dJMAlist[nJMAn][nJMAs60] >= dJMAs20)
{
if (dJMAlist[nJMAn][nJMAs60 - 1] <= dJMAs20) nJMAs68 = 1; else {nJMAs68 = nJMAs68 *0.5; nJMAs60 = nJMAs60 - nJMAs68; }
}
else{nJMAs68 = nJMAs68 *0.5; nJMAs60 = nJMAs60 + nJMAs68;}
if ((nJMAs60 == 127) && (dJMAs20 > dJMAlist[nJMAn][127])) nJMAs60 = 128;
}
if (nJMAs70[nJMAn] > 127)
{
if (nJMAs58 >= nJMAs60)
{
if ((nJMAs38[nJMAn] + 1 > nJMAs60) && (nJMAs40[nJMAn] - 1 < nJMAs60)) dJMAs18[nJMAn] = dJMAs18[nJMAn] + dJMAs20;
else 
if ((nJMAs40[nJMAn] + 0 > nJMAs60) && (nJMAs40[nJMAn] - 1 < nJMAs58)) dJMAs18[nJMAn] 
= dJMAs18[nJMAn] + dJMAlist[nJMAn][nJMAs40[nJMAn] - 1];
}
else
if (nJMAs40[nJMAn] >= nJMAs60) {if ((nJMAs38[nJMAn] + 1 < nJMAs60) && (nJMAs38[nJMAn] + 1 > nJMAs58)) dJMAs18[nJMAn] 
= dJMAs18[nJMAn] + dJMAlist[nJMAn][nJMAs38[nJMAn] + 1]; }
else if  (nJMAs38[nJMAn] + 2 > nJMAs60) dJMAs18[nJMAn] = dJMAs18[nJMAn] + dJMAs20; 
else if ((nJMAs38[nJMAn] + 1 < nJMAs60) && (nJMAs38[nJMAn] + 1 > nJMAs58)) dJMAs18[nJMAn] 
= dJMAs18[nJMAn] + dJMAlist[nJMAn][nJMAs38[nJMAn] + 1];
if (nJMAs58 > nJMAs60)
{
if ((nJMAs40[nJMAn] - 1 < nJMAs58) && (nJMAs38[nJMAn] + 1 > nJMAs58)) dJMAs18[nJMAn] = dJMAs18[nJMAn] - dJMAlist[nJMAn][nJMAs58];
else 
if ((nJMAs38[nJMAn]     < nJMAs58) && (nJMAs38[nJMAn] + 1 > nJMAs60)) dJMAs18[nJMAn] = dJMAs18[nJMAn] - dJMAlist[nJMAn][nJMAs38[nJMAn]];
}
else
{
if ((nJMAs38[nJMAn] + 1 > nJMAs58) && (nJMAs40[nJMAn] - 1 < nJMAs58)) dJMAs18[nJMAn] = dJMAs18[nJMAn] - dJMAlist[nJMAn][nJMAs58];
else
if ((nJMAs40[nJMAn] + 0 > nJMAs58) && (nJMAs40[nJMAn] - 0 < nJMAs60)) dJMAs18[nJMAn] = dJMAs18[nJMAn] - dJMAlist[nJMAn][nJMAs40[nJMAn]];
}
}
if (nJMAs58 <= nJMAs60)
{
if (nJMAs58 >= nJMAs60)
{
if(nJMAbar==0)
{
//--+ <<< Сохранение значений для восстановления буфера >>> +sssss+
dJMAmem8[nJMAn][nJMAcountL[nJMAn]]=dJMAlist[nJMAn][nJMAs60];
nJMAmem9[nJMAn][nJMAcountL[nJMAn]]=nJMAs60;nJMAcountL[nJMAn]++;
//--++ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss+
}
dJMAlist[nJMAn][nJMAs60] = dJMAs20;
}
else
{
if(nJMAbar==0)
{
//--+ <<< Сохранение значений для восстановления буфера >>> +sssssssssssssssssssssssssssssssssssssssssssssssss+
nJMAsize=nJMAs60-nJMAs58;for(nJMAaa=0; nJMAaa<=nJMAsize-2;nJMAaa++){dJMAmem8[nJMAn][nJMAcountL[nJMAn]+nJMAaa]
=dJMAlist[nJMAn][nJMAs58+nJMAaa];nJMAmem9[nJMAn][nJMAcountL[nJMAn]+nJMAaa]=nJMAs58+1+nJMAaa;}
nJMAcountL[nJMAn]=nJMAcountL[nJMAn]+nJMAsize;dJMAmem8[nJMAn][nJMAcountL[nJMAn]]=dJMAlist[nJMAn][nJMAs60-1];
nJMAmem9[nJMAn][nJMAcountL[nJMAn]]=nJMAs60-1;nJMAcountL[nJMAn]++;
//--++ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss+
}
for( nJMAjj = nJMAs58 + 1; nJMAjj<=nJMAs60 - 1 ;nJMAjj++)dJMAlist[nJMAn][nJMAjj - 1] = dJMAlist[nJMAn][nJMAjj];
dJMAlist[nJMAn][nJMAs60 - 1] = dJMAs20;
}
}
else
{
if(nJMAbar==0)
{
//--+ <<< Сохранение значений для восстановления буфера >>> +ssssssssssssssssssssssssssssssssssssssssssssssssss+
nJMAsize=nJMAs58-nJMAs60+1;for(nJMAaa=0; nJMAaa<=nJMAsize-2;nJMAaa++){dJMAmem8[nJMAn][nJMAcountL[nJMAn]+nJMAaa]
=dJMAlist[nJMAn][nJMAs58-nJMAaa];nJMAmem9[nJMAn][nJMAcountL[nJMAn]+nJMAaa]=nJMAs58-1-nJMAaa;}
nJMAcountL[nJMAn]=nJMAcountL[nJMAn]+nJMAsize;dJMAmem8[nJMAn][nJMAcountL[nJMAn]]=dJMAlist[nJMAn][nJMAs60];
nJMAmem9[nJMAn][nJMAcountL[nJMAn]]=nJMAs60;nJMAcountL[nJMAn]++;
//--++sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss+
}
for( nJMAjj = nJMAs58 - 1; nJMAjj>=nJMAs60 ;nJMAjj--) dJMAlist[nJMAn][nJMAjj + 1] = dJMAlist[nJMAn][nJMAjj];
dJMAlist[nJMAn][nJMAs60] = dJMAs20;
}
if (nJMAs70[nJMAn] <= 127)
{
dJMAs18[nJMAn] = 0;
for( nJMAjj = nJMAs40[nJMAn] ; nJMAjj<=nJMAs38[nJMAn] ;nJMAjj++) dJMAs18[nJMAn] = dJMAs18[nJMAn] + dJMAlist[nJMAn][nJMAjj];
}
dJMAf60 = dJMAs18[nJMAn] / (nJMAs38[nJMAn] - nJMAs40[nJMAn] + 1.0);
if (nJMALP2[nJMAn] + 1 > 31) nJMALP2[nJMAn] = 31; else nJMALP2[nJMAn] = nJMALP2[nJMAn] + 1;
if (nJMALP2[nJMAn] <= 30)
{
if (dJMAf28 > 0.0) dJMAf18[nJMAn] = dJMAf8; else dJMAf18[nJMAn] = dJMAf8 - dJMAf28 * dJMAf90[nJMAn];
if (dJMAf48 < 0.0) dJMAf38[nJMAn] = dJMAf8; else dJMAf38[nJMAn] = dJMAf8 - dJMAf48 * dJMAf90[nJMAn];
dJMAJMA[nJMAn] = dJMAseries;
if (nJMALP2[nJMAn]!=30) continue;
if (nJMALP2[nJMAn]==30)
{
dJMAfC0[nJMAn] = dJMAseries;
if ( MathCeil(dJMAf78[nJMAn]) >= 1) dJMAv4 = MathCeil(dJMAf78[nJMAn]); else dJMAv4 = 1.0;

if(dJMAv4>0)nJMAfE8 = MathFloor(dJMAv4);else{if(dJMAv4<0)nJMAfE8 = MathCeil (dJMAv4);else nJMAfE8 = 0.0;}

if (MathFloor(dJMAf78[nJMAn]) >= 1) dJMAv2[nJMAn] = MathFloor(dJMAf78[nJMAn]); else dJMAv2[nJMAn] = 1.0;

if(dJMAv2[nJMAn]>0)nJMAfE0 = MathFloor(dJMAv2[nJMAn]);else{if(dJMAv2[nJMAn]<0)nJMAfE0 = MathCeil (dJMAv2[nJMAn]);else nJMAfE0 = 0.0;}

if (nJMAfE8== nJMAfE0) dJMAf68 = 1.0; else {dJMAv4 = nJMAfE8 - nJMAfE0; dJMAf68 = (dJMAf78[nJMAn] - nJMAfE0) / dJMAv4;}
if (nJMAfE0 <= 29) nJMAv5 = nJMAfE0; else nJMAv5 = 29;
if (nJMAfE8 <= 29) nJMAv6 = nJMAfE8; else nJMAv6 = 29;
dJMAfA8[nJMAn] = (dJMAseries - dJMAbuffer[nJMAn][nJMALP1[nJMAn] - nJMAv5]) * (1.0 - dJMAf68) / nJMAfE0 + (dJMAseries 
- dJMAbuffer[nJMAn][nJMALP1[nJMAn] - nJMAv6]) * dJMAf68 / nJMAfE8;
}
}
else
{
if (dJMAf98[nJMAn] >= MathPow(dJMAfA0/dJMAf60, dJMAf88[nJMAn])) dJMAv1[nJMAn] = MathPow(dJMAfA0/dJMAf60, dJMAf88[nJMAn]);
else dJMAv1[nJMAn] = dJMAf98[nJMAn];
if (dJMAv1[nJMAn] < 1.0) dJMAv2[nJMAn] = 1.0;
else
{if(dJMAf98[nJMAn] >= MathPow(dJMAfA0/dJMAf60, dJMAf88[nJMAn])) dJMAv3[nJMAn] = MathPow(dJMAfA0/dJMAf60, dJMAf88[nJMAn]);
else dJMAv3[nJMAn] = dJMAf98[nJMAn]; dJMAv2[nJMAn] = dJMAv3[nJMAn];}
dJMAf58 = dJMAv2[nJMAn]; dJMAf70 = MathPow(dJMAf90[nJMAn], MathSqrt(dJMAf58));
if (dJMAf28 > 0.0) dJMAf18[nJMAn] = dJMAf8; else dJMAf18[nJMAn] = dJMAf8 - dJMAf28 * dJMAf70;
if (dJMAf48 < 0.0) dJMAf38[nJMAn] = dJMAf8; else dJMAf38[nJMAn] = dJMAf8 - dJMAf48 * dJMAf70;
}
}
if (nJMALP2[nJMAn] >30)
{
dJMAf30 = MathPow(dJMAKg[nJMAn], dJMAf58);
dJMAfC0[nJMAn] =(1.0 - dJMAf30) * dJMAseries + dJMAf30 * dJMAfC0[nJMAn];
dJMAfC8[nJMAn] =(dJMAseries - dJMAfC0[nJMAn]) * (1.0 - dJMAKg[nJMAn]) + dJMAKg[nJMAn] * dJMAfC8[nJMAn];
dJMAfD0 = dJMAPf[nJMAn] * dJMAfC8[nJMAn] + dJMAfC0[nJMAn];
dJMAf20 = dJMAf30 *(-2.0);
dJMAf40 = dJMAf30 * dJMAf30;
dJMAfB0 = dJMAf20 + dJMAf40 + 1.0;
dJMAfA8[nJMAn] =(dJMAfD0 - dJMAJMA[nJMAn]) * dJMAfB0 + dJMAf40 * dJMAfA8[nJMAn];
dJMAJMA[nJMAn] = dJMAJMA[nJMAn] + dJMAfA8[nJMAn];
}
}
//++++++++++++++++++
if (nJMALP1[nJMAn] <=30)dJMAJMA[nJMAn]=0.0;
if (nJMAbar==1)
{
//--+ <<< Сохранение значений переменных >>> +ssssssssssssssssssssssssssssssssssssssssssssssssssssssssss+
dJMAmem1[nJMAn][00]=dJMAfC0[nJMAn];dJMAmem1[nJMAn][01]=dJMAfC8[nJMAn];dJMAmem1[nJMAn][02]=dJMAfA8[nJMAn];
dJMAmem1[nJMAn][03]= dJMAs8[nJMAn];dJMAmem1[nJMAn][04]=dJMAf18[nJMAn];dJMAmem1[nJMAn][05]=dJMAf38[nJMAn];
dJMAmem1[nJMAn][06]=dJMAs18[nJMAn];dJMAmem1[nJMAn][07]=dJMAJMA[nJMAn];nJMAmem2[nJMAn][02]=nJMAs38[nJMAn];
nJMAmem2[nJMAn][03]=nJMAs48[nJMAn];nJMAmem2[nJMAn][04]=nJMAs50[nJMAn];nJMAmem2[nJMAn][05]=nJMALP1[nJMAn];
nJMAmem2[nJMAn][06]=nJMALP2[nJMAn];nJMAmem2[nJMAn][07]=nJMAs40[nJMAn];nJMAmem2[nJMAn][08]=nJMAs70[nJMAn];
nJMAmem2[nJMAn][00]=Time[0];nJMAmem2[nJMAn][01]=Time[1];
//--+sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss+
}
//----+  done --------------------------+
nJMAreset=0;
return(dJMAJMA[nJMAn]);
}