#property copyright "Copyright 2006, Davi Chan"

// declaração de variáveis definidas
#property indicator_buffers 1
#property indicator_separate_window
#property indicator_color1 Lime

// declaração de variáveis
extern int periodos = 12;
double medidor_operacoes = 0;
double buffer_indicador[];
int i;

//extern int maxbars = 0; //maxbars limita quando não estiver no modo teste.
int maxbars;

int init()
{
//   if(IsTesting())
 //    maxbars = Bars;
//	else
//	  maxbars = 500;
	  
	SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1);
	SetIndexBuffer(0, buffer_indicador);
	SetLevelValue(0,0.0);
	return(0);
}

int start()
{

	int inicio;   	
	double roc_GBP, roc_EUR, roc_JPY, roc_CHF, roc;	
	int counted_bars=IndicatorCounted();
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
   int limit=Bars-counted_bars;
   
   for(int i=0; i<limit; i++)
   
   {
			roc = 0;			
			roc_GBP = ( iClose("GBPUSD", 0, i) - iClose("GBPUSD", 0, periodos+i)  )/ iClose("GBPUSD", 0, periodos+i) ;	
	      roc_EUR = (iClose("EURUSD", 0, i) - iClose("EURUSD", 0, periodos+i))/iClose("EURUSD", 0, periodos+i);	
	      //inversão dos valores dessas duas moedas
	      roc_JPY = (1/iClose("USDJPY", 0, i) - 1/iClose("USDJPY", 0, periodos+i)) /(1/iClose("USDJPY", 0, periodos+i));	
	      roc_CHF = (1/iClose("USDCHF", 0, i) - 1/iClose("USDCHF", 0, periodos+i)) /(1/iClose("USDCHF", 0, periodos+i));
	      //inversão dos valores dessas duas moedas
	      
	      roc = (roc_GBP + roc_EUR + roc_JPY + roc_CHF)/4;
	      
			buffer_indicador[i] = roc;			
	}
}

