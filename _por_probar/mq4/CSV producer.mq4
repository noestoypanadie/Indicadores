//+------------------------------------------------------------------+
//|                                                 CSV producer.mq4 |
//|                                                           MojoFX |
//|                                                fx.studiomojo.com |
//+------------------------------------------------------------------+
#property copyright "MojoFX"
#property link      "fx.studiomojo.com"
#property show_confirm
#property show_inputs

extern int barQty = 500;
extern string fileExtension = ".txt";
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
   {
   if (barQty == 0) barQty = Bars-1; 
   
//----
   FileDelete(Symbol()+Period()+fileExtension);
   for (int i=barQty; i>0; i--)
      {
      int handle;      
      handle = FileOpen(Symbol()+Period()+fileExtension, FILE_CSV|FILE_WRITE|FILE_READ,',');      
      if (handle>0)
         {
         string mmStr,ddStr;
         if (TimeDay(Time[i])<10) ddStr="0"+TimeDay(Time[i]); else ddStr=TimeDay(Time[i]);
         if (TimeMonth(Time[i])<10) mmStr="0"+TimeMonth(Time[i]); else mmStr=TimeMonth(Time[i]);
         string dateStr = TimeYear(Time[i])+"-"+mmStr+"-"+ddStr;
         FileSeek(handle,0,SEEK_END);
         FileWrite(handle,
            dateStr,
            Symbol(),
            Open[i]*MathPow(10,Digits),
            High[i]*MathPow(10,Digits),
            Low[i]*MathPow(10,Digits),
            Close[i]*MathPow(10,Digits),
            Volume[i]);
         FileClose(handle);
         }      
      }
//----
   return(0);
  }
//+------------------------------------------------------------------+