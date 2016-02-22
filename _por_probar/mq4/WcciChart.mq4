#property copyright "(C)2005, Yuri Ershtad & Nirvanatiger"
#property link      "http://www.metaquotes.net"

#property indicator_separate_window
#property indicator_buffers 7
#property indicator_color1 Blue
#property indicator_color2 Lime
#property indicator_color3 OrangeRed
#property indicator_color4 HotPink
#property indicator_color5 OrangeRed
#property indicator_color6 White
#property indicator_color7 White

#property indicator_level1  225
#property indicator_level2  100
#property indicator_level3    0
#property indicator_level4 -100
#property indicator_level5 -225


//////////////////////////////////////////////////////////////////////
// Пареметы
//////////////////////////////////////////////////////////////////////

extern int fastPeriod  = 6;
extern int slowPeriod  = 14;

//////////////////////////////////////////////////////////////////////
// Буферы данных
//////////////////////////////////////////////////////////////////////

double FastBuffer[];    // Быстрый CCI
double SlowBuffer[];    // Медленный CCI
double HistBuffer[];
double UpTrBuffer[];
double DnTrBuffer[];
double UpTrBuffer2[];
double DnTrBuffer2[];

//////////////////////////////////////////////////////////////////////
// Инициализация
//////////////////////////////////////////////////////////////////////

int init()
{
   string short_name;
   IndicatorBuffers(7);
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS));
   short_name="WoodiesCCI("+fastPeriod+","+slowPeriod+")";
   IndicatorShortName(short_name);
   // indicator lines ////////////////////////////////
   SetIndexStyle(0, DRAW_HISTOGRAM);   
   SetIndexBuffer(0, HistBuffer);
   SetIndexDrawBegin(0, slowPeriod);
   SetIndexLabel(0,"SlowCCI histogram");      
   SetIndexEmptyValue(0, EMPTY_VALUE);  
   //////////////////////////////////////////////////
   SetIndexStyle(1, DRAW_HISTOGRAM);   
   SetIndexBuffer(1, UpTrBuffer);
   SetIndexDrawBegin(1, slowPeriod); 
   SetIndexLabel(1,"UpTrend histogram");           
   SetIndexEmptyValue(1, EMPTY_VALUE);  
   //////////////////////////////////////////////////
   SetIndexStyle(2, DRAW_HISTOGRAM);   
   SetIndexBuffer(2, DnTrBuffer);
   SetIndexDrawBegin(2, slowPeriod);  
   SetIndexLabel(2,"DnTrend histogram");     
   SetIndexEmptyValue(2, EMPTY_VALUE);  
   //////////////////////////////////////////////////
   SetIndexStyle(3, DRAW_LINE,2,3);   
   SetIndexBuffer(3, SlowBuffer);
   SetIndexDrawBegin(3, slowPeriod);     
   SetIndexLabel(3,"SlowCCI("+slowPeriod+")");   
   SetIndexEmptyValue(3, EMPTY_VALUE);  
   //////////////////////////////////////////////////
   SetIndexStyle(4, DRAW_LINE);
   SetIndexBuffer(4, FastBuffer);
   SetIndexDrawBegin(4, slowPeriod);     
   SetIndexLabel(4,"FastCCI("+fastPeriod+")");  
   SetIndexEmptyValue(4, EMPTY_VALUE);  
   //////////////////////////////////////////////////
   SetIndexStyle(5, DRAW_LINE, 1, 3);   
   SetIndexBuffer(5, UpTrBuffer2);
   SetIndexDrawBegin(5, slowPeriod); 
   SetIndexLabel(5,"UpTrend line");           
   SetIndexEmptyValue(5, EMPTY_VALUE);  
   //////////////////////////////////////////////////
   SetIndexStyle(6, DRAW_LINE, 1, 3);   
   SetIndexBuffer(6, DnTrBuffer2);
   SetIndexDrawBegin(6, slowPeriod);  
   SetIndexLabel(6,"DnTrend line");     
   SetIndexEmptyValue(6, EMPTY_VALUE);  
   //////////////////////////////////////////////////
   return(0);
}
  
//////////////////////////////////////////////////////////////////////
// Custor indicator deinitialization function                       
//////////////////////////////////////////////////////////////////////

int deinit()
{
   // TODO: add your code here
   return(0);
}

//////////////////////////////////////////////////////////////////////
// Custom indicator iteration function                              
//////////////////////////////////////////////////////////////////////

int start()
{
   string symbolName;
   int i, shift, checksum, counted_bars=IndicatorCounted();
   double slowCCI=0.0;
   if (Bars<slowPeriod) return(0); 
   // check for possible errors
   if (counted_bars<0) return(-1);
   // last counted bar will be recounted
   if (counted_bars>0) counted_bars++;
   int limit=Bars-counted_bars;
   if (counted_bars<1 || checksum!=(fastPeriod+slowPeriod+Period()) || symbolName!=Symbol())
   {
      // Параметры изменены, проводим реинициализацию 
      for(i=1; i<=slowPeriod; i++) FastBuffer[Bars-i]=EMPTY_VALUE;    // Быстрый CCI
      for(i=1; i<=slowPeriod; i++) SlowBuffer[Bars-i]=EMPTY_VALUE;    // Медленный CCI
      for(i=1; i<=slowPeriod; i++) HistBuffer[Bars-i]=EMPTY_VALUE;    // Гистограмма медленного CCI
      for(i=1; i<=slowPeriod; i++) UpTrBuffer[Bars-i]=EMPTY_VALUE;    // Направление тренда
      for(i=1; i<=slowPeriod; i++) DnTrBuffer[Bars-i]=EMPTY_VALUE;    // Направление тренда
      for(i=1; i<=slowPeriod; i++) UpTrBuffer2[Bars-i]=EMPTY_VALUE;    // Направление тренда
      for(i=1; i<=slowPeriod; i++) DnTrBuffer2[Bars-i]=EMPTY_VALUE;    // Направление тренда
      checksum = fastPeriod+slowPeriod+Period(); 
      symbolName=Symbol();
      limit=Bars-slowPeriod;      
   }   
   for (shift=limit; shift>=0; shift--)
   {
      FastBuffer[shift] = iCCI(NULL,0,fastPeriod,PRICE_TYPICAL,shift);
      SlowBuffer[shift] = iCCI(NULL,0,slowPeriod,PRICE_TYPICAL,shift);
      HistBuffer[shift] = SlowBuffer[shift];
      UpTrBuffer[shift] = EMPTY_VALUE;
      DnTrBuffer[shift] = EMPTY_VALUE;         
      UpTrBuffer2[shift] = EMPTY_VALUE;
      DnTrBuffer2[shift] = EMPTY_VALUE;         
      //	Заполнение массива точек и определение тренда
      int a, up=0, dn=0;
      for (a=0;a<8;a++)
      {  
         slowCCI=iCCI(NULL,0,slowPeriod,PRICE_TYPICAL,shift+a);
         if (slowCCI>0) up++;
         if (slowCCI<=0) dn++;		         
		}
      if (up>=6){
         UpTrBuffer[shift]=SlowBuffer[shift];
         UpTrBuffer2[shift]=SlowBuffer[shift];
      }
      if (dn>=6){
         DnTrBuffer[shift]=SlowBuffer[shift];      
         DnTrBuffer2[shift]=SlowBuffer[shift];      
      }
   }    
   return(0);
}

//////////////////////////////////////////////////////////////////////




