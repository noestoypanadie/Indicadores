//=============================================================================
//															CollectData.mq4
//											  Copyright © 2006, Derk Wehler
//
//=============================================================================
#property copyright "Copyright © 2006, Derk Wehler"
#property link      "none"


//=============================================================================
// expert initialization function
//=============================================================================
int init()
{
	return(0);
}
  
  
//=============================================================================
// expert deinitialization function
//=============================================================================
int deinit()
{
	return(0);
}
  
  
//=============================================================================
// expert start function
//=============================================================================
int start()
{
	int handle;

	handle = FileOpen("Data_" + Symbol() + ".csv", FILE_READ|FILE_WRITE|FILE_CSV, ",");
	FileSeek(handle, 0, SEEK_END);      
	FileWrite(handle, TimeToStr(CurTime(), TIME_DATE|TIME_SECONDS), Bid, Ask);
	FileClose(handle);
	
	return(0);
}


