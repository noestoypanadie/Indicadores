//+------------------------------------------------------------------+
// you are free to use and improve, however I would appreciate you send me your versions at gideonsmolders(@)gmail.com
//ATTENTION: error messages: zero divide
#property copyright "Gideon Smolders,2005"
#property link      "gideonsmolders(@)gmail.com"
//---- indicator settings
#property  indicator_chart_window
#property  indicator_buffers 2
#property  indicator_color1  Olive  
#property  indicator_color2  FireBrick

//---- indicator parameters
extern int FastEMA=12;
extern int SlowEMA=26;
extern int SignalSMA=9;
extern double DivCalc1=0.3;
extern double DivCalc2=0.35;
extern double DivCalc3=0.45;
extern double DivCalc4=0.60;
//---- indicator buffers
double     ind_buffer1a[];
double     ind_buffer1b[];
double     ind_buffer2[];
double     ind_buffer3[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- 2 additional buffers are used for counting.
   IndicatorBuffers(4);
//---- drawing settings
   SetIndexStyle(0,DRAW_ARROW);
   SetIndexArrow(0,108);
   SetIndexStyle(1,DRAW_ARROW);
   SetIndexArrow(1,108);
   
//---- 3 indicator buffers mapping
   if(!SetIndexBuffer(0,ind_buffer1a) &&
      !SetIndexBuffer(1,ind_buffer1b) &&
      !SetIndexBuffer(2,ind_buffer2) &&      
      !SetIndexBuffer(3,ind_buffer3))
      Print("cannot set indicator buffers!");
//---- name for DataWindow and indicator subwindow label
   IndicatorShortName("MACDsignalsv0.2("+FastEMA+","+SlowEMA+","+SignalSMA+")");
//---- initialization done
   return(0);
  }
//+------------------------------------------------------------------+
//| Moving Average                                      |
//+------------------------------------------------------------------+
int start()
  {
   int limit;
   int counted_bars=IndicatorCounted();
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   limit=Bars-counted_bars;
//---- macd counted in the 1-st additional buffer
   for(int i=0; i<limit; i++)
      ind_buffer2[i]=iMA(NULL,0,FastEMA,0,MODE_EMA,PRICE_CLOSE,i)
                        -iMA(NULL,0,SlowEMA,0,MODE_EMA,PRICE_CLOSE,i);
//---- signal line counted in the 2-nd additional buffer
   for(i=0; i<limit; i++)
      ind_buffer3[i]=iMAOnArray(ind_buffer2,Bars,SignalSMA,0,MODE_SMA,i);
//---- main loop
   double value=0;
   double prev1_value=0;
   double prev2_value=0;
   double prev3_value=0;
   double prev4_value=0;   
   double div_value1=0;
   double div_value2=0;
   double div_value3=0;
   double div1=0;
   double div2=0;
   double div3=0;
   for(i=0; i<limit; i++)
      {
         ind_buffer1a[i]=0.0;
         ind_buffer1b[i]=0.0;      
         value=ind_buffer2[i]-ind_buffer3[i];
         prev1_value=ind_buffer2[i+1]-ind_buffer3[i+1];
         prev2_value=ind_buffer2[i+2]-ind_buffer3[i+2];
         prev3_value=ind_buffer2[i+3]-ind_buffer3[i+3];
         prev4_value=ind_buffer2[i+4]-ind_buffer3[i+4];
         if(prev1_value != 0)  div_value1=MathAbs(div1/prev1_value); else div_value1 =  0;
         if(prev2_value != 0)  div_value1=MathAbs(div2/prev2_value); else div_value2 =  0;
         if(prev3_value != 0)  div_value1=MathAbs(div3/prev3_value); else div_value3 =  0;
         
         div1=value-prev1_value;
         div2=value-prev2_value;
         div3=value-prev3_value;
         if ((value>prev1_value && prev1_value<prev2_value && prev2_value<prev3_value && div_value1>DivCalc1) || 
             (value>prev1_value && prev1_value>prev2_value && prev2_value<prev3_value && div_value2>DivCalc2) ||
             (value>prev1_value && (prev1_value<prev2_value || prev1_value>prev2_value) && prev2_value>prev3_value && prev3_value<prev4_value && div_value3>DivCalc3) || 
             (value>prev1_value && prev1_value>prev2_value && prev2_value>prev3_value && div_value1>DivCalc4) ) ind_buffer1a[i]=Low[i]-2*Point;
         if ((value<prev1_value && prev1_value>prev2_value && prev2_value>prev3_value && div_value1>DivCalc1) ||
             (value<prev1_value && prev1_value<prev2_value && prev2_value>prev3_value && div_value2>DivCalc2) ||
             (value<prev1_value && (prev1_value>prev2_value || prev1_value<prev2_value)  && prev2_value<prev3_value && prev3_value>prev4_value && div_value3>DivCalc3) ||
             (value<prev1_value && prev1_value<prev2_value && prev2_value<prev3_value && div_value2>DivCalc4)) ind_buffer1b[i]=High[i]+2*Point;
      }   
//---- done
   return(0);
  }
//+------------------------------------------------------------------+


