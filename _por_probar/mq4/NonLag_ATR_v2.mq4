//+------------------------------------------------------------------+
//|                                                NonLag_ATR_v2.mq4 |
//+------------------------------------------------------------------+

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 White
#property indicator_color2 Orange
#property indicator_color3 Lime
#property indicator_color4 FireBrick

//---- input parameters

extern int     Length         =  14;  // Period of NonLagMA
extern int     Filter         =   0;  // Static filter in points
extern int NonLagLineWidth    =   2;

extern int     MaPeriods      =   8;  // Moving Average Line Periods
extern int     Displace       =   0;  // Moving Average Line DispLace or Shift
extern int     Price          =   1;  // Moving Average Line Method 0 SMA , 1 EMA , 2 SMMA , 3 LWMA
extern int MaLineWidth        =   1;

extern int     Color          =   1;  // Switch of Color mode (1-color)  
extern int     ColorBarBack   =   0;  // Bar back for color mode
double         Deviation      = 0.0;  // Up/down deviation        
extern int     SoundAlertMode =   0;  // Sound Alert switch 

//---- indicator buffers

double MaArray[];
double MABuffer[];
double UpBuffer[];
double DnBuffer[];
double trend[];

double alfa[];
int i,  Len, Cycle=4,Phase;
double Coeff, beta, t, Sum, Weight, g;
double pi = 3.1415926535;    
bool   UpTrendAlert=false, DownTrendAlert=false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

  int init()
  {
   
   IndicatorBuffers(5);
   
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,MaLineWidth);
   SetIndexBuffer(0,MaArray);
   
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,NonLagLineWidth);
   SetIndexBuffer(1,MABuffer);
   
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,NonLagLineWidth);
   SetIndexBuffer(2,UpBuffer);
   
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,NonLagLineWidth);
   SetIndexBuffer(3,DnBuffer);
   
   SetIndexBuffer(4,trend);
    
   string short_name;

//---- indicator line
   
   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS));

//---- name for DataWindow and indicator subwindow label
   
   short_name="NonLag_ATR_v2("+Length+")";
   
   IndicatorShortName(short_name);
   
   SetIndexLabel(0," ("+MaPeriods+") Period Ma of NonLag_ATR");
   SetIndexLabel(1,"NonLag_ATR");
   SetIndexLabel(2,"Up");
   SetIndexLabel(3,"Dn");
   
//----
   
   SetIndexEmptyValue(0,EMPTY_VALUE);
   SetIndexEmptyValue(1,EMPTY_VALUE);
   SetIndexEmptyValue(2,EMPTY_VALUE);
   SetIndexEmptyValue(3,EMPTY_VALUE);
   
   SetIndexDrawBegin(0,Length*Cycle+Length);
   SetIndexDrawBegin(1,Length*Cycle+Length);
   SetIndexDrawBegin(2,Length*Cycle+Length);
   SetIndexDrawBegin(3,Length*Cycle+Length);
   
//----
   
   Coeff =  3*pi;
   Phase = Length-1;
   Len = Length*Cycle + Length-1; 
   ArrayResize(alfa,Len);
   Weight=0;    
      
      for (i=0;i<Len-1;i++)
      {
      if (i<=Phase-1) t = 1.0*i/(Phase-1);
      else t = 1.0 + (i-Phase+1)*(2.0*Cycle-1.0)/(Cycle*Length-1.0); 
      beta = MathCos(pi*t);
      g = 1.0/(Coeff*t+1);   
      if (t <= 0.5 ) g = 1;
      alfa[i] = g * beta;
      Weight += alfa[i];
      }
 
   return(0);
  }

//+------------------------------------------------------------------+
//| NonLagMA_v6.1                                                      |
//+------------------------------------------------------------------+

int start()
{
   
   int    i,shift, counted_bars=IndicatorCounted(),limit;
   double price;      
   if ( counted_bars > 0 )  limit=Bars-counted_bars;
   if ( counted_bars < 0 )  return(0);
   if ( counted_bars ==0 )  limit=Bars-Len-1; 
   if ( counted_bars < 1 ) 
   
   for(i=1;i<Length*Cycle+Length;i++) 
   {
   MaArray[Bars-i]=EMPTY_VALUE;
   MABuffer[Bars-i]=EMPTY_VALUE;
   UpBuffer[Bars-i]=EMPTY_VALUE;
   DnBuffer[Bars-i]=EMPTY_VALUE;
   }
   
   for(shift=limit;shift>=0;shift--) 
   {	
      Sum = 0;
      for (i=0;i<=Len-1;i++)
	   { 
      price = NormalizeDouble(iATR(Symbol(), 0, 1, i+shift),Digits);
      Sum += alfa[i]*price;
      
      }
   
	if (Weight > 0) MABuffer[shift] = NormalizeDouble((1.0+Deviation/100)*Sum/Weight,Digits);
   
      if (Filter>0)
      {
      if( MathAbs(MABuffer[shift]-MABuffer[shift+1]) < Filter*Point ) MABuffer[shift]=MABuffer[shift+1];
      }
      
      if (Color>0)
      {
      trend[shift]=trend[shift+1];
      if (MABuffer[shift]-MABuffer[shift+1] > Filter*Point) trend[shift]= 1; 
      if (MABuffer[shift+1]-MABuffer[shift] > Filter*Point) trend[shift]=-1; 
         if (trend[shift]>0)
         {  
         UpBuffer[shift] = MABuffer[shift];
         if (trend[shift+ColorBarBack]<0) UpBuffer[shift+ColorBarBack]=MABuffer[shift+ColorBarBack];
         DnBuffer[shift] = EMPTY_VALUE;
         if (SoundAlertMode>0 && trend[shift+1]<0 && shift==0) PlaySound("alert2.wav");
         }
         if (trend[shift]<0) 
         {
         DnBuffer[shift] = MABuffer[shift];
         if (trend[shift+ColorBarBack]>0) DnBuffer[shift+ColorBarBack]=MABuffer[shift+ColorBarBack];
         UpBuffer[shift] = EMPTY_VALUE;
         if (SoundAlertMode>0 && trend[shift+1]>0 && shift==0) PlaySound("alert2.wav");
         }
      }
    }
   for(shift=limit;shift>=0;shift--) 
         {
         MaArray[shift] = iMAOnArray(MABuffer,0,MaPeriods,Displace,Price,shift);
         }
//----------   
   string Message;
   
   if ( trend[2]<0 && trend[1]>0 && Volume[0]>1 && !UpTrendAlert)
	{
	Message = " "+Symbol()+" M"+Period()+": Signal for BUY @ "+DoubleToStr(Ask,Digits);
	if ( SoundAlertMode>0 ) Alert (Message); 
	UpTrendAlert=true; DownTrendAlert=false;
	} 
	 	  
	if ( trend[2]>0 && trend[1]<0 && Volume[0]>1 && !DownTrendAlert)
	{
	Message = " "+Symbol()+" M"+Period()+": Signal for SELL @ "+DoubleToStr(Bid,Digits);
	if ( SoundAlertMode>0 ) Alert (Message); 
	DownTrendAlert=true; UpTrendAlert=false;
	} 	         
//----
	return(0);	
}

