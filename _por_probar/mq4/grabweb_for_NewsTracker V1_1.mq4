//+------------------------------------------------------------------+
//|                                                      grabweb.mq4 |
//|                                           Copyright © 2006, Abhi |
//|                                http://www.megadelfi.com/experts/ |
//|                            E-mail: grabwebexpert{Q)megadelfi.com |
//|                       fix my e-mail address before mailing me ;) |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Abhi"
#property link      "http://www.megadelfi.com/experts/"
#property show_inputs

extern string sUrl = "http://www.forexfactory.com/index.php?s=&page=calendar&timezoneoffset=g0"; // GMT output for the week
extern string Outputfile = "NewsItems.csv";
extern bool IncludeHigh = true;
extern bool IncludeMedium = true;
extern bool IncludeLow = false;
extern bool IncludeSpeaks = false; // news items with "Speaks" in them have very different characteristics
extern bool RemoveDuplicates = true; // only one news item per time
extern string ConvertUSDto = "USD"; // can change this to a full currency pair such as "GBPUSD"
extern double Parameter2 = 0;
extern double Parameter3 = 0;
extern double Parameter4 = 0;
extern double Parameter5 = 0;


int hSession_IEType;
int hSession_Direct;
int Internet_Open_Type_Preconfig = 0;
int Internet_Open_Type_Direct = 1;
int Internet_Open_Type_Proxy = 3;
int Buffer_LEN = 13;


#import "wininet.dll"
  int InternetOpenA(
    string sAgent,
    int    lAccessType,
    string sProxyName="",
    string sProxyBypass="",
    int lFlags=0
  );

  int InternetOpenUrlA(
    int    hInternetSession,
    string sUrl, 
    string sHeaders="",
    int lHeadersLength=0,
    int lFlags=0,
    int lContext=0 
  );

  int InternetReadFile(
    int hFile,
    string sBuffer,
    int lNumBytesToRead,
    int& lNumberOfBytesRead[]
  );

  int InternetCloseHandle(
    int hInet
  );


int hSession(bool Direct)
   {
    string InternetAgent;
    if (hSession_IEType == 0)
      {
        InternetAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q312461)";
        hSession_IEType = InternetOpenA(InternetAgent, Internet_Open_Type_Preconfig, "0", "0", 0);
        hSession_Direct = InternetOpenA(InternetAgent, Internet_Open_Type_Direct, "0", "0", 0);
      }
    if (Direct) 
    { return(hSession_Direct); }
    else 
    { return(hSession_IEType); }
   }
   
int start()
  {
//   Print("fake start");
  }

int init()
  {
int hInternet;
string iResult;
int lReturn[]={1};
string sBuffer="x";
string sData, csvoutput;
int handle;
int bytes;
int beginning, finalend,end,i;
string aju, text, newsdate, newstime, country, news, level, actual, forecast, previous;
string lastNewsdate, lastNewstime, lastCountry;

hInternet = InternetOpenUrlA(hSession(FALSE), sUrl, "0", 0, 67108864, 0);
Print("hInternet: " + hInternet);   
iResult = InternetReadFile(hInternet, sBuffer, Buffer_LEN, lReturn);
Print("iResult: " + iResult);
Print("lReturn: " + lReturn[0]);
//iResult = InternetCloseHandle(hInternet);
Print("iResult: " + iResult);
Print("sBuffer: " +  sBuffer);
Comment("sBuffer: " +  sBuffer);
bytes = lReturn[0];

        sData = StringSubstr(sBuffer, 0, lReturn[0]);
        //if there's more data then keep reading it into the buffer
      while (lReturn[0] != 0)
       {
            iResult = InternetReadFile(hInternet, sBuffer, Buffer_LEN, lReturn);
            if (lReturn[0]==0) break;
            bytes = bytes + lReturn[0];
            sData = sData + StringSubstr(sBuffer, 0, lReturn[0]);
       }

Print("sData: " + sData);
iResult = InternetCloseHandle(hInternet);
Print("iResult: " + iResult);

handle=FileOpen(Day()+ "-"+ Month() +"-"+ Year() +"-"+ "grabweb.htm",FILE_BIN|FILE_READ|FILE_WRITE);
if(handle<1)
    {
     Print("Can\'t open htm file, the last error is ", GetLastError());
     return(false);
    }
   FileWriteString(handle,sData,StringLen(sData));
   FileClose(handle);

   Print("bytes: "+bytes);

// htm file is written, let's parse it now and write to csv file

handle=FileOpen(Outputfile,FILE_CSV|FILE_WRITE,",");
if(handle<1)
    {
     Print("Can\'t open csv file, the last error is ", GetLastError());
     return(false);
    }

	FileWrite(handle,"Description","Currency","DateTime","TimeZone","Level","Parameter2","Parameter3","Parameter4","Parameter5");

beginning = 1;
beginning = StringFind(sData,"<span class=\"smallfont\">Info.</span>",beginning)+36;
finalend = StringFind(sData,"</table>",beginning)-1235;


while (beginning < finalend)
   {
      for (i=0; i < 8; i++)
         {
            beginning = StringFind(sData,"<span class=\"smallfont\"",beginning)+23;
            beginning = StringFind(sData,">",beginning)+1;
            end = StringFind(sData,"</span>",beginning)-0;
               if (end != beginning)
                  {      
                     text = StringSubstr(sData, beginning, end-beginning);
                  }
               else
                  {
                     text = "";
                  }

                  if (i == 0)
                  {
                     if (text != "")
                     {
                        newsdate = text;
                     }
                     else
                     {
                        text = newsdate;
                     }
                  }
         
// date and time conversion here if needed

                 if (i == 1)
                  {
                     text = StringTrimLeft(text);
                     newstime = StringTrimRight(text);
                  } 

                 if (i == 2)
                  {
                     country = text;
                  }                   
                 if (i == 3)
                  {
                     news = text;
                     beginning = StringFind(sData,"src=\"http://www.forexfactory.com/forexforum/images/misc/",beginning)+59;
                     end = StringFind(sData,".gif",beginning);
                     text = StringSubstr(sData,beginning,end-beginning);
                     level = text;

                  }                   
                 if (i == 4)
                  {
                     actual = text;
                  }                   
                 if (i == 5)
                  {
                     forecast = text;
                  }                   
                 if (i == 6)
                  {
                     previous = text;
                  }                   

         }      
//         csvoutput = newsdate + ", " + newstime + ", " + country + ", " + news + ", " +level + ", " + actual + ", " + forecast + ", " + previous;

			if (!IncludeHigh && level == "high") continue;
			if (!IncludeMedium && level == "med") continue;
			if (!IncludeLow && level == "low") continue;
			if (!IncludeSpeaks && (StringFind(news,"speaks") != -1 || StringFind(news,"Speaks") != -1) ) continue;
			if (newstime == "tentative" || newstime == "Tentative") continue;
			if (RemoveDuplicates && lastNewsdate == newsdate && lastNewstime == newstime && lastCountry == country) continue;
			if (country == "USD") country = ConvertUSDto;
			int nLevel = 0;
			if (level == "high") nLevel = 3;
			if (level == "med") nLevel = 2;
			if (level == "low") nLevel = 1;
			
			lastNewsdate = newsdate;
			lastNewstime = newstime;
			lastCountry = country;
			
         csvoutput = StringConcatenate(news,",",country,",",MakeDateTime(newsdate,newstime),",GMT,",nLevel,",",Parameter2,",",Parameter3,",",Parameter4,",",Parameter5);
         Print("newslist: "+ csvoutput);
         FileWrite(handle,news,country,MakeDateTime(newsdate,newstime),"GMT",nLevel,Parameter2,Parameter3,Parameter4,Parameter5);
    }
   FileClose(handle);

return(0);
  }
   //+------------------------------------------------------------------+
   
string MakeDateTime(string strDate, string strTime)
{
	// converts forexfactory time & date into yyyy.mm.dd hh:mm
	int nDateSpacePos = StringFind(strDate," ");
	int nDateSlashPos = StringFind(strDate,"/");
	
	string strMonth = StringSubstr(strDate,nDateSpacePos+1,nDateSlashPos-nDateSpacePos-1);
	string strDay = StringSubstr(strDate,nDateSlashPos+1);
	
	int nTimeColonPos	= StringFind(strTime,":");
	string strHour = StringSubstr(strTime,0,nTimeColonPos);
	string strMinute = StringSubstr(strTime,nTimeColonPos+1,2);
	string strAM_PM = StringSubstr(strTime,StringLen(strTime)-2);

	int nHour24 = StrToInteger(strHour);
	if (strAM_PM == "pm" || strAM_PM == "PM" && nHour24 != 12)
	{
		nHour24 += 12;
	}
	string strHourPad = "";
	if (nHour24 < 10) strHourPad = "0";

	return(StringConcatenate(Year(),".",strMonth,".",strDay," ",strHourPad,nHour24,":",strMinute));
}
	
