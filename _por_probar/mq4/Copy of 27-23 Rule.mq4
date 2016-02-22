//+------------------------------------------------------------------+
//|                                                   27-23 Rule.mq4 |
//|                                                tonyc2a@yahoo.com |
//|                                             Version 1.0.12-09-04 |
//+------------------------------------------------------------------+
#property copyright "tonyc2a@yahoo.com"
#property link      ""

extern double TakeProfit = 100;
extern double Lots = 0.1;
extern double TrailingStop = 15;
extern double InitialStop = 30;
extern double RefHour = 8;
extern double CloseHour = 9;
extern double TopPriceBuf = 27;
extern double BottomPriceBuf = 23;
extern double MaxSlippage = 5;
extern double EntryCap = 5;
extern string WavFilePath="sound.wav";

double Points;


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- TODO: Add your code here.
   Points = MarketInfo (Symbol(), MODE_POINT); 
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//---- TODO: Add your code here.
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//---- TODO: Add your code here.
   RefreshRates();
   int BarsInADay=24*60/Period();
   int n=MathFloor(BarsInADay*0.7);
   double RefPrice, BuyPrice, SellPrice, LongStopPrice, ShortStopPrice, TodaysRefPrice, TodaysBuyPrice, TodaysSellPrice;

   for(int i=0;i<=200;i++){
      if(TimeHour(Time[i])!=RefHour || TimeMinute(Time[i]) !=0) continue;
      
      RefPrice=Open[i];
      BuyPrice=RefPrice+(TopPriceBuf*Points);
      SellPrice=RefPrice-(BottomPriceBuf*Points);
      LongStopPrice=BuyPrice-(InitialStop*Points);
      ShortStopPrice=SellPrice+(InitialStop*Points);
            
      if(TimeDayOfYear(Time[i])==TimeDayOfYear(CurTime())){
         TodaysRefPrice=RefPrice;
         TodaysBuyPrice=BuyPrice;
         TodaysSellPrice=SellPrice;
         }
         
      int x=MathMax(i-n,0);
      string DateString=TimeDay(Time[i])+"/"+TimeMonth(Time[i]);
      double TrendLineBeginTime=Time[i];
      double TrendLineEndTime=Time[x];

      ObjectCreate(DateString+" RefPrice",OBJ_TREND,0,TrendLineBeginTime,RefPrice,TrendLineEndTime,RefPrice);
      ObjectSet(DateString+" RefPrice",OBJPROP_TIME1,TrendLineBeginTime);
      ObjectSet(DateString+" RefPrice",OBJPROP_TIME2,TrendLineEndTime);
      ObjectSet(DateString+" RefPrice",OBJPROP_PRICE1,RefPrice);
      ObjectSet(DateString+" RefPrice",OBJPROP_PRICE2,RefPrice);
      ObjectSet(DateString+" RefPrice",OBJPROP_COLOR,MediumBlue);
      ObjectSet(DateString+" RefPrice",OBJPROP_WIDTH,2);
      ObjectSet(DateString+" RefPrice",OBJPROP_RAY,0);
      
      ObjectCreate(DateString+" BuyPrice",OBJ_TREND,0,TrendLineBeginTime,BuyPrice,TrendLineEndTime,BuyPrice);
      ObjectSet(DateString+" BuyPrice",OBJPROP_TIME1,TrendLineBeginTime);
      ObjectSet(DateString+" BuyPrice",OBJPROP_TIME2,TrendLineEndTime);
      ObjectSet(DateString+" BuyPrice",OBJPROP_PRICE1,BuyPrice);
      ObjectSet(DateString+" BuyPrice",OBJPROP_PRICE2,BuyPrice);      
      ObjectSet(DateString+" BuyPrice",OBJPROP_COLOR,LimeGreen);
      ObjectSet(DateString+" BuyPrice",OBJPROP_WIDTH,3);
      ObjectSet(DateString+" BuyPrice",OBJPROP_RAY,0);
      
      ObjectCreate(DateString+" SellPrice",OBJ_TREND,0,TrendLineBeginTime,SellPrice,TrendLineEndTime,SellPrice);
      ObjectSet(DateString+" SellPrice",OBJPROP_TIME1,TrendLineBeginTime);
      ObjectSet(DateString+" SellPrice",OBJPROP_TIME2,TrendLineEndTime);
      ObjectSet(DateString+" SellPrice",OBJPROP_PRICE1,SellPrice);
      ObjectSet(DateString+" SellPrice",OBJPROP_PRICE2,SellPrice);     
      ObjectSet(DateString+" SellPrice",OBJPROP_COLOR,FireBrick);
      ObjectSet(DateString+" SellPrice",OBJPROP_WIDTH,3);   
      ObjectSet(DateString+" SellPrice",OBJPROP_RAY,0); 
      
      ObjectCreate(DateString+" LongStopPrice",OBJ_TREND,0,TrendLineBeginTime,LongStopPrice,TrendLineEndTime,LongStopPrice);
      ObjectSet(DateString+" LongStopPrice",OBJPROP_TIME1,TrendLineBeginTime);
      ObjectSet(DateString+" LongStopPrice",OBJPROP_TIME2,TrendLineEndTime);
      ObjectSet(DateString+" LongStopPrice",OBJPROP_PRICE1,LongStopPrice);
      ObjectSet(DateString+" LongStopPrice",OBJPROP_PRICE2,LongStopPrice);     
      ObjectSet(DateString+" LongStopPrice",OBJPROP_COLOR,LimeGreen);
      ObjectSet(DateString+" LongStopPrice",OBJPROP_WIDTH,1);
      ObjectSet(DateString+" LongStopPrice",OBJPROP_RAY,0);
      
      ObjectCreate(DateString+" ShortStopPrice",OBJ_TREND,0,TrendLineBeginTime,ShortStopPrice,TrendLineEndTime,ShortStopPrice);
      ObjectSet(DateString+" ShortStopPrice",OBJPROP_TIME1,TrendLineBeginTime);
      ObjectSet(DateString+" ShortStopPrice",OBJPROP_TIME2,TrendLineEndTime);
      ObjectSet(DateString+" ShortStopPrice",OBJPROP_PRICE1,ShortStopPrice);
      ObjectSet(DateString+" ShortStopPrice",OBJPROP_PRICE2,ShortStopPrice);
      ObjectSet(DateString+" ShortStopPrice",OBJPROP_COLOR,Red);
      ObjectSet(DateString+" ShortStopPrice",OBJPROP_WIDTH,1);
      ObjectSet(DateString+" ShortStopPrice",OBJPROP_RAY,0);
      }
      
   Comment( "\n","Today\'s Info:\n\n",
         "RefPrice: ",TodaysRefPrice,"\n",
         "BuyPrice: ",TodaysBuyPrice,"\n",
         "SellPrice: ",TodaysSellPrice,"\n");
      
   if( (Open[1]>TodaysSellPrice||Open[0]>TodaysSellPrice) && Close[0]<=TodaysSellPrice) {
      //PlaySound(WavFilePath);
      Alert(Symbol()," Price went Below SellPrice");
      
      }
   if( (Open[1]<TodaysBuyPrice||Open[0]<TodaysBuyPrice) && Close[0]>=TodaysBuyPrice){
      //PlaySound(WavFilePath);
      Alert( Symbol()," Price went Above BuyPrice");
      }
   
      
             
//----
   return(0);
  }
//+------------------------------------------------------------------+