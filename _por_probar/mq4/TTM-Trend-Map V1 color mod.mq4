//+------------------------------------------------------------------+
//|                                                TTM-Trend-Map.mq4 |
//|                                  Tamir Bleicher, +972-54-4941653 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Tamir Bleicher, +972-54-4941653"
#property link      ""
//-- This indicator will show a "Map" of the trends at different time frames on the currencies of your choice, according to the TTM-Trend indicator.
//-- You should have the TTM-Trend indicator in your indicator's folder for this indicator to work.
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_buffers 1
#property indicator_color1 Red
//---- input parameters
extern int       CompBars=6;//- Do not change. This is the same parameter as in the TTM-Trend indicator.
extern string    SymbolSuffix="";//- If your broker names the currency pairs with a suffix for a mini account (like an "m", for example), enter the suffix here.
extern string    PairsList="GBPUSD,EURUSD,USDCHF,USDJPY";//- This is where you add the currency pairs you want to track. Add each one of them separated by a coma.
extern string    MainCurrency="";//- If you want to see only pairs where the USD (or any other currency) appears just enter here USD (or the currency of your choice) and it will show all USD (or the currency you chose) pairs.
extern bool      Invert=false;//- If you chose to show all USD pairs and you want to show them with the USD as the first currency, change this setting to "true".
extern color     UpTrendColor=Green;
extern color     DownTrendColor=Red;
extern color     NoTrendColor=Yellow;
extern bool      MN=true;//- Change to "false" if you don't want to show this time frame.
extern bool      W1=true;//- Change to "false" if you don't want to show this time frame.
extern bool      D1=true;//- Change to "false" if you don't want to show this time frame.
extern bool      H4=true;//- Change to "false" if you don't want to show this time frame.
extern bool      H1=true;//- Change to "false" if you don't want to show this time frame.
extern bool      M30=true;//- Change to "false" if you don't want to show this time frame.
extern bool      M15=true;//- Change to "false" if you don't want to show this time frame.
extern bool      M5=true;//- Change to "false" if you don't want to show this time frame.
extern bool      M1=true;//- Change to "false" if you don't want to show this time frame.

//---- buffers
double ExtMapBuffer1[];
string Pair[20];
int    SymNo;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
  
  int i,j,k;
  string Cur;
  bool AllCur;
  
//---- indicators
   SetIndexStyle(0,DRAW_SECTION);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexEmptyValue(0,0.0);
   
   AllCur=(StringFind(PairsList,MainCurrency,0)==-1);
   
   for (i=0; i<20; i++) Pair[i]="";
   for (i=0, j=0, k=1; i<20 && k>0; )
   {
      
      k=StringFind(PairsList,",",j);
      if (k==0) Cur=StringSubstr(PairsList,j,0);
      else Cur=StringSubstr(PairsList,j,k-j);
         

      if (AllCur || StringFind(Cur,MainCurrency,0)>-1) 
      {
         Pair[i]=Cur;
         i++;
      }
     
      j=StringFind(PairsList,",",j)+1;
      if (j==0) break;

   }
   SymNo=i;
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
  
int trend(string sym,int per)
{
   int t1=(iCustom(sym,per,"ttm-trend",CompBars,4,1));
   int t2=(iCustom(sym,per,"ttm-trend",CompBars,4,2));
   
   if (t1==1 && t2==1) return (1);
   if (t1==-1 && t2==-1) return (-1);
   else return (0);
}

void output_arrow(string label, string sym,int bar, double price, int per, string per_name, bool invert, bool create)
{
   
   datetime time = Time[bar];
   string sym1;

   if (invert && StringSubstr(sym,3,3)==MainCurrency)
      sym1=StringSubstr(sym,3,3)+StringSubstr(sym,0,3)+SymbolSuffix;
   else { sym1=sym; invert=false; }

   if (sym=="Title")
   {
      ObjectDelete(label+per_name);
      if (create)
      {
         ObjectCreate(label+per_name,OBJ_TEXT,1,time,price);
         ObjectSetText(label+per_name,per_name);
         ObjectSet(label+per_name,OBJPROP_COLOR,White);
         ObjectSet(label+per_name,OBJPROP_WIDTH,2);
      }
   }  
   else if (per==0)
   {
      ObjectDelete(label);
      if (create)
      {
         ObjectCreate(label,OBJ_TEXT,1,time,price);
         ObjectSetText(label,sym1);
         ObjectSet(label+per_name,OBJPROP_COLOR,White);
         ObjectSet(label+per_name,OBJPROP_WIDTH,2);
      }
   }
   else
   {
      ObjectDelete(label+per_name);

      if (create)
      {
         int t=trend(sym,per);
         if (invert) t=-t;
   
         if (t==1)
         {
            ObjectCreate(label+per_name,OBJ_ARROW,1,time,price);
            ObjectSet(label+per_name,OBJPROP_COLOR,UpTrendColor);
            ObjectSet(label+per_name,OBJPROP_ARROWCODE,225);
            ObjectSet(label+per_name,OBJPROP_WIDTH,2);

         }
         else if (t==-1)
         {
            ObjectCreate(label+per_name,OBJ_ARROW,1,time,price);
            ObjectSet(label+per_name,OBJPROP_COLOR,DownTrendColor);
            ObjectSet(label+per_name,OBJPROP_ARROWCODE,226);
            ObjectSet(label+per_name,OBJPROP_WIDTH,2);
         }
         else
         {
            ObjectCreate(label+per_name,OBJ_ARROW,1,time,price);
            ObjectSet(label+per_name,OBJPROP_COLOR,NoTrendColor);
            ObjectSet(label+per_name,OBJPROP_ARROWCODE,104);
            ObjectSet(label+per_name,OBJPROP_WIDTH,2);
         }
      }
   }
}

void output_line(string label, string sym,double price, bool invert, bool create)
{
   int n=MN+W1+M1+D1+H4+H1+M30+M15+M1;
   int br=MathRound(BarsPerWindow()/12);
   int D=MN+W1+D1;
   int H=D+H4+H1;

   output_arrow(label,sym,MathRound(br*10.5),price,0,"",invert,create);
   output_arrow(label,sym,br*9,price,PERIOD_MN1,"MN",invert,create&&MN);
   output_arrow(label,sym,br*(9-MN),price,PERIOD_W1,"W1",invert,create&&W1);
   output_arrow(label,sym,br*(9-MN-W1),price,PERIOD_D1,"D1",invert,create&&D1);
   output_arrow(label,sym,br*(9-D),price,PERIOD_H4,"H4",invert,create&&H4);
   output_arrow(label,sym,br*(9-D-H4),price,PERIOD_H1,"H1",invert,create&&H1);
   output_arrow(label,sym,br*(9-H),price,PERIOD_M30,"M30",invert,create&&M30);
   output_arrow(label,sym,br*(9-H-M30),price,PERIOD_M15,"M15",invert,create&&M15);
   output_arrow(label,sym,br*(9-H-M30-M15),price,PERIOD_M5,"M5",invert,create&&M5);
   output_arrow(label,sym,br*(9-H-M30-M15-M1),price,PERIOD_M1,"M1",invert,create&&M1);

}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   bool invert;
   
   double space=(95-5)/SymNo;
   if (space>10) space=10;
   
   output_line("Title","Title",95,false,true);
   for (int i=0; i<20; i++) 
   {
      output_line(DoubleToStr(i,0),Pair[i]+SymbolSuffix,95-space*(i+1),Invert,i<SymNo);
      //else output_line(DoubleToStr(i,0),"",90-5*i,Invert);
   } 

   return(0);
  }
//+------------------------------------------------------------------+