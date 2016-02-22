//+------------------------------------------------------------------+
//|                                                      grabweb.mq4 |
//|                      Copyright © 2006, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern string sUrl = "http://www.forexfactory.com/index.php?page=calendar";

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
   Print("fake start");
  }

int init()
  {
int hInternet;
string iResult;
int lReturn[]={1};
string sBuffer="x";
string sData;
int handle;

hInternet = InternetOpenUrlA(hSession(FALSE), sUrl, "0", 0, 67108864, 0);
Print("hInternet: " + hInternet);   
iResult = InternetReadFile(hInternet, sBuffer, Buffer_LEN, lReturn);
Print("iResult: " + iResult);
Print("lReturn: " + lReturn[0]);
Print("sBuffer: " +  sBuffer);
Comment("sBuffer: " +  sBuffer);

        sData = StringSubstr(sBuffer, 0, lReturn[0]);
        //if there's more data then keep reading it into the buffer
      while (lReturn[0] != 0)
       {
            iResult = InternetReadFile(hInternet, sBuffer, Buffer_LEN, lReturn);
            if (lReturn[0]==0) break;
            sData = sData + StringSubstr(sBuffer, 0, lReturn[0]);
       }

Print("sData: " + sData);
iResult = InternetCloseHandle(hInternet);
Print("iResult: " + iResult);

handle=FileOpen(Day()+ "-"+ Month() +"-"+ Year() +"-"+ "grabweb.htm",FILE_BIN|FILE_READ|FILE_WRITE);
if(handle<1)
    {
     Print("Can\'t open file, the last error is ", GetLastError());
     return(false);
    }
   FileWriteString(handle,sData,StringLen(sData));
   FileClose(handle);


return(0);
  }
   //+------------------------------------------------------------------+