//+------------------------------------------------------------------+
//|                                                         days.mq4 |
//|                Copyright © 2005, Nick Bilak, beluck[AT]gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Nick Bilak"
#property link      "http://metatrader.50webs.com/"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1 Blue
#property indicator_color2 Black
#property indicator_color3 Red
#property indicator_minimum -10
#property indicator_maximum 10
#property indicator_width1 3
#property indicator_width2 3
#property indicator_width3 3

extern string font="Arial";
extern int fontSize=10;
extern string USD="15:30-23:00";
extern string EUR="08:00-17:00";
extern string JPY="02:00-09:00";


double buf0[],b1[],b2[],b3[],e1[],e2[];
int eur1,eur2,usd1,usd2,jpy1,jpy2;

int init()  {
   IndicatorBuffers(6);
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2);
   SetIndexBuffer(0,buf0);
   ArrayInitialize(buf0,-12);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2);
   SetIndexBuffer(1,e1);
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,2);
   SetIndexBuffer(2,e2);
   SetIndexBuffer(3,b1);
   SetIndexBuffer(4,b2);
   SetIndexBuffer(5,b3);
   SetIndexEmptyValue(1,0);
   SetIndexEmptyValue(2,0);
   SetIndexEmptyValue(3,0);
   eur1=StrToInteger(StringSubstr(EUR,0,2))*100;
   eur2=StrToInteger(StringSubstr(EUR,6,2))*100;
   usd1=StrToInteger(StringSubstr(USD,0,2))*100;
   usd2=StrToInteger(StringSubstr(USD,6,2))*100;
   jpy1=StrToInteger(StringSubstr(JPY,0,2))*100;
   jpy2=StrToInteger(StringSubstr(JPY,6,2))*100;
   return(0);
}
int deinit() {
   ObjectsDeleteAll(0,OBJ_TEXT);
}
int start() {
   int counted_bars=IndicatorCounted();
   int i,j,limit,c,lev,t;
   double line;
   string days[] = {"Su","Mo","Tu","We","Th","Fr","Sa"};
   
   if (counted_bars<0) return(-1);
   if (counted_bars>0) counted_bars--;
   //limit=6*24*60/Period();
   limit=Bars-2;
   if(counted_bars>=2) limit=Bars-counted_bars+1;
   int wn=WindowFind("days");
   color day;
   if (wn<=0) wn=1;
   for (i=limit;i>=0;i--)   {
      if (TimeDay(Time[i])!=TimeDay(Time[i+1])) {
         ObjectDelete(TimeToStr(Time[i],TIME_DATE|TIME_MINUTES)+"-"+i);
			ObjectCreate(TimeToStr(Time[i],TIME_DATE|TIME_MINUTES)+"-"+i,OBJ_TEXT,wn,Time[i],8);
			ObjectSetText(TimeToStr(Time[i],TIME_DATE|TIME_MINUTES)+"-"+i, days[TimeDayOfWeek(Time[i])], fontSize, font, indicator_color1);
      }
      b1[i]=0; b2[i]=0; b3[i]=0; e1[i]=0; e2[i]=0;
      t=TimeHour(Time[i])*100+TimeMinute(Time[i]);
      //Symbol()=="EURUSD"
      if (StringSubstr(Symbol(),3,3)=="EUR" || StringSubstr(Symbol(),0,3)=="EUR") {
         if ( eur1<eur2 && t>=eur1 && t<=eur2 ) {
            b1[i]=1;
         }
         if ( eur1>eur2 && !(t>=eur1 && t<=eur2) ) {
            b1[i]=1;
         }
      }
      if (StringSubstr(Symbol(),3,3)=="USD" || StringSubstr(Symbol(),0,3)=="USD") {
         if ( usd1<usd2 && (t>=usd1 && t<=usd2) ) {
            b2[i]=1;
         }
         if ( usd1>usd2 && !(t>=usd1 && t<=usd2) ) {
            b2[i]=1;
         }
      }
      if (StringSubstr(Symbol(),3,3)=="JPY" || StringSubstr(Symbol(),0,3)=="JPY") {
         if ( jpy1<jpy2 && (t>=jpy1 && t<=jpy2) ) {
            b3[i]=1;
         }
         if ( jpy1>jpy2 && !(t>=jpy1 && t<=jpy2) ) {
            b3[i]=1;
         }
      }
      if (Symbol()=="USDJPY") {
         if (b3[i]>0 || b2[i]>0) e1[i]=1;
         if (b3[i]>0 && b2[i]>0) { e2[i]=1; e2[i]=1; }
      } else
      if (Symbol()=="EURJPY") {
         if (b3[i]>0 || b1[i]>0) e1[i]=1;
         if (b3[i]>0 && b1[i]>0) { e2[i]=1; e2[i]=1; }
      } else
      if (Symbol()=="EURUSD") {
         if (b1[i]>0 || b2[i]>0) e1[i]=1;
         if (b1[i]>0 && b2[i]>0) { e2[i]=1; e2[i]=1; }
      } else
      if (StringSubstr(Symbol(),3,3)=="JPY" || StringSubstr(Symbol(),0,3)=="JPY") {
         if (b3[i]>0) e1[i]=1;
      } else
      if (StringSubstr(Symbol(),3,3)=="USD" || StringSubstr(Symbol(),0,3)=="USD") {
         if (b2[i]>0) e1[i]=1;
      } else
      if (StringSubstr(Symbol(),3,3)=="EUR" || StringSubstr(Symbol(),0,3)=="EUR") {
         if (b1[i]>0) e1[i]=1;
      }
   }
   return(0);
}


