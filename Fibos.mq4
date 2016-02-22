//+------------------------------------------------------------------+
//|                                                        Fibos.mq4 |
//|                                        Developed by Coders' Guru |
//|                                            http://www.xpworx.com |
//+------------------------------------------------------------------+

#property copyright "Coders' Guru"
#property link      "http://www.xpworx.com"
string   ver  = "Last Modified: 2008.02.22 19:20";

#property indicator_chart_window
#property  indicator_buffers 7

extern bool  Higher_To_Lower  = true;    //else Lower_To_Higher
extern bool  DrawVerticalLines = true;
extern int   StartBar = 0;
extern int   BarsBack = 20;

double f_1[];
double f_2[];
double f_3[];
double f_4[];
double f_5[];
double f_6[];
double f_7[];

void DeleteAllObjects()
{
   int objs = ObjectsTotal();
   string name;
   for(int cnt=ObjectsTotal()-1;cnt>=0;cnt--)
   {
      name=ObjectName(cnt);
      if (StringFind(name,"V_",0)>-1) ObjectDelete(name);
      if (StringFind(name,"H_",0)>-1) ObjectDelete(name);
      if (StringFind(name,"f_",0)>-1) ObjectDelete(name);
      if (StringFind(name,"fib",0)>-1) ObjectDelete(name);
      if (StringFind(name,"trend",0)>-1) ObjectDelete(name);
      WindowRedraw();
   }
}


void CalcFibo()
{
  
  DeleteAllObjects();
  
  int lowest_bar = iLowest(NULL,0,MODE_LOW,BarsBack,StartBar);
  int highest_bar = iHighest(NULL,0,MODE_HIGH,BarsBack,StartBar);
  
  double higher_point = 0;
  double lower_point = 0;
  higher_point=High[highest_bar];
  lower_point=Low[lowest_bar];
  
  if(DrawVerticalLines) DrawVerticalLine("V_UPPER",highest_bar,Blue);
  if(DrawVerticalLines) DrawVerticalLine("V_LOWER",lowest_bar,Blue);
  
  int i = 0;
  
  if(Higher_To_Lower)
  {
      for(i = 0; i < 500; i++)
      {
         f_1[i] = higher_point;
         f_2[i] = NormalizeDouble(lower_point+(higher_point-lower_point)*0.236,Digits);
         f_3[i] = NormalizeDouble(lower_point+(higher_point-lower_point)*0.382,Digits);
         f_4[i] = NormalizeDouble(lower_point+(higher_point-lower_point)*0.5,Digits);
         f_5[i] = NormalizeDouble(lower_point+(higher_point-lower_point)*0.618,Digits);
         f_6[i] = NormalizeDouble(lower_point+(higher_point-lower_point)*1.618,Digits);
         f_7[i] = lower_point;
      }
      ObjectCreate("fib",OBJ_FIBO,0,0,higher_point,0,lower_point);
      ObjectCreate("trend",OBJ_TREND,0,Time[highest_bar],higher_point,Time[lowest_bar],lower_point);
      ObjectSet("trend",OBJPROP_STYLE,STYLE_DOT);
      ObjectSet("trend",OBJPROP_RAY,false);
  }
  else
  {
      for(i = 0; i < 500; i++)
      {
         f_7[i] = higher_point;
         f_6[i] = NormalizeDouble(lower_point+(higher_point-lower_point)*0.236,Digits);
         f_5[i] = NormalizeDouble(lower_point+(higher_point-lower_point)*0.382,Digits);
         f_4[i] = NormalizeDouble(lower_point+(higher_point-lower_point)*0.5,Digits);
         f_3[i] = NormalizeDouble(lower_point+(higher_point-lower_point)*0.618,Digits);
         f_2[i] = NormalizeDouble(lower_point+(higher_point-lower_point)*1.618,Digits);
         f_1[i] = lower_point;
      }
      DeleteAllObjects();
      ObjectCreate("fib",OBJ_FIBO,0,0,lower_point,0,higher_point);
      ObjectCreate("trend",OBJ_TREND,0,Time[lowest_bar],lower_point,Time[highest_bar],higher_point);
      ObjectSet("trend",OBJPROP_STYLE,STYLE_DOT);
      ObjectSet("trend",OBJPROP_RAY,false);
  }
  
  
}

void DrawVerticalLine(string name , int bar , color clr)
{
   if(ObjectFind(name)==false)
   {
      ObjectCreate(name,OBJ_VLINE,0,Time[bar],0);
      ObjectSet(name,OBJPROP_COLOR,clr);
      ObjectSet(name,OBJPROP_WIDTH,2);
      WindowRedraw();
   }
   else
   {
      ObjectDelete(name);
      ObjectCreate(name,OBJ_VLINE,0,Time[bar],0);
      ObjectSet(name,OBJPROP_COLOR,clr);
      ObjectSet(name,OBJPROP_WIDTH,2);
      WindowRedraw();
   }

}



int deinit()
{
   DeleteAllObjects();
   return (0);
}

int init()
{
  DeleteAllObjects();
  SetIndexBuffer(0,f_1);
  SetIndexBuffer(1,f_2);
  SetIndexBuffer(2,f_3);
  SetIndexBuffer(3,f_4);
  SetIndexBuffer(4,f_5);
  SetIndexBuffer(5,f_6);
  SetIndexBuffer(6,f_7);
  return(0);
}


int start()
{
  CalcFibo();
  return(0);
}







