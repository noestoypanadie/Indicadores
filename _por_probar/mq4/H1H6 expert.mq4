//+------------------------------------------------------------------+
//|                           Copyright 2005, Gordago Software Corp. |
//|                                          http://www.gordago.com/ |
//+------------------------------------------------------------------+



#property copyright "Copyright 2005, Gordago Software Corp."
#property link      "http://www.gordago.com"
bool indicator_buffers [2];
double indicator_color1= Aqua;
double indicator_color2= Red;
extern double lStopLoss = 25;
extern double sStopLoss = 25;
extern double lTrailingStop = 30;
extern double sTrailingStop = 30;
extern double Lots = 1;
int    ServerTimeZone = 0;

 extern int NumberOfBarH6 = 100;     // quantity H6 of the candles  
 
 
 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void init() {
  int i;

  for (i=0; i<NumberOfBarH6; i++) {
    ObjectDelete("H6Bar" + i);
  }
  for (i=0; i<NumberOfBarH6; i++) {
    ObjectCreate("H6Bar" + i, OBJ_RECTANGLE, 0, 0,0, 0,0);
  }
  Comment("");
}
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
void deinit()
{
  //the removal of the objects
  for (int i=0; i<NumberOfBarH6; i++) {
    ObjectDelete("H6Bar" + i);
  }
  Comment("");
}


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
//void start() {
 


int start(){


int sh6=0, sh1=0;
  double   oh6, ch6; // the prices of opening and closing N' the candle

  datetime to6, tc6; // the time of opening and closing N' the candle

  if (Period()!=60) Comment("Indicator i -H6-From-H1 support THE only equal to Ny");
  else {
    ch6 = Close[0];
    tc6 = Time[0];
    // we run on H6 to the candles
    while (sh6<NumberOfBarH6) {
      // we run on H1 to the candles
      if (TimeHour(Time[sh1])==0 || TimeHour(Time[sh1])==5
      || TimeHour(Time[sh1])==11 || TimeHour(Time[sh1])==17)
      {
      
        oh6 = Open[sh1-1];
        to6 = Time[sh1-1];
        ObjectSet("H6Bar"+sh6, OBJPROP_TIME1, to6);
        ObjectSet("H6Bar"+sh6, OBJPROP_PRICE1, oh6);
        ObjectSet("H6Bar"+sh6, OBJPROP_TIME2, tc6);
        ObjectSet("H6Bar"+sh6, OBJPROP_PRICE2, ch6);
        ObjectSet("H6Bar"+sh6, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSet("H6Bar"+sh6, OBJPROP_BACK, True);
        if (oh6<ch6) ObjectSet("H6Bar"+sh6, OBJPROP_COLOR, indicator_color1);
        else ObjectSet("H6Bar"+sh6, OBJPROP_COLOR, indicator_color2);
        ch6 = Close[sh1];
        tc6 = Time[sh1];
        sh6++;
      }
      sh1++;
    }
  }


// T.**********************************************
// *** Trade in TimeZone                        ***
// ************************************************
   if(TimeHour(CurTime()) + ServerTimeZone >= 19 || TimeHour(CurTime()) + ServerTimeZone <= 0) {
      Comment ("\n","Current Time : ",TimeToStr(CurTime())," ( GTM=", ServerTimeZone," ) is NOT GOOD for Trade by this Robot",
               "\n");
      return(0);
   }
  
   int cnt, ticket;
   if(Bars<100){
      Print("bars less than 100");
      return(0);
   }
   if(lStopLoss<10){
      Print("StopLoss less than 10");
      return(0);
   }
   if(sStopLoss<10){
      Print("StopLoss less than 10");
      return(0);
   }
   double diMA0=iMA(NULL,240,7,0,MODE_EMA,PRICE_CLOSE,0);
   double diMA1=iMA(NULL,240,18,0,MODE_EMA,PRICE_CLOSE,0);
         
   double diMA3=iMA(NULL,240,7,0,MODE_EMA,PRICE_CLOSE,0);
   double diMA4=iMA(NULL,240,18,0,MODE_EMA,PRICE_CLOSE,0);
  double diCustom5=iCustom(NULL, 15, "GentorCCIM_v[1]", Close, 0, 0);
   double diMA6=iMA(NULL,15,7,0,MODE_EMA,PRICE_CLOSE,0);
   double diOpen7=iOpen(NULL,15,0);
   double diClose8=iClose(NULL,15,0);
   
   double diCustom9=iCustom(NULL, 15, "GentorCCIM_v[1]", Close, 0, 0);
   int total=OrdersTotal();
   if(total<1){
 
   
      if(AccountFreeMargin()<(1000*Lots)){
         Print("We have no money. Free Margin = ", AccountFreeMargin());
         return(0);
      }

      if ((oh6>ch6 && diCustom5>0 )){
         ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-lStopLoss*Point,0, "gordago simple",16384,0,Green);
         if(ticket>0){
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
            
         }
         else Print("Error opening BUY order : ",GetLastError());
         return(0);
      }

      if (( oh6<ch6 && diCustom5<0 )){
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+sStopLoss*Point,0,"gordago sample",16384,0,Red);
         if(ticket>0) {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
            
         }
         else Print("Error opening SELL order : ",GetLastError());
         return(0);
      }
   }
  
   for(cnt=0;cnt<total;cnt++) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol()) {
         if(OrderType()==OP_BUY){

        
         }
            if(lTrailingStop>0) {
               if(Bid-OrderOpenPrice()>Point*lTrailingStop) {
                  if(OrderStopLoss()<Bid-Point*lTrailingStop) {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*lTrailingStop,OrderTakeProfit(),0,Green);
                     return(0);
                  }
               }
            }
         }else{
            if(sTrailingStop>0) {
               if((OrderOpenPrice()-Ask)>(Point*sTrailingStop)) {
                  if((OrderStopLoss()>(Ask+Point*sTrailingStop)) || (OrderStopLoss()==0)) {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*sTrailingStop,OrderTakeProfit(),0,Red);
                     return(0);
                  }
               }
            }
         }
      }
   }

