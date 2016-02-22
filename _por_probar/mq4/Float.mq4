//+------------------------------------------------------------------+
//|                                                        float.mq4 |
//|                                       Copyright © 2005, Rachamim |
//+------------------------------------------------------------------+                                                                  |

#property copyright "Copyright © 2005, Rachamim"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Blue   //histo
#property indicator_color2 Red    //signal
#property indicator_level1 0
//---- input parameters
extern int       float=50;
extern int       sh=1;
//---- buffers
double vol[];
double hi[];

int prevbars;
   double cumulativeV,FLOATV,high_bar,low_bar,swing;
   int bars_high, bars_low, swing_time,cvstart,cvend,cvstarto,cvendo;
   int i,shift;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(0,vol);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,hi);
   SetIndexLabel(0,"float");
   for (int i=0;i<=Bars-1;i++) {
      vol[i]=0;
      hi[i]=0;
   }

   IndicatorShortName("float("+float+")");
//----
   return(0);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()  {

   for (i=sh;i>=sh;i--)  {
		cumulativeV=0;
		FLOATV=0;
		//find bar counts
		bars_high = Highest(NULL,0,MODE_HIGH,float,i);
		bars_low = Lowest(NULL,0,MODE_LOW,float,i);
		//find high and low
		high_bar = High[bars_high];
		low_bar = Low[bars_low];
		//find swing price differance
		swing = high_bar-low_bar;
		//find float time barcount
		swing_time = MathAbs(bars_low-bars_high);
		
		//find cumulative volume for float period
		if (bars_high < bars_low) {
			cvstart=bars_low;
			cvend=bars_high;
		} else {
			cvstart=bars_high;
			cvend=bars_low;
		}
		if (cvstart != cvstarto || cvend!=cvendo) {
			cvstarto=cvstart;
			cvendo=cvend;
			for (shift = cvstart; shift>=cvend; shift--) {
				FLOATV=FLOATV+Volume[shift];
			}
			//first1 = False;
			
			//find cumulative volume since last turnover
			for (shift = cvstart; shift>=i; shift--) {
				cumulativeV=cumulativeV+Volume[shift];
				
				if (cumulativeV>=FLOATV)
					cumulativeV=0;
				
				//SetIndexValue(shift,cumulativeV*0.001);//RoyalBlue
				vol[shift]=cumulativeV*0.001;
				//SetIndexValue2(shift,FLOATV*0.001);//Red
				hi[shift]=FLOATV*0.001;
				
				string comm1=
					"high was   "+bars_high+"  bars ago";
				string comm2=
					"Low was    "+bars_low+" bars ago";
				string comm3=
					"Float time was  =      "+ swing_time+" bars";
				string comm4=
					"Float Vol. left    =     "+DoubleToStr(FLOATV-cumulativeV,0);
				string comm5=
					"Float Volume    =     "+DoubleToStr(FLOATV,0);

				ObjectDelete("Comment1");
   			ObjectCreate("Comment1",OBJ_TEXT,0,Time[15],low_bar,);
   			ObjectSetText("Comment1",comm1,8,"Arial",Purple);
				ObjectDelete("Comment2");
   			ObjectCreate("Comment2",OBJ_TEXT,0,Time[15],low_bar-0.0005,);
   			ObjectSetText("Comment2",comm2,8,"Arial",Purple);
				ObjectDelete("Comment3");
   			ObjectCreate("Comment3",OBJ_TEXT,0,Time[15],low_bar-0.0010,);
   			ObjectSetText("Comment3",comm3,8,"Arial",Purple);
				ObjectDelete("Comment4");
   			ObjectCreate("Comment4",OBJ_TEXT,0,Time[15],low_bar-0.0015,);
   			ObjectSetText("Comment4",comm4,8,"Arial",Purple);
				ObjectDelete("Comment5");
   			ObjectCreate("Comment5",OBJ_TEXT,0,Time[15],low_bar-0.0020,);
   			ObjectSetText("Comment5",comm5,8,"Arial",Purple);


				
				//ObjectsDeleteAll(0);
				ObjectDelete("swingtop");
				ObjectDelete("swingbottom");
				ObjectDelete("CVSTART");
				ObjectDelete("CVEND");
				ObjectDelete("swingend");
				ObjectDelete("swingend2");
				ObjectDelete("swingend3");
				ObjectDelete("swingend4");
				ObjectDelete("swingend5");
				ObjectDelete("swingend6");
				ObjectDelete("swingend7");
				ObjectDelete("swingend8");
				ObjectDelete("swingend9");
				
				ObjectCreate("swingtop",OBJ_TREND,0,Time[cvstart],high_bar,Time[1],high_bar);
				ObjectSet("swingtop",OBJPROP_COLOR,RoyalBlue);
				ObjectSet("swingtop",OBJPROP_STYLE,STYLE_SOLID);
				ObjectCreate("swingbottom",OBJ_TREND,0,Time[cvstart],low_bar,Time[1],low_bar);
				ObjectSet("swingbottom",OBJPROP_COLOR,RoyalBlue);
				ObjectSet("swingbottom",OBJPROP_STYLE,STYLE_SOLID);
				
				//vert. float lines. these draw the lines that calculate the float
				//if you change "trendline" to "Vline" it will draw through oscillators too.might be fun
				ObjectCreate("CVSTART",OBJ_TREND,0,Time[cvstart],high_bar,Time[cvstart],low_bar);
				ObjectSet("CVSTART",OBJPROP_COLOR,RoyalBlue);
				ObjectSet("CVSTART",OBJPROP_STYLE,STYLE_SOLID);
				ObjectCreate("CVEND",OBJ_TREND,0,Time[cvend],high_bar,Time[cvend],low_bar);
				ObjectSet("CVSTART",OBJPROP_COLOR,RoyalBlue);
				ObjectSet("CVSTART",OBJPROP_STYLE,STYLE_SOLID);

			
				
				//vert float predictions. These are only time based.
				//see RoyalBlue histogram for real float values.
				//if you change "trendline" to "Vline" it will draw through oscillators too.might be fun
				if (cvend-swing_time>0 ) {
					ObjectCreate("swingend",OBJ_TREND,0,Time[(cvend-swing_time)+5],high_bar,Time[cvend-swing_time+5],low_bar);
				   ObjectSet("swingend",OBJPROP_COLOR,Green);
				   ObjectSet("swingend",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend");
				if (cvend-(swing_time*2)>0 ) {
					ObjectCreate("swingend2",OBJ_TREND,0,Time[(cvend-(swing_time*2))+5],high_bar,Time[cvend-(swing_time*2)+5],low_bar);
				   ObjectSet("swingend2",OBJPROP_COLOR,Green);
				   ObjectSet("swingend2",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend2");
				if (cvend-(swing_time*3)>0 ) {
					ObjectCreate("swingend3",OBJ_TREND,0,Time[(cvend-(swing_time*3))+5],high_bar,Time[cvend-(swing_time*3)+5],low_bar);
				   ObjectSet("swingend3",OBJPROP_COLOR,Green);
				   ObjectSet("swingend3",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend3");
				if (cvend-(swing_time*4)>0 ) {
					ObjectCreate("swingend4",OBJ_TREND,0,Time[(cvend-(swing_time*4))+5],high_bar,Time[cvend-(swing_time*4)+5],low_bar);
				   ObjectSet("swingend4",OBJPROP_COLOR,Green);
				   ObjectSet("swingend4",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend4");
				if (cvend-(swing_time*5)>0 ) {
					ObjectCreate("swingend5",OBJ_TREND,0,Time[(cvend-(swing_time*5))+5],high_bar,Time[cvend-(swing_time*5)+5],low_bar);
				   ObjectSet("swingend5",OBJPROP_COLOR,Green);
				   ObjectSet("swingend5",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend5");
				if (cvend-(swing_time*6)>0 ) {
					ObjectCreate("swingend6",OBJ_TREND,0,Time[cvend-(swing_time*6)+5],high_bar,Time[cvend-(swing_time*6)+5],low_bar);
				   ObjectSet("swingend6",OBJPROP_COLOR,Green);
				   ObjectSet("swingend6",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend6");
				if (cvend-(swing_time*7)>0 ) {
					ObjectCreate("swingend7",OBJ_TREND,0,Time[cvend-(swing_time*7)+5],high_bar,Time[cvend-(swing_time*7)+5],low_bar);
				   ObjectSet("swingend7",OBJPROP_COLOR,Green);
				   ObjectSet("swingend7",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend7");
				if (cvend-(swing_time*8)>0 ) {
					ObjectCreate("swingend8",OBJ_TREND,0,Time[cvend-(swing_time*8)+5],high_bar,Time[cvend-(swing_time*8)+5],low_bar);
				   ObjectSet("swingend8",OBJPROP_COLOR,Green);
				   ObjectSet("swingend8",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend8");
				if (cvend-(swing_time*9)>0 ) {
					ObjectCreate("swingend9",OBJ_TREND,0,Time[cvend-(swing_time*9)+5],high_bar,Time[cvend-(swing_time*9)+5],low_bar);
				   ObjectSet("swingend9",OBJPROP_COLOR,Green);
				   ObjectSet("swingend9",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend9");

			}
		}
	}

   return(0);
}
//+------------------------------------------------------------------+