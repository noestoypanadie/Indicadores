//+------------------------------------------------------------------+
//|     FarhadCrab3.mq4 |
//|     Copyright © 2006, Farhad Farshad |
//|     http://www.fxperz.com
//|     info@farhadfarshad.com
//|     info@fxperz.com
//|     ***** PLEASE NOTE *****
//|     This EA best works on EURUSD 1M TimeFrame. 
//|     For every Run specify your "initialDeposit"(Default amount is 10000$). 
//|     As soon as your profit reaches 5% (maxYield) of your initialDeposit (Usually in one day!) 
//|     The EA will stop and you should run it again with your new initialDeposit.
//|     The best time to run this EA is 00:00 according to your broker server.
//|     But it is possible to run this EA several times a day!
//|     This EA has a powerful 'internal' stoploss so let the stoploss be 0 . 
//|     It's recommended to withdraw everyday profit and trade with your initial deposit.
//|     Please feel free to ask any question.
//|     See my site to be infored about last update and paid EAs of mine.
//|     Enjoy a better automatic investment:) with at least 20% a month.
//|     If you get money from this EA please donate some to poor people of your country.
//+-----------------------------------------------------------------+
#property copyright "Copyright © 2006, Farhad Farshad"
#property link      "http://www.fxperz.com"
#include <stdlib.mqh>

extern double maxLoss        = 30; // Maximum Loss that you can bear in percent
extern double maxYield       = 5; // a number between 0 to 100 (not more than 10 is recommended)
extern double lTakeProfit    = 10;   // recomended  no more than 20
extern double sTakeProfit    = 10;   // recomended  no more than 20
extern double takeProfit     = 10;            // recomended  no more than 20
extern double pr             = 8;      //take profit in sideway markets.
extern double stopLoss       = 0;             // 
extern int magicEA           = 124;        // Magic EA identifier. Allows for several co-existing EA with different input values
extern double lTrailingStop  = 15;   // trail stop in points
extern double sTrailingStop  = 15;   // trail stop in points
extern color clOpenBuy       = Blue;  //Different colors for different positions
extern color clCloseBuy      = Aqua;  //Different colors for different positions
extern color clOpenSell      = Red;  //Different colors for different positions
extern color clCloseSell     = Violet;  //Different colors for different positions
extern color clModiBuy       = Blue;   //Different colors for different positions
extern color clModiSell      = Red;   //Different colors for different positions
extern int Slippage          = 3;
extern double Lots           = 0.1;// you can change the lot but be aware of margin. Its better to trade with 1/4 of your capital. 
extern string nameEA         = "FarhadCrab3.mq4";// To "easy read" which EA place an specific order and remember me forever :)
extern double vVolume;

//pivots
extern bool Alerts = false;
extern int  GMTshift = 0;
extern int LabelShift = 20;
extern int LineShift = 40;
extern bool Pivot = true;
extern color PivotColor = Yellow;
extern color PivotFontColor = White;
extern int PivotFontSize = 12;
extern int PivotWidth = 1;
extern int PipDistance = 20;
extern bool Cams = true;
extern color CamFontColor = White;
extern int CamFontSize = 10;
extern bool Fibs = true;
extern color FibColor = Sienna;
extern color FibFontColor = White;
extern int FibFontSize = 8;
extern bool StandardPivots = true;
extern color StandardFontColor = White;
extern int StandardFontSize = 8;
extern color SupportColor = White;
extern color ResistanceColor = FireBrick;
extern bool MidPivots = true;
extern color MidPivotColor = White;
extern int MidFontSize = 8;


datetime LabelShiftTime, LineShiftTime;
double P, H3, H4, H5;
double L3, L4, L5;
double LastHigh,LastLow,x;
double day_high;
double day_low;
double yesterday_open;
double today_open;
double cur_day;
double prev_day;
bool firstL3=true;
bool firstH3=true;

double D1=0.091667;
double D2=0.183333;
double D3=0.2750;
double D4=0.55;


// Fib variables

double yesterday_high=0;
double yesterday_low=0;
double yesterday_close=0;
double r3=0;
double r2=0;
double r1=0;
double p=0;
double s1=0;
double s2=0;
double s3=0;
double R;

double macdHistCurrent, macdHistPrevious, macdSignalCurrent, macdSignalPrevious, highCurrent, lowCurrent;
double stochHistCurrent, stochHistPrevious, stochSignalCurrent, stochSignalPrevious;
double sarCurrent, sarPrevious,  momCurrent, momPrevious, highCurrentH1, lowCurrentH1;
double maLongCurrent, maShortCurrent, maLongPrevious, maShortPrevious, faRSICurrent, deMark;
double realTP, realSL, faMiddle, faHighest, faLowest, closeCurrent,faCloseM5, closeCurrentD, closePreviousD;
int cnt, ticket;
bool isBuying = false, isSelling = false, isBuyClosing = false, isSellClosing = false;
double initialDeposit; //First of All Specify your initial Deposit.

void init()
{
  initialDeposit = AccountBalance();
}



void deinit() {
if (Fibs)
{ObjectDelete("FibR1 Label"); 
ObjectDelete("FibR1 Line");
ObjectDelete("FibR2 Label");
ObjectDelete("FibR2 Line");
ObjectDelete("FibR3 Label");
ObjectDelete("FibR3 Line");
ObjectDelete("FibS1 Label");
ObjectDelete("FibS1 Line");
ObjectDelete("FibS2 Label");
ObjectDelete("FibS2 Line");
ObjectDelete("FibS3 Label");
ObjectDelete("FibS3 Line");
}
if (Pivot)
{
ObjectDelete("P Label");
ObjectDelete("P Line");
}
if (Cams)
{
ObjectDelete("H5 Label");
ObjectDelete("H5 Line");
ObjectDelete("H4 Label");
ObjectDelete("H4 Line");
ObjectDelete("H3 Label");
ObjectDelete("H3 Line");
ObjectDelete("L3 Label");
ObjectDelete("L3 Line");
ObjectDelete("L4 Label");
ObjectDelete("L4 Line");
ObjectDelete("L5 Label");
ObjectDelete("L5 Line");
}
//----
if (StandardPivots)
{
ObjectDelete("R1 Label"); 
ObjectDelete("R1 Line");
ObjectDelete("R2 Label");
ObjectDelete("R2 Line");
ObjectDelete("R3 Label");
ObjectDelete("R3 Line");
ObjectDelete("S1 Label");
ObjectDelete("S1 Line");
ObjectDelete("S2 Label");
ObjectDelete("S2 Line");
ObjectDelete("S3 Label");
ObjectDelete("S3 Line");
}
if (MidPivots)
{
ObjectDelete("M5 Label");
ObjectDelete("M5 Line");
ObjectDelete("M4 Label");
ObjectDelete("M4 Line");
ObjectDelete("M3 Label");
ObjectDelete("M3 Line");
ObjectDelete("M2 Label");
ObjectDelete("M2 Line");
ObjectDelete("M1 Label");
ObjectDelete("M1 Line");
ObjectDelete("M0 Label");
ObjectDelete("M0 Line");

}
   return(0);
  }

int DoAlerts()
{
   double DifAboveL3,PipsLimit;
   double DifBelowH3;

   DifBelowH3 = H3 - Close[0];
   DifAboveL3 = Close[0] - L3;
   PipsLimit = PipDistance*Point;
   
   if (DifBelowH3 > PipsLimit) firstH3 = true;
   if (DifBelowH3 <= PipsLimit && DifBelowH3 > 0)
   {
    if (firstH3)
    {
      Alert("Below Cam H3 Line by ",DifBelowH3, " for ", Symbol(),"-",Period());
      PlaySound("alert.wav");
      firstH3=false;
    }
   }

   if (DifAboveL3 > PipsLimit) firstL3 = true;
   if (DifAboveL3 <= PipsLimit && DifAboveL3 > 0)
   {
    if (firstL3)
    {
      Alert("Above Cam L3 Line by ",DifAboveL3," for ", Symbol(),"-",Period());
      Sleep(2000);
      PlaySound("timeout.wav");
      firstL3=false;
    }
   }
   


   Comment("");
   
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start() {
// *****This line is for some reason very important. you'd better settle all your account at the end of day.*****

/*if (TimeHour(CurTime())==23 && MathAbs(faMiddle-faHighest)<MathAbs(faMiddle-faLowest))
{
 CloseBuyPositions();
 return(0);
 }
 if (TimeHour(CurTime())==23 && MathAbs(faMiddle-faHighest)>MathAbs(faMiddle-faLowest) )
{
 CloseSellPositions();
 return(0);
 }
*/

//System Stoploss based on LongTerm Moving Average (Fibo  55 day MA)
//StopLoss For Buy Positions (Optional)
//if ((maLongCurrent>closeCurrentD) && (maLongPrevious<closePreviousD) && (maLongCurrent>highCurrentH1)) {
if ((AccountEquity()>(initialDeposit+((maxYield/100)*initialDeposit))) 
|| (AccountBalance()-AccountEquity()>((maxLoss/100)*initialDeposit))
|| ((maLongCurrent>closeCurrentD) && (maLongPrevious<closePreviousD) && (maLongCurrent>highCurrentH1))
){
CloseBuyPositions(); 
 //return(0);
}

//StopLoss For Sell Positions (Optional)
//if ((maLongCurrent<closeCurrentD) && (maLongPrevious>closePreviousD) && (maLongCurrent<lowCurrentH1)) {
if ((AccountEquity()>(initialDeposit+((maxYield/100)*initialDeposit)))
|| (AccountBalance()-AccountEquity()>((maxLoss/100)*initialDeposit))
|| ((maLongCurrent<closeCurrentD) && (maLongPrevious>closePreviousD) && (maLongCurrent<lowCurrentH1))

){

CloseSellPositions();

return(0);
}

int    counted_bars=IndicatorCounted();
//---- TODO: add your code here
double Q=0,S=0,R=0,M2=0,M3=0,S1=0,R1=0,M1=0,M4=0,S2=0,R2=0,M0=0,M5=0,S3=0,R3=0,nQ=0,nD=0,D=0;

int cnt=720;

//---- exit if period is greater than daily charts
if(Period() > 1440)
{
Print("Error - Chart period is greater than 1 day.");
return(-1); // then exit
}

//---- Get new daily prices & calculate pivots
 day_high=0;
 day_low=0;
 yesterday_open=0;
 today_open=0;
 cur_day=0;
 prev_day=0;

while (cnt!= 0)
{
	if (TimeDayOfWeek(Time[cnt]) == 0)
	{
     cur_day = prev_day;
	}
	else
	{
     cur_day = TimeDay(Time[cnt]- (GMTshift*3600));
	}
	
	if (prev_day != cur_day)
	{
		yesterday_close = Close[cnt+1];
		today_open = Open[cnt];
		yesterday_high = day_high;
		yesterday_low = day_low;

		day_high = High[cnt];
		day_low  = Low[cnt];

		prev_day = cur_day;
	}
   
   if (High[cnt]>day_high)
   {
      day_high = High[cnt];
   }
   if (Low[cnt]<day_low)
   {
      day_low = Low[cnt];
   }
	
	cnt--;

}



D = (day_high - day_low);
Q = (yesterday_high - yesterday_low);
//------ Pivot Points ------

P = (yesterday_high + yesterday_low + yesterday_close)/3;//Pivot

if (Cams)
{
//---- To display all 8 Camarilla pivots remove comment symbols below and
// add the appropriate object functions below
H5 = (yesterday_high - yesterday_low)*yesterday_close;
H4 = ((yesterday_high - yesterday_low)* D4) + yesterday_close;
H3 = ((yesterday_high - yesterday_low)* D3) + yesterday_close;
//H2 = ((yesterday_high - yesterday_low) * D2) + yesterday_close;
//H1 = ((yesterday_high - yesterday_low) * D1) + yesterday_close;

//L1 = yesterday_close - ((yesterday_high - yesterday_low)*(D1));
//L2 = yesterday_close - ((yesterday_high - yesterday_low)*(D2));
L3 = yesterday_close - ((yesterday_high - yesterday_low)*(D3));
L4 = yesterday_close - ((yesterday_high - yesterday_low)*(D4));
L5 = yesterday_close - (H5 - yesterday_close);
}

if (Fibs)
{
      R = yesterday_high - yesterday_low;//range
      p = (yesterday_high + yesterday_low + yesterday_close)/3;// Standard Pivot
      r1 = p + (R * 0.38);
      r2 = p + (R * 0.62);
      r3 = p + (R * 0.99);
      s1 = p - (R * 0.38);
      s2 = p - (R * 0.62);
      s3 = p - (R * 0.99);
}

if (StandardPivots)
{
R1 = (2*P)-yesterday_low;
S1 = (2*P)-yesterday_high;
R2 = P-S1+R1;
S2 = P-R1+S1;
R3 = (2*P)+(yesterday_high-(2*yesterday_low));
S3 = (2*P)-((2* yesterday_high)-yesterday_low);
}
if (MidPivots && StandardPivots)
{
M0 = (S2+S3)/2;
M1 = (S1+S2)/2;
M2 = (P+S1)/2;
M3 = (P+R1)/2;
M4 = (R1+R2)/2;
M5 = (R2+R3)/2;
}

//comment on OHLC and daily range

if (Q > 5) 
{
	nQ = Q;
}
else
{
	nQ = Q*10000;
}

if (D > 5)
{
	nD = D;
}
else
{
	nD = D*10000;
}

 if (StringSubstr(Symbol(),3,3)=="JPY")
      {
      nQ=nQ/100;
      nD=nD/100;
      }

Comment("High= ",yesterday_high,"    Previous Days Range= ",nQ,"\nLow= ",yesterday_low,"    Current Days Range= ",nD,"\nClose= ",yesterday_close);

LabelShiftTime = Time[LabelShift];
LineShiftTime = Time[LineShift];
//---- Set line labels on chart window
 if (Pivot)
   {

      if(ObjectFind("P label") != 0)
      {
      ObjectCreate("P label", OBJ_TEXT, 0, LabelShiftTime, P);
      ObjectSetText("P label", "Pivot", PivotFontSize, "Arial", PivotFontColor);
      }
      else
      {
      ObjectMove("P label", 0, LabelShiftTime, P);
      }

//---  Draw  Pivot lines on chart

      if(ObjectFind("P line") != 0)
      {
      ObjectCreate("P line", OBJ_HLINE, 0, LineShiftTime, P);
      ObjectSet("P line", OBJPROP_STYLE, STYLE_DASH);
      ObjectSet("P line", OBJPROP_COLOR, PivotColor);
      }
      else
      {
      ObjectMove("P line", 0, LineShiftTime, P);
      }

  }

  if (StandardPivots)
  {
if(ObjectFind("R1 label") != 0)
      {
      ObjectCreate("R1 label", OBJ_TEXT, 0, LabelShiftTime, R1);
      ObjectSetText("R1 label", " R1", StandardFontSize, "Arial", StandardFontColor);
      }
      else
      {
      ObjectMove("R1 label", 0, LabelShiftTime, R1);
      }

      if(ObjectFind("R2 label") != 0)
      {
      ObjectCreate("R2 label", OBJ_TEXT, 0, LabelShiftTime, R2);
      ObjectSetText("R2 label", " R2", StandardFontSize, "Arial", StandardFontColor);
      }
      else
      {
      ObjectMove("R2 label", 0, LabelShiftTime, R2);
      }

      if(ObjectFind("R3 label") != 0)
      {
      ObjectCreate("R3 label", OBJ_TEXT, 0, LabelShiftTime, R3);
      ObjectSetText("R3 label", " R3", StandardFontSize, "Arial", StandardFontColor);
      }
      else
      {
      ObjectMove("R3 label", 0, LabelShiftTime, R3);
      }

      if(ObjectFind("S1 label") != 0)
      {
      ObjectCreate("S1 label", OBJ_TEXT, 0, LabelShiftTime, S1);
      ObjectSetText("S1 label", "S1", StandardFontSize, "Arial", StandardFontColor);
      }
      else
      {
      ObjectMove("S1 label", 0, LabelShiftTime, S1);
      }

      if(ObjectFind("S2 label") != 0)
      {
      ObjectCreate("S2 label", OBJ_TEXT, 0, LabelShiftTime, S2);
      ObjectSetText("S2 label", "S2", StandardFontSize, "Arial", StandardFontColor);
      }
      else
      {
      ObjectMove("S2 label", 0, LabelShiftTime, S2);
      }

      if(ObjectFind("S3 label") != 0)
      {
      ObjectCreate("S3 label", OBJ_TEXT, 0, LabelShiftTime, S3);
      ObjectSetText("S3 label", "S3", StandardFontSize, "Arial", StandardFontColor);
      }
      else
      {
      ObjectMove("S3 label", 0, LabelShiftTime, S3);
      }

//---  Draw  Pivot lines on chart
      if(ObjectFind("S1 line") != 0)
      {
      ObjectCreate("S1 line", OBJ_HLINE, 0, LineShiftTime, S1);
      ObjectSet("S1 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("S1 line", OBJPROP_COLOR, SupportColor);
      }
      else
      {
      ObjectMove("S1 line", 0, LineShiftTime, S1);
      }

      if(ObjectFind("S2 line") != 0)
      {
      ObjectCreate("S2 line", OBJ_HLINE, 0, LineShiftTime, S2);
      ObjectSet("S2 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("S2 line", OBJPROP_COLOR, SupportColor);
      }
      else
      {
      ObjectMove("S2 line", 0, LineShiftTime, S2);
      }

      if(ObjectFind("S3 line") != 0)
      {
      ObjectCreate("S3 line", OBJ_HLINE, 0, LineShiftTime, S3);
      ObjectSet("S3 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("S3 line", OBJPROP_COLOR, SupportColor);
      }
      else
      {
      ObjectMove("S3 line", 0, LineShiftTime, S3);
      }

      if(ObjectFind("R1 line") != 0)
      {
      ObjectCreate("R1 line", OBJ_HLINE, 0, LineShiftTime, R1);
      ObjectSet("R1 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("R1 line", OBJPROP_COLOR, ResistanceColor);
      }
      else
      {
      ObjectMove("R1 line", 0, LineShiftTime, R1);
      }

      if(ObjectFind("R2 line") != 0)
      {
      ObjectCreate("R2 line", OBJ_HLINE, 0, LineShiftTime, R2);
      ObjectSet("R2 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("R2 line", OBJPROP_COLOR, ResistanceColor);
      }
      else
      {
      ObjectMove("R2 line", 0, LineShiftTime, R2);
      }

      if(ObjectFind("R3 line") != 0)
      {
      ObjectCreate("R3 line", OBJ_HLINE, 0, LineShiftTime, R3);
      ObjectSet("R3 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("R3 line", OBJPROP_COLOR, ResistanceColor);
      }
      else
      {
      ObjectMove("R3 line", 0, LineShiftTime, R3);
      }
  }
  
  if (MidPivots)
  {
      if(ObjectFind("M5 label") != 0)
      {
      ObjectCreate("M5 label", OBJ_TEXT, 0, LabelShiftTime, M5);
      ObjectSetText("M5 label", " M5", MidFontSize, "Arial", MidPivotColor);
      }
      else
      {
      ObjectMove("M5 label", 0, LabelShiftTime, M5);
      }

      if(ObjectFind("M4 label") != 0)
      {
      ObjectCreate("M4 label", OBJ_TEXT, 0, LabelShiftTime, M4);
      ObjectSetText("M4 label", " M4", MidFontSize, "Arial", MidPivotColor);
      }
      else
      {
      ObjectMove("M4 label", 0, LabelShiftTime, M4);
      }

      if(ObjectFind("M3 label") != 0)
      {
      ObjectCreate("M3 label", OBJ_TEXT, 0, LabelShiftTime, M3);
      ObjectSetText("M3 label", " M3", MidFontSize, "Arial", MidPivotColor);
      }
      else
      {
      ObjectMove("M3 label", 0, LabelShiftTime, M3);
      }

      if(ObjectFind("M2 label") != 0)
      {
      ObjectCreate("M2 label", OBJ_TEXT, 0, LabelShiftTime, M2);
      ObjectSetText("M2 label", " M2", MidFontSize, "Arial", MidPivotColor);
      }
      else
      {
      ObjectMove("M2 label", 0, LabelShiftTime, M2);
      }

      if(ObjectFind("M1 label") != 0)
      {
      ObjectCreate("M1 label", OBJ_TEXT, 0, LabelShiftTime, M1);
      ObjectSetText("M1 label", " M1", MidFontSize, "Arial", MidPivotColor);
      }
      else
      {
      ObjectMove("M1 label", 0, LabelShiftTime, M1);
      }

      if(ObjectFind("M0 label") != 0)
      {
      ObjectCreate("M0 label", OBJ_TEXT, 0, LabelShiftTime, M0);
      ObjectSetText("M0 label", " M0", MidFontSize, "Arial", MidPivotColor);
      }
      else
      {
      ObjectMove("M0 label", 0, LabelShiftTime, M0);
      }
     

      if(ObjectFind("M5 line") != 0)
      {
      ObjectCreate("M5 line", OBJ_HLINE, 0, LineShiftTime, M5);
      ObjectSet("M5 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("M5 line", OBJPROP_COLOR, MidPivotColor);
      }
      else
      {
      ObjectMove("M5 line", 0, LineShiftTime, M5);
      }

      if(ObjectFind("M4 line") != 0)
      {
      ObjectCreate("M4 line", OBJ_HLINE, 0, LineShiftTime, M4);
      ObjectSet("M4 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("M4 line", OBJPROP_COLOR, MidPivotColor);
      }
      else
      {
      ObjectMove("M4 line", 0, LineShiftTime, M4);
      }

      if(ObjectFind("M3 line") != 0)
      {
      ObjectCreate("M3 line", OBJ_HLINE, 0, LineShiftTime, M3);
      ObjectSet("M3 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("M3 line", OBJPROP_COLOR, MidPivotColor);
      }
      else
      {
      ObjectMove("M3 line", 0, LineShiftTime, M3);
      }

      if(ObjectFind("M2 line") != 0)
      {
      ObjectCreate("M2 line", OBJ_HLINE, 0, LineShiftTime, M2);
      ObjectSet("M2 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("M2 line", OBJPROP_COLOR, MidPivotColor);
      }
      else
      {
      ObjectMove("M2 line", 0, LineShiftTime, M2);
      }

      if(ObjectFind("M1 line") != 0)
      {
      ObjectCreate("M1 line", OBJ_HLINE, 0, LineShiftTime, M1);
      ObjectSet("M1 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("M1 line", OBJPROP_COLOR, MidPivotColor);
      }
      else
      {
      ObjectMove("M1 line", 0, LineShiftTime, M1);
      }

      if(ObjectFind("M0 line") != 0)
      {
      ObjectCreate("M0 line", OBJ_HLINE, 0, LineShiftTime, M0);
      ObjectSet("M0 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
      ObjectSet("M0 line", OBJPROP_COLOR, MidPivotColor);
      }
      else
      {
      ObjectMove("M0 line", 0, LineShiftTime, M0);
      }
  }
  
  if (Fibs)
  {
      if(ObjectFind("FibR1 label") != 0)
      {
        ObjectCreate("FibR1 label", OBJ_TEXT, 0, LabelShiftTime, 0);
        ObjectSetText("FibR1 label", "Fib R1", FibFontSize, "Arial", FibFontColor);
      }
      else
      {
        ObjectMove("FibR1 label", 0, LabelShiftTime, r1);
      }
      if(ObjectFind("FibR2 label") != 0)
      {
        ObjectCreate("FibR2 label", OBJ_TEXT, 0, LabelShiftTime, 0);
        ObjectSetText("FibR2 label", "Fib R2", FibFontSize, "Arial", FibFontColor);
      }
      else
      {
        ObjectMove("FibR2 label", 0, LabelShiftTime, r2);
      }
      if(ObjectFind("FibR3 label") != 0)
      {
        ObjectCreate("FibR3 label", OBJ_TEXT, 0, LabelShiftTime, 0);
        ObjectSetText("FibR3 label", "Fib R3", FibFontSize, "Arial", FibFontColor);
      }
      else
      {
        ObjectMove("FibR3 label", 0, LabelShiftTime, r3);
      }
      if(ObjectFind("FibS1 label") != 0)
      {
        ObjectCreate("FibS1 label", OBJ_TEXT, 0, LabelShiftTime, 0);
        ObjectSetText("FibS1 label", "Fib S1", FibFontSize, "Arial", FibFontColor);
      }
      else
      {
        ObjectMove("FibS1 label", 0, LabelShiftTime, s1);
      }
      if(ObjectFind("FibS2 label") != 0)
      {
        ObjectCreate("FibS2 label", OBJ_TEXT, 0, LabelShiftTime, 0);
        ObjectSetText("FibS2 label", "Fib S2", FibFontSize, "Arial", FibFontColor);
      }
      else
      {
        ObjectMove("FibS2 label", 0, LabelShiftTime, s2);
      }
      if(ObjectFind("FibS3 label") != 0)
      {
        ObjectCreate("FibS3 label", OBJ_TEXT, 0, LabelShiftTime, 0);
        ObjectSetText("FibS3 label", "Fib S3", FibFontSize, "Arial", FibFontColor);
      }
      else
      {
        ObjectMove("FibS3 label", 0, LabelShiftTime, s3);
      }

//---- Set lines on chart window

      if(ObjectFind("FibS1 line") != 0)
      {
        ObjectCreate("FibS1 line", OBJ_HLINE, 0, LineShiftTime, 0);
        ObjectSet("FibS1 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
        ObjectSet("FibS1 line", OBJPROP_COLOR, FibColor);
      }
      else
      {
        ObjectMove("FibS1 line", 0, LineShiftTime, s1);
      }
      if(ObjectFind("FibS2 line") != 0)
      {
        ObjectCreate("FibS2 line", OBJ_HLINE, 0, LineShiftTime, 0);
        ObjectSet("FibS2 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
        ObjectSet("FibS2 line", OBJPROP_COLOR, FibColor);
      }
      else
      {
        ObjectMove("FibS2 line", 0, LineShiftTime, s2);
      }
      if(ObjectFind("FibS3 line") != 0)
      {
        ObjectCreate("FibS3 line", OBJ_HLINE, 0, LineShiftTime, 0);
        ObjectSet("FibS3 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
        ObjectSet("FibS3 line", OBJPROP_COLOR, FibColor);
      }
      else
      {
        ObjectMove("FibS3 line", 0, LineShiftTime, s3);
      }
      if(ObjectFind("FibR1 line") != 0)
      {
        ObjectCreate("FibR1 line", OBJ_HLINE, 0, LineShiftTime, 0);
        ObjectSet("FibR1 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
        ObjectSet("FibR1 line", OBJPROP_COLOR, FibColor);
      }
      else
      {
        ObjectMove("FibR1 line", 0, LineShiftTime, r1);
      }
      if(ObjectFind("FibR2 line") != 0)
      {
        ObjectCreate("FibR2 line", OBJ_HLINE, 0, LineShiftTime, 0);
        ObjectSet("FibR2 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
        ObjectSet("FibR2 line", OBJPROP_COLOR, FibColor);
      }
      else
      {
        ObjectMove("FibR2 line", 0, LineShiftTime, r2);
      }
      if(ObjectFind("FibR3 line") != 0)
      {
        ObjectCreate("FibR3 line", OBJ_HLINE, 0, LineShiftTime, 0);
        ObjectSet("FibR3 line", OBJPROP_STYLE, STYLE_DASHDOTDOT);
        ObjectSet("FibR3 line", OBJPROP_COLOR, FibColor);
      }
      else
      {
        ObjectMove("FibR3 line", 0, LineShiftTime, r3);
      }

  }


  if (Cams)
  {
// --- THE CAMARILLA ---
   if(ObjectFind("H5 label") != 0)
      {
      ObjectCreate("H5 label", OBJ_TEXT, 0, LabelShiftTime, H5);
      ObjectSetText("H5 label", " H5 LB TARGET", CamFontSize, "Arial", CamFontColor);
      }
      else
      {
      ObjectMove("H5 label", 0, LabelShiftTime, H5);
      }
      
      if(ObjectFind("H4 label") != 0)
      {
      ObjectCreate("H4 label", OBJ_TEXT, 0, LabelShiftTime, H4);
      ObjectSetText("H4 label", " H4 LONG BREAKOUT", CamFontSize, "Arial", CamFontColor);
      }
      else
      {
      ObjectMove("H4 label", 0, LabelShiftTime, H4);
      }

      if(ObjectFind("H3 label") != 0)
      {
      ObjectCreate("H3 label", OBJ_TEXT, 0, LabelShiftTime, H3);
      ObjectSetText("H3 label", " H3 SHORT", CamFontSize, "Arial", CamFontColor);
      }
      else
      {
      ObjectMove("H3 label", 0, LabelShiftTime, H3);
      }

      if(ObjectFind("L3 label") != 0)
      {
      ObjectCreate("L3 label", OBJ_TEXT, 0, LabelShiftTime, L3);
      ObjectSetText("L3 label", " L3 LONG", CamFontSize, "Arial", CamFontColor);
      }
      else
      {
      ObjectMove("L3 label", 0, LabelShiftTime, L3);
      }

      if(ObjectFind("L4 label") != 0)
      {
      ObjectCreate("L4 label", OBJ_TEXT, 0, LabelShiftTime, L4);
      ObjectSetText("L4 label", " L4 SHORT BREAKOUT", CamFontSize, "Arial", CamFontColor);
      }
      else
      {
      ObjectMove("L4 label", 0, LabelShiftTime, L4);
      }
      
      if(ObjectFind("L5 label") != 0)
      {
      ObjectCreate("L5 label", OBJ_TEXT, 0, LabelShiftTime, L5);
      ObjectSetText("L5 label", " L5 SB TARGET", CamFontSize, "Arial", CamFontColor);
      }
      else
      {
      ObjectMove("L5 label", 0, LabelShiftTime, L5);
      }

//---- Draw Camarilla lines on Chart
      if(ObjectFind("H5 line") != 0)
      {
      ObjectCreate("H5 line", OBJ_HLINE, 0, LineShiftTime, H5);
      ObjectSet("H5 line", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("H5 line", OBJPROP_COLOR, SpringGreen);
      ObjectSet("H5 line", OBJPROP_WIDTH, 1);
      }
      else
      {
      ObjectMove("H5 line", 0, LineShiftTime, H5);
      }
      
      if(ObjectFind("H4 line") != 0)
      {
      ObjectCreate("H4 line", OBJ_HLINE, 0, LineShiftTime, H4);
      ObjectSet("H4 line", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("H4 line", OBJPROP_COLOR, SpringGreen);
      ObjectSet("H4 line", OBJPROP_WIDTH, 1);
      }
      else
      {
      ObjectMove("H4 line", 0, LineShiftTime, H4);
      }

      if(ObjectFind("H3 line") != 0)
      {
      ObjectCreate("H3 line", OBJ_HLINE, 0, LineShiftTime, H3);
      ObjectSet("H3 line", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("H3 line", OBJPROP_COLOR, SpringGreen);
      ObjectSet("H3 line", OBJPROP_WIDTH, 2);
      }
      else
      {
      ObjectMove("H3 line", 0, LineShiftTime, H3);
      }

      if(ObjectFind("L3 line") != 0)
      {
      ObjectCreate("L3 line", OBJ_HLINE, 0, LineShiftTime, L3);
      ObjectSet("L3 line", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("L3 line", OBJPROP_COLOR, Red);
      ObjectSet("L3 line", OBJPROP_WIDTH, 2);
      }
      else
      {
      ObjectMove("L3 line", 0, LineShiftTime, L3);
      }

      if(ObjectFind("L4 line") != 0)
      {
      ObjectCreate("L4 line", OBJ_HLINE, 0, LineShiftTime, L4);
      ObjectSet("L4 line", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("L4 line", OBJPROP_COLOR, Red);
      ObjectSet("L4 line", OBJPROP_WIDTH, 1);
      }
      else
      {
      ObjectMove("L4 line", 0, LineShiftTime, L4);
      }
      
      if(ObjectFind("L5 line") != 0)
      {
      ObjectCreate("L5 line", OBJ_HLINE, 0, LineShiftTime, L5);
      ObjectSet("L5 line", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("L5 line", OBJPROP_COLOR, Red);
      ObjectSet("L5 line", OBJPROP_WIDTH, 1);
      }
      else
      {
      ObjectMove("L5 line", 0, LineShiftTime, L5);
      }
    }

//---- done
   // Now check for Alert
   
   if (Alerts){ DoAlerts();
   
//----
   return(0);
   }


   // Check for invalid bars and takeprofit
   if(Bars < 200) {
      Print("Not enough bars for this strategy - ", nameEA);
      return(0);
      }
      /*
       if(isBuying && !isSelling && !isBuyClosing && !isSellClosing) {  // Check for BUY entry signal
         if(stopLoss > 0)
            realSL = Ask - stopLoss * Point;
         if(takeProfit > 0)
            realTP = Ask + takeProfit * Point;
         ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,realSL,realTP,nameEA+" - Magic: "+magicEA+" ",magicEA,0,Red);  // Buy
         if(ticket < 0) {
            Print("OrderSend (" + nameEA + ") failed with error #" + GetLastError() + " --> " + ErrorDescription(GetLastError()));
         } else {
             
         }
      }
      if(isSelling && !isBuying && !isBuyClosing && !isSellClosing) {  // Check for SELL entry signal
         if(stopLoss > 0)
            realSL = Bid + stopLoss * Point;
         if(takeProfit > 0)
            realTP = Bid - takeProfit * Point;
         ticket = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,realSL,realTP,nameEA+" - Magic: "+magicEA+" ",magicEA,0,Red); // Sell
         if(ticket < 0) {
            Print("OrderSend (" + nameEA + ") failed with error #" + GetLastError() + " --> " + ErrorDescription(GetLastError()));
         } else {
             
         }
      
   }
   return(0);
   */
    calculateIndicators();                      // Calculate indicators' value 
    //Check for TakeProfit Conditions  
   if(lTakeProfit<1){
      Print("TakeProfit less than 1 on this EA with Magic -", magicEA );
      return(0);
   }
   if(sTakeProfit<1){
      Print("TakeProfit less than 1 on this EA with Magic -", magicEA);
      return(0);
   }
   //Introducing new expressions
double faClose0            = iClose(NULL,PERIOD_M15,0);
double previousfaClose0    = iClose(NULL,PERIOD_M15,1);
double faMA1               = iMA(NULL,PERIOD_M15,13,0,MODE_EMA,PRICE_TYPICAL,0);
double previousfaMA1       = iMA(NULL,PERIOD_M15,13,0,MODE_EMA,PRICE_TYPICAL,1);
double faCloseM5           = iClose(NULL,PERIOD_M5,0);
double deMark              = iDeMarker(NULL,PERIOD_M15,14,0);
//double faMA2               = iMAOnArray(faMA1,0,9,0,MODE_EMA,0);
//double faMA4               = iMAOnArray(faMA2,0,9,0,MODE_EMA,0);
double faClose2            = iClose(NULL,PERIOD_M15,0);
double previousfaClose2    = iClose(NULL,PERIOD_M15,1);
double faMA3               = iMA(NULL,PERIOD_M15,13,0,MODE_SMA,PRICE_TYPICAL,0);
double previousfaMA3       = iMA(NULL,PERIOD_M15,13,0,MODE_SMA,PRICE_TYPICAL,1);
double stochHistCurrent    = iStochastic(NULL,PERIOD_H1,5,3,3,MODE_SMA,0,MODE_MAIN,0);
double sarCurrent          = iSAR(NULL,PERIOD_M5,0.009,0.2,0);           // Parabolic Sar Current
double sarPrevious         = iSAR(NULL,PERIOD_M5,0.009,0.2,1);  //Parabolic Sar Previous
double vVolume             = iVolume(NULL,0,0);   // Current Volume
//double VolumeAve           = iMAOnArray(vVolume,0,6,0,MODE_SMA,0);
//double faMAvVolume         = iMAOnArray(vVolume,0,9,0,MODE_SMA,0); //Simple Moving Average
double faHighest           = Highest(NULL,PERIOD_H4,MODE_HIGH,30,0); // Highest High in an interval of time
double faLowest            = Lowest(NULL,PERIOD_H4,MODE_LOW,30,0); //Lowest Low in an interval of time
double faMiddle            = (faHighest+faLowest)/2; //...
double pPlus               = p+5*Point;
double pMinus              = p-5*Point;
double H5Plus              = H5+5*Point;
double H5Minus             = H5-5*Point;
double H4Plus              = H4+5*Point;
double H4Minus             = H4-5*Point;
double H3Plus              = H3+5*Point;
double H3Minus             = H3-5*Point;
double L3Plus              = L3+5*Point;
double L3Minus             = L3-5*Point;
double L4Plus              = L4+5*Point;
double L4Minus             = L4-5*Point;
double L5Plus              = L5+5*Point;
double L5Minus             = L5-5*Point;
double RPlus               = R+5*Point;
double RMinus              = R-5*Point;
double PPlus               = P+5*Point;
double PMinus              = P-5*Point;
double r1Plus              = r1+5*Point;
double r1Minus             = r1-5*Point;
double r2Plus              = r2+5*Point;
double r2Minus             = r2-5*Point;
double r3Plus              = r3+5*Point;
double r3Minus             = r3-5*Point;
double s1Plus              = s1+5*Point;
double s1Minus             = s1-5*Point;
double s2Plus              = s2+5*Point;
double s2Minus             = s2-5*Point;
double s3Plus              = s3+5*Point;
double s3Minus             = s3-5*Point;
double R1Plus              = R1+5*Point;
double R1Minus             = R1-5*Point;
double R2Plus              = R2+5*Point;
double R2Minus             = R2-5*Point;
double R3Plus              = R3+5*Point;
double R3Minus             = R3-5*Point;
double S1Plus              = S1+5*Point;
double S1Minus             = S1-5*Point;
double S2Plus              = S2+5*Point;
double S2Minus             = S2-5*Point;
double S3Plus              = S3+5*Point;
double S3Minus             = S3-5*Point;
double M0Plus              = M0+5*Point;
double M0Minus             = M0-5*Point;
double M1Plus              = M1+5*Point;
double M1Minus             = M1-5*Point;
double M2Plus              = M2+5*Point;
double M2Minus             = M2-5*Point;
double M3Plus              = M3+5*Point;
double M3Minus             = M3-5*Point;
double M4Plus              = M4+5*Point;
double M4Minus             = M4-5*Point;
double M5Plus              = M5+5*Point;
double M5Minus             = M5-5*Point;

/*
//Check Margin Requirement

 

   if(AccountFreeMargi n()<0){

      if (((faClose2<faMA3) && (previousfaClose2>previousfaMA3) ) 

      //&& (Ask < PPlus)

      //&& (Ask > PMinus)

      //&& (vVolume>VolumeAve)

      //&& (deMark>0.3) 

//      && (deMark>0.7) 

      && ( pMinus <Ask || Bid < pPlus)

      && (H5Minus <Ask || Bid < H5Plus)

      && (H4Minus <Ask || Bid < H4Plus)

      && (H3Minus <Ask || Bid < H3Plus)

      && (L3Minus <Ask || Bid < L3Plus)

      && (L4Minus <Ask || Bid < L4Plus)

      && (L5Minus <Ask || Bid < L5Plus)

      && ( PMinus <Ask || Bid < PPlus)

      && ( RMinus <Ask || Bid < RPlus)

      && (r1Minus <Ask || Bid < r1Plus)

      && (r2Minus <Ask || Bid < r2Plus)

      && (r3Minus <Ask || Bid < r3Plus)

      && (s1Minus <Ask || Bid < s1Plus)

      && (s2Minus <Ask || Bid < s2Plus)

      && (s3Minus <Ask || Bid < s3Plus)

      && (R1Minus <Ask || Bid < R1Plus)

      && (R2Minus <Ask || Bid < r2Plus)

      && (R3Minus <Ask || Bid < R3Plus)

      && (S1Minus <Ask || Bid < S1Plus)

      && (S2Minus <Ask || Bid < S2Plus)

      && (S3Minus <Ask || Bid < S3Plus)

      && (M0Minus <Ask || Bid < M0Plus)

      && (M1Minus <Ask || Bid < M1Plus)

      && (M2Minus <Ask || Bid < M2Plus)

      && (M3Minus <Ask || Bid < M3Plus)

      && (M4Minus <Ask || Bid < M4Plus)

      && (M5Minus <Ask || Bid < M5Plus)

      && ((maLongCurrent>closeCurrentD) ) 

 

 

 

 

      ){

   //if(!(sarCurrent<faCloseM5)){

         OpenSell();}

      if (((faClose0>faMA1) && (previousfaClose0<previousfaMA1) ) 

      //&& (Ask < PPlus)

      //&& (Ask > PMinus)

 

      //&& (vVolume>VolumeAve)

//      && (deMark<0.3) 

      //&& (deMark<0.7)

      && ( pMinus <Ask || Bid < pPlus)

      && (H5Minus <Ask || Bid < H5Plus)

      && (H4Minus <Ask || Bid < H4Plus)

      && (H3Minus <Ask || Bid < H3Plus)

      && (L3Minus <Ask || Bid < L3Plus)

      && (L4Minus <Ask || Bid < L4Plus)

      && (L5Minus <Ask || Bid < L5Plus)

      && ( PMinus <Ask || Bid < PPlus)

      && ( RMinus <Ask || Bid < RPlus)

      && (r1Minus <Ask || Bid < r1Plus)

      && (r2Minus <Ask || Bid < r2Plus)

      && (r3Minus <Ask || Bid < r3Plus)

      && (s1Minus <Ask || Bid < s1Plus)

      && (s2Minus <Ask || Bid < s2Plus)

      && (s3Minus <Ask || Bid < s3Plus)

      && (R1Minus <Ask || Bid < R1Plus)

      && (R2Minus <Ask || Bid < r2Plus)

      && (R3Minus <Ask || Bid < R3Plus)

      && (S1Minus <Ask || Bid < S1Plus)

      && (S2Minus <Ask || Bid < S2Plus)

      && (S3Minus <Ask || Bid < S3Plus)

      && (M0Minus <Ask || Bid < M0Plus)

      && (M1Minus <Ask || Bid < M1Plus)

      && (M2Minus <Ask || Bid < M2Plus)

      && (M3Minus <Ask || Bid < M3Plus)

      && (M4Minus <Ask || Bid < M4Plus)

      && (M5Minus <Ask || Bid < M5Plus)

      && ((maLongCurrent<closeCurrentD) ) 

 

      ){

      // if(!(sarCurrent>faCloseM5)){

         OpenBuy();}

 

      

      Print("We have no money. Free Margin = ", AccountFreeMargin( ));

      return(0);

   }

 

And change it to the following:

 

//Check Margin Requirement

 

   if(AccountFreeMargi n()<0){

      if (((faClose2<faMA3) && (previousfaClose2>previousfaMA3) ) 

      //&& (Ask < PPlus)

      //&& (Ask > PMinus)

      //&& (vVolume>VolumeAve)

      //&& (deMark>0.3) 

//      && (deMark>0.7) 

      && ( pMinus <Ask || Bid < pPlus)

      && (H5Minus <Ask || Bid < H5Plus)

      && (H4Minus <Ask || Bid < H4Plus)

      && (H3Minus <Ask || Bid < H3Plus)

      && (L3Minus <Ask || Bid < L3Plus)

      && (L4Minus <Ask || Bid < L4Plus)

      && (L5Minus <Ask || Bid < L5Plus)

      && ( PMinus <Ask || Bid < PPlus)

      && ( RMinus <Ask || Bid < RPlus)

      && (r1Minus <Ask || Bid < r1Plus)

      && (r2Minus <Ask || Bid < r2Plus)

      && (r3Minus <Ask || Bid < r3Plus)

      && (s1Minus <Ask || Bid < s1Plus)

      && (s2Minus <Ask || Bid < s2Plus)

      && (s3Minus <Ask || Bid < s3Plus)

      && (R1Minus <Ask || Bid < R1Plus)

      && (R2Minus <Ask || Bid < r2Plus)

      && (R3Minus <Ask || Bid < R3Plus)

      && (S1Minus <Ask || Bid < S1Plus)

      && (S2Minus <Ask || Bid < S2Plus)

      && (S3Minus <Ask || Bid < S3Plus)

      && (M0Minus <Ask || Bid < M0Plus)

      && (M1Minus <Ask || Bid < M1Plus)

      && (M2Minus <Ask || Bid < M2Plus)

      && (M3Minus <Ask || Bid < M3Plus)

      && (M4Minus <Ask || Bid < M4Plus)

      && (M5Minus <Ask || Bid < M5Plus)

      && ((maLongCurrent>closeCurrentD) ) 

 

 

 

 

      ){

   //if(!(sarCurrent<faCloseM5)){

         OpenSell();}

      if (((faClose0>faMA1) && (previousfaClose0<previousfaMA1) ) 

      //&& (Ask < PPlus)

      //&& (Ask > PMinus)

 

      //&& (vVolume>VolumeAve)

//      && (deMark<0.3) 

      //&& (deMark<0.7)

      && ( pMinus <Ask || Bid < pPlus)

      && (H5Minus <Ask || Bid < H5Plus)

      && (H4Minus <Ask || Bid < H4Plus)

      && (H3Minus <Ask || Bid < H3Plus)

      && (L3Minus <Ask || Bid < L3Plus)

      && (L4Minus <Ask || Bid < L4Plus)

      && (L5Minus <Ask || Bid < L5Plus)

      && ( PMinus <Ask || Bid < PPlus)

      && ( RMinus <Ask || Bid < RPlus)

      && (r1Minus <Ask || Bid < r1Plus)

      && (r2Minus <Ask || Bid < r2Plus)

      && (r3Minus <Ask || Bid < r3Plus)

      && (s1Minus <Ask || Bid < s1Plus)

      && (s2Minus <Ask || Bid < s2Plus)

      && (s3Minus <Ask || Bid < s3Plus)

      && (R1Minus <Ask || Bid < R1Plus)

      && (R2Minus <Ask || Bid < r2Plus)

      && (R3Minus <Ask || Bid < R3Plus)

      && (S1Minus <Ask || Bid < S1Plus)

      && (S2Minus <Ask || Bid < S2Plus)

      && (S3Minus <Ask || Bid < S3Plus)

      && (M0Minus <Ask || Bid < M0Plus)

      && (M1Minus <Ask || Bid < M1Plus)

      && (M2Minus <Ask || Bid < M2Plus)

      && (M3Minus <Ask || Bid < M3Plus)

      && (M4Minus <Ask || Bid < M4Plus)

      && (M5Minus <Ask || Bid < M5Plus)

      && ((maLongCurrent<closeCurrentD) ) 

 

      ){

      // if(!(sarCurrent>faCloseM5)){

         OpenBuy();}



      

      Print("We have no money. Free Margin = ", AccountFreeMargin( ));

      return(0);

   }

 

You can change the  “if(AccountFreeMargi n()<0)” to every amount you like. 

 

*/

//Check Margin Requirement

   if(AccountFreeMargin()<0){
      if (((faClose2<faMA3) && (previousfaClose2>previousfaMA3)) 
      //&& (Ask < PPlus)
      //&& (Ask > PMinus)
      //&& (vVolume>VolumeAve)
      //&& (deMark>0.3) 
//      && (deMark>0.7) 
      && ( pMinus <Ask || Bid < pPlus)
      && (H5Minus <Ask || Bid < H5Plus)
      && (H4Minus <Ask || Bid < H4Plus)
      && (H3Minus <Ask || Bid < H3Plus)
      && (L3Minus <Ask || Bid < L3Plus)
      && (L4Minus <Ask || Bid < L4Plus)
      && (L5Minus <Ask || Bid < L5Plus)
      && ( PMinus <Ask || Bid < PPlus)
      && ( RMinus <Ask || Bid < RPlus)
      && (r1Minus <Ask || Bid < r1Plus)
      && (r2Minus <Ask || Bid < r2Plus)
      && (r3Minus <Ask || Bid < r3Plus)
      && (s1Minus <Ask || Bid < s1Plus)
      && (s2Minus <Ask || Bid < s2Plus)
      && (s3Minus <Ask || Bid < s3Plus)
      && (R1Minus <Ask || Bid < R1Plus)
      && (R2Minus <Ask || Bid < r2Plus)
      && (R3Minus <Ask || Bid < R3Plus)
      && (S1Minus <Ask || Bid < S1Plus)
      && (S2Minus <Ask || Bid < S2Plus)
      && (S3Minus <Ask || Bid < S3Plus)
      && (M0Minus <Ask || Bid < M0Plus)
      && (M1Minus <Ask || Bid < M1Plus)
      && (M2Minus <Ask || Bid < M2Plus)
      && (M3Minus <Ask || Bid < M3Plus)
      && (M4Minus <Ask || Bid < M4Plus)
      && (M5Minus <Ask || Bid < M5Plus)
      && ((maLongCurrent>closeCurrentD)) 




      ){
   //if(!(sarCurrent<faCloseM5)){
         OpenSell();}
      if (((faClose0>faMA1) && (previousfaClose0<previousfaMA1)) 
      //&& (Ask < PPlus)
      //&& (Ask > PMinus)

      //&& (vVolume>VolumeAve)
//      && (deMark<0.3) 
      //&& (deMark<0.7)
      && ( pMinus <Ask || Bid < pPlus)
      && (H5Minus <Ask || Bid < H5Plus)
      && (H4Minus <Ask || Bid < H4Plus)
      && (H3Minus <Ask || Bid < H3Plus)
      && (L3Minus <Ask || Bid < L3Plus)
      && (L4Minus <Ask || Bid < L4Plus)
      && (L5Minus <Ask || Bid < L5Plus)
      && ( PMinus <Ask || Bid < PPlus)
      && ( RMinus <Ask || Bid < RPlus)
      && (r1Minus <Ask || Bid < r1Plus)
      && (r2Minus <Ask || Bid < r2Plus)
      && (r3Minus <Ask || Bid < r3Plus)
      && (s1Minus <Ask || Bid < s1Plus)
      && (s2Minus <Ask || Bid < s2Plus)
      && (s3Minus <Ask || Bid < s3Plus)
      && (R1Minus <Ask || Bid < R1Plus)
      && (R2Minus <Ask || Bid < r2Plus)
      && (R3Minus <Ask || Bid < R3Plus)
      && (S1Minus <Ask || Bid < S1Plus)
      && (S2Minus <Ask || Bid < S2Plus)
      && (S3Minus <Ask || Bid < S3Plus)
      && (M0Minus <Ask || Bid < M0Plus)
      && (M1Minus <Ask || Bid < M1Plus)
      && (M2Minus <Ask || Bid < M2Plus)
      && (M3Minus <Ask || Bid < M3Plus)
      && (M4Minus <Ask || Bid < M4Plus)
      && (M5Minus <Ask || Bid < M5Plus)
      && ((maLongCurrent<closeCurrentD)) 

      ){
      // if(!(sarCurrent>faCloseM5)){
         OpenBuy();}

      
      Print("We have no money. Free Margin = ", AccountFreeMargin());
      return(0);
   }
   
   //Buy Condition
   if (!takeBuyPositions()){

      //if ((faClose0>faMA1 && faBandWidth<faMABandWidth)){
       //if(!(sarCurrent>faCloseM5)){
      if (((faClose0>faMA1) && (previousfaClose0<previousfaMA1)) 
      //&& (Ask < PPlus)
      //&& (Ask > PMinus)

      //&& (vVolume>VolumeAve) 
//      && (deMark<0.3) 
      //&& (deMark<0.7)
      && ( pMinus <Ask || Bid < pPlus)
      && (H5Minus <Ask || Bid < H5Plus)
      && (H4Minus <Ask || Bid < H4Plus)
      && (H3Minus <Ask || Bid < H3Plus)
      && (L3Minus <Ask || Bid < L3Plus)
      && (L4Minus <Ask || Bid < L4Plus)
      && (L5Minus <Ask || Bid < L5Plus)
      && ( PMinus <Ask || Bid < PPlus)
      && ( RMinus <Ask || Bid < RPlus)
      && (r1Minus <Ask || Bid < r1Plus)
      && (r2Minus <Ask || Bid < r2Plus)
      && (r3Minus <Ask || Bid < r3Plus)
      && (s1Minus <Ask || Bid < s1Plus)
      && (s2Minus <Ask || Bid < s2Plus)
      && (s3Minus <Ask || Bid < s3Plus)
      && (R1Minus <Ask || Bid < R1Plus)
      && (R2Minus <Ask || Bid < r2Plus)
      && (R3Minus <Ask || Bid < R3Plus)
      && (S1Minus <Ask || Bid < S1Plus)
      && (S2Minus <Ask || Bid < S2Plus)
      && (S3Minus <Ask || Bid < S3Plus)
      && (M0Minus <Ask || Bid < M0Plus)
      && (M1Minus <Ask || Bid < M1Plus)
      && (M2Minus <Ask || Bid < M2Plus)
      && (M3Minus <Ask || Bid < M3Plus)
      && (M4Minus <Ask || Bid < M4Plus)
      && (M5Minus <Ask || Bid < M5Plus)
      && ((maLongCurrent<closeCurrentD))
       
){
         OpenBuy();
        
         //if (OrdersTotal()==2 && (faClose2<faMA3)) {OpenSell();}
         //if (OrdersTotal()==3 && (faClose2<faMA3)) {OpenSell();}
         
         return(0);
      }
      
      
      
//Sell Condition
      //if ((faClose2<faMA3 && faBandWidth<faMABandWidth)){
   if (!takeSellPositions()){
     // if(!(sarCurrent<faCloseM5)){
      if (((faClose2<faMA3) && (previousfaClose2>previousfaMA3)) 
      //&& (Ask < PPlus)
      //&& (Ask > PMinus)
 
      //&& (vVolume>VolumeAve)
      //&& (deMark>0.3) 
//      && (deMark>0.7)
      && ( pMinus <Ask || Bid < pPlus)
      && (H5Minus <Ask || Bid < H5Plus)
      && (H4Minus <Ask || Bid < H4Plus)
      && (H3Minus <Ask || Bid < H3Plus)
      && (L3Minus <Ask || Bid < L3Plus)
      && (L4Minus <Ask || Bid < L4Plus)
      && (L5Minus <Ask || Bid < L5Plus)
      && ( PMinus <Ask || Bid < PPlus)
      && ( RMinus <Ask || Bid < RPlus)
      && (r1Minus <Ask || Bid < r1Plus)
      && (r2Minus <Ask || Bid < r2Plus)
      && (r3Minus <Ask || Bid < r3Plus)
      && (s1Minus <Ask || Bid < s1Plus)
      && (s2Minus <Ask || Bid < s2Plus)
      && (s3Minus <Ask || Bid < s3Plus)
      && (R1Minus <Ask || Bid < R1Plus)
      && (R2Minus <Ask || Bid < r2Plus)
      && (R3Minus <Ask || Bid < R3Plus)
      && (S1Minus <Ask || Bid < S1Plus)
      && (S2Minus <Ask || Bid < S2Plus)
      && (S3Minus <Ask || Bid < S3Plus)
      && (M0Minus <Ask || Bid < M0Plus)
      && (M1Minus <Ask || Bid < M1Plus)
      && (M2Minus <Ask || Bid < M2Plus)
      && (M3Minus <Ask || Bid < M3Plus)
      && (M4Minus <Ask || Bid < M4Plus)
      && (M5Minus <Ask || Bid < M5Plus)
      && ((maLongCurrent>closeCurrentD)) 

){
         OpenSell();
        
         //if (OrdersTotal()==2 && (faClose0>faMA1)) {OpenBuy();}
         //if (OrdersTotal()==3 && (faClose0>faMA1)) {OpenBuy();}
         return(0);
      }
      //Close Buy Condition
/*      if ((faClose2<faMA3)){
      CloseBuy();
      return(0);
      }
      
      //Close Sell Condition
      if ((faClose2<faMA3)){
      CloseSell();
      return(0);
      }
*/
   }
   }
   
   //Trailing Expressions
   TrailingPositionsBuy(lTrailingStop);
   TrailingPositionsSell(sTrailingStop);
   return (0);
}
//Number of Buy Positions

bool takeBuyPositions() {
int j = 0 ;
//if (maLongCurrent<closeCurrent) {
if ((CurTime()-OrderOpenTime()>300)) {j=1;}
if ((CurTime()-OrderOpenTime()>600)) {j=2;}
if ((CurTime()-OrderOpenTime()>900)) {j=3;}
if ((CurTime()-OrderOpenTime()>1200)) {j=4;}
if ((CurTime()-OrderOpenTime()>1500)) {j=5;}
if ((CurTime()-OrderOpenTime()>1800)) {j=6;}
if ((CurTime()-OrderOpenTime()>2100)) {j=7;}
if ((CurTime()-OrderOpenTime()>2400)) {j=8;}
if ((CurTime()-OrderOpenTime()>2700)) {j=9;}
if ((CurTime()-OrderOpenTime()>3000)) {j=10;}
if ((CurTime()-OrderOpenTime()>3300)) {j=11;}
if ((CurTime()-OrderOpenTime()>3600)) {j=12;}
if ((CurTime()-OrderOpenTime()>3900)) {j=13;}
if ((CurTime()-OrderOpenTime()>4200)) {j=14;}
if ((CurTime()-OrderOpenTime()>4500)) {j=15;}
if ((CurTime()-OrderOpenTime()>4800)) {j=16;}
if ((CurTime()-OrderOpenTime()>5100)) {j=17;}
if ((CurTime()-OrderOpenTime()>5400)) {j=18;}
if ((CurTime()-OrderOpenTime()>5700)) {j=19;}
for (int i=j; i<OrdersTotal(); i++) {
if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) {
return(0);
}
} 
}

return(0);
}

//Number of Sell Positions

bool takeSellPositions() {
int j = 0 ;
//if ((OrdersTotal()==0)) {j=0;}
//if (maLongCurrent>closeCurrent) {
if ((CurTime()-OrderOpenTime()>300)) {j=1;}
if ((CurTime()-OrderOpenTime()>600)) {j=2;}
if ((CurTime()-OrderOpenTime()>900)) {j=3;}
if ((CurTime()-OrderOpenTime()>1200)) {j=4;}
if ((CurTime()-OrderOpenTime()>1500)) {j=5;}
if ((CurTime()-OrderOpenTime()>1800)) {j=6;}
if ((CurTime()-OrderOpenTime()>2100)) {j=7;}
if ((CurTime()-OrderOpenTime()>2700)) {j=9;}
if ((CurTime()-OrderOpenTime()>3000)) {j=10;}
if ((CurTime()-OrderOpenTime()>3300)) {j=11;}
if ((CurTime()-OrderOpenTime()>3600)) {j=12;}
if ((CurTime()-OrderOpenTime()>3900)) {j=13;}
if ((CurTime()-OrderOpenTime()>4200)) {j=14;}
if ((CurTime()-OrderOpenTime()>4500)) {j=15;}
if ((CurTime()-OrderOpenTime()>4800)) {j=16;}
if ((CurTime()-OrderOpenTime()>5100)) {j=17;}
if ((CurTime()-OrderOpenTime()>5400)) {j=18;}
if ((CurTime()-OrderOpenTime()>5700)) {j=19;}
for (int i=j; i<OrdersTotal(); i++) {
if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) {
return(0);
}
} 
}

return(0);
}

void TrailingPositionsBuy(int trailingStop) { 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) { 
            if (OrderType()==OP_BUY) { 
               if (Bid-OrderOpenPrice()>trailingStop*Point) { 
                  if (OrderStopLoss()<Bid-trailingStop*Point) 
                     ModifyStopLoss(Bid-trailingStop*Point); 
               } 
            } 
         } 
      } 
   } 
} 
void TrailingPositionsSell(int trailingStop) { 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) { 
            if (OrderType()==OP_SELL) { 
               if (OrderOpenPrice()-Ask>trailingStop*Point) { 
                  if (OrderStopLoss()>Ask+trailingStop*Point || 
OrderStopLoss()==0)  
                     ModifyStopLoss(Ask+trailingStop*Point); 
               } 
            } 
         } 
      } 
   } 
} 
void ModifyStopLoss(double ldStopLoss) { 
   bool fm;
   fm = OrderModify(OrderTicket(),OrderOpenPrice
(),ldStopLoss,OrderTakeProfit(),0,CLR_NONE); 
  
} 

void OpenBuy() { 
   double ldLot, ldStop, ldTake; 
   string lsComm; 
   ldLot = GetSizeLot(); 
   ldStop = GetStopLossBuy(); 
   ldTake = GetTakeProfitBuy(); 
   lsComm = GetCommentForOrder(); 
   OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,ldStop,ldTake,nameEA,magicEA,0,clOpenBuy);  

    
} 
void OpenSell() { 
   double ldLot, ldStop, ldTake; 
   string lsComm; 

   ldLot = GetSizeLot(); 
   ldStop = GetStopLossSell(); 
   ldTake = GetTakeProfitSell(); 
   lsComm = GetCommentForOrder(); 
   OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,ldStop,ldTake,nameEA,magicEA,0,clOpenSell); 
  
} 
string GetCommentForOrder() { return(nameEA); } 
double GetSizeLot() { return(Lots); } 
double GetTakeProfitBuy() { if (iADX(NULL,0,14,PRICE_MEDIAN,MODE_MAIN,0)<25)  return(Ask+lTakeProfit*Point); else return(Ask+pr*Point); } 
double GetTakeProfitSell() { if (iADX(NULL,0,14,PRICE_MEDIAN,MODE_MAIN,0)<25) return(Bid-sTakeProfit*Point); else return (Bid-pr*Point);} 
double GetStopLossBuy() { if (stopLoss==0) return(0); else  return(Ask - stopLoss*Point);}
double GetStopLossSell() { if (stopLoss==0) return(0); else return(Bid + stopLoss*Point);}
  void calculateIndicators() {  
    // Calculate indicators' value   
   macdHistCurrent     = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_MAIN,0);   
   macdHistPrevious    = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_MAIN,1);   
   macdSignalCurrent   = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_SIGNAL,0); 
   macdSignalPrevious  = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_SIGNAL,1); 
   stochHistPrevious   = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,1);
   stochSignalCurrent  = iStochastic(NULL,PERIOD_H4,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
   stochSignalPrevious = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);
   sarCurrent          = iSAR(NULL,PERIOD_M5,0.009,0.2,0);           // Parabolic Sar Current
   sarPrevious         = iSAR(NULL,PERIOD_M5,0.009,0.2,1);  //Parabolic Sar Previous
   momCurrent          = iMomentum(NULL,0,14,PRICE_OPEN,0); // Momentum Current
   momPrevious         = iMomentum(NULL,0,14,PRICE_OPEN,1); // Momentum Previous
   highCurrent         = iHigh(NULL,0,0);     //High price Current
   lowCurrent          = iLow(NULL,0,0);      //Low Price Current
   highCurrentH1       = iHigh(NULL,PERIOD_H1,0);
   lowCurrentH1        = iLow(NULL,PERIOD_H1,0);
   closeCurrent        = iClose(NULL,PERIOD_H4,0);  //Close Price Current for H4 TimeFrame
   closeCurrentD       = iClose(NULL,PERIOD_H1,0); //Close Price Current for D1 TimeFrame
   closePreviousD      = iClose(NULL,PERIOD_H1,1); //Close Price Previous for D1 TimeFrame
   maLongCurrent       = iMA(NULL,PERIOD_H1,55,1,MODE_SMMA,PRICE_TYPICAL,0); //Current Long Term Moving Average 
   maLongPrevious      = iMA(NULL,PERIOD_H1,55,1,MODE_SMMA,PRICE_TYPICAL,1); //Previous Long Term Moving Average 
   maShortCurrent      = iMA(NULL,0,2,1,MODE_SMMA,PRICE_TYPICAL,0);  //Current Short Term Moving Average 
   maShortPrevious     = iMA(NULL,0,2,1,MODE_SMMA,PRICE_TYPICAL,1);  //Previous Long Term Moving Average
   faRSICurrent        = iRSI(NULL,0,14,PRICE_TYPICAL,0); //Current RSI 
   
   // Check for BUY, SELL, and CLOSE signal
   isBuying  = false;
   isSelling = false;
   isBuyClosing = false;
   isSellClosing = false;
}
void CloseBuyPositions(){ 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) { 
            if (OrderType()==OP_BUY) OrderClose(OrderTicket(),Lots,Bid,Slippage);
         } 
      } 
   } 
} 
void CloseSellPositions(){ 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) { 
            if (OrderType()==OP_SELL) OrderClose(OrderTicket(),Lots,Ask,Slippage);
         } 
      } 
   } 
}


