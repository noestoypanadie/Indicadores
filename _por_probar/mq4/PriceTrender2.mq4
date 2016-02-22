//+------------------------------------------------------------------+
//|                                                PriceTrender2.mq4 |
//|                                                          Kalenzo |
//|                                      bartlomiej.gorski@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Kalenzo"
#property link      "bartlomiej.gorski@gmail.com"
#property indicator_buffers 3
#property indicator_color1 DodgerBlue
#property indicator_color2 Gold
#property indicator_color3 Lime

extern int TimeFrame = 60,
           Price = 0,
           Ma1Type = 0,
           Ma1Price = 0,
           Ma1Length = 24,
           Ma2Type = 0,
           Ma2Price = 0,
           Ma2Length = 5;
           

double price[],trend[],trend2[];
 
#property indicator_separate_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
SetIndexBuffer(0,price);
SetIndexBuffer(1,trend);
SetIndexBuffer(2,trend2);

SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1);
SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1);
SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1);
    
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    limit, bigshift; 
   int    counted_bars=IndicatorCounted(); 
//---- 
   if (counted_bars<0) return(-1); 
   if (counted_bars>0) counted_bars--; 
   limit=Bars-counted_bars; 
    
   for (int i=limit; i>=0; i--) 
   { 
      bigshift = iBarShift(Symbol(),TimeFrame,Time[i]); 
      
       price[i] = getPrice(bigshift);
       trend[i] = iMA(Symbol(),TimeFrame,Ma1Length,0,Ma1Type,Ma1Price,bigshift);
       trend2[i] = iMA(Symbol(),TimeFrame,Ma2Length,0,Ma2Type,Ma2Price,bigshift);
   } 

//----
 
   return(0);
  }
//+------------------------------------------------------------------+
double getPrice(int shift)
{
   switch(Price)
   {
      case 0 : return ( iClose(Symbol(),TimeFrame,shift) );
      case 1 : return (iOpen(Symbol(),TimeFrame,shift));
      case 2 : return (iHigh(Symbol(),TimeFrame,shift));
      case 3 : return (iLow(Symbol(),TimeFrame,shift));
      case 4 : return ((iLow(Symbol(),TimeFrame,shift)+iHigh(Symbol(),TimeFrame,shift))/2);
      case 5 : return ((iClose(Symbol(),TimeFrame,shift)+iLow(Symbol(),TimeFrame,shift)+iHigh(Symbol(),TimeFrame,shift))/3);
      case 6 : return ((iOpen(Symbol(),TimeFrame,shift)+iClose(Symbol(),TimeFrame,shift)+iLow(Symbol(),TimeFrame,shift)+iHigh(Symbol(),TimeFrame,shift))/4);
   }
}