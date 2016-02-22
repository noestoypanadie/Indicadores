//+------------------------------------------------------------------+
//|                                                  TimeGMTdemo.mq4 |
//|                                               Paul Hampton-Smith |
//+------------------------------------------------------------------+

#include <TimeGMT.mqh>

int init()
{
	start();
}

int start()
{
	string strLocal = TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES|TIME_SECONDS);
	string strServer = TimeToStr(TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS);
	string strGMT = TimeToStr(TimeGMT(),TIME_DATE|TIME_MINUTES|TIME_SECONDS);
	
	string strLocalTimeZone;
	if (TimeZoneLocal() > 0) strLocalTimeZone = StringConcatenate("Local timezone: GMT plus ",TimeZoneLocal()," hours");
	if (TimeZoneLocal() == 0) strLocalTimeZone = "Local timezone: GMT";
	if (TimeZoneLocal() < 0) strLocalTimeZone = StringConcatenate("Local timezone: GMT minus ",-TimeZoneLocal()," hours");
	
	string strServerTimeZone;
	if (TimeZoneServer() > 0) strServerTimeZone = StringConcatenate("Server timezone: GMT plus ",TimeZoneServer()," hours");
	if (TimeZoneServer() == 0) strServerTimeZone = "Server timezone: GMT";
	if (TimeZoneServer() < 0) strServerTimeZone = StringConcatenate("Server timezone: GMT minus ",-TimeZoneServer()," hours");

	Comment("\n",strLocalTimeZone,"\n",
			  strServerTimeZone,
			  "\n\nThe time at the last tick was ...\n",
			  strLocal,"   local time from PC clock\n",
	        strServer,"   server time from broker\n",
	        strGMT,"   GMT");

   return(0);
}

