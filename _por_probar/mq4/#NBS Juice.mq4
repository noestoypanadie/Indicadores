//+------------------------------------------------------------------+
//|                                                        Juice.mq4 |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 5
#property  indicator_color1  Olive
#property  indicator_color2  FireBrick
#property  indicator_color3  Orange
#property  indicator_color4  Pink
#property  indicator_color5  Magenta
//---- indicator parameters
extern int    Length=7;
extern double Ks=1.5; //multiplier times avg of stdev over the # of CalcBars
extern int    CalcBars=96; //put zero if want to calculate on all bars
extern int    Advance = 70; 

//---- indicator buffers

//---- indicator buffers
double GoodJuice[];
double SoSoJuice[];
double BadJuice[];
double SoSoLine[];
double GoodLine[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {

//---- drawing settings
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,2);
   SetIndexStyle(3,DRAW_LINE,STYLE_DOT,1);
   SetIndexStyle(4,DRAW_LINE,STYLE_DOT,1);

//---- indicator buffers mapping
   SetIndexBuffer(0,GoodJuice);
   SetIndexBuffer(1,SoSoJuice);
   SetIndexBuffer(2,BadJuice);
   SetIndexBuffer(3,SoSoLine);
   SetIndexBuffer(4,GoodLine);
   
   
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("Juice mod v1 ("+Length+","+Ks+")");
   SetIndexShift (1, Advance);
//---- initialization done
   SetIndexEmptyValue(0,0);
   SetIndexEmptyValue(1,0);
   SetIndexEmptyValue(2,0);
   SetIndexEmptyValue(3,0);
   SetIndexEmptyValue(4,0);   
   return(0);
  }
//+------------------------------------------------------------------+
//| Juice_mod_v1.2                                                   |
//+------------------------------------------------------------------+
int start()
{

   int i;
    
//---- main loop
   double sum=0;
   if (CalcBars==0) int NBars=Bars-Length; else NBars=CalcBars;
   for(i=1; i<=NBars; i++) sum+=iStdDev(NULL,0,Length,MODE_LWMA,0,PRICE_CLOSE,i);
   
   double avg=sum/NBars;
   
   for(i=Bars-Length-1; i>=0; i--)
   {
        
      double Juice=iStdDev(NULL,0,Length,MODE_LWMA,0,PRICE_CLOSE,i);
         
         SoSoLine[i]=avg/Point;  
         GoodLine[i]=(Ks*avg)/Point;
         
   
   if((Juice/Point)>=GoodLine[i]){
         GoodJuice[i]=Juice/Point;
         BadJuice[i]=0;
         SoSoJuice[i]=0;
      }
   if((Juice/Point)<GoodLine[i] && (Juice/Point)>=SoSoLine[i]){
         GoodJuice[i]=0;
         BadJuice[i]=0;
         SoSoJuice[i]=Juice/Point;
      }   
    if((Juice/Point)<SoSoLine[i]){
         GoodJuice[i]=0;
         BadJuice[i]=Juice/Point;
         SoSoJuice[i]=0;
      }  
   }
//---- done
   return(0);
  }
//+------------------------------------------------------------------+

