/*
Для  работы  индикатора  следует  положить файл JJMASeries.mqh в папку
(директорию): MetaTrader\experts\include\
*/
//+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+ 
//|                                                        JMACD.mq4 | 
//|                 JMA code: Copyright © 2005, Weld, Jurik Research | 
//|                                          http://weld.torguem.net | 
//|                           Copyright © 2005,     Nikolay Kositsin | 
//|                                   Khabarovsk, violet@mail.kht.ru | 
//+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+ 
#property  copyright "Copyright © 2004, MetaQuotes Software Corp."
#property  link      "http://www.metaquotes.net/"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 2
#property  indicator_color1  BlueViolet
#property  indicator_color2  Magenta
//---- indicator parameters
extern int FastJMA=12;
extern int SlowJMA=26;
extern int SignalJMA=9;
extern int JMACD_Phase  = 5;
extern int Signal_Phase = 5;
extern int Input_Price_Customs = 0;//Выбор цен, по которым производится расчёт индикатора (0-"Close", 1-"Open", 2-"(High+Low)/2", 3-"High", 4-"Low", 5-"input Heiken Ashi Close") 
extern int CountBars = 300;//Количество последних баров, на которых происходит расчёт ндикатора
//---- indicator buffers
double F.JMA,S.JMA,jmacd,Series;
//---- JMA variabls
double JMACD[];
double JSIGN[];
int    count,IPC;
//+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
//| Custom indicator initialization function                         |
//+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
int init()
  {
//---- drawing settings
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID);
   SetIndexDrawBegin(0,Bars-CountBars);
   SetIndexDrawBegin(1,Bars-CountBars);
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+1);
//---- indicator buffers mapping
   if(!SetIndexBuffer(0,JMACD) && !SetIndexBuffer(1,JSIGN))Alert("cannot set indicator buffers!");
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("JMACD("+FastJMA+","+SlowJMA+","+SignalJMA+")");
   SetIndexLabel(0,"JMACD");
   SetIndexLabel(1,"SignalJMA");
//+=======================================================================================================================================================+ 
if(JMACD_Phase<-100){Alert("Параметр JMACD_Phase должен быть от -100 до +100" + " Вы ввели недопустимое " +JMACD_Phase+   " будет использовано -100");}
if(JMACD_Phase> 100){Alert("Параметр JMACD_Phase должен быть от -100 до +100" + " Вы ввели недопустимое " +JMACD_Phase+   " будет использовано  100");}
if(Signal_Phase<-100){Alert("Параметр Signal_Phase должен быть от -100 до +100" + " Вы ввели недопустимое " +Signal_Phase+   " будет использовано -100");}
if(Signal_Phase> 100){Alert("Параметр Signal_Phase должен быть от -100 до +100" + " Вы ввели недопустимое " +Signal_Phase+   " будет использовано  100");}
if(FastJMA<  1){Alert("Параметр FastJMA должен быть не менее 1"     + " Вы ввели недопустимое " +FastJMA+  " будет использовано  1"  );}
if(SlowJMA<  1){Alert("Параметр SlowJMA должен быть не менее 1"     + " Вы ввели недопустимое " +SlowJMA+  " будет использовано  1"  );}
if(SignalJMA<1){Alert("Параметр SignalJMA должен быть не менее 1"   + " Вы ввели недопустимое " +SignalJMA+" будет использовано  1"  );}
if(IPC<0){Alert("Параметр Input_Price_Customs должен быть не менее 0" + " Вы ввели недопустимое "+IPC+ " будет использовано 0"       );}
if(IPC>6){Alert("Параметр Input_Price_Customs должен быть не более 4" + " Вы ввели недопустимое "+IPC+ " будет использовано 0"       );}
//+=======================================================================================================================================================+    
   IPC=Input_Price_Customs;
//---- initialization done
   return(0);
  }
//+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
//| JMACD                                                            |
//+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
int start()
  {
   int limit;
   int counted_bars=IndicatorCounted();
   //---- check for possible errors
   if(counted_bars<0) return(-1);
   limit=Bars-counted_bars-1;
   //----+ Введение и инициализация внутренних переменных функции JJMASeries, JMAnumberJ=3(Три обращенния к функции) 
   if (limit==Bars-1){int reset=-1;int set=JJMASeries(3,0,0,0,0,0,0,0,reset);if((reset!=0)||(set!=0))return(-1);}
   //----+  
   //---- macd counted in the JMACD buffer
   for(int bar=limit; bar>=0; bar--)
    {
     switch(IPC)
      {
       //----+ Выбор цен, по которым производится расчёт индикатора +-----+
       case 0:  Series=Close[bar];break;
       case 1:  Series= Open[bar];break;
       case 2: {Series=(High[bar]+Low  [bar])/2;}break;
       case 3:  Series= High[bar];break;
       case 4:  Series=  Low[bar];break;
       case 5: {Series=(Open[bar]+High [bar]+Low[bar]+Close[bar])/4;}break;
       case 6: {Series=(Open[bar]+Close[bar])/2;}break;
       default: Series=Close[bar];break;
       //----+------------------------------------------------------------+
      }
     //----+ Обращение к функции JJMASeries за номером 0, параметры PhaseJ и LengthJ не меняются на каждом баре (din=0)
     reset=1;F.JMA=JJMASeries(0,0,Bars-1,limit,JMACD_Phase,FastJMA,Series,bar,reset);if(reset!=0)return(-1);
     //----+ Обращение к функции JJMASeries за номером 1, (din=0)
     reset=1;S.JMA=JJMASeries(1,0,Bars-1,limit,JMACD_Phase,SlowJMA,Series,bar,reset);if(reset!=0)return(-1);
     //----+
     jmacd=F.JMA-S.JMA;
     JMACD[bar]=jmacd;
     //----+ Обращение к функции JJMASeries за номером 2, (din=0, В этом обращении параметр MaxBarJ уменьшен на 30  т. к. это повторное JMA сглаживание) 
     reset=1;JSIGN[bar]=JJMASeries(2,0,Bars-29,limit,Signal_Phase,SignalJMA,jmacd,bar,reset);if(reset!=0)return(-1);
   }
//---- done
   return(0);
  } 
//----+ Введение функции JJMASeries (файл JJMASeries.mqh следует положить в папку (директорию): MetaTrader\experts\include)
#include <JJMASeries.mqh> 