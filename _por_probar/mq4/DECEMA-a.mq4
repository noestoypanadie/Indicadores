//Version: 1
//Time: December 03, 2006
//+------------------------------------------------------------------+
//|                              DECEMA                              | 
//|                                                       DECEMA.mq4 |
//|                                         Developed by Coders Guru |
//|                                            http://www.xpworx.com |
//+------------------------------------------------------------------+

#property link      "http://www.xpworx.com"


#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Red
#property indicator_color2 Red

 
extern   int      MA_Period                  = 15;
extern   int      MA_Price                   = PRICE_CLOSE;

double CalcBuffer[];
double LastBuffer[];
double Buffer1[];
double Buffer2[];
double Buffer3[];
double Buffer4[];
double Buffer5[];

int init()
{
   IndicatorBuffers(7); 

   SetIndexStyle(0,DRAW_LINE, STYLE_SOLID,2);
   SetIndexStyle(1,DRAW_LINE, STYLE_SOLID,2);
   SetIndexBuffer(0,CalcBuffer);
   SetIndexBuffer(1,LastBuffer);
   SetIndexBuffer(2,Buffer1);
   SetIndexBuffer(3,Buffer2);
   SetIndexBuffer(4,Buffer3);
   SetIndexBuffer(5,Buffer4);
   SetIndexBuffer(6,Buffer5);
   SetIndexLabel(0,"CalcBuffer");
   SetIndexLabel(1,"LastBuffer");
   
   return(0);
}
int deinit()
{
   return(0);
}



void start()
{
   
   int limit;
   
   int counted_bars=IndicatorCounted();
   if(counted_bars<0) return(-1);
   limit=Bars-counted_bars-1;
   

   for(int shift=0; shift<limit; shift++)
       Buffer1[shift] = iMA(NULL,0,MA_Period,0,MODE_EMA,MA_Price,shift);

   for(shift=0; shift<limit; shift++)
       Buffer2[shift] = iMAOnArray(Buffer1,0,MA_Period,0,MODE_EMA,shift);

   for(shift=0; shift<limit; shift++)
       Buffer3[shift] = iMAOnArray(Buffer2,0,MA_Period,0,MODE_EMA,shift);

   for(shift=0; shift<limit; shift++)
       Buffer4[shift] = iMAOnArray(Buffer3,0,MA_Period,0,MODE_EMA,shift);

   for(shift=0; shift<limit; shift++)
       Buffer5[shift] = iMAOnArray(Buffer4,0,MA_Period,0,MODE_EMA,shift);

   for(shift=0; shift<limit; shift++)
       LastBuffer[shift] = iMAOnArray(Buffer5,0,MA_Period,0,MODE_EMA,shift);

   //DECEMA:= (10*EMA1)-(45*EMA2)+(120*EMA3)-(210*EMA4)+(252*EMA5)-(210*EMA6)+(120*EMA7)-(45*EMA8)+(10*EMA9)-EMA10;
   for(shift=0; shift<limit; shift++)
       CalcBuffer[shift] = (10*Buffer1[shift])-(45*Buffer2[shift])+(120*Buffer3[shift])-(210*Buffer4[shift])+(252*Buffer5[shift])-(210*LastBuffer[shift]);
   
   return(0);
}


