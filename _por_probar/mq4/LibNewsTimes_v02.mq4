//=============================================================================
//                                                        LibNewsTimes_v02.mq4
//                                               Copyright © 2006, Derk Wehler
//                                                                10 Dec, 2006
// This lib serves one main function:
//
// To inform the calling EA whether it is currently close to news times,
// as reported by ForexFactory.com.  It is to be used in conjunction with 
// the GetNewsFF indicator, which reads the ForexFactory site once per hour 
// and outputs a CSV file containing info on announcements.
//
// The method os use is to call: IsNewsTime(prior, after, currency);
// where "prior" is the number of minutes before the annoucement and 
// "after" is the number of minutes after the announcement, and "currency"
// is the currency pair (defaults to current symbol if you send NULL).  
// So if you call:
//
//     bool newsTime = IsNewsTime(15, 30, "GBPUSD");
//
// ...and there is an announcement for then it will return true fifteen 
// minutes before and 30 minutes after any announcement that involves the 
// GBP or the USD.
//
// Version 02:
// 14 Dec, 2006 - Changed IsNewsTime() to only read the .csv file once 
//                per hour, to save time, because it seemed that the 
//                EA running this was very slow.  Also because it is 
//                just more efficient to avoid opening, reading, and 
//                closing the file every tick.
//
//=============================================================================
#property copyright "Copyright © 2006, Derk Wehler"
#property link      ""
#property library

int DebugOn = 0;

static bool 	Initialized = false;
static int		NewsCount = 0;
static string 	Title[100];
static string 	Currency[100];
static string 	Date[100];
static string 	TimeZone[100];
static string 	Importance[100];


bool IsNewsTime(int prior, int after, string currency)
{
	// Convert minutes to seconds
	prior *= 60;
	after *= 60;
	
	int handle, err;

	// Set the currency variable, pair
	string pair = currency;
	if (currency == "")
		pair = Symbol();
	
	// Break the currency pair string into 2 separate currencies
	string curr1 = StringSubstr(pair, 0, 3);
	string curr2 = StringSubstr(pair, 3, 3);
	if (DebugOn > 2)
	{
		Print("Curr1 calculated: ", curr1);
		Print("Curr2 calculated: ", curr2);
	}

	// Read in the .csv file only initially and once per hour
	if (!Initialized || Minute() == 5)
	{
		Initialized = true;
		
		handle = FileOpen("NewsItems.csv", FILE_READ|FILE_CSV); 
	
		if (handle < 0)
		{
			err = GetLastError();
			if (DebugOn > 0)
	    		Print("IsNewsTime: FileOpen error(",err,"): ", ErrDescription(err));
			return(0);
		}
	
		// Get past (read) the header line of the input file
		string line = "";
		string Header = FileReadString(handle);
		if (DebugOn > 2)
			Print("String read: ", Header);
	
	
		// Now loop through and read each line, breaking it up into separate strings
		line = FileReadString(handle);
		NewsCount = 0;
		while (line != "")
		{
			if (DebugOn > 2)
				Print("WHOLE LINE = ", line);

			int idxComma = 0;
			int idxPrevComma = 0;

			idxComma = StringFind(line, ",", idxComma);
			Title[NewsCount] = StringSubstr(line, idxPrevComma, idxComma - idxPrevComma);
			if (DebugOn > 2)
				Print("String read: ", Title[NewsCount]);
			idxComma++;
			idxPrevComma = idxComma;

			idxComma = StringFind(line, ",", idxComma);
			Currency[NewsCount] = StringSubstr(line, idxPrevComma, idxComma - idxPrevComma);
			if (DebugOn > 2)
				Print("String read: ", Currency[NewsCount]);
			idxComma++;
			idxPrevComma = idxComma;

			idxComma = StringFind(line, ",", idxComma);
			Date[NewsCount] = StringSubstr(line, idxPrevComma, idxComma - idxPrevComma);
			if (DebugOn > 2)
				Print("String read: ", Date[NewsCount]);
			idxComma++;
			idxPrevComma = idxComma;

			idxComma = StringFind(line, ",", idxComma);
			TimeZone[NewsCount] = StringSubstr(line, idxPrevComma, idxComma - idxPrevComma);
			if (DebugOn > 2)
				Print("String read: ", TimeZone[NewsCount]);
			idxComma++;
			idxPrevComma = idxComma;

			idxComma = StringFind(line, ",", idxComma);
			Importance[NewsCount] = StringSubstr(line, idxPrevComma, idxComma - idxPrevComma);
			if (DebugOn > 2)
				Print("String read: ", Importance[NewsCount]);
			idxComma++;
			idxPrevComma = idxComma;

			NewsCount++;
			line = FileReadString(handle);
		}
		FileClose(handle);
	}
	else
	{
		if (DebugOn > 2)
			Print("LibNewsTimes_v02 - Did NOT read file: Date[0] = ", Date[0]);
	}
	
	
	// We now have all the info from the news file in our arrays.
	// Determine if we are "near" news times
	bool isNewsTime = false;
	for (int j=0; j < NewsCount; j++)
	{
		// If this news does not concern the Currency being traded, skip it
		if (Currency[j] != curr1 && Currency[j] != curr2)
			continue;
		
		datetime newsTime = StrToTime(Date[j]);
		datetime beginTime = newsTime - prior;
		datetime endTime = newsTime + after;
		if (DebugOn > 1)
		{
			Print("News: ", Date[j]);
			Print("     Secs Prior:", beginTime);
			Print("      Secs News:", newsTime);
			Print("     Secs After:", endTime);
			Print(" ");
			Print("     Secs NOW:", CurTime());
			Print(" ");
			Print(" ");
			Print(" ");
		}
				
		// Now we just need to decipher the time and 
		// see if it matches the current local time
		if (CurTime() >= beginTime && CurTime() <= endTime)
		{
			isNewsTime = true;
			break;
		}
	}
	
	if (DebugOn > 0 && isNewsTime)
		Print("!!!!!!!!!!!!!!!!!!  LibNewsTime: Is News Time !!!!!!!!!!!!!!!!!!");
	else if (DebugOn > 0)
		Print("!!!!!!!!!!!!!!!!!!  LibNewsTime: NOT News Time !!!!!!!!!!!!!!!!!!");

	return (isNewsTime);
}


//=============================================================================
// return error description
//=============================================================================
string ErrDescription(int error_code)
{
	string error_string;

	switch (error_code)
	{
		//---- codes returned from trade server
		case 0:
		case 1:   error_string = "no error";													break;
		case 2:   error_string = "common error";												break;
		case 3:   error_string = "invalid trade parameters";									break;
		case 4:   error_string = "trade server is busy";										break;
		case 5:   error_string = "old version of the client terminal";							break;
		case 6:   error_string = "no connection with trade server";								break;
		case 7:   error_string = "not enough rights";											break;
		case 8:   error_string = "too frequent requests";										break;
		case 9:   error_string = "malfunctional trade operation";								break;
		case 64:  error_string = "account disabled";											break;
		case 65:  error_string = "invalid account";												break;
		case 128: error_string = "trade timeout";												break;
		case 129: error_string = "invalid price";												break;
		case 130: error_string = "invalid stops";												break;
		case 131: error_string = "invalid trade volume";										break;
		case 132: error_string = "market is closed";											break;
		case 133: error_string = "trade is disabled";											break;
		case 134: error_string = "not enough money";											break;
		case 135: error_string = "price changed";												break;
		case 136: error_string = "off quotes";													break;
		case 137: error_string = "broker is busy";												break;
		case 138: error_string = "requote";														break;
		case 139: error_string = "order is locked";												break;
		case 140: error_string = "long positions only allowed";									break;
		case 141: error_string = "too many requests";											break;
		case 145: error_string = "modification denied because order too close to market";		break;
		case 146: error_string = "trade context is busy";										break;
		//---- mql4 errors
		case 4000: error_string = "no error";													break;
		case 4001: error_string = "wrong function pointer";										break;
		case 4002: error_string = "array index is out of range";								break;
		case 4003: error_string = "no memory for function call stack";							break;
		case 4004: error_string = "recursive stack overflow";									break;
		case 4005: error_string = "not enough stack for parameter";								break;
		case 4006: error_string = "no memory for parameter string";								break;
		case 4007: error_string = "no memory for temp string";									break;
		case 4008: error_string = "not initialized string";										break;
		case 4009: error_string = "not initialized string in array";							break;
		case 4010: error_string = "no memory for array\' string";								break;
		case 4011: error_string = "too long string";											break;
		case 4012: error_string = "remainder from zero divide";									break;
		case 4013: error_string = "zero divide";												break;
		case 4014: error_string = "unknown command";											break;
		case 4015: error_string = "wrong jump (never generated error)";							break;
		case 4016: error_string = "not initialized array";										break;
		case 4017: error_string = "dll calls are not allowed";									break;
		case 4018: error_string = "cannot load library";										break;
		case 4019: error_string = "cannot call function";										break;
		case 4020: error_string = "expert function calls are not allowed";						break;
		case 4021: error_string = "not enough memory for temp string returned from function";	break;
		case 4022: error_string = "system is busy (never generated error)";						break;
		case 4050: error_string = "invalid function parameters count";							break;
		case 4051: error_string = "invalid function parameter value";							break;
		case 4052: error_string = "string function internal error";								break;
		case 4053: error_string = "some array error";											break;
		case 4054: error_string = "incorrect series array using";								break;
		case 4055: error_string = "custom indicator error";										break;
		case 4056: error_string = "arrays are incompatible";									break;
		case 4057: error_string = "global variables processing error";							break;
		case 4058: error_string = "global variable not found";									break;
		case 4059: error_string = "function is not allowed in testing mode";					break;
		case 4060: error_string = "function is not confirmed";									break;
		case 4061: error_string = "send mail error";											break;
		case 4062: error_string = "string parameter expected";									break;
		case 4063: error_string = "integer parameter expected";									break;
		case 4064: error_string = "double parameter expected";									break;
		case 4065: error_string = "array as parameter expected";								break;
		case 4066: error_string = "requested history data in update state";						break;
		case 4099: error_string = "end of file";												break;
		case 4100: error_string = "some file error";											break;
		case 4101: error_string = "wrong file name";											break;
		case 4102: error_string = "too many opened files";										break;
		case 4103: error_string = "cannot open file";											break;
		case 4104: error_string = "incompatible access to a file";								break;
		case 4105: error_string = "no order selected";											break;
		case 4106: error_string = "unknown symbol";												break;
		case 4107: error_string = "invalid price parameter for trade function";					break;
		case 4108: error_string = "invalid ticket";												break;
		case 4109: error_string = "trade is not allowed";										break;
		case 4110: error_string = "longs are not allowed";										break;
		case 4111: error_string = "shorts are not allowed";										break;
		case 4200: error_string = "object is already exist";									break;
		case 4201: error_string = "unknown object property";									break;
		case 4202: error_string = "object is not exist";										break;
		case 4203: error_string = "unknown object type";										break;
		case 4204: error_string = "no object name";												break;
		case 4205: error_string = "object coordinates error";									break;
		case 4206: error_string = "no specified subwindow";										break;
		default:   error_string = "unknown error";
	}

	return(error_string);
}  



