/*
���  ������  ����������  �������  �������� ���� JJMASeries.mqh � �����
(����������): MetaTrader\experts\include\
*/
//+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+ 
//|                                                        JMACD.mq4 | 
//|                 JMA code: Copyright � 2005, Weld, Jurik Research | 
//|                                          http://weld.torguem.net | 
//|                           Copyright � 2005,     Nikolay Kositsin | 
//|                                   Khabarovsk, violet@mail.kht.ru | 
//+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+ 
#property  copyright "Copyright � 2004, MetaQuotes Software Corp."
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
extern int Input_Price_Customs = 0;//����� ���, �� ������� ������������ ������ ���������� (0-"Close", 1-"Open", 2-"(High+Low)/2", 3-"High", 4-"Low", 5-"input Heiken Ashi Close") 
extern int CountBars = 300;//���������� ��������� �����, �� ������� ���������� ������ ���������
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
if(JMACD_Phase<-100){Alert("�������� JMACD_Phase ������ ���� �� -100 �� +100" + " �� ����� ������������ " +JMACD_Phase+   " ����� ������������ -100");}
if(JMACD_Phase> 100){Alert("�������� JMACD_Phase ������ ���� �� -100 �� +100" + " �� ����� ������������ " +JMACD_Phase+   " ����� ������������  100");}
if(Signal_Phase<-100){Alert("�������� Signal_Phase ������ ���� �� -100 �� +100" + " �� ����� ������������ " +Signal_Phase+   " ����� ������������ -100");}
if(Signal_Phase> 100){Alert("�������� Signal_Phase ������ ���� �� -100 �� +100" + " �� ����� ������������ " +Signal_Phase+   " ����� ������������  100");}
if(FastJMA<  1){Alert("�������� FastJMA ������ ���� �� ����� 1"     + " �� ����� ������������ " +FastJMA+  " ����� ������������  1"  );}
if(SlowJMA<  1){Alert("�������� SlowJMA ������ ���� �� ����� 1"     + " �� ����� ������������ " +SlowJMA+  " ����� ������������  1"  );}
if(SignalJMA<1){Alert("�������� SignalJMA ������ ���� �� ����� 1"   + " �� ����� ������������ " +SignalJMA+" ����� ������������  1"  );}
if(IPC<0){Alert("�������� Input_Price_Customs ������ ���� �� ����� 0" + " �� ����� ������������ "+IPC+ " ����� ������������ 0"       );}
if(IPC>6){Alert("�������� Input_Price_Customs ������ ���� �� ����� 4" + " �� ����� ������������ "+IPC+ " ����� ������������ 0"       );}
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
   //----+ �������� � ������������� ���������� ���������� ������� JJMASeries, JMAnumberJ=3(��� ���������� � �������) 
   if (limit==Bars-1){int reset=-1;int set=JJMASeries(3,0,0,0,0,0,0,0,reset);if((reset!=0)||(set!=0))return(-1);}
   //----+  
   //---- macd counted in the JMACD buffer
   for(int bar=limit; bar>=0; bar--)
    {
     switch(IPC)
      {
       //----+ ����� ���, �� ������� ������������ ������ ���������� +-----+
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
     //----+ ��������� � ������� JJMASeries �� ������� 0, ��������� PhaseJ � LengthJ �� �������� �� ������ ���� (din=0)
     reset=1;F.JMA=JJMASeries(0,0,Bars-1,limit,JMACD_Phase,FastJMA,Series,bar,reset);if(reset!=0)return(-1);
     //----+ ��������� � ������� JJMASeries �� ������� 1, (din=0)
     reset=1;S.JMA=JJMASeries(1,0,Bars-1,limit,JMACD_Phase,SlowJMA,Series,bar,reset);if(reset!=0)return(-1);
     //----+
     jmacd=F.JMA-S.JMA;
     JMACD[bar]=jmacd;
     //----+ ��������� � ������� JJMASeries �� ������� 2, (din=0, � ���� ��������� �������� MaxBarJ �������� �� 30  �. �. ��� ��������� JMA �����������) 
     reset=1;JSIGN[bar]=JJMASeries(2,0,Bars-29,limit,Signal_Phase,SignalJMA,jmacd,bar,reset);if(reset!=0)return(-1);
   }
//---- done
   return(0);
  } 
//----+ �������� ������� JJMASeries (���� JJMASeries.mqh ������� �������� � ����� (����������): MetaTrader\experts\include)
#include <JJMASeries.mqh> 