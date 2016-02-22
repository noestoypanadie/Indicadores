//+------------------------------------------------------------------+
//|                                                      grabweb.mq4 |
//|                                           Copyright © 2006, Abhi |
//|                                http://www.megadelfi.com/experts/ |
//|                            E-mail: grabwebexpert{Q)megadelfi.com |
//|                       fix my e-mail address before mailing me ;) |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Abhi"
#property link      "http://www.megadelfi.com/experts/"

extern string sUrl = "http://www.forexfactory.com/index.php?s=&page=calendar&timezoneoffset=t+3";

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

handle=FileOpen(Day()+ "-"+ Month() +"-"+ Year() +"-"+ "grabweb.csv",FILE_BIN|FILE_READ|FILE_WRITE);
if(handle<1)
    {
     Print("Can\'t open csv file, the last error is ", GetLastError());
     return(false);
    }


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
         csvoutput = newsdate + ", " + newstime + ", " + country + ", " + news + ", " +level + ", " + actual + ", " + forecast + ", " + previous;
         Print("newslist: "+ csvoutput);
         FileWriteString(handle,csvoutput,StringLen(csvoutput));
         FileWriteString(handle,"\x0D\x0A",2); // force new line
    }
   FileClose(handle);

return(0);
  }
   //+------------------------------------------------------------------+