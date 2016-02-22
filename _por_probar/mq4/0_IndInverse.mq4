//+------------------------------------------------------------------+
//|                                               IND Inverse.mq4 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, ..."
#property link      "http://www.forex-tsd.com/"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Maroon
#property indicator_color2 Green
#property indicator_color3 Red

//---- input parameters
//---- buffers
double Buffer[];
double SigBuffer[];
double DirBuffer[];

extern int iPeriod = 1;
extern int cbars = 1000;

//----
//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
int init()
{
//---- indicators
    IndicatorDigits(Digits+2);
    SetIndexStyle(0,DRAW_LINE);
    SetIndexBuffer(0,Buffer);
    
    
    SetIndexStyle(1,DRAW_ARROW);
    SetIndexBuffer(1,SigBuffer);
    SetIndexEmptyValue(1,0);
    SetIndexArrow(1,233);
    
    SetIndexStyle(2,DRAW_ARROW);
    SetIndexBuffer(2,DirBuffer);
    SetIndexEmptyValue(2,0);
    SetIndexArrow(2,234);

//----
    return(0);
}

int last = 0;
//+------------------------------------------------------------------+
//| Parabolic Sell And Reverse system                                |
//+------------------------------------------------------------------+
int start()
  {
   if(last == 0) ArrayInitialize(DirBuffer,0);
   last = Bars;
   
    int b = 0,i = 0;
    for(i=0; i<=cbars; i++){
        // Easy to read
        double HD = High[Highest(NULL,0,MODE_HIGH,(iPeriod* 20),i)];
        double LD = Low[Lowest(NULL,0,MODE_LOW,(iPeriod* 20),i)];
        double amplitude = HD - LD;
        if(amplitude!=0)
            Buffer[i]= ((Close[i]-(HD-(amplitude/2)))/amplitude) * iPeriod;
        else
            Buffer[i]= Close[i] * iPeriod;
        }
    double dir = 0;
    for(i=cbars; i>=0; i--){
        SigBuffer[i] = 0;
        DirBuffer[i] = 0;
        if(Buffer[i]*Buffer[i+1]<0){
            if(Buffer[i]<0) DirBuffer[i] = Buffer[i];
            else SigBuffer[i] = Buffer[i];
            }
        }
       
   
//----
   return(0);
  }
//+------------------------------------------------------------------+