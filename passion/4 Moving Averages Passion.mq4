//+-------------------------------------------------------------------+
//| 4 Moving Averages Passion.mq4
//| Victor Diaz
//+-------------------------------------------------------------------+
#property copyright "Copyright © 2016, Victor Diaz"

#property indicator_buffers 4

#property indicator_color1 Green
#property indicator_color2 Red
#property indicator_color3 Blue
#property indicator_color4 Yellow

#property indicator_style1 STYLE_SOLID
#property indicator_style2 STYLE_SOLID
#property indicator_style3 STYLE_SOLID
#property indicator_style4 STYLE_SOLID

#property  indicator_width1 1
#property  indicator_width2 1
#property  indicator_width3 1
#property  indicator_width4 1

#define NOMBRE_INDICADOR "4 Moving Averages Passion"

//---- input parameters
extern int period1=30;
extern int period2=50;
extern int period3=100;
extern int period4=200;

//---- buffers
double Buffer1[];
double Buffer2[];
double Buffer3[];
double Buffer4[];

int yaEstaCargado = 0;


//+---------------------------------------------------------------------+
//| Custom indicator initialization function							|
//+---------------------------------------------------------------------+
int init()
{
   yaEstaCargado = existeIndicador(NOMBRE_INDICADOR);

   IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+1);
	
	//---- indicators
	SetIndexStyle(0, DRAW_LINE, indicator_style1, indicator_width1, indicator_color1);
	SetIndexBuffer(0, Buffer1);
	SetIndexDrawBegin(0, period1);
	SetIndexLabel(0,period1);
	
	SetIndexStyle(1, DRAW_LINE, indicator_style2, indicator_width2, indicator_color2);
	SetIndexBuffer(1, Buffer2);
	SetIndexDrawBegin(1, period2);
	SetIndexLabel(1,period2);
	
	SetIndexStyle(2, DRAW_LINE, indicator_style3, indicator_width3, indicator_color3);
	SetIndexBuffer(2, Buffer3);
	SetIndexDrawBegin(2, period3);
	SetIndexLabel(2,period3);
	
	SetIndexStyle(3, DRAW_LINE, indicator_style4, indicator_width4, indicator_color4);
	SetIndexBuffer(3, Buffer4);
	SetIndexDrawBegin(3, period4);
	SetIndexLabel(3,period4);
   	
   if(yaEstaCargado !=0){
	   limpiaIndicador(NOMBRE_INDICADOR);
	}

	return(0);
}
//+---------------------------------------------------------------------+
//| Custor indicator deinitialization function							|
//+---------------------------------------------------------------------+
int deinit()
{
	return(0);
}
//+---------------------------------------------------------------------+
//| Custom indicator iteration function									|
//+---------------------------------------------------------------------+
int start()
{
	int limit;
	int counted_bars = IndicatorCounted();
	//---- check for possible errors
	if (counted_bars<0){
		return(-1);
	}
	//---- last counted bar will be recounted
	if (counted_bars>0){
		counted_bars--;
	}
	limit = Bars - counted_bars;

	for(int i=limit; i>=0; i--){
		Buffer1[i] = iMA(NULL, 0, period1, 0, MODE_SMA, PRICE_CLOSE, i);
		Buffer2[i] = iMA(NULL, 0, period2, 0, MODE_SMA, PRICE_CLOSE, i);
		Buffer3[i] = iMA(NULL, 0, period3, 0, MODE_SMA, PRICE_CLOSE, i);
		Buffer4[i] = iMA(NULL, 0, period4, 0, MODE_SMA, PRICE_CLOSE, i);
	}
	
	return(0);
}
//+---------------------------------------------------------------------+


int existeIndicador(string indicatorName){
   int numeroIndicadoresConEsteNombre = 0;
   long  chartId = ChartID();
   int numeroWindows = WindowsTotal();
   
   for(int v=0; v<=numeroWindows; v++){
      int numeroIndicadores = ChartIndicatorsTotal(chartId,v);
   
      for(int i=0; i<numeroIndicadores ; i++){
         if(indicatorName==ChartIndicatorName(chartId, v, i)){
            numeroIndicadoresConEsteNombre += 1;
         }
      }
   }
   return (numeroIndicadoresConEsteNombre-1);
}

void limpiaIndicador(string indicatorName){
   long  chartId = ChartID();
   int numeroWindows = WindowsTotal();
   
   for(int v=0; v<=numeroWindows; v++){
      if(indicatorName!="Hot Keys Passion"){
         ChartIndicatorDelete(chartId, v, indicatorName);
         return;
      }
   }
}
