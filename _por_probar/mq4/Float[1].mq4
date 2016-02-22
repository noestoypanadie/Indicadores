//+--------------------------------------------------------------------------------+
//|                Float.mq4                                                       |
//|                Copyright © 2005  Barry Stander  Barry_Stander_4@yahoo.com      |
//|                http://www.4Africa.net/4meta/                                   |
//|                Float                                                           |
//+--------------------------------------------------------------------------------+

#property copyright "Float converted from MT3 to MT4"
#property link      "http://www.4Africa.net/4meta/"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Blue
#property indicator_color2 Red

//   Var    //////////////////////////////////////////////////////////////
extern int float=200,use_fibos=1,Backtesting=0;
string short_name;

double f,c1,high_bar,Low_bar,bars_high,bars_low;
double cumulativeV,FLOATV,cumulativeV2,loopbegin2,swing;
double swingv,loopbegin1,cnt,prevbars;
double newcv,CV,CV2;
double fib23,fib38,fib50,fib62,fib76;
double dinap0,dinap1,dinap2,dinap3,dinap4,dinap5;
double CVL,CVL1,CVL2,CVL3,CVL4;
double Buffer1[];
double Buffer2[];

bool   first = true , first1 = true;

int shift,swing_time;
int cvstart,cvend,bar;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   IndicatorBuffers(2);
   
   ObjectDelete("swingtop");
   ObjectDelete("swingbottom"); 
 
   ObjectDelete( "fib23" );
   ObjectDelete( "fib38" );
   ObjectDelete( "fib50" );
   ObjectDelete( "fib62" );
   ObjectDelete( "fib76" );

   ObjectDelete( "fib23t" );
   ObjectDelete( "fib38t" );
   ObjectDelete( "fib50t" );
   ObjectDelete( "fib62t" );
   ObjectDelete( "fib76t" );

   ObjectDelete( "dinap0" );
   ObjectDelete( "dinap1" );
   ObjectDelete( "dinap2" );
   ObjectDelete( "dinap3" );
   ObjectDelete( "dinap4" );
   ObjectDelete( "dinap5" );

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
      
   short_name="Float";
   IndicatorShortName(short_name);
   SetIndexLabel(0,short_name);
   
   SetIndexStyle(0,DRAW_HISTOGRAM );
   SetIndexBuffer(0,Buffer1);
   SetIndexDrawBegin(0,Buffer1);
   
   SetIndexStyle(1,DRAW_LINE );
   SetIndexBuffer(1,Buffer2);
   SetIndexDrawBegin(1,Buffer2);

   return(0);
  }
  
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+

int deinit()
 {
 
ObjectDelete("swingtop");
ObjectDelete("swingbottom"); 
 
ObjectDelete( "fib23" );
ObjectDelete( "fib38" );
ObjectDelete( "fib50" );
ObjectDelete( "fib62" );
ObjectDelete( "fib76" );

ObjectDelete( "fib23t" );
ObjectDelete( "fib38t" );
ObjectDelete( "fib50t" );
ObjectDelete( "fib62t" );
ObjectDelete( "fib76t" );

ObjectDelete( "dinap0" );
ObjectDelete( "dinap1" );
ObjectDelete( "dinap2" );
ObjectDelete( "dinap3" );
ObjectDelete( "dinap4" );
ObjectDelete( "dinap5" );

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

Comment("");
  return(0);
 }
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+


int start()
  {
   
   int counted_bars=IndicatorCounted();
   if(counted_bars<0) return(-1); // Exit if na data
    
   cumulativeV=0;
   cumulativeV2=0;
   int SetLoopCount=0;
      
   if( Bars < prevbars || Bars-prevbars>1 ) //If 1
   {
    first = True;
    first1 = True;
    prevbars = Bars;
    FLOATV=0;

   if( first )                               //if 2
   {
	loopbegin1 = Bars-float-1;
	loopbegin2 = Bars-float-1;
	first = False;

   loopbegin1 = loopbegin1+1;

for( shift=loopbegin1;shift>=0;shift--)  //  for 1
{

//find high and low
high_bar = High[Highest(NULL,0,MODE_HIGH,float,1)]; 
Low_bar  =  Low[Lowest(NULL,0,MODE_LOW,float,1)]; 

//find bar counts
bars_high = Highest(NULL,0,MODE_HIGH,float,1);
bars_low  = Lowest(NULL,0,MODE_LOW,float,1);

//find swing price differance
swing = High[Highest(NULL,0,MODE_HIGH,float,1)] - Low[Lowest(NULL,0,MODE_LOW,float,1)];

//find float time barcount
swing_time = MathAbs(bars_low-bars_high);

//find cumulative volume for float period
if( bars_high < bars_low )
{
cvstart=bars_low;
cvend=bars_high;
}
else
{
cvstart=bars_high;
cvend=bars_low;
}

if( first1 && FLOATV == 0 )                       //   if   3
{

for( shift=cvstart;shift>=cvend;shift--)
{
FLOATV=FLOATV+Volume[shift];
first1 = False;}
}

}

//find cumulative volume since last turnover
for( shift=cvstart;shift>=0;shift--)         //  for    2
{
cumulativeV=cumulativeV+Volume[shift];

if( cumulativeV >= FLOATV )
{
cumulativeV=0;
}

Buffer1[shift] = cumulativeV*0.001; //Blue
Buffer2[shift] = FLOATV*0.001;      //Red

Comment(
"\n","high was   ",bars_high,"  bars ago",
"\n","Low was    ",bars_low," bars ago","\n",
"\n","Float time was  =      ", swing_time," bars",
"\n","Float Vol. left    =     ",FLOATV-cumulativeV,
"\n","Float Volume    =     ",FLOATV,
);
 ObjectDelete("swingtop");
 ObjectCreate("swingtop", OBJ_TREND  , 0, Time[cvstart],high_bar,Time[1],high_bar);
 ObjectSet("swingtop" , OBJPROP_STYLE, STYLE_SOLID);
 ObjectSet("swingtop" , OBJPROP_COLOR , Blue );
 ObjectSet("swingtop" , OBJPROP_RAY , 0  );
 ObjectSet("swingtop" , OBJPROP_WIDTH , 1 );

 ObjectDelete("swingbottom");
 ObjectCreate("swingbottom", OBJ_TREND , 0, Time[cvstart],Low_bar,Time[1],Low_bar);
 ObjectSet("swingbottom" , OBJPROP_STYLE, STYLE_SOLID);
 ObjectSet("swingbottom" , OBJPROP_COLOR , Blue );
 ObjectSet("swingbottom" , OBJPROP_RAY , 0  );
 ObjectSet("swingbottom"  , OBJPROP_WIDTH , 1 );
 
 //fibos
if( use_fibos == 1 ) 
{
ObjectDelete( "fib23" );
ObjectDelete( "fib38" );
ObjectDelete( "fib50" );
ObjectDelete( "fib62" );
ObjectDelete( "fib76" );

ObjectDelete( "dinap0" );
ObjectDelete( "dinap1" );
ObjectDelete( "dinap2" );
ObjectDelete( "dinap3" );
ObjectDelete( "dinap4" );
ObjectDelete( "dinap5" );

fib23=((high_bar-Low_bar)*0.236)+Low_bar;
fib38=((high_bar-Low_bar)*0.382)+Low_bar;
fib50=((high_bar-Low_bar)/2)+Low_bar;
fib62=((high_bar-Low_bar)*0.618)+Low_bar;
fib76=((high_bar-Low_bar)*0.764)+Low_bar;
dinap0=(Low_bar+fib23)/2;
dinap1=(fib23+fib38)/2;
dinap2=(fib38+fib50)/2;
dinap3=(fib50+fib62)/2;
dinap4=(fib62+fib76)/2;
dinap5=(high_bar+fib76)/2;

 ObjectCreate("fib23", OBJ_TREND  , 0, Time[cvstart],fib23,Time[1],fib23 );
 ObjectSet("fib23" , OBJPROP_STYLE, STYLE_DASH );
 ObjectSet("fib23" , OBJPROP_COLOR , Green );
 ObjectSet("fib23" , OBJPROP_RAY , 0  );
 ObjectSet("fib23" , OBJPROP_WIDTH , 1 );
 ObjectCreate("fib23t", OBJ_TEXT  , 0, Time[1],fib23  );
 ObjectSetText("fib23t" , "23.6", 8 , "Arial", Green);
 
 ObjectCreate("fib38", OBJ_TREND  , 0, Time[cvstart],fib38,Time[1],fib38 );
 ObjectSet("fib38" , OBJPROP_STYLE, STYLE_DASH );
 ObjectSet("fib38" , OBJPROP_COLOR , Green );
 ObjectSet("fib38" , OBJPROP_RAY , 0  );
 ObjectSet("fib38" , OBJPROP_WIDTH , 1 );
  ObjectCreate("fib38t", OBJ_TEXT  , 0, Time[1],fib38   );
 ObjectSetText("fib38t" , "38.2", 8 , "Arial", Green);
 
 ObjectCreate("fib50", OBJ_TREND  , 0, Time[cvstart],fib50,Time[1],fib50 );
 ObjectSet("fib50" , OBJPROP_STYLE, STYLE_SOLID );
 ObjectSet("fib50" , OBJPROP_COLOR , Red );
 ObjectSet("fib50" , OBJPROP_RAY , 0  );
 ObjectSet("fib50" , OBJPROP_WIDTH , 2 );
 ObjectCreate("fib50t", OBJ_TEXT  , 0, Time[1],fib50  );
 ObjectSetText("fib50t" , "50", 8 , "Arial", Green);

 ObjectCreate("fib62", OBJ_TREND  , 0, Time[cvstart],fib62,Time[1],fib62 );
 ObjectSet("fib62" , OBJPROP_STYLE, STYLE_DASH );
 ObjectSet("fib62" , OBJPROP_COLOR , Green );
 ObjectSet("fib62" , OBJPROP_RAY , 0  );
 ObjectSet("fib62" , OBJPROP_WIDTH , 1 );
 ObjectCreate("fib62t", OBJ_TEXT  , 0, Time[1],fib62  );
 ObjectSetText("fib62t" , "61.8", 8 , "Arial", Green);
 
 ObjectCreate("fib76", OBJ_TREND  , 0, Time[cvstart],fib76,Time[1],fib76 );
 ObjectSet("fib76" , OBJPROP_STYLE, STYLE_DASH );
 ObjectSet("fib76" , OBJPROP_COLOR , Green );
 ObjectSet("fib76" , OBJPROP_RAY , 0  );
 ObjectSet("fib76" , OBJPROP_WIDTH , 1 );
 ObjectCreate("fib76t", OBJ_TEXT  , 0, Time[1],fib76  );
 ObjectSetText("fib76t" , "76.4", 8 , "Arial", Green); 

 ObjectCreate("dinap0", OBJ_TREND  , 0, Time[cvstart],dinap0,Time[1],dinap0 );
 ObjectSet("dinap0" , OBJPROP_STYLE, STYLE_DOT );
 ObjectSet("dinap0" , OBJPROP_COLOR , Red );
 ObjectSet("dinap0" , OBJPROP_RAY , 0  );
 ObjectSet("dinap0" , OBJPROP_WIDTH , 1 );
 
 ObjectCreate("dinap1", OBJ_TREND  , 0, Time[cvstart],dinap1,Time[1],dinap1 );
 ObjectSet("dinap1" , OBJPROP_STYLE, STYLE_DOT );
 ObjectSet("dinap1" , OBJPROP_COLOR , Red );
 ObjectSet("dinap1" , OBJPROP_RAY , 0  );
 ObjectSet("dinap1" , OBJPROP_WIDTH , 1 );
 
 ObjectCreate("dinap2", OBJ_TREND  , 0, Time[cvstart],dinap2,Time[1],dinap2 );
 ObjectSet("dinap2" , OBJPROP_STYLE, STYLE_DOT );
 ObjectSet("dinap2" , OBJPROP_COLOR , Red );
 ObjectSet("dinap2" , OBJPROP_RAY , 0  );
 ObjectSet("dinap2" , OBJPROP_WIDTH , 1 );
 
 ObjectCreate("dinap3", OBJ_TREND  , 0, Time[cvstart],dinap3,Time[1],dinap3 );
 ObjectSet("dinap3" , OBJPROP_STYLE, STYLE_DOT );
 ObjectSet("dinap3" , OBJPROP_COLOR , Red );
 ObjectSet("dinap3" , OBJPROP_RAY , 0  );
 ObjectSet("dinap3" , OBJPROP_WIDTH , 1 );
 
 ObjectCreate("dinap4", OBJ_TREND  , 0, Time[cvstart],dinap4,Time[1],dinap4 );
 ObjectSet("dinap4" , OBJPROP_STYLE, STYLE_DOT );
 ObjectSet("dinap4" , OBJPROP_COLOR , Red );
 ObjectSet("dinap4" , OBJPROP_RAY , 0  );
 ObjectSet("dinap4" , OBJPROP_WIDTH , 1 );
 
 ObjectCreate("dinap5", OBJ_TREND  , 0, Time[cvstart],dinap5,Time[1],dinap5 );
 ObjectSet("dinap5" , OBJPROP_STYLE, STYLE_DOT );
 ObjectSet("dinap5" , OBJPROP_COLOR , Red );
 ObjectSet("dinap5" , OBJPROP_RAY , 0  );
 ObjectSet("dinap5" , OBJPROP_WIDTH , 1 );
 
}
else
{
ObjectDelete( "fib23" );
ObjectDelete( "fib38" );
ObjectDelete( "fib50" );
ObjectDelete( "fib62" );
ObjectDelete( "fib76" );

ObjectDelete( "dinap0" );
ObjectDelete( "dinap1" );
ObjectDelete( "dinap2" );
ObjectDelete( "dinap3" );
ObjectDelete( "dinap4" );
ObjectDelete( "dinap5" );
}

//vert. float lines. these draw the lines that calculate the float
//if you change "trendline" to "Vline" it will draw through oscillators too.might be fun
 ObjectDelete("CVSTART");
 ObjectCreate("CVSTART", OBJ_TREND  , 0, Time[cvstart],high_bar,Time[cvstart],Low_bar*Point);
 ObjectSet("CVSTART" , OBJPROP_STYLE, STYLE_SOLID);
 ObjectSet("CVSTART" , OBJPROP_COLOR , Blue );
 ObjectSet("CVSTART" , OBJPROP_RAY , 0  );
 ObjectSet("CVSTART" , OBJPROP_WIDTH , 1 );

 ObjectDelete("CVEND");
 ObjectCreate("CVEND", OBJ_TREND , 0, Time[cvend],high_bar,Time[cvend],Low_bar*Point);
 ObjectSet("CVEND" , OBJPROP_STYLE, STYLE_SOLID);
 ObjectSet("CVEND" , OBJPROP_COLOR , Blue );
 ObjectSet("CVEND" , OBJPROP_RAY , 0  );
 ObjectSet("CVEND" , OBJPROP_WIDTH , 1 );

//vert float predictions. These are only time based.
//see blue histogram for real float values.
//if you change "trendline" to "Vline" it will draw through oscillators too.might be fun
if ( cvend-swing_time > 0 )
{
 ObjectDelete("swingend");
 ObjectCreate("swingend", OBJ_TREND , 0, Time[(cvend-swing_time)+5],high_bar,Time[cvend-swing_time+5],Low_bar);
 ObjectSet("swingend" , OBJPROP_STYLE, STYLE_DOT);
 ObjectSet("swingend" , OBJPROP_COLOR , Red );
 ObjectSet("swingend" , OBJPROP_RAY , 0  );
 ObjectSet("swingend" , OBJPROP_WIDTH , 1 );
}
else ObjectDelete("swingend");


if( cvend-(swing_time*2)>0 )
{
 ObjectDelete("swingend2");
 ObjectCreate("swingend2", OBJ_TREND , 0, Time[(cvend-(swing_time*2))+5],high_bar,Time[cvend-(swing_time*2)+5],Low_bar);
 ObjectSet("swingend2" , OBJPROP_STYLE, STYLE_DOT);
 ObjectSet("swingend2" , OBJPROP_COLOR , Red );
 ObjectSet("swingend2", OBJPROP_RAY , 0  );
 ObjectSet("swingend2" , OBJPROP_WIDTH , 1 );
}
else ObjectDelete("swingend2");


if( cvend-(swing_time*3)>0 )
{
 ObjectDelete("swingend3");
 ObjectCreate("swingend3", OBJ_TREND , 0, Time[(cvend-(swing_time*3))+5],high_bar,Time[cvend-(swing_time*3)+5],Low_bar);
 ObjectSet("swingend3" , OBJPROP_STYLE, STYLE_DOT);
 ObjectSet("swingend3" , OBJPROP_COLOR , Red );
 ObjectSet("swingend3", OBJPROP_RAY , 0  );
 ObjectSet("swingend3" , OBJPROP_WIDTH , 1 );
}
else ObjectDelete("swingend3");

if( cvend-(swing_time*4)>0 )
{
 ObjectDelete("swingend4");
 ObjectCreate("swingend4", OBJ_TREND , 0, Time[(cvend-(swing_time*4))+5],high_bar,Time[cvend-(swing_time*4)+5],Low_bar);
 ObjectSet("swingend4" , OBJPROP_STYLE, STYLE_DOT);
 ObjectSet("swingend4" , OBJPROP_COLOR , Red );
 ObjectSet("swingend4", OBJPROP_RAY , 0  );
 ObjectSet("swingend4" , OBJPROP_WIDTH , 1 );
}
else ObjectDelete("swingend4");

if( cvend-(swing_time*5)>0 )
{
 ObjectDelete("swingend5");
 ObjectCreate("swingend5", OBJ_TREND , 0, Time[(cvend-(swing_time*5))+5],high_bar,Time[cvend-(swing_time*5)+5],Low_bar);
 ObjectSet("swingend5" , OBJPROP_STYLE, STYLE_DOT);
 ObjectSet("swingend5" , OBJPROP_COLOR , Red );
 ObjectSet("swingend5", OBJPROP_RAY , 0  );
 ObjectSet("swingend5" , OBJPROP_WIDTH , 1 );
}
else ObjectDelete("swingend5");

if( cvend-(swing_time*6)>0 )
{
 ObjectDelete("swingend6");
 ObjectCreate("swingend6", OBJ_TREND , 0, Time[cvend-(swing_time*6)+5],high_bar,Time[cvend-(swing_time*6)+5],Low_bar);
 ObjectSet("swingend6" , OBJPROP_STYLE, STYLE_DOT);
 ObjectSet("swingend6" , OBJPROP_COLOR , Red );
 ObjectSet("swingend6", OBJPROP_RAY , 0  );
 ObjectSet("swingend6" , OBJPROP_WIDTH , 1 );
}
else ObjectDelete("swingend6");

if( cvend-(swing_time*7)>0 )
{
 ObjectDelete("swingend7");
 ObjectCreate("swingend7", OBJ_TREND , 0, Time[cvend-(swing_time*7)+5],high_bar,Time[cvend-(swing_time*7)+5],Low_bar);
 ObjectSet("swingend7" , OBJPROP_STYLE, STYLE_DOT);
 ObjectSet("swingend7" , OBJPROP_COLOR , Red );
 ObjectSet("swingend7", OBJPROP_RAY , 0  );
 ObjectSet("swingend7" , OBJPROP_WIDTH , 1 );
}
else ObjectDelete("swingend7");

if( cvend-(swing_time*8)>0 )
{
 ObjectDelete("swingend8");
 ObjectCreate("swingend8", OBJ_TREND , 0, Time[cvend-(swing_time*8)+5],high_bar,Time[cvend-(swing_time*8)+5],Low_bar);
 ObjectSet("swingend8" , OBJPROP_STYLE, STYLE_DOT);
 ObjectSet("swingend8" , OBJPROP_COLOR , Red );
 ObjectSet("swingend8", OBJPROP_RAY , 0  );
 ObjectSet("swingend8" , OBJPROP_WIDTH , 1 );
}
else ObjectDelete("swingend8");

if( cvend-(swing_time*9)>0 )
{
 ObjectDelete("swingend9");
 ObjectCreate("swingend9", OBJ_TREND , 0, Time[cvend-(swing_time*9)+5],high_bar,Time[cvend-(swing_time*9)+5],Low_bar);
 ObjectSet("swingend9" , OBJPROP_STYLE, STYLE_DOT);
 ObjectSet("swingend9" , OBJPROP_COLOR , Red );
 ObjectSet("swingend9", OBJPROP_RAY , 0  );
 ObjectSet("swingend9" , OBJPROP_WIDTH , 1 );
}
else ObjectDelete("swingend9");



//comment out anything you"re not using it will help with speed.
if( Backtesting == 1 )
{
GlobalVariableSet("fib23",fib23);
GlobalVariableSet("fib38",fib38);
GlobalVariableSet("fib50",fib50);
GlobalVariableSet("fib62",fib62);
GlobalVariableSet("fib76",fib76);
GlobalVariableSet("dinap0",dinap0);
GlobalVariableSet("dinap1",dinap1);
GlobalVariableSet("dinap2",dinap2);
GlobalVariableSet("dinap3",dinap3);
GlobalVariableSet("dinap4",dinap4);
GlobalVariableSet("dinap5",dinap5);
GlobalVariableSet("swingtop",high_bar);
GlobalVariableSet("swingbottom",Low_bar);
GlobalVariableSet("CVSTART",cvstart);
GlobalVariableSet("CVEND",cvend);
GlobalVariableSet("FLOATV",FLOATV);
GlobalVariableSet("cumulativeV",cumulativeV);
GlobalVariableSet("swing_time",swing_time);
GlobalVariableSet("bars_high",bars_high);
GlobalVariableSet("bars_low",bars_low);

if( cvend-swing_time>0 )
GlobalVariableSet("swingend",(cvend-swing_time)+5);

if( cvend-(swing_time*2)>0 )
GlobalVariableSet("swingend2",cvend-(swing_time*2)+5);

if( cvend-(swing_time*3)>0 )
GlobalVariableSet("swingend3",cvend-(swing_time*3)+5);

if( cvend-(swing_time*4)>0 )
GlobalVariableSet("swingend4",cvend-(swing_time*4)+5);

if( cvend-(swing_time*5)>0 )
GlobalVariableSet("swingend5",cvend-(swing_time*5)+5);

if( cvend-(swing_time*6)>0 )
GlobalVariableSet("swingend6",cvend-(swing_time*6)+5);

if( cvend-(swing_time*7)>0 )
GlobalVariableSet("swingend7",cvend-(swing_time*7)+5);

if( cvend-(swing_time*8)>0 )
GlobalVariableSet("swingend8",cvend-(swing_time*8)+5);

if( cvend-(swing_time*9)>0 )
GlobalVariableSet("swingend9",cvend-(swing_time*9)+5);
 
}  //   end  Backtesting
     
    
   }
  }
 }
 return(0);
}
  

