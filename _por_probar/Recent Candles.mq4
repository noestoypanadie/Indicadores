//+------------------------------------------------------------------+
//|                                               Recent Candles.mq4 |
//+------------------------------------------------------------------+

#property indicator_separate_window
#property indicator_minimum -35
#property indicator_maximum 120
//#property indicator_level1 75
//#property indicator_level2 50
//#property indicator_level3 25
//#property indicator_levelcolor MidnightBlue
#property indicator_buffers 8
#property indicator_color1 Lime               // color of body, if Close > Open
#property indicator_color2 Red                // color of body, if Close < Open
#property indicator_color3 White              // color of body, if Close = Open
#property indicator_color4 Black              // color of background
#property indicator_color5 Lime               // color of shadow, if Close > Open
#property indicator_color6 Red                // color of shadow, if Close < Open
#property indicator_color7 White              // color of shadow, if Close = Open
#property indicator_color8 Black              // color of background
/*
#property indicator_width1 5                  // width of body, if Close > Open
#property indicator_width2 5                  // width of body, if Close < Open
#property indicator_width3 5                  // width of body, if Close = Open
#property indicator_width4 5                  // width of background
#property indicator_width5 1                  // width of shadow, if Close > Open
#property indicator_width6 1                  // width of shadow, if Close < Open
#property indicator_width7 1                  // width of shadow, if Close = Open
#property indicator_width8 1                  // width of background
*/
extern string     CurrencyPairs          = "";
extern string     TimeFrames             = "M1, M5, M15, M30, H1, H4, D1, W1, MN";
extern string     NumCandles             = "5";
extern string     HistoricalShift        = "0";
extern int        CandleWidth            = 5;
extern int        SpacingBetweenCandles  = 1;
extern color      CandleUpColor          = Lime;
extern color      CandleDownColor        = Red;
extern color      TextColor              = White;
extern string     TextFont               = "Verdana";
extern int        TextSize               = 9;
extern color      BackgroundColor        = Black;
extern bool       DisplayInfo            = true;
extern bool       DisplayCcyName         = true;
extern bool       DisplayTF              = true;
extern int        RefreshEveryXMins      = 0;
extern bool       HeikinAshiCandles      = false;

//---- buffers ------------------------------------------------------+
static double UpBodyBuffer[];
static double DnBodyBuffer[];
static double EqBodyBuffer[];
static double BgBodyBuffer[];
static double UpShadowBuffer[];
static double DnShadowBuffer[];
static double EqShadowBuffer[];
static double BgShadowBuffer[];

string   ccy, sym, CP[30], ccyp, IndiName;
int      dig, tf, tmf, Wnum, ccCP, ccTF, ccNC, ccHS, TF[9], NC[9], HS[9], IC[30];
double   spr, pnt, tickval, bidp, askp, Lswap, Sswap, HH, LL, O, H, L, C;
datetime prev_time, lastick;
double   HAhigh[],HAlow[],HAopen[],HAclose[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()  {

  CheckPresets();

  if (RefreshEveryXMins > 240)                             RefreshEveryXMins = 240;
  if (RefreshEveryXMins > 60 && RefreshEveryXMins < 240)   RefreshEveryXMins = 60;
  if (RefreshEveryXMins > 30 && RefreshEveryXMins < 60)    RefreshEveryXMins = 30;
  if (RefreshEveryXMins > 15 && RefreshEveryXMins < 30)    RefreshEveryXMins = 15;
  if (RefreshEveryXMins > 5  && RefreshEveryXMins < 15)    RefreshEveryXMins = 5;
  if (RefreshEveryXMins > 1  && RefreshEveryXMins < 5)     RefreshEveryXMins = 1;

  sym     = Symbol();
  ccy     = Symbol();
  if (CurrencyPairs > "")  ccy = CurrencyPairs;
  tmf     = Period();
  bidp    = MarketInfo(ccy,MODE_BID);
  askp    = MarketInfo(ccy,MODE_ASK);
  pnt     = MarketInfo(ccy,MODE_POINT);
  dig     = MarketInfo(ccy,MODE_DIGITS);
  spr     = MarketInfo(ccy,MODE_SPREAD);
  tickval = MarketInfo(ccy,MODE_TICKVALUE);
  if (dig == 3 || dig == 5) {
    pnt     *= 10;
    spr     /= 10;
    tickval *= 10;
  }  

  prev_time = -9999;

  //---- set a accuracy of values of the indicator -----------------+
  IndicatorDigits(dig);
  //---- set a style for line --------------------------------------+
  SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,CandleWidth,CandleUpColor);
  SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,CandleWidth,CandleDownColor);
  SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,CandleWidth,TextColor);
  SetIndexStyle(3,DRAW_HISTOGRAM,STYLE_SOLID,CandleWidth,BackgroundColor);
  SetIndexStyle(4,DRAW_HISTOGRAM,STYLE_SOLID,1,CandleUpColor);
  SetIndexStyle(5,DRAW_HISTOGRAM,STYLE_SOLID,1,CandleDownColor);
  SetIndexStyle(6,DRAW_HISTOGRAM,STYLE_SOLID,1,TextColor);
  SetIndexStyle(7,DRAW_HISTOGRAM,STYLE_SOLID,1,BackgroundColor);
  //---- set a arrays for line -------------------------------------+
  SetIndexBuffer(0,UpBodyBuffer);
  SetIndexBuffer(1,DnBodyBuffer);
  SetIndexBuffer(2,EqBodyBuffer);
  SetIndexBuffer(3,BgBodyBuffer);
  SetIndexBuffer(4,UpShadowBuffer);
  SetIndexBuffer(5,DnShadowBuffer);
  SetIndexBuffer(6,EqShadowBuffer);
  SetIndexBuffer(7,BgShadowBuffer);

/*
  ArrayInitialize(UpBodyBuffer,EMPTY_VALUE);
  ArrayInitialize(DnBodyBuffer,EMPTY_VALUE);
  ArrayInitialize(EqBodyBuffer,EMPTY_VALUE);
  ArrayInitialize(BgBodyBuffer,EMPTY_VALUE);
  ArrayInitialize(UpShadowBuffer,EMPTY_VALUE);
  ArrayInitialize(DnShadowBuffer,EMPTY_VALUE);
  ArrayInitialize(EqShadowBuffer,EMPTY_VALUE);
  ArrayInitialize(BgShadowBuffer,EMPTY_VALUE);
*/
  del_obj();
  plot_obj();    
  
  return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()  {
  del_obj();
  return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start() {

    if (RefreshEveryXMins == 0) {
      del_obj();
      plot_obj();    
    }
    else {
      if(prev_time != iTime(sym,RefreshEveryXMins,0))  {
        del_obj();
        plot_obj();
        prev_time = iTime(sym,RefreshEveryXMins,0);
    } }      
      
//  }  
  return(0);
}

//+------------------------------------------------------------------+
//| del_obj                                                          |
//+------------------------------------------------------------------+
void del_obj()
{
  int k=0;
  while (k<ObjectsTotal())   {
    string objname = ObjectName(k);
    if (StringSubstr(objname,0,StringLen(IndiName)) == IndiName)  
      ObjectDelete(objname);
    else
      k++;
  }    
  return(0);
}

//+------------------------------------------------------------------+
void plot_obj()   {
//+------------------------------------------------------------------+
  CheckPresets();

  SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID,CandleWidth,CandleUpColor);
  SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID,CandleWidth,CandleDownColor);
  SetIndexStyle(2,DRAW_HISTOGRAM,STYLE_SOLID,CandleWidth,TextColor);
  SetIndexStyle(3,DRAW_HISTOGRAM,STYLE_SOLID,CandleWidth,BackgroundColor);
  SetIndexStyle(4,DRAW_HISTOGRAM,STYLE_SOLID,1,CandleUpColor);
  SetIndexStyle(5,DRAW_HISTOGRAM,STYLE_SOLID,1,CandleDownColor);
  SetIndexStyle(6,DRAW_HISTOGRAM,STYLE_SOLID,1,TextColor);
  SetIndexStyle(7,DRAW_HISTOGRAM,STYLE_SOLID,1,BackgroundColor);

  Wnum = WindowFind(IndiName);
  if (Wnum < 0)   return(0);

/*
  ArrayInitialize(UpBodyBuffer,EMPTY_VALUE);
  ArrayInitialize(DnBodyBuffer,EMPTY_VALUE);
  ArrayInitialize(EqBodyBuffer,EMPTY_VALUE);
  ArrayInitialize(BgBodyBuffer,EMPTY_VALUE);
  ArrayInitialize(UpShadowBuffer,EMPTY_VALUE);
  ArrayInitialize(DnShadowBuffer,EMPTY_VALUE);
  ArrayInitialize(EqShadowBuffer,EMPTY_VALUE);
  ArrayInitialize(BgShadowBuffer,EMPTY_VALUE);
*/

  for (int i=0; i<Bars; i++)   {
    UpBodyBuffer[i]   = EMPTY_VALUE;
    DnBodyBuffer[i]   = EMPTY_VALUE;
    EqBodyBuffer[i]   = EMPTY_VALUE;
    BgBodyBuffer[i]   = EMPTY_VALUE;
    UpShadowBuffer[i] = EMPTY_VALUE;
    DnShadowBuffer[i] = EMPTY_VALUE;
    EqShadowBuffer[i] = EMPTY_VALUE;
    BgShadowBuffer[i] = EMPTY_VALUE;
  }

  int    j = 0;
  
  for (int c=29; c>=0; c--)   {  
    ccyp = CP[c];
    if (ccyp == "")   continue;

    Lswap   = MarketInfo(ccyp,MODE_SWAPLONG);
    Sswap   = MarketInfo(ccyp,MODE_SWAPSHORT);
    lastick = MarketInfo(ccyp,MODE_TIME);
    bidp    = MarketInfo(ccyp,MODE_BID);
    askp    = MarketInfo(ccyp,MODE_ASK);
    spr     = MarketInfo(ccyp,MODE_SPREAD);
    pnt     = MarketInfo(ccyp,MODE_POINT);
    dig     = MarketInfo(ccyp,MODE_DIGITS);
    tickval = MarketInfo(ccyp,MODE_TICKVALUE);
    if (dig == 3 || dig == 5) {
      spr     /= 10;
      tickval *= 10;
    }  

    string tft;
    for(int z=8; z>=0; z--) {
      tf = TF[z];
      if (tf == 0)    continue;
      tft = TFToStr(tf);
      string ccyt = ccyp;
      if (IC[c] == 1)   ccyt = "(" + StringSubstr(ccyp,3,3) + StringSubstr(ccyp,0,3) + ")";
      string tct = ccyt + "," + tft;

      int minval = HS[z];
      int maxval = MathMin(iBars(ccyp,tf)-2,NC[z]+HS[z]+50);
      ArrayResize(HAclose,maxval);
      ArrayResize(HAopen,maxval);
      ArrayResize(HAhigh,maxval);
      ArrayResize(HAlow,maxval);
      
      for (int q=maxval; q>=minval; q--)  {
        if (q == maxval || !HeikinAshiCandles)   {
          HAopen[q]  = iOpen(ccyp,tf,q);
          HAhigh[q]  = iHigh(ccyp,tf,q);
          HAlow[q]   = iLow(ccyp,tf,q);
          HAclose[q] = iClose(ccyp,tf,q);
        } else {
          HAopen[q]  = (HAopen[q+1]+HAclose[q+1])/2;
          HAhigh[q]  = MathMax(HAopen[q],iHigh(ccyp,tf,q));
          HAlow[q]   = MathMin(HAopen[q],iLow(ccyp,tf,q));
          HAclose[q] = (iOpen(ccyp,tf,q)+iHigh(ccyp,tf,q)+iLow(ccyp,tf,q)+iClose(ccyp,tf,q))/4;
      } }          

      HH = 0;             // highest high across last NumCandles candles, used for scaling
      LL = 999999;        // lowest low across last NumCandles candles, used for scaling
      for(i=HS[z]; i<=NC[z]+HS[z]; i++)  {
        if (IC[c] == 1)  {
          HH = MathMax(HH,DivZero(1,HAlow[i]));
          LL = MathMin(LL,DivZero(1,HAhigh[i]));
        } else  {
          HH = MathMax(HH,HAhigh[i]);
          LL = MathMin(LL,HAlow[i]);
        }
      }

      for(i=HS[z]; i<=NC[z]+HS[z]; i++)  {
  //      Print ("***" + tct + "  " + i + "  " + j);
        if (IC[c] == 1)  {
          O = DivZero(1,HAopen[i]);     // candle open
          H = DivZero(1,HAlow[i]);      // candle high
          L = DivZero(1,HAhigh[i]);     // candle low
          C = DivZero(1,HAclose[i]);    // candle close
        } else  {
          O = HAopen[i];     // candle open
          H = HAhigh[i];     // candle high
          L = HAlow[i];      // candle low
          C = HAclose[i];    // candle close
        }
        double open  = DivZero(100*(O-LL),(HH-LL));
        double high  = DivZero(100*(H-LL),(HH-LL));
        double low   = DivZero(100*(L-LL),(HH-LL));
        double close = DivZero(100*(C-LL),(HH-LL));

        if (open < close)
          {
           UpBodyBuffer[j] = close;
           DnBodyBuffer[j] = EMPTY_VALUE;
           EqBodyBuffer[j] = EMPTY_VALUE;
           BgBodyBuffer[j] = open;
           UpShadowBuffer[j] = high;
           DnShadowBuffer[j] = EMPTY_VALUE;
           EqShadowBuffer[j] = EMPTY_VALUE;
           BgShadowBuffer[j] = low;
          }
        else
          {
           if (open > close)
             {
              UpBodyBuffer[j] = EMPTY_VALUE;
              DnBodyBuffer[j] = open;
              EqBodyBuffer[j] = EMPTY_VALUE;
              BgBodyBuffer[j] = close;
              UpShadowBuffer[j] = EMPTY_VALUE;
              DnShadowBuffer[j] = high;
              EqShadowBuffer[j] = EMPTY_VALUE;
              BgShadowBuffer[j] = low;
             }
           else
             {
              UpBodyBuffer[j] = EMPTY_VALUE;
              DnBodyBuffer[j] = EMPTY_VALUE;
              EqBodyBuffer[j] = open;
              BgBodyBuffer[j] = open - 1;
              UpShadowBuffer[j] = EMPTY_VALUE;
              DnShadowBuffer[j] = EMPTY_VALUE;
              if (high == low)
                {
                 EqShadowBuffer[j] = EMPTY_VALUE;
                 BgShadowBuffer[j] = EMPTY_VALUE;
                }
              else
                {
                 EqShadowBuffer[j] = high;
                 BgShadowBuffer[j] = low;
                }
             }
        }
        j += SpacingBetweenCandles;
      }

  // separator line (between time frames)
      string ObjNameS = IndiName + "-" + tct + "-s";
      ObjectCreate(ObjNameS,OBJ_TREND,Wnum,iTime(sym,tmf,j),120,iTime(sym,tmf,j),-20);
      ObjectSet(ObjNameS,OBJPROP_COLOR,TextColor);

  // text, e.g. "USDJPY,H1"
      string ObjNameT = IndiName + "-" + tct + "-t";
      string dispstr = "";
      ObjectCreate(ObjNameT,OBJ_TEXT,Wnum,iTime(sym,tmf,j-SpacingBetweenCandles*(NC[z]+2)/2),-10);
      ObjectSetText(ObjNameT, " ", TextSize, TextFont, TextColor);
      if (DisplayCcyName && DisplayTF)  dispstr = tct;      else
      if (DisplayCcyName             )  dispstr = ccyt;     else
      if (DisplayTF                  )  dispstr = tft;
      if (HeikinAshiCandles && DisplayCcyName) dispstr = dispstr + "-HA";
      ObjectSetText(ObjNameT, dispstr, TextSize, TextFont, TextColor);

      j += SpacingBetweenCandles;
    }

    if (DisplayInfo)   {
      if (IC[c] == 0)
        string info = ccyt + " = " + DoubleToStr(bidp,dig) + " / " + DoubleToStr(askp,dig);
      else
        info = ccyt + " = " + DoubleToStr(DivZero(1,(bidp+askp)/2),dig);
      string ObjNameI = IndiName + "-" + ccyp + "-i1";
      ObjectCreate(ObjNameI,OBJ_TEXT,Wnum,iTime(sym,tmf,j+13*SpacingBetweenCandles/2),98);
      ObjectSetText(ObjNameI, info, TextSize, TextFont, TextColor); 

      info = "  Last Tick = " + TimeToStr(lastick,TIME_SECONDS);
      ObjNameI = IndiName + "-" + ccyp + "-i2";
      ObjectCreate(ObjNameI,OBJ_TEXT,Wnum,iTime(sym,tmf,j+13*SpacingBetweenCandles/2),73);
      ObjectSetText(ObjNameI, info, TextSize, TextFont, TextColor); 

      if (IC[c] == 0)   {
        info = "  Swap = " + DoubleToStr(Lswap,2) + " / " + DoubleToStr(Sswap,2);
        ObjNameI = IndiName + "-" + ccyp + "-i3";
        ObjectCreate(ObjNameI,OBJ_TEXT,Wnum,iTime(sym,tmf,j+13*SpacingBetweenCandles/2),48);
        ObjectSetText(ObjNameI, info, TextSize, TextFont, TextColor); 

        int    k         = 0;
        double DailyMove = 0;
        for (i=1; i<=10; i++)  {
          if (TimeDayOfWeek(iTime(ccyp,PERIOD_D1,i)) > 0)  {
            k++;
            DailyMove += (iHigh(ccyp,PERIOD_D1,i) - iLow(ccyp,PERIOD_D1,i)) / pnt;
        } }  
        DailyMove = DivZero(DailyMove,k);   
        if (dig == 3 || dig == 5) 
          DailyMove /= 10;

        info = "  Spread = " + DoubleToStr(spr,1) + "  (" + DoubleToStr(spr * 100 / DailyMove, 2) + "%)";
        ObjNameI = IndiName + "-" + ccyp + "-i4";
        ObjectCreate(ObjNameI,OBJ_TEXT,Wnum,iTime(sym,tmf,j+13*SpacingBetweenCandles/2),23);
        ObjectSetText(ObjNameI, info, TextSize, TextFont, TextColor); 

        info = "  Pip Value = " + DoubleToStr(tickval,3);
        ObjNameI = IndiName + "-" + ccyp + "-i5";
        ObjectCreate(ObjNameI,OBJ_TEXT,Wnum,iTime(sym,tmf,j+13*SpacingBetweenCandles/2),-2);
        ObjectSetText(ObjNameI, info, TextSize, TextFont, TextColor); 
      }  
      
      j += 20*SpacingBetweenCandles;
    }
  }  
  return(0);
} 
/*
//+------------------------------------------------------------------+
int MathSign(double n)
//+------------------------------------------------------------------+
 {
   if (n > 0) return(1);
   else if (n < 0) return (-1);
   else return(0);
 }  

//+------------------------------------------------------------------+
double MathFix(double n, int d)
//+------------------------------------------------------------------+
 {
   return(MathRound(n*MathPow(10,d)+0.000000000001)/MathPow(10,d));
 }  
*/
//+------------------------------------------------------------------+
double DivZero(double n, double d)
//+------------------------------------------------------------------+
 {
   if (d == 0) return(0);  else return(n/d);
 }  

//+------------------------------------------------------------------+
bool StrToBool(string str)
//+------------------------------------------------------------------+
{
  str = StringLower(StringSubstr(str,0,1));
  if (str == "t" || str == "y" || str == "1")   return(true);
  return(false);
}  

//+------------------------------------------------------------------+
string StringUpper(string str)
//+------------------------------------------------------------------+
{
  string outstr = "";
  string lower  = "abcdefghijklmnopqrstuvwxyz";
  string upper  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  for(int i=0; i<StringLen(str); i++)  {
    int t1 = StringFind(lower,StringSubstr(str,i,1),0);
    if (t1 >=0)  
      outstr = outstr + StringSubstr(upper,t1,1);
    else
      outstr = outstr + StringSubstr(str,i,1);
  }
  return(outstr);
}  

//+------------------------------------------------------------------+
string StringTrim(string str)
//+------------------------------------------------------------------+
{
  string outstr = "";
  for(int i=0; i<StringLen(str); i++)  {
    if (StringSubstr(str,i,1) != " ")
      outstr = outstr + StringSubstr(str,i,1);
  }
  return(outstr);
}
//+------------------------------------------------------------------+
string TFToStr(int tf)
//+------------------------------------------------------------------+
// Converts a MT4-numeric timeframe to its descriptor string
// Usage:   string s=TFToStr(15) returns s="M15"
{
  switch (tf)  {
    case     1 :  return("M1");
    case     5 :  return("M5");
    case    15 :  return("M15");
    case    30 :  return("M30");
    case    60 :  return("H1");
    case   240 :  return("H4");
    case  1440 :  return("D1");
    case 10080 :  return("W1");
    case 43200 :  return("MN");
  }  
  return(0);
}  

//+------------------------------------------------------------------+
int StrToTF(string str)
//+------------------------------------------------------------------+
// Converts a timeframe string to its MT4-numeric value
// Usage:   int x=StrToTF("M15")   returns x=15
{
  if (str == "M1")   return(1);
  if (str == "M5")   return(5);
  if (str == "M15")  return(15);
  if (str == "M30")  return(30);
  if (str == "H1")   return(60);
  if (str == "H4")   return(240);
  if (str == "D1")   return(1440);
  if (str == "W1")   return(10080);
  if (str == "MN")   return(43200);
  return(0);
}  

//+------------------------------------------------------------------+
int CheckPresets()
//+------------------------------------------------------------------+
{
//---------------------------------------------------------------------------------------------------------------
//    Enter the file name in here
//---------------------------------------------------------------------------------------------------------------
  string FileName = "Presets---Recent Candles.TXT";
//---------------------------------------------------------------------------------------------------------------
  int handle = FileOpen(FileName, FILE_CSV|FILE_READ,';');
  if (handle > 0)  {
    while(!FileIsEnding(handle))  {
      string text  = FileReadString(handle);
      int t0 = StringFind(text,"//",0);
      if (t0 == 0)       text = "";    
      else if (t0 > 0)   text = StringSubstr(text,0,t0);
      string temp  = "";
      int    quote = 0;
      for(int i=0; i<StringLen(text); i++)   {
        string char = StringSubstr(text,i,1);
        if (char == "\x22")     quote = 1 - quote;  
        else if (quote == 1)    temp  = temp + char;
        else if (char != " " && char != "_") temp  = temp + StringLower(char);  
      }
      if (StringLen(temp) > 0) {
        int equal = StringFind(temp,"=",0);
        int semic = StringFind(temp,";",0);
        string pname = "";
        pname   = StringSubstr(temp,0,equal);
        string pvalue = StringSubstr(temp,equal+1,semic-equal+1);
        if (pvalue != "*")  {
//---------------------------------------------------------------------------------------------------------------
//    Parameter assignment statements go in here
//---------------------------------------------------------------------------------------------------------------
          if (pname == "currencypairs")            CurrencyPairs            = pvalue;                     else
          if (pname == "timeframes")               TimeFrames               = pvalue;                     else
          if (pname == "numcandles")               NumCandles               = pvalue;                     else
          if (pname == "historicalshift")          HistoricalShift          = pvalue;                     else
          if (pname == "candlewidth")              CandleWidth              = StrToInteger(pvalue);       else
          if (pname == "spacingbetweencandles")    SpacingBetweenCandles    = StrToInteger(pvalue);       else
          if (pname == "candleupcolor")            CandleUpColor            = StrToColor(pvalue);         else
          if (pname == "candledowncolor")          CandleDownColor          = StrToColor(pvalue);         else
          if (pname == "textcolor")                TextColor                = StrToColor(pvalue);         else
          if (pname == "textfont")                 TextFont                 = pvalue;                     else
          if (pname == "textsize")                 TextSize                 = StrToInteger(pvalue);       else
          if (pname == "backgroundcolor")          BackgroundColor          = StrToColor(pvalue);         else
          if (pname == "displayinfo")              DisplayInfo              = StrToBool(pvalue);          else
          if (pname == "displayccyname")           DisplayCcyName           = StrToBool(pvalue);          else
          if (pname == "displaytf")                DisplayTF                = StrToBool(pvalue);          else
          if (pname == "refresheveryxmins")        RefreshEveryXMins        = StrToInteger(pvalue);       else
          if (pname == "heikinashicandles")        HeikinAshiCandles        = StrToBool(pvalue);         

//---------------------------------------------------------------------------------------------------------------
        }
      }  
      temp = FileReadString(handle);
    }
    FileClose(handle);
  }  
  
  CurrencyPairs  = StringUpper(CurrencyPairs);
  if (CurrencyPairs == "")  CurrencyPairs = Symbol();
  ccy            = CurrencyPairs;
  if (StringSubstr(CurrencyPairs,StringLen(CurrencyPairs)-1,1) != ",")  CurrencyPairs = CurrencyPairs + ",";
  TimeFrames     = StringTrim(StringUpper(TimeFrames));
  if (TimeFrames == "")  TimeFrames = TFToStr(Period());
  if (StringSubstr(TimeFrames,StringLen(TimeFrames)-1,1) != ",")  TimeFrames = TimeFrames + ",";
  if (NumCandles == "")   NumCandles = "5";
  if (StringSubstr(NumCandles,StringLen(NumCandles)-1,1) != ",")  NumCandles = NumCandles + ",";

  ccCP = StringFindCount(CurrencyPairs,",");
  ccTF = StringFindCount(TimeFrames,",");
  ccNC = StringFindCount(NumCandles,",");
  ccHS = StringFindCount(HistoricalShift,",");
  for (i=0; i<30; i++)
    CP[i] = "";
  ArrayInitialize(TF,0);  
  ArrayInitialize(NC,-1);
  ArrayInitialize(HS,0);  
  ArrayInitialize(IC,0);  
  int comma1 = -1;
  for (i=0; i<30; i++)  {
    int comma2 = StringFind(CurrencyPairs,",",comma1+1);
    temp  = StringSubstr(CurrencyPairs,comma1+1,comma2-comma1-1);
    if (StringFind(temp,"*",0) >= 0)   {
      temp = StringReplace(temp,"*","");
      IC[i] = 1;
    }
    CP[i] = ExpandCcy(temp);
    if (StringLen(CP[i]) > 6)
      CP[i] = StringSubstr(CP[i],0,6) + StringLower(StringSubstr(CP[i],6));
    if (comma2 >= StringLen(CurrencyPairs)-1)   break;
    comma1 = comma2;
  }  
  comma1 = -1;
  for (i=0; i<9; i++)  {
    comma2 = StringFind(TimeFrames,",",comma1+1);
    temp  = StringSubstr(TimeFrames,comma1+1,comma2-comma1-1);
    TF[i] = StrToTF(temp);
    if (comma2 >= StringLen(TimeFrames)-1)   break;
    comma1 = comma2;
  }  
  comma1 = -1;
  for (i=0; i<9; i++)  {
    comma2 = StringFind(NumCandles,",",comma1+1);
    temp  = StringSubstr(NumCandles,comma1+1,comma2-comma1-1);
    NC[i] = StrToInteger(temp);
    if (comma2 >= StringLen(NumCandles)-1)   break;
    comma1 = comma2;
  }
  if (ccNC == 1)   
    for (i=0; i<ccTF; i++)  
      NC[i] = NC[0];
  comma1 = -1;
  for (i=0; i<9; i++)  {
    comma2 = StringFind(HistoricalShift,",",comma1+1);
    temp  = StringSubstr(HistoricalShift,comma1+1,comma2-comma1-1);
    HS[i] = StrToInteger(temp);
    if (comma2 >= StringLen(HistoricalShift)-1)   break;
    comma1 = comma2;
  }
  if (ccHS == 1)   
    for (i=0; i<ccHS; i++)  
      HS[i] = HS[0];

/*
  for (i=0; i<9; i++)
    Print(i + "     " + CP[i] + "     " + TF[i] + "     " + NC[i]);  
  
    Print("**** CurrencyPairs = " + CurrencyPairs); 
    Print("**** TimeFrames = " + TimeFrames); 
    Print("**** NumCandles = " + NumCandles); 
    Print("**** Spacing = " + SpacingBetweenCandles); 
    Print("**** UpColor = " + CandleUpColor); 
    Print("**** DownColor = " + CandleDownColor); 
    Print("**** TextColor = " + TextColor); 
    Print("**** BGColor = " + BackgroundColor); 
    Print("**** Info = " + DisplayInfo); 
    Print("**** Refresh = " + RefreshEveryXMins); 
*/  

  int checksum = 0;
  string str = CurrencyPairs + TimeFrames + NumCandles + HistoricalShift + SpacingBetweenCandles + CP[0] + HeikinAshiCandles;
  for (i=0; i<StringLen(str); i++)  
    checksum += (i+1) * StringGetChar(str,i);
  IndiName = "RecentCandles-" + checksum;
  IndicatorShortName(IndiName);
  return(0);
}

//+------------------------------------------------------------------+
string StringLower(string str)
//+------------------------------------------------------------------+
{
  string outstr = "";
  string lower  = "abcdefghijklmnopqrstuvwxyz";
  string upper  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  for(int i=0; i<StringLen(str); i++)  {
    int t1 = StringFind(upper,StringSubstr(str,i,1),0);
    if (t1 >=0)  
      outstr = outstr + StringSubstr(lower,t1,1);
    else
      outstr = outstr + StringSubstr(str,i,1);
  }
  return(outstr);
}



//+------------------------------------------------------------------+
int StrToColor(string str)
//+------------------------------------------------------------------+
{
  str = StringLower(str);
  if (str == "aliceblue")              return(0xFFF8F0);
  if (str == "antiquewhite")           return(0xD7EBFA);
  if (str == "aqua")                   return(0xFFFF00);
  if (str == "aquamarine")             return(0xD4FF7F);
  if (str == "beige")                  return(0xDCF5F5);
  if (str == "bisque")                 return(0xC4E4FF);
  if (str == "black")                  return(0x000000);
  if (str == "blanchedalmond")         return(0xCDEBFF);
  if (str == "blue")                   return(0xFF0000);
  if (str == "blueviolet")             return(0xE22B8A);
  if (str == "brown")                  return(0x2A2AA5);
  if (str == "burlywood")              return(0x87B8DE);
  if (str == "cadetblue")              return(0xA09E5F);
  if (str == "chartreuse")             return(0x00FF7F);
  if (str == "chocolate")              return(0x1E69D2);
  if (str == "coral")                  return(0x507FFF);
  if (str == "cornflowerblue")         return(0xED9564);
  if (str == "cornsilk")               return(0xDCF8FF);
  if (str == "crimson")                return(0x3C14DC);
  if (str == "darkblue")               return(0x8B0000);
  if (str == "darkgoldenrod")          return(0x0B86B8);
  if (str == "darkgray")               return(0xA9A9A9);
  if (str == "darkgreen")              return(0x006400);
  if (str == "darkkhaki")              return(0x6BB7BD);
  if (str == "darkolivegreen")         return(0x2F6B55);
  if (str == "darkorange")             return(0x008CFF);
  if (str == "darkorchid")             return(0xCC3299);
  if (str == "darksalmon")             return(0x7A96E9);
  if (str == "darkseagreen")           return(0x8BBC8F);
  if (str == "darkslateblue")          return(0x8B3D48);
  if (str == "darkslategray")          return(0x4F4F2F);
  if (str == "darkturquoise")          return(0xD1CE00);
  if (str == "darkviolet")             return(0xD30094);
  if (str == "deeppink")               return(0x9314FF);
  if (str == "deepskyblue")            return(0xFFBF00);
  if (str == "dimgray")                return(0x696969);
  if (str == "dodgerblue")             return(0xFF901E);
  if (str == "firebrick")              return(0x2222B2);
  if (str == "forestgreen")            return(0x228B22);
  if (str == "gainsboro")              return(0xDCDCDC);
  if (str == "gold")                   return(0x00D7FF);
  if (str == "goldenrod")              return(0x20A5DA);
  if (str == "gray")                   return(0x808080);
  if (str == "green")                  return(0x008000);
  if (str == "greenyellow")            return(0x2FFFAD);
  if (str == "honeydew")               return(0xF0FFF0);
  if (str == "hotpink")                return(0xB469FF);
  if (str == "indianred")              return(0x5C5CCD);
  if (str == "indigo")                 return(0x82004B);
  if (str == "ivory")                  return(0xF0FFFF);
  if (str == "khaki")                  return(0x8CE6F0);
  if (str == "lavender")               return(0xFAE6E6);
  if (str == "lavenderblush")          return(0xF5F0FF);
  if (str == "lawngreen")              return(0x00FC7C);
  if (str == "lemonchiffon")           return(0xCDFAFF);
  if (str == "lightblue")              return(0xE6D8AD);
  if (str == "lightcoral")             return(0x8080F0);
  if (str == "lightcyan")              return(0xFFFFE0);
  if (str == "lightgoldenrod")         return(0xD2FAFA);
  if (str == "lightgray")              return(0xD3D3D3);
  if (str == "lightgreen")             return(0x90EE90);
  if (str == "lightpink")              return(0xC1B6FF);
  if (str == "lightsalmon")            return(0x7AA0FF);
  if (str == "lightseagreen")          return(0xAAB220);
  if (str == "lightskyblue")           return(0xFACE87);
  if (str == "lightslategray")         return(0x998877);
  if (str == "lightsteelblue")         return(0xDEC4B0);
  if (str == "lightyellow")            return(0xE0FFFF);
  if (str == "lime")                   return(0x00FF00);
  if (str == "limegreen")              return(0x32CD32);
  if (str == "linen")                  return(0xE6F0FA);
  if (str == "magenta")                return(0xFF00FF);
  if (str == "maroon")                 return(0x000080);
  if (str == "mediumaquamarine")       return(0xAACD66);
  if (str == "mediumblue")             return(0xCD0000);
  if (str == "mediumorchid")           return(0xD355BA);
  if (str == "mediumpurple")           return(0xDB7093);
  if (str == "mediumseagreen")         return(0x71B33C);
  if (str == "mediumslateblue")        return(0xEE687B);
  if (str == "mediumspringgreen")      return(0x9AFA00);
  if (str == "mediumturquoise")        return(0xCCD148);
  if (str == "mediumvioletred")        return(0x8515C7);
  if (str == "midnightblue")           return(0x701919);
  if (str == "mintcream")              return(0xFAFFF5);
  if (str == "mistyrose")              return(0xE1E4FF);
  if (str == "moccasin")               return(0xB5E4FF);
  if (str == "navajowhite")            return(0xADDEFF);
  if (str == "navy")                   return(0x800000);
  if (str == "none")                   return(C'0x00,0x00,0x00');
  if (str == "oldlace")                return(0xE6F5FD);
  if (str == "olive")                  return(0x008080);
  if (str == "olivedrab")              return(0x238E6B);
  if (str == "orange")                 return(0x00A5FF);
  if (str == "orangered")              return(0x0045FF);
  if (str == "orchid")                 return(0xD670DA);
  if (str == "palegoldenrod")          return(0xAAE8EE);
  if (str == "palegreen")              return(0x98FB98);
  if (str == "paleturquoise")          return(0xEEEEAF);
  if (str == "palevioletred")          return(0x9370DB);
  if (str == "papayawhip")             return(0xD5EFFF);
  if (str == "peachpuff")              return(0xB9DAFF);
  if (str == "peru")                   return(0x3F85CD);
  if (str == "pink")                   return(0xCBC0FF);
  if (str == "plum")                   return(0xDDA0DD);
  if (str == "powderblue")             return(0xE6E0B0);
  if (str == "purple")                 return(0x800080);
  if (str == "red")                    return(0x0000FF);
  if (str == "rosybrown")              return(0x8F8FBC);
  if (str == "royalblue")              return(0xE16941);
  if (str == "saddlebrown")            return(0x13458B);
  if (str == "salmon")                 return(0x7280FA);
  if (str == "sandybrown")             return(0x60A4F4);
  if (str == "seagreen")               return(0x578B2E);
  if (str == "seashell")               return(0xEEF5FF);
  if (str == "sienna")                 return(0x2D52A0);
  if (str == "silver")                 return(0xC0C0C0);
  if (str == "skyblue")                return(0xEBCE87);
  if (str == "slateblue")              return(0xCD5A6A);
  if (str == "slategray")              return(0x908070);
  if (str == "snow")                   return(0xFAFAFF);
  if (str == "springgreen")            return(0x7FFF00);
  if (str == "steelblue")              return(0xB48246);
  if (str == "tan")                    return(0x8CB4D2);
  if (str == "teal")                   return(0x808000);
  if (str == "thistle")                return(0xD8BFD8);
  if (str == "tomato")                 return(0x4763FF);
  if (str == "turquoise")              return(0xD0E040);
  if (str == "violet")                 return(0xEE82EE);
  if (str == "wheat")                  return(0xB3DEF5);
  if (str == "white")                  return(0xFFFFFF);
  if (str == "whitesmoke")             return(0xF5F5F5);
  if (str == "yellow")                 return(0x00FFFF);
  if (str == "yellowgreen")            return(0x32CD9A);

  int t1 = StringFind(str,",",0);
  int t2 = StringFind(str,",",t1+1);
  if (t1>0 && t2>0) {
    int red   = StrToInteger(StringSubstr(str,0,t1));
    int green = StrToInteger(StringSubstr(str,t1+1,t2-1));
    int blue  = StrToInteger(StringSubstr(str,t2+1,StringLen(str)));
    return(blue*256*256+green*256+red);
  }  

  return(0);
}  

//+------------------------------------------------------------------+
int StringFindCount(string str, string str2)
//+------------------------------------------------------------------+
// Returns the number of occurrences of STR2 in STR
// Usage:   int x = StringFindCount("ABCDEFGHIJKABACABB","AB")   returns x = 3
{
  int c = 0;
  for (int i=0; i<StringLen(str); i++)
    if (StringSubstr(str,i,StringLen(str2)) == str2)  c++;
  return(c);
}

//+------------------------------------------------------------------+
string ExpandCcy(string str)
//+------------------------------------------------------------------+
{
  str = StringTrim(StringUpper(str));
  if (StringLen(str) < 1 || StringLen(str) > 2)   return(str);
  string str2 = "";
  for (int i=0; i<StringLen(str); i++)   {
    string char = StringSubstr(str,i,1);
    if (char == "A")  str2 = str2 + "AUD";     else
    if (char == "C")  str2 = str2 + "CAD";     else   
    if (char == "E")  str2 = str2 + "EUR";     else   
    if (char == "F")  str2 = str2 + "CHF";     else   
    if (char == "G")  str2 = str2 + "GBP";     else   
    if (char == "J")  str2 = str2 + "JPY";     else   
    if (char == "N")  str2 = str2 + "NZD";     else   
    if (char == "U")  str2 = str2 + "USD";     else   
    if (char == "H")  str2 = str2 + "HKD";     else   
    if (char == "S")  str2 = str2 + "SGD";     else   
    if (char == "Z")  str2 = str2 + "ZAR";   
  }  
  return(str2);
}

//+------------------------------------------------------------------+
string StringReplace(string str, string str1, string str2)  {
//+------------------------------------------------------------------+
// Usage: replaces every occurrence of str1 with str2 in str
  string outstr = "";
  for (int i=0; i<StringLen(str); i++)   {
    if (StringSubstr(str,i,StringLen(str1)) == str1)  {
      outstr = outstr + str2;
      i += StringLen(str1) - 1;
    }
    else
      outstr = outstr + StringSubstr(str,i,1);
  }
  return(outstr);
}









