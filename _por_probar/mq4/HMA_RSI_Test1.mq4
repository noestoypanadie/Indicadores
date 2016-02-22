//+------------------------------------------------------------------+
//|                                                HMA_RSI_Test1.mq4 |
//|                                                              HMA |
//|                Copyright © 2006 WizardSerg <wizardserg@mail.ru>, |
//|                                    ?? ??????? ForexMagazine #104 |
//|                                               wizardserg@mail.ru |
//|                         Revised by IgorAD,igorad2003@yahoo.co.uk |   
//|                                        http://www.forex-tsd.com/ |                                      
//+------------------------------------------------------------------+

#property copyright "Reconfigured by General Public" 
#property link      "Everyones@Planet.Earth" 

#property indicator_separate_window

#property indicator_buffers 2 

#property indicator_color1 Aqua 
#property indicator_color2 Red
#property indicator_maximum 100
#property indicator_minimum 0
#property indicator_level1 70
#property indicator_level2 50
#property indicator_level3 30

//---- input parameters 

extern int       period=14; 
extern int       method=1;                         // 0 = MODE_SMA 
extern int       price=0;                          // 0 = PRICE_CLOSE
extern int       width=2;
//extern string    Sound_File="alert2.wav";

//---- buffers 

double Uptrend[];
double Dntrend[];
double ExtMapBuffer[]; 


//+------------------------------------------------------------------+ 
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int init() 
{ 
    IndicatorBuffers(3);  
    SetIndexBuffer(0, Uptrend); 
    
    SetIndexBuffer(1, Dntrend); 
    
    SetIndexBuffer(2, ExtMapBuffer); 
    ArraySetAsSeries(ExtMapBuffer, true); 
    
    SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,width);
    SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,width);
    
    IndicatorShortName(" HMA_RSI_Test1 ( "+period+" )"); 
    return(0); 
} 

//+------------------------------------------------------------------+ 
//| Custor indicator deinitialization function                       | 
//+------------------------------------------------------------------+ 

int deinit() 
{ 
    return(0); 
} 

//+------------------------------------------------------------------+ 
//|                                                                  | 
//+------------------------------------------------------------------+ 

double WMA(int x, int p) 
{ 
    return(iMA(Symbol(), 0, p, 0, method, price, x));
} 

//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 

int start() 
{ 
    int counted_bars = IndicatorCounted(); 
    
    if(counted_bars < 0) 
        return(-1); 
                  
    int x = 0; 
    int p = MathSqrt(period);              
    int e = Bars - counted_bars + period + 1; 
    
    double vect[], trend[]; 
    
    if(e > Bars) e = Bars;    

    ArrayResize(vect, e); 
    ArraySetAsSeries(vect, true);
    ArrayResize(trend, e); 
    ArraySetAsSeries(trend, true); 
    
    for(x = 0; x < e; x++) 
    { 
        vect[x] = 2*WMA(x, period/2) - WMA(x, period);
    } 

    for(x = 0; x < e-period; x++)
     
        ExtMapBuffer[x] = iRSIOnArray(vect, 0, p, x);
    
    for(x = e-period; x >= 0; x--)
    {     
        trend[x] = trend[x+1];
        if (ExtMapBuffer[x]> ExtMapBuffer[x+1]) trend[x] =1;
        if (ExtMapBuffer[x]< ExtMapBuffer[x+1]) trend[x] =-1;
    
    if (trend[x]>0)
    { Uptrend[x] = ExtMapBuffer[x]; 
      if (trend[x+1]<0) {
      Uptrend[x+1]=ExtMapBuffer[x+1];
      //PlaySound(Sound_File);
      }
      Dntrend[x] = EMPTY_VALUE;
      
    }
    else              
    if (trend[x]<0)
    { 
      Dntrend[x] = ExtMapBuffer[x]; 
      if (trend[x+1]>0) {
      Dntrend[x+1]=ExtMapBuffer[x+1];
      //PlaySound(Sound_File);
      }
      
      Uptrend[x] = EMPTY_VALUE;
      
    }              
    
   }
    
  return(0); 
} 
//+------------------------------------------------------------------+ 