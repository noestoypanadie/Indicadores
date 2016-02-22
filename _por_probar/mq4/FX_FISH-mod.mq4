#property copyright "Copyright � 2005, Kiko Segui"
#property link      "webtecnic@terra.es"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 SteelBlue
#property indicator_color2 Orange
// #property indicator_maximum 2
// #property indicator_minimum -2

           
double buffer1[];
double buffer2[];


extern int period=10;
extern int price=0; // 0 or other = (H+L)/2
                    // 1 = Open
                    // 2 = Close
                    // 3 = High
                    // 4 = Low
                    // 5 = (H+L+C)/3
                    // 6 = (O+C+H+L)/4
                    // 7 = (O+C)/2
extern bool Mode_Fast= True;
extern bool Signals= False;
      
int init()
  {
  SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,1,SteelBlue);
  SetIndexBuffer(0,buffer1);
  SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,1,Orange);
  SetIndexBuffer(1,buffer2);
  return(0);
  }


int deinit()
  {
  int i;
  double tmp;
  
  
  for (i=0;i<Bars;i++)
    {
    ObjectDelete("SELL SIGNAL: "+DoubleToStr(i,0));
    ObjectDelete("BUY SIGNAL: "+DoubleToStr(i,0));
    ObjectDelete("EXIT: "+DoubleToStr(i,0));
    }
  return(0);
  }


double Value=0,Value1=0,Value2=0,Fish=0,Fish1=0,Fish2=0;

int buy=0,sell=0;

int start()
  {
  int i;
  int barras;
  double _price;
  double tmp;
  
  double MinL=0;
  double MaxH=0;                    
  
  double Threshold=1.2; 

  barras = Bars;
  if (Mode_Fast)
    barras = 1;
  i = 300;
  while(i>-1)
   {
   MaxH = High[Highest(NULL,0,MODE_HIGH,period,i)];
   MinL = Low[Lowest(NULL,0,MODE_LOW,period,i)];
  
   switch (price)
     {
     case 1: _price = Open[i]; break;
     case 2: _price = Close[i]; break;
     case 3: _price = High[i]; break;
     case 4: _price = Low[i]; break;
     case 5: _price = (High[i]+Low[i]+Close[i])/3; break;
     case 6: _price = (Open[i]+High[i]+Low[i]+Close[i])/4; break;
     case 7: _price = (Open[i]+Close[i])/2; break;
     default: _price = (High[i]+Low[i])/2; break;
     }
   
        
   Value = 0.33*2*((_price-MinL)/(MaxH-MinL)-0.5) + 0.67*Value1;     
   Value=MathMin(MathMax(Value,-0.999),0.999); 
   Fish = 0.5*MathLog((1+Value)/(1-Value)) -0.5*Fish1 -0.5*Fish2;

   buffer1[i]= 0;
   buffer2[i]= 0;
   
   if ( (Fish<0) && (Fish1>0)) 
     {
     if (Signals)
       {
       ObjectCreate("EXIT: "+DoubleToStr(i,0),OBJ_TEXT,0,Time[i],_price);
       ObjectSetText("EXIT: "+DoubleToStr(i,0),"EXIT AT "+DoubleToStr(_price,4),7,"Arial",White);
       }
     buy = 0;
     }   
   if ((Fish>0) && (Fish1<0))
     {
     if (Signals)
       {
       ObjectCreate("EXIT: "+DoubleToStr(i,0),OBJ_TEXT,0,Time[i],_price);
       ObjectSetText("EXIT: "+DoubleToStr(i,0),"EXIT AT "+DoubleToStr(_price,4),7,"Arial",White);
       }
     sell = 0;
     }        
    
   if (Fish>=0)
     {
     buffer1[i] = Fish;
     }
   else
     {
     buffer2[i] = Fish;  
     }
     
   tmp = i;
   if ((Fish<-Threshold) && 
       (Fish>Fish1) && 
       (Fish1<=Fish2))
     {     
     if (Signals)
       {
       ObjectCreate("SELL SIGNAL: "+DoubleToStr(i,0),OBJ_TEXT,0,Time[i],_price);
       ObjectSetText("SELL SIGNAL: "+DoubleToStr(i,0),"SELL AT "+DoubleToStr(_price,4),7,"Arial",Red);
       }
     sell = 1;
     }

  if ((Fish>Threshold) && 
       (Fish<Fish1) && 
       (Fish1>=Fish2))
    {
    if (Signals)
       {
       ObjectCreate("BUY SIGNAL: "+DoubleToStr(i,0),OBJ_TEXT,0,Time[i],_price);
       ObjectSetText("BUY SIGNAL: "+DoubleToStr(i,0),"BUY AT "+DoubleToStr(_price,4),7,"Arial",Lime);
       }
    buy=1;
    }

   Value1 = Value;
   Fish2 = Fish1;  
   Fish1 = Fish;
 
   i--;
   }
  return(0);
  }
//+------------------------------------------------------------------+