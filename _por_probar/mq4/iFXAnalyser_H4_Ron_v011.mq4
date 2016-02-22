//+------------------------------------------------------------------+
//|                                               iFXAnalyser_H4.mq4 |
//|                           Copyright © 2006, Renato P. dos Santos |
//|                   inspired on 4xtraderCY's and SchaunRSA's ideas |
//|   http://www.strategybuilderfx.com/forums/showthread.php?t=16086 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Renato P. dos Santos"
#property link "http://www.strategybuilderfx.com/forums/showthread.php?t=16086"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 White

// Externals
extern int BarCount=5000;
extern double DVLimit0=10.0;
extern double DVLimit1= 5.0;

//indicator buffers
double ind_buffer0[];
double ind_buffer1[];
double ind_buffer2[];

// indicator controls
extern int FastMA=4;
extern int SlowMA=6;

int Fast_MAMode = PRICE_CLOSE;
int Slow_MAMode = PRICE_OPEN;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ind_buffer0);
   
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,ind_buffer1);

   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(2,ind_buffer2);

   int i;
   //remove the old objects 
   for(i=0; i<=BarCount; i++) 
     {
      ObjectDelete("myx"+DoubleToStr(i,0));
     }
  }
  
  
//+-----------+
//| DeInit    |
//+-----------+
int deinit()
  {
   int i;
   //remove the old objects 
   for(i=0; i<=BarCount; i++) 
     {
      ObjectDelete("myx"+DoubleToStr(i,0));
     }
  }
  
  
//+------------------------------------------------------------------+
//| Shaun's 2MA difference                                           |
//+------------------------------------------------------------------+
int start()
  {
   int limit=BarCount;
   int i;
   
   double pos;

   double maF1, maF2, maS1, maS2;
   
   for(i=0; i<limit; i++)
     {
      maF1=iMA(NULL,0,FastMA,0,MODE_SMA,Fast_MAMode,i);
      maS1=iMA(NULL,0,SlowMA,0,MODE_SMA,Slow_MAMode,i);
      ind_buffer0[i]=(maF1-maS1)/Point();                //Blue

      maF2=iMA(NULL,0,FastMA,0,MODE_SMA,Fast_MAMode,i+1);
      maS2=iMA(NULL,0,SlowMA,0,MODE_SMA,Slow_MAMode,i+1);
      ind_buffer1[i]=((maF1-maS1)-(maF2-maS2))/Point();   //Red
      ind_buffer2[i]=ind_buffer1[i]*4;

      pos=( (High[i]+Low[i]+Close[i])/3 ) + ( 13*Point() );
      
      if( ind_buffer0[i] >= DVLimit0 || ind_buffer0[i] <= DVLimit0*(-1) )
        {
         ObjectDelete( "myx"+DoubleToStr(i,0));
         ObjectCreate( "myx"+DoubleToStr(i,0), OBJ_TEXT, 0, Time[i], pos);
         ObjectSetText("myx"+DoubleToStr(i,0),".",32,"Arial",Blue);
        }
      if( ind_buffer2[i] >= DVLimit1 || ind_buffer2[i] <= DVLimit1*(-1) )
        {
         ObjectDelete( "myx"+DoubleToStr(i,0));
         ObjectCreate( "myx"+DoubleToStr(i,0), OBJ_TEXT, 0, Time[i], pos);
         ObjectSetText("myx"+DoubleToStr(i,0),".",32,"Arial",Red);
        }

     }
      
  }

