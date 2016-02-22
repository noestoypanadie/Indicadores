//+-------------------------------------------------------------------+
//|													 MACD Passion.mq4 |
//|														  Victor Diaz |
//|					 	  Based in Euclid's Horizontal Grid Indicator |
//+-------------------------------------------------------------------+
#property indicator_chart_window

// 0 Solid line; 1 Dashed line; 2 Dotted line; 3 Dash-and-dot line; 4 Double dotted dash-and-dot line
extern color  	MajorGridColour=DimGray;
extern int    	MajorGridWidth=1;			
extern int 		MajorGridStyle=2;

extern color  	MinorGridColour=LightGray;
extern int    	MinorGridWidth=1;
extern int    	MinorGridStyle=2;

extern bool   	ChartShift=true;        	//Shift grid with chart
extern int    	MaximumVisibleLines=50; 	//Maximum number of gridlines plotted before indicator shifts spacing up to the next order of magnitude
extern int 		MajorMultiple=10;

double Top=0;
double Bottom=0;
int    Left=0;
int    Width=0;


#define NOMBRE_INDICADOR "Round Numbers Passion"
#define gPREFIX "HGRID"
//gLib constants
#define gSEP " "
#define gHLINE  "HL"
#define gTLINE  "TL"
#define gRPRICE "RP"
#define gWINDOW 0

int yaEstaCargado = 0;

void init()
{
   yaEstaCargado = existeIndicador(NOMBRE_INDICADOR);

   if(yaEstaCargado ==0){
   	if (MajorGridWidth<1){
   		MajorGridStyle=2; 
   		MajorGridWidth=1;
   	}
   	if (MinorGridWidth<1){
   		MinorGridStyle=2; 
   		MinorGridWidth=1;
   	}
   	MajorGridWidth=MathMin(MajorGridWidth,5);
   	MinorGridWidth=MathMin(MinorGridWidth,5); 
	} else {
	   limpiaIndicador(NOMBRE_INDICADOR);
	}
	
}


void deinit()
{
   gClearObjects("","");
}

void start()
{
	if (Top==WindowPriceMax() && Bottom==WindowPriceMin() && Left==WindowFirstVisibleBar() && Width==WindowBarsPerChart()){
		return;
	}
 	Top = WindowPriceMax();
	Bottom = WindowPriceMin();
	Left = WindowFirstVisibleBar();
	Width = WindowBarsPerChart();
  
	double minor=Point;
	while ((Top-Bottom)/minor > MaximumVisibleLines){
		minor*=10;
	}
	double major=minor*MajorMultiple;
  
	gClearObjects("","");
	for (int p=Bottom/major; p<Top/major; p++){
		double gridp=p*major;
		string n=DoubleToStr(gridp,Digits);
		if (ChartShift && Width-Left>2){
			gTLine(n, gridp, gridp, Time[Bars-1], Time[0]+Period()*60, MajorGridColour, MajorGridStyle, true);
			gSetProp(gTLINE, n, OBJPROP_WIDTH, MajorGridWidth);
			gRParrow(n, gridp, Time[0], MajorGridColour);
		} else {
			gHLine(n, gridp, MajorGridColour, MajorGridStyle, false);
			gSetProp(gHLINE, n, OBJPROP_WIDTH, MajorGridWidth);
		}
		for (int i=1; i<MajorMultiple; i++)	{
			gridp+=minor;
			n=DoubleToStr(gridp,Digits);
			gTLine(n, gridp, gridp, Time[Bars-1], Time[0]+Period()*60, MinorGridColour, MinorGridStyle, true);
			if (!ChartShift || Width-Left<=2){
				gSetProp(gTLINE, n, OBJPROP_RAY, true);
			}
			gSetProp(gTLINE, n, OBJPROP_WIDTH, MinorGridWidth);
		}
	}
}
  
//+------------------------------------------------------------------+
//gLib objects functions
//+------------------------------------------------------------------+

void gSetProp(string type, string n, int prop, double val)
{
	n=gName(type,n);
	if (ObjectFind(n)==-1) return;
	ObjectSet(n,prop,val);
}

void gClearObjects(string type, string n)
{
	int obj_num=ObjectsTotal();
	string obj_name;
	n=gName(type,n);
	int i=0;
	while (i<ObjectsTotal()){
		obj_name=ObjectName(i);
		if (StringSubstr(obj_name,0,StringLen(n))==n){
			ObjectDelete(obj_name);
		} else {
			i++;
		}
	}
}

string gName(string type,string n)
{
	if (n==""){
		return(StringConcatenate(gPREFIX,gSEP,type));
	}
	
	return(StringConcatenate(gPREFIX,gSEP,type,gSEP,n));
}
  
void gHLine(string n, double p, int c, int s, bool b)
{
	n=gName(gHLINE, n);
	if (ObjectFind(n)==-1){
		ObjectCreate(n,OBJ_HLINE,gWINDOW,0,p); 
	} else {
		ObjectSet(n,OBJPROP_PRICE1,p); 
	}
	ObjectSet(n,OBJPROP_COLOR,c);
	ObjectSet(n,OBJPROP_STYLE,s);
	ObjectSet(n,OBJPROP_BACK,b);
}

void gTLine(string n, double pl, double ph, datetime tl, datetime th, int c, int s, bool b)
{
	n=gName(gTLINE, n);
	if (ObjectFind(n)==-1){
		ObjectCreate(n,OBJ_TREND,gWINDOW,tl,pl,th,ph); 
	} else{
		ObjectSet(n,OBJPROP_TIME1,tl);
		ObjectSet(n,OBJPROP_PRICE1,pl);
		ObjectSet(n,OBJPROP_TIME2,th);
		ObjectSet(n,OBJPROP_PRICE2,ph);
    }     
	ObjectSet(n,OBJPROP_COLOR,c);
	ObjectSet(n,OBJPROP_STYLE,s);
	ObjectSet(n,OBJPROP_BACK,b);
	ObjectSet(n,OBJPROP_RAY,false);
}

void gRParrow(string n, double p, datetime t, int c)
{
	n=gName(gRPRICE, n);
	if (ObjectFind(n)==-1){
		ObjectCreate(n,OBJ_ARROW,gWINDOW,t,p); 
	} else {
		ObjectSet(n,OBJPROP_PRICE1,p);
		ObjectSet(n,OBJPROP_TIME1,t);
	}
	ObjectSet(n,OBJPROP_ARROWCODE,6);
	ObjectSet(n,OBJPROP_WIDTH,2);
	ObjectSet(n,OBJPROP_COLOR,c);
}

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
