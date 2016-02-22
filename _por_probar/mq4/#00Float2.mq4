//+------------------------------------------------------------------+
//|                                                        float.mq4 |
//|                                       Copyright © 2005, Rachamim |
//+------------------------------------------------------------------+                                                                  |

#property copyright "Copyright © 2005, Rachamim"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 MidnightBlue   //histo
#property indicator_color2 Red    //signal
#property indicator_level1 0
//---- input parameters
extern int       float=75;
extern int       sh=1;
//---- buffers
double vol[];
double hi[];
string short_name;

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
   SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,4);
   SetIndexBuffer(0,vol);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,hi);
   //SetIndexLabel(0,"float");
   for (int i=0;i<=Bars-1;i++) {
      vol[i]=0;
      hi[i]=0;
   }
   IndicatorShortName("FL");//("Float ("+float+") ");
   IndicatorShortName(short_name);
   SetIndexLabel(0,short_name);


   //IndicatorShortName("FLOAT PANEL ("+float+") ");
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
	
	double myFirstValue = high_bar;//High bar Price
	double mySecondValue = low_bar;//High bar Price
	double myThirdValue = bars_high;
	double myFourthValue = bars_low;
	double myFifthValue = FLOATV-cumulativeV;
	double mySixthValue = FLOATV;
	/*			
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
*/
        ObjectDelete("MyLabel101");
        ObjectCreate("MyLabel101", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("MyLabel101",DoubleToStr(myFirstValue,Digits),15, "Arial Bold", SteelBlue);
        ObjectSet("MyLabel101", OBJPROP_CORNER, 0);
        ObjectSet("MyLabel101", OBJPROP_XDISTANCE, 80);
        ObjectSet("MyLabel101", OBJPROP_YDISTANCE, 13);

        ObjectDelete("MyLabel21");
        ObjectCreate("MyLabel21", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("MyLabel21",DoubleToStr(mySecondValue,Digits),15, "Arial Bold", SteelBlue);
        ObjectSet("MyLabel21", OBJPROP_CORNER, 0);
        ObjectSet("MyLabel21", OBJPROP_XDISTANCE, 195);
        ObjectSet("MyLabel21", OBJPROP_YDISTANCE, 13);
        
        ObjectDelete("MyLabel22");
        ObjectCreate("MyLabel22", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("MyLabel22",DoubleToStr(float,Digits-4),12, "Arial Bold", SlateGray);
        ObjectSet("MyLabel22", OBJPROP_CORNER, 0);
        ObjectSet("MyLabel22", OBJPROP_XDISTANCE, 157);
        ObjectSet("MyLabel22", OBJPROP_YDISTANCE, 13);
        
        ObjectCreate("labFL23", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("labFL23","BarHIGH ", 9, "Arial Bold", SteelBlue);
        ObjectSet("labFL23", OBJPROP_CORNER, 0);
        ObjectSet("labFL23", OBJPROP_XDISTANCE, 82);
        ObjectSet("labFL23", OBJPROP_YDISTANCE, 3);
        
        ObjectCreate("labFL24", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("labFL24","BarLOW ", 9, "Arial Bold", SteelBlue);
        ObjectSet("labFL24", OBJPROP_CORNER, 0);
        ObjectSet("labFL24", OBJPROP_XDISTANCE, 195);
        ObjectSet("labFL24", OBJPROP_YDISTANCE, 3);
        
        ObjectCreate("labFL25", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("labFL25","Float", 9, "Arial Bold", SlateGray);
        ObjectSet("labFL25", OBJPROP_CORNER, 0);
        ObjectSet("labFL25", OBJPROP_XDISTANCE, 157);
        ObjectSet("labFL25", OBJPROP_YDISTANCE, 3);
        
        ObjectDelete("labFL26");
        ObjectCreate("labFL26", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("labFL26",DoubleToStr(myThirdValue,Digits-4),9, "Arial Bold", SteelBlue);
        ObjectSet("labFL26", OBJPROP_CORNER, 0);
        ObjectSet("labFL26", OBJPROP_XDISTANCE, 130);
        ObjectSet("labFL26", OBJPROP_YDISTANCE, 3);
        
        ObjectDelete("labFL27");
        ObjectCreate("labFL27", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("labFL27",DoubleToStr(myFourthValue,Digits-4),9, "Arial Bold", SteelBlue);
        ObjectSet("labFL27", OBJPROP_CORNER, 0);
        ObjectSet("labFL27", OBJPROP_XDISTANCE, 245);
        ObjectSet("labFL27", OBJPROP_YDISTANCE, 3);
        
        ObjectDelete("labFL28");
        ObjectCreate("labFL28", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("labFL28",DoubleToStr(myFifthValue,0),12, "Arial Bold", SlateGray);
        ObjectSet("labFL28", OBJPROP_CORNER, 0);
        ObjectSet("labFL28", OBJPROP_XDISTANCE, 330);
        ObjectSet("labFL28", OBJPROP_YDISTANCE, 13);
        
        ObjectDelete("labFL29");
        ObjectCreate("labFL29", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("labFL29",DoubleToStr(mySixthValue,0),12, "Arial Bold", SlateGray);
        ObjectSet("labFL29", OBJPROP_CORNER, 0);
        ObjectSet("labFL29", OBJPROP_XDISTANCE, 270);
        ObjectSet("labFL29", OBJPROP_YDISTANCE, 13);
        
        ObjectCreate("labFL30", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("labFL30","Float Vol", 9, "Arial Bold", SlateGray);
        ObjectSet("labFL30", OBJPROP_CORNER, 0);
        ObjectSet("labFL30", OBJPROP_XDISTANCE, 270);
        ObjectSet("labFL30", OBJPROP_YDISTANCE, 3);
        
        ObjectCreate("labFL31", OBJ_LABEL, WindowFind("FL"), 0, 0);
        ObjectSetText("labFL31","Left", 9, "Arial Bold", SlateGray);
        ObjectSet("labFL31", OBJPROP_CORNER, 0);
        ObjectSet("labFL31", OBJPROP_XDISTANCE, 330);
        ObjectSet("labFL31", OBJPROP_YDISTANCE, 3);
/*

				ObjectDelete("Comment1");
   			ObjectCreate("Comment1",OBJ_TEXT,0,Time[15],low_bar,);
   			ObjectSetText("Comment1",comm1,8,"Verdana",White);
				ObjectDelete("Comment2");
   			ObjectCreate("Comment2",OBJ_TEXT,0,Time[15],low_bar+0.0005,);
   			ObjectSetText("Comment2",comm2,8,"Verdana",White);
				ObjectDelete("Comment3");
   			ObjectCreate("Comment3",OBJ_TEXT,0,Time[15],low_bar+0.0010,);
   			ObjectSetText("Comment3",comm3,8,"Verdana",White);
				ObjectDelete("Comment4");
   			ObjectCreate("Comment4",OBJ_TEXT,0,Time[15],low_bar+0.0015,);
   			ObjectSetText("Comment4",comm4,8,"Verdana",White);
				ObjectDelete("Comment5");
   			ObjectCreate("Comment5",OBJ_TEXT,0,Time[15],low_bar+0.0020,);
   			ObjectSetText("Comment5",comm5,8,"Verdana",White);
*/

				
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
				ObjectSet("swingtop",OBJPROP_COLOR,White);
				ObjectSet("swingtop",OBJPROP_STYLE,STYLE_DOT);
				ObjectSet("swingtop",OBJPROP_WIDTH,1);
				ObjectCreate("swingbottom",OBJ_TREND,0,Time[cvstart],low_bar,Time[1],low_bar);
				ObjectSet("swingbottom",OBJPROP_COLOR,White);
				ObjectSet("swingbottom",OBJPROP_STYLE,STYLE_DOT);
				ObjectSet("swingbottom",OBJPROP_WIDTH,1);
				
				//vert. float lines. these draw the lines that calculate the float
				//if you change "trendline" to "Vline" it will draw through oscillators too.might be fun
				ObjectCreate("CVSTART",OBJ_TREND,0,Time[cvstart],high_bar,Time[cvstart],low_bar);
				ObjectSet("CVSTART",OBJPROP_COLOR,Lime);
				ObjectSet("CVSTART",OBJPROP_STYLE,STYLE_SOLID);
				ObjectSet("CVSTART",OBJPROP_WIDTH,2);
				ObjectCreate("CVEND",OBJ_TREND,0,Time[cvend],high_bar,Time[cvend],low_bar);
				ObjectSet("CVEND",OBJPROP_COLOR,Red);
				ObjectSet("CVEND",OBJPROP_STYLE,STYLE_SOLID);
				ObjectSet("CVEND",OBJPROP_WIDTH,2);
            //ObjectSet("CVSTART",OBJPROP_COLOR,Lime);
				//ObjectSet("CVSTART",OBJPROP_STYLE,STYLE_SOLID);
			
				
				//vert float predictions. These are only time based.
				//see RoyalBlue histogram for real float values.
				//if you change "trendline" to "Vline" it will draw through oscillators too.might be fun
				if (cvend-swing_time>0 ) {
					ObjectCreate("swingend",OBJ_TREND,0,Time[(cvend-swing_time)+5],high_bar,Time[cvend-swing_time+5],low_bar);
				   ObjectSet("swingend",OBJPROP_COLOR,Lime);
				   ObjectSet("swingend",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend");
				if (cvend-(swing_time*2)>0 ) {
					ObjectCreate("swingend2",OBJ_TREND,0,Time[(cvend-(swing_time*2))+5],high_bar,Time[cvend-(swing_time*2)+5],low_bar);
				   ObjectSet("swingend2",OBJPROP_COLOR,Lime);
				   ObjectSet("swingend2",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend2");
				if (cvend-(swing_time*3)>0 ) {
					ObjectCreate("swingend3",OBJ_TREND,0,Time[(cvend-(swing_time*3))+5],high_bar,Time[cvend-(swing_time*3)+5],low_bar);
				   ObjectSet("swingend3",OBJPROP_COLOR,Lime);
				   ObjectSet("swingend3",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend3");
				if (cvend-(swing_time*4)>0 ) {
					ObjectCreate("swingend4",OBJ_TREND,0,Time[(cvend-(swing_time*4))+5],high_bar,Time[cvend-(swing_time*4)+5],low_bar);
				   ObjectSet("swingend4",OBJPROP_COLOR,Lime);
				   ObjectSet("swingend4",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend4");
				if (cvend-(swing_time*5)>0 ) {
					ObjectCreate("swingend5",OBJ_TREND,0,Time[(cvend-(swing_time*5))+5],high_bar,Time[cvend-(swing_time*5)+5],low_bar);
				   ObjectSet("swingend5",OBJPROP_COLOR,Lime);
				   ObjectSet("swingend5",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend5");
				if (cvend-(swing_time*6)>0 ) {
					ObjectCreate("swingend6",OBJ_TREND,0,Time[cvend-(swing_time*6)+5],high_bar,Time[cvend-(swing_time*6)+5],low_bar);
				   ObjectSet("swingend6",OBJPROP_COLOR,Lime);
				   ObjectSet("swingend6",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend6");
				if (cvend-(swing_time*7)>0 ) {
					ObjectCreate("swingend7",OBJ_TREND,0,Time[cvend-(swing_time*7)+5],high_bar,Time[cvend-(swing_time*7)+5],low_bar);
				   ObjectSet("swingend7",OBJPROP_COLOR,Lime);
				   ObjectSet("swingend7",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend7");
				if (cvend-(swing_time*8)>0 ) {
					ObjectCreate("swingend8",OBJ_TREND,0,Time[cvend-(swing_time*8)+5],high_bar,Time[cvend-(swing_time*8)+5],low_bar);
				   ObjectSet("swingend8",OBJPROP_COLOR,Lime);
				   ObjectSet("swingend8",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend8");
				if (cvend-(swing_time*9)>0 ) {
					ObjectCreate("swingend9",OBJ_TREND,0,Time[cvend-(swing_time*9)+5],high_bar,Time[cvend-(swing_time*9)+5],low_bar);
				   ObjectSet("swingend9",OBJPROP_COLOR,Lime);
				   ObjectSet("swingend9",OBJPROP_STYLE,STYLE_DOT);
				}
				else ObjectDelete("swingend9");

			}
		}
	}

   return(0);
}
//+------------------------------------------------------------------+