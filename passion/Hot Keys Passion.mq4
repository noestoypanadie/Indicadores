//+------------------------------------------------------------------
//| MyHotKeys.mq4 
//|
//| Z -> bajar de TimeFrame
//| X -> subir de TimeFrame
//| 1 -> Aplicar template Limpia.tpl
//| 2 -> Aplicar template tripleMedia.tpl
//| 4 -> Quitar indicador 4 medias moviles
//| A -> Quitar todos los indicadores
//| B -> ??
//| C -> Rotar color de fondo
//|                                         
//+------------------------------------------------------------------
#property version   "1.00"
#property strict
#property indicator_chart_window
#import "user32.dll"
  int RegisterWindowMessageW(string MessageName);
  int PostMessageW(int hwnd, int msg, int wparam, char &Name[]);
#import

//#define KEY_NUMPAD_5       12
//#define KEY_LEFT           37
//#define KEY_UP             38
//#define KEY_RIGHT          39
//#define KEY_DOWN           40
//#define KEY_NUMLOCK_DOWN   98
//#define KEY_NUMLOCK_LEFT  100
//#define KEY_NUMLOCK_5     101
//#define KEY_NUMLOCK_RIGHT 102
//#define KEY_NUMLOCK_UP    104

//static bool ctrl_pressed = false;

int colorFondoIndex = 0;
//http://www.w3schools.com/colors/colors_picker.asp
#property indicator_color1 0xe6f5ff
#property indicator_color2 0xfffae6
#property indicator_color3 0xffe6e6

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//   if (id == CHARTEVENT_KEYDOWN) {
//     if (ctrl_pressed == false && lparam == 17) {
//         ctrl_pressed = true;
//      } else if (ctrl_pressed == true) {
//         if (lparam == 74) {
//            Print ("ctrl + j pressed");
//            ctrl_pressed = false;
//         } else {
//            ctrl_pressed = false;   
//         }
//      }
//   }
   if (id == CHARTEVENT_KEYDOWN) {
      if(lparam == 90){          // Z -> bajar de TimeFrame
         disminuyeTimeFrame();
      } else if(lparam == 88){   // X -> subir de TimeFrame
         aumentaTimeFrame();
      } else if(lparam == 49){   // 1 -> Aplicar template Limpia.tpl
        ChartApplyTemplate(0,"Limpia.tpl");
      } else if(lparam == 50){   // 2 -> Aplicar template tripleMedia.tpl
         ChartApplyTemplate(0,"tripleMedia.tpl");
      } else if(lparam == 52){   // 4 -> Quitar indicador 4 medias moviles
         limpiaIndicador("4 Moving Averages Passion");
      } else if(lparam == 65){   // A -> Quitar todos los indicadores
         limpiaIndicadores();
      } else if(lparam == 66){   // B -> ??
         hectorSetupChart();
      } else if(lparam == 67){   // C -> Rotar color de fondo
         cambiarColorFondo();
      } else if(lparam == 82){   // R -> Quitar indicador Round Number
         limpiaIndicador("Round Numbers Passion");
      }
   }
}

void cambiarColorFondo(){
	if ( ObjectFind( "backgroundColor" ) == -1 ){
		ObjectCreate( "backgroundColor", OBJ_LABEL, 0, 0, 0 );      
		ObjectSet( "backgroundColor", OBJPROP_XDISTANCE, 0 );
		ObjectSet( "backgroundColor", OBJPROP_YDISTANCE, 0 );  
		ObjectSet( "backgroundColor", OBJPROP_CORNER, 0 );    
		ObjectSet( "backgroundColor", OBJPROP_BACK, true );    
  	}
  	if(colorFondoIndex == 0){
		ObjectSetText( "backgroundColor", "ggg", 600, "Webdings", indicator_color1 );
		colorFondoIndex = 1;
	} else if(colorFondoIndex == 1){
		ObjectSetText( "backgroundColor", "ggg", 600, "Webdings", indicator_color2 );
		colorFondoIndex = 2;
	} else if(colorFondoIndex == 2){
		ObjectSetText( "backgroundColor", "ggg", 600, "Webdings", indicator_color3 );
		colorFondoIndex = 3;
	} else if(colorFondoIndex == 3){
		ObjectSetText( "backgroundColor", "ggg", 600, "Webdings", White );
		colorFondoIndex = 0;
	}
}
//+------------------------------------------------------------------+

void hectorSetupChart(){
   long  chartId = ChartID();
   
   
   string name = "Fibos";
   uchar name2[256];
   StringToCharArray(name , name2);
   
   int hWnd = WindowHandle(Symbol(), Period());
   int MessageNumber = RegisterWindowMessageW("MetaTrader4_Internal_Message");
   Print("........"+CharArrayToString(name2));
   int r = PostMessageW(hWnd, MessageNumber, 15, name2);
}

void limpiaIndicador(string indicatorName){
   long  chartId = ChartID();
   int numeroWindows = WindowsTotal();
   
   for(int v=0; v<=numeroWindows; v++){
      int numeroIndicadores = ChartIndicatorsTotal(chartId,v);
   
      for(int i=0; i<numeroIndicadores ; i++){
         if(indicatorName!="Hot Keys Passion"){
            Print("Quitamos indicador "+indicatorName);
            ChartIndicatorDelete(chartId, v, indicatorName);
         }
      }
   }
}

void limpiaIndicadores(){ //TODO Queda definir qué indicadores se van a quedar siempre. P.ej. el MyHotKeys
   long  chartId = ChartID();
   
   int numeroWindows = WindowsTotal();
   
   for(int v=0; v<=numeroWindows; v++){ 
   
      int numeroIndicadores = ChartIndicatorsTotal(chartId,v);
   
      for(int  i=0; i<numeroIndicadores ; i++){
         string indicatorName = ChartIndicatorName(chartId, v, i);
         if(indicatorName!="Hot Keys Passion" && indicatorName!="FINAL3.CustomIndicators4.3SMATrendFilterPro"){
            ChartIndicatorDelete(chartId, v, indicatorName);
         }
      }
   }
}

void aumentaTimeFrame(){
   int periodo =Period();
   ENUM_TIMEFRAMES nuevoPeriodo = PERIOD_M5;
   
   if(periodo == PERIOD_M1){
      nuevoPeriodo = PERIOD_M5;
   } else if(periodo == PERIOD_M5){
      nuevoPeriodo = PERIOD_M15;
   } else if(periodo == PERIOD_M15){
      nuevoPeriodo = PERIOD_M30;
   } else if(periodo == PERIOD_M30){
      nuevoPeriodo = PERIOD_H1;
   } else if(periodo == PERIOD_H1){
      nuevoPeriodo = PERIOD_H4;
   } else if(periodo == PERIOD_H4){
      nuevoPeriodo = PERIOD_D1;
   } else if(periodo == PERIOD_D1){
      nuevoPeriodo = PERIOD_W1;
   } else if(periodo == PERIOD_W1){
      nuevoPeriodo = PERIOD_MN1;
   } else if(periodo == PERIOD_MN1){
      nuevoPeriodo = PERIOD_M1;
   }

   long  chartId = ChartID();
   ChartSetSymbolPeriod(chartId, ChartSymbol(chartId), nuevoPeriodo);
}

void disminuyeTimeFrame(){
   int periodo =Period();
   ENUM_TIMEFRAMES nuevoPeriodo = PERIOD_M5;
   
   if(periodo == PERIOD_MN1){
      nuevoPeriodo = PERIOD_W1;
   } else if(periodo == PERIOD_W1){
      nuevoPeriodo = PERIOD_D1;
   } else if(periodo == PERIOD_D1){
      nuevoPeriodo = PERIOD_H4;
   } else if(periodo == PERIOD_H4){
      nuevoPeriodo = PERIOD_H1;
   } else if(periodo == PERIOD_H1){
      nuevoPeriodo = PERIOD_M30;
   } else if(periodo == PERIOD_M30){
      nuevoPeriodo = PERIOD_M15;
   } else if(periodo == PERIOD_M15){
      nuevoPeriodo = PERIOD_M5;
   } else if(periodo == PERIOD_M5){
      nuevoPeriodo = PERIOD_M1;
   } else if(periodo == PERIOD_M1){
      nuevoPeriodo = PERIOD_MN1;
   }
   
   long  chartId = ChartID();
   ChartSetSymbolPeriod(chartId, ChartSymbol(chartId), nuevoPeriodo);
}