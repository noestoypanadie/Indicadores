//+------------------------------------------------------------------+
//|                             #(T_S_R)-Daily Range Calculator .mq4 |
//|                      Copyright © 2006, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
#property link      "Data window by cja"
//+------------------------------------------------------------------+
//|                                                   TSR_Ranges.mq4 |
//|                                         Copyright © 2006, Ogeima |
//|                                             ph_bresson@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Ogeima"
#property link      "ph_bresson@yahoo.com"

#property indicator_separate_window
//---- input parameters
extern double  Risk_to_Reward_ratio =  3.0;
int nDigits;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
IndicatorShortName("TSR");
   if(Symbol()=="GBPJPY" || Symbol()=="EURJPY" || Symbol()=="USDJPY" || Symbol()=="GOLD" || Symbol()=="USDMXN") nDigits = 2;
   if(Symbol()=="GBPUSD" || Symbol()=="EURUSD" || Symbol()=="NZDUSD" || Symbol()=="USDCHF"  ||
   Symbol()=="USDCAD" || Symbol()=="AUDUSD" || Symbol()=="EURUSD" || Symbol()=="EURCHF"  || Symbol()=="EURGBP"
   || Symbol()=="EURCAD" || Symbol()=="EURAUD" || Symbol()=="AUDNZD")nDigits = 4;

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
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   //----
   int R1=0,R5=0,R10=0,R20=0,RAvg=0;
   int RoomUp=0,RoomDown=0,StopLoss_Long=0,StopLoss_Short=0;
   double   SL_Long=0,SL_Short=0;
   double   low0=0,high0=0;
   string   Text="";
   int i=0;

   R1 =  (iHigh(NULL,PERIOD_D1,1)-iLow(NULL,PERIOD_D1,1))/Point;
   for(i=1;i<=5;i++)
      R5    =    R5  +  (iHigh(NULL,PERIOD_D1,i)-iLow(NULL,PERIOD_D1,i))/Point;
   for(i=1;i<=10;i++)
      R10   =    R10 +  (iHigh(NULL,PERIOD_D1,i)-iLow(NULL,PERIOD_D1,i))/Point;
   for(i=1;i<=20;i++)
      R20   =    R20 +  (iHigh(NULL,PERIOD_D1,i)-iLow(NULL,PERIOD_D1,i))/Point;

   R5 = R5/5;
   R10 = R10/10;
   R20 = R20/20;
   RAvg  =  (R1+R5+R10+R20)/4;    

   low0  =  iLow(NULL,PERIOD_D1,0);
   high0 =  iHigh(NULL,PERIOD_D1,0);
   RoomUp   =  RAvg - (Bid - low0)/Point;
   RoomDown =  RAvg - (high0 - Bid)/Point;
   StopLoss_Long  =  RoomUp/Risk_to_Reward_ratio;
   SL_Long        =  Bid - StopLoss_Long*Point;
   StopLoss_Short =  RoomDown/Risk_to_Reward_ratio;
   SL_Short       =  Bid + StopLoss_Short*Point;


   Text =   "Average Day  Range: " +  RAvg + "\n"  + 
            "Prev 01  Day  Range: " +  R1   + "\n" + 
            "Prev 05  Days Range: " +  R5   + "\n" + 
            "Prev 10  Days Range: " +  R10  + "\n" +
            "Prev 20  Days Range: " +  R20  + "\n";
   Text =   Text +
            "Room Up:     " + RoomUp              + "\n" +
            "Room Down: " + RoomDown            + "\n" +
            "Maximum StopLosses :"  + "\n" +
            "Long:  " + StopLoss_Long  + " Pips at " + DoubleToStr(SL_Long,nDigits)  + "\n" +
            "Short: " + StopLoss_Short + " Pips at " + DoubleToStr(SL_Short,nDigits) + "\n" ;

   Comment(Text);
  
   string P=Period();
  
   
        ObjectCreate("TSR", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR",StringSubstr(Symbol(),0),12, "Arial Bold", CadetBlue);
        ObjectSet("TSR", OBJPROP_CORNER, 0);
        ObjectSet("TSR", OBJPROP_XDISTANCE, 25);
        ObjectSet("TSR", OBJPROP_YDISTANCE, 2);
        ObjectCreate("TSR1", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR1",StringSubstr(P,0),12, "Arial Bold", CadetBlue);
        ObjectSet("TSR1", OBJPROP_CORNER, 0);
        ObjectSet("TSR1", OBJPROP_XDISTANCE, 100);
        ObjectSet("TSR1", OBJPROP_YDISTANCE, 2);
        
        ObjectCreate("TSR2", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR2","Average Daily Range:", 10, "Arial Bold", CadetBlue);
        ObjectSet("TSR2", OBJPROP_CORNER, 0);
        ObjectSet("TSR2", OBJPROP_XDISTANCE, 150);
        ObjectSet("TSR2", OBJPROP_YDISTANCE, 2);
        ObjectCreate("TSR3", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR3",DoubleToStr(RAvg ,0),12, "Arial Bold", Teal);
        ObjectSet("TSR3", OBJPROP_CORNER, 0);
        ObjectSet("TSR3", OBJPROP_XDISTANCE, 300);
        ObjectSet("TSR3", OBJPROP_YDISTANCE, 2);
        
        ObjectCreate("TSR4", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR4","Prev 01 Day Range:", 10, "Arial ", Teal);
        ObjectSet("TSR4", OBJPROP_CORNER, 0);
        ObjectSet("TSR4", OBJPROP_XDISTANCE, 25);
        ObjectSet("TSR4", OBJPROP_YDISTANCE, 20);
        ObjectCreate("TSR5", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR5",DoubleToStr(R1,0),12, "Arial Bold", Teal);
        ObjectSet("TSR5", OBJPROP_CORNER, 0);
        ObjectSet("TSR5", OBJPROP_XDISTANCE, 160);
        ObjectSet("TSR5", OBJPROP_YDISTANCE, 20);
        
        ObjectCreate("TSR6", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR6","Prev 05 Days Range:", 10, "Arial ", Maroon);
        ObjectSet("TSR6", OBJPROP_CORNER, 0);
        ObjectSet("TSR6", OBJPROP_XDISTANCE, 25);
        ObjectSet("TSR6", OBJPROP_YDISTANCE, 35);
        ObjectCreate("TSR7", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR7",DoubleToStr(R5,0),12, "Arial Bold", Teal);
        ObjectSet("TSR7", OBJPROP_CORNER, 0);
        ObjectSet("TSR7", OBJPROP_XDISTANCE, 160);
        ObjectSet("TSR7", OBJPROP_YDISTANCE, 35);
        
        ObjectCreate("TSR8", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR8","Prev 10 Days Range:", 10, "Arial ", Maroon);
        ObjectSet("TSR8", OBJPROP_CORNER, 0);
        ObjectSet("TSR8", OBJPROP_XDISTANCE, 220);
        ObjectSet("TSR8", OBJPROP_YDISTANCE, 20);
        ObjectCreate("TSR9", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR9",DoubleToStr(R10,0),12, "Arial Bold", Teal);
        ObjectSet("TSR9", OBJPROP_CORNER, 0);
        ObjectSet("TSR9", OBJPROP_XDISTANCE, 355);
        ObjectSet("TSR9", OBJPROP_YDISTANCE, 20);
        
        ObjectCreate("TSR10", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR10","Prev 20 Days Range:", 10, "Arial ", Maroon);
        ObjectSet("TSR10", OBJPROP_CORNER, 0);
        ObjectSet("TSR10", OBJPROP_XDISTANCE, 220);
        ObjectSet("TSR10", OBJPROP_YDISTANCE, 35);
        ObjectCreate("TSR11", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR11",DoubleToStr(R20,0),12, "Arial Bold", Teal);
        ObjectSet("TSR11", OBJPROP_CORNER, 0);
        ObjectSet("TSR11", OBJPROP_XDISTANCE, 355);
        ObjectSet("TSR11", OBJPROP_YDISTANCE, 35);
        
        ObjectCreate("TSR12", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR12","Room UP:", 10, "Arial ", Maroon);
        ObjectSet("TSR12", OBJPROP_CORNER, 0);
        ObjectSet("TSR12", OBJPROP_XDISTANCE, 420);
        ObjectSet("TSR12", OBJPROP_YDISTANCE, 20);
        ObjectCreate("TSR13", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR13",DoubleToStr(RoomUp,0),12, "Arial Bold", Teal);
        ObjectSet("TSR13", OBJPROP_CORNER, 0);
        ObjectSet("TSR13", OBJPROP_XDISTANCE, 490);
        ObjectSet("TSR13", OBJPROP_YDISTANCE, 20);
        
        ObjectCreate("TSR14", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR14","Room DN:", 10, "Arial ", Maroon);
        ObjectSet("TSR14", OBJPROP_CORNER, 0);
        ObjectSet("TSR14", OBJPROP_XDISTANCE, 420);
        ObjectSet("TSR14", OBJPROP_YDISTANCE, 35);
        ObjectCreate("TSR15", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR15",DoubleToStr(RoomDown,0),12, "Arial Bold", Teal);
        ObjectSet("TSR15", OBJPROP_CORNER, 0);
        ObjectSet("TSR15", OBJPROP_XDISTANCE, 490);
        ObjectSet("TSR15", OBJPROP_YDISTANCE, 35);
        
        ObjectCreate("TSR16", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR16","Maximum StopLosses;",10, "Arial Bold", CadetBlue);
        ObjectSet("TSR16", OBJPROP_CORNER, 0);
        ObjectSet("TSR16", OBJPROP_XDISTANCE, 560);
        ObjectSet("TSR16", OBJPROP_YDISTANCE, 2);
        
        ObjectCreate("TSR17", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR17","Long:             Pips at", 10, "Arial ", Maroon);
        ObjectSet("TSR17", OBJPROP_CORNER, 0);
        ObjectSet("TSR17", OBJPROP_XDISTANCE, 560);
        ObjectSet("TSR17", OBJPROP_YDISTANCE, 20);
        ObjectCreate("TSR18", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR18",DoubleToStr(StopLoss_Long,0),12, "Arial Bold", Teal);
        ObjectSet("TSR18", OBJPROP_CORNER, 0);
        ObjectSet("TSR18", OBJPROP_XDISTANCE, 600);
        ObjectSet("TSR18", OBJPROP_YDISTANCE, 20);
        
        ObjectCreate("TSR19", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR19","Short:             Pips at", 10, "Arial ", Maroon);
        ObjectSet("TSR19", OBJPROP_CORNER, 0);
        ObjectSet("TSR19", OBJPROP_XDISTANCE, 560);
        ObjectSet("TSR19", OBJPROP_YDISTANCE, 35);
        ObjectCreate("TSR20", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR20",DoubleToStr(StopLoss_Short,0),12, "Arial Bold", Teal);
        ObjectSet("TSR20", OBJPROP_CORNER, 0);
        ObjectSet("TSR20", OBJPROP_XDISTANCE, 600);
        ObjectSet("TSR20", OBJPROP_YDISTANCE, 35);
        
        ObjectCreate("TSR21", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR21",DoubleToStr(SL_Long,nDigits),12, "Arial Bold", SteelBlue);
        ObjectSet("TSR21", OBJPROP_CORNER, 0);
        ObjectSet("TSR21", OBJPROP_XDISTANCE, 690);
        ObjectSet("TSR21", OBJPROP_YDISTANCE, 20);
        ObjectCreate("TSR22", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR22",DoubleToStr(SL_Short,nDigits),12, "Arial Bold",SteelBlue);
        ObjectSet("TSR22", OBJPROP_CORNER, 0);
        ObjectSet("TSR22", OBJPROP_XDISTANCE, 690);
        ObjectSet("TSR22", OBJPROP_YDISTANCE, 35);
        
        ObjectCreate("TSR23", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR23","Risk to Reward Ratio:", 10, "Arial Bold", CadetBlue);
        ObjectSet("TSR23", OBJPROP_CORNER, 0);
        ObjectSet("TSR23", OBJPROP_XDISTANCE, 350);
        ObjectSet("TSR23", OBJPROP_YDISTANCE, 2);
        ObjectCreate("TSR24", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("TSR24",DoubleToStr( Risk_to_Reward_ratio ,0),12, "Arial Bold", Teal);
        ObjectSet("TSR24", OBJPROP_CORNER, 0);
        ObjectSet("TSR24", OBJPROP_XDISTANCE, 500);
        ObjectSet("TSR24", OBJPROP_YDISTANCE, 2);
        
     
        double HIDaily = iMA(Symbol(),PERIOD_D1,1,0,MODE_HIGH,PRICE_HIGH,0);
        double LOWDaily = iMA(Symbol(),PERIOD_D1,1,0,MODE_LOW,PRICE_LOW,0); 
        double YEST_HIDaily = iMA(Symbol(),PERIOD_D1,1,0,MODE_HIGH,PRICE_HIGH,1);
        double YEST_LOWDaily = iMA(Symbol(),PERIOD_D1,1,0,MODE_LOW,PRICE_LOW,1); 
   
        ObjectCreate("high", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("high",DoubleToStr(HIDaily,Digits), 12, "Arial Bold", Teal);
        ObjectSet("high", OBJPROP_CORNER, 0);
        ObjectSet("high", OBJPROP_XDISTANCE, 890);
        ObjectSet("high", OBJPROP_YDISTANCE, 20);
        
        ObjectCreate("high2", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("high2","DailyHigh", 9, "Arial Bold", CadetBlue);
        ObjectSet("high2", OBJPROP_CORNER, 0);
        ObjectSet("high2", OBJPROP_XDISTANCE, 890);
        ObjectSet("high2", OBJPROP_YDISTANCE, 2);
        
        ObjectCreate("low", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("low",DoubleToStr(LOWDaily,Digits), 12, "Arial Bold", Teal);
        ObjectSet("low", OBJPROP_CORNER, 0);
        ObjectSet("low", OBJPROP_XDISTANCE, 830);
        ObjectSet("low", OBJPROP_YDISTANCE, 20);
        
        ObjectCreate("low2", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("low2","DailyLow", 9, "Arial Bold", CadetBlue);
        ObjectSet("low2", OBJPROP_CORNER, 0);
        ObjectSet("low2", OBJPROP_XDISTANCE, 830);
        ObjectSet("low2", OBJPROP_YDISTANCE, 2);
        
         double CURR = iMA(Symbol(),0,1,0,MODE_EMA,PRICE_CLOSE,0);
   
           
        ObjectCreate("high3", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("high3",DoubleToStr(CURR,Digits), 12, "Arial Bold", Coral);
        ObjectSet("high3", OBJPROP_CORNER, 0);
        ObjectSet("high3", OBJPROP_XDISTANCE, 890);
        ObjectSet("high3", OBJPROP_YDISTANCE,35 );
            
        ObjectCreate("high4", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("high4",DoubleToStr(CURR,Digits), 12, "Arial Bold", Coral);
        ObjectSet("high4", OBJPROP_CORNER, 0);
        ObjectSet("high4", OBJPROP_XDISTANCE, 830);
        ObjectSet("high4", OBJPROP_YDISTANCE,35 );
        
        ObjectCreate("low4", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("low4","T/Day", 9, "Arial ", Maroon);
        ObjectSet("low4", OBJPROP_CORNER, 0);
        ObjectSet("low4", OBJPROP_XDISTANCE, 790);
        ObjectSet("low4", OBJPROP_YDISTANCE, 20);
        ObjectCreate("low5", OBJ_LABEL, WindowFind("TSR"), 0, 0);
        ObjectSetText("low5","Price", 9, "Arial ", Maroon);
        ObjectSet("low5", OBJPROP_CORNER, 0);
        ObjectSet("low5", OBJPROP_XDISTANCE, 790);
        ObjectSet("low5", OBJPROP_YDISTANCE, 37);
   
   


   return(0);
  }
//+------------------------------------------------------------------+