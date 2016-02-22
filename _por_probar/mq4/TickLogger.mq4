//+------------------------------------------------------------------+
//|                                                   TickLogger.mq4 |
//|                                               Paul Hampton-Smith |
//+------------------------------------------------------------------+

int handle;

int init()
{
   Comment("Waiting for tick");
   handle = FileOpen(Symbol() + TimeToStr(CurTime(),TIME_DATE) + "_tick_log.csv", FILE_CSV|FILE_READ|FILE_WRITE, ',' );
   FileSeek(handle,0,SEEK_END);
   FileWrite(handle,MyTimeToString(CurTime()),Bid,Ask);
}

int deinit()
{
   FileClose(handle);
}

int start()
{
   Comment("Logging ticks");
   FileWrite(handle,MyTimeToString(CurTime()),Bid,Ask);
   return(0);
}

string MyTimeToString(datetime dt)
{
   // output format dd/mm/yyyy mm:hh:ss
   string strDayPad;
   int nDay = TimeDay(dt);
   if (nDay >= 0 && nDay <= 9) strDayPad = "0";
   else strDayPad = "";

   string strMonthPad;
   int nMonth = TimeMonth(dt);
   if (nMonth >= 0 && nMonth <= 9) strMonthPad = "0";
   else strMonthPad = "";
   
   string strHourPad;
   int nHour = TimeHour(dt);
   if (nHour >= 0 && nHour <= 9) strHourPad = "0";
   else strHourPad = "";
   
   string strMinutePad;
   int nMinute = TimeMinute(dt);
   if (nMinute >= 0 && nMinute <= 9) strMinutePad = "0";
   else strMinutePad = "";

   string strSecondPad;
   int nSecond = TimeSeconds(dt);
   if (nSecond >= 0 && nSecond <= 9) strSecondPad = "0";
   else strSecondPad = "";

   return(StringConcatenate(strDayPad,nDay,"/",strMonthPad,nMonth,"/",TimeYear(dt)," ",strHourPad,nHour,":",strMinutePad,nMinute,":",strSecondPad,nSecond));
}

