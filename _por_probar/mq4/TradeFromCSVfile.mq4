//+------------------------------------------------------------------+
//|                                             TradeFromCSVfile.mq4 |
//|                                               Paul Hampton-Smith |
//+------------------------------------------------------------------+
/*
APPEARS TO WORK BUT NOT FULLY TESTED

This is a crude "API" for MT4. It allows external programs to control MT4 to execute, modify and delete trades

Store in experts/scripts and compile

Polls folder experts/files every nRepeatDelaySeconds for a file commandfile.txt
If it exists, reads a single trade command as per examples below:

OrderSend,AUDUSD,OP_BUY,1,Ask,5,0,0,1236,9999,0,Orange
OrderSend,AUDUSD,OP_BUYSTOP,1,0.7670,5,0,0,1236,9999,0,Orange
OrderModify,1236,0.7695,0.7620,0.7720,0,Orange
OrderClose,1236,1,Bid,5,Purple
OrderDelete,1236

If the command in commandfile.txt is successful it is deleted and the command is written to commandfile_log.txt
Unsuccessful commandfiles are renamed "FAILED Time[0] commandfile.txt"

Maintains list of open orders in openorders.txt in format:
OrderOpenTime,OrderComment,OrderMagicNumber,OrderSymbol,OrderType,OrderLots,OrderOpenPrice,OrderStopLoss,OrderTakeProfit

*/


#include <stderror.mqh>
#include <stdlib.mqh>

#property show_inputs
extern bool bTradeDebug = false; // turn on for debug messages
extern int nRepeatDelaySeconds = 10; // poll repeat delay

string strCommandFileName = "commandfile.txt";
string strCommandFileLogName = "commandfile_log.txt";
string strOrdersReportFileName = "openorders.txt";



int start()
{
	while(true)
	{
		int handle = FileOpen(strCommandFileName, FILE_CSV|FILE_READ, ',');
   	if (handle > 0 && GetLastError() == 0)
   	{  
			int nTry = 0;
			int nMaxTries = 5;
			int nTryDelay_mSec = 500;
			
			bool bSuccess = ReadAndExecuteCommand(handle);
			while (!bSuccess && nTry < nMaxTries)
			{
				Sleep(nTryDelay_mSec);
				bSuccess = ReadAndExecuteCommand(handle);
				nTry++;
   		}
   		
   		if (bSuccess)
   		{
   			FileClose(handle);
   			FileDelete(strCommandFileName);
   		}
   		else
   		{
   			FileClose(handle);
   			Alert("Problem executing ", strCommandFileName);
   			FileRename(strCommandFileName, "FAILED "+Time[0]+" "+strCommandFileName);
			}   		
   	}
   	ReportOrders();
      SleepSeconds(nRepeatDelaySeconds);
	}
	return(0);
}
//+------------------------------------------------------------------+



bool ReadAndExecuteCommand(int handle)
{
   int nLastError = 0;

//////////////////////////////////////
   // Handle

   if (handle <= 0)
   {
      Print("Invalid file handle for command file", strCommandFileName);
      return(false);
   }

//////////////////////////////////////
   // Command
   string strCommand = FileReadString(handle); nLastError = GetLastError();
   if (nLastError != 0 && nLastError != ERR_NOT_INITIALIZED_STRING)
   {
      if (nLastError != ERR_END_OF_FILE) Print(ErrorDescription(nLastError)," reading command from ",strCommandFileName);
      return(false);
   }
   
	bool bResult;
	if (strCommand == "OrderSend") bResult = CSVfileOrderSend(handle);
   else if (strCommand == "OrderModify") bResult = CSVfileOrderModify(handle);
   else if (strCommand == "OrderDelete") bResult = CSVfileOrderDelete(handle);
   else if (strCommand == "OrderClose") bResult = CSVfileOrderClose(handle);
	else 
	{
      Print("Unknown command ",strCommand," in ",strCommandFileName);
      return(false);
	}

	if (bResult)
	{
   	if (bTradeDebug) Print("Function ReadAndExecuteCommand() returning true for ",strCommand);
   	return(true);
   }
   else
   {
   	Print("Function ReadAndExecuteCommand() returning false for ",strCommand);
   	return(false);
	}   
}


bool CSVfileOrderSend(int handle)
{
	int cmd,slippage,magic,handle1;
	double volume,price,stoploss,takeprofit;
	string symbol,comment;
	datetime expiration;
	color arrow_color;
	
	if (!CheckHandle(handle)) return(false);
	if (!ReadSymbol(handle,symbol)) return(false);
	if (!ReadCmd(handle,cmd)) return(false);
	if (!ReadVolume(handle,volume)) return(false);
	if (!ReadPrice(handle,symbol,price)) return(false);
	if (!ReadSlippage(handle,slippage)) return(false);
   if (!ReadStopLoss(handle,stoploss)) return(false);
	if (!ReadTakeProfit(handle,takeprofit)) return(false);
	if (!ReadComment(handle,comment)) return(false);
	if (!ReadMagic(handle,magic)) return(false);
	if (!ReadExpiration(handle,expiration)) return(false);
	if (!ReadArrowColor(handle,arrow_color)) return(false);
  	
	int nTicket = FindOrderFromComment(comment);
	if (nTicket == -1)  	
  	{
  		nTicket = OrderSend(symbol,cmd,volume,price,slippage,stoploss,takeprofit,comment,magic,expiration,arrow_color);
	  	if (nTicket > 0)
	  	{
  			if (bTradeDebug) Print("Function CSVfileOrderSend() returning true after sending cmd (",symbol,",",cmd,",",volume,",",price,",",slippage,",",stoploss,",",takeprofit,",\"",comment,"\",",magic,",",StrToTime(expiration),",",arrow_color,")");
  			handle1 = FileOpen(strCommandFileLogName,FILE_READ|FILE_WRITE|FILE_CSV,',');
  			if (handle1 > 0 && GetLastError() == 0)
  			{
  				FileSeek(handle1,0,SEEK_END);
  				FileWrite(handle1,TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS)," OrderSend",symbol,CmdToStr(cmd),volume,price,slippage,stoploss,takeprofit,comment,magic,StrToTime(expiration),arrow_color);
  				FileClose(handle1);
  			}
  			else
  			{
  				Print("Problem writing to ",strCommandFileLogName);
  			}
	  		return(true);
  		}
  		else
		{  	
 			Print("Function CSVfileOrderSend() returning false after error ",ErrorDescription(GetLastError())," sending cmd (",symbol,",",cmd,",",volume,",",price,",",slippage,",",stoploss,",",takeprofit,",\"",comment,"\",",magic,",",StrToTime(expiration),",",arrow_color,")");
 			return(false);
 		}
  	}
  	else
  	{
  		Print("Function CSVfileOrderSend() returning false after finding existing cmd (",symbol,",",cmd,",",volume,",",price,",",slippage,",",stoploss,",",takeprofit,",\"",comment,"\",",magic,",",StrToTime(expiration),",",arrow_color,")");
  		return(false);
  	}
}

bool CSVfileOrderModify(int handle)
{
// bool OrderModify( int ticket, double price, double stoploss, double takeprofit, datetime expiration, color arrow_color=CLR_NONE) 
	int ticket, nLastError;
	double price,stoploss,takeprofit;
	datetime expiration;
	color arrow_color;
	
	if (!CheckHandle(handle)) return(false);
	if (!ReadTicket(handle,ticket)) return(false);
	OrderSelect(ticket,SELECT_BY_TICKET);
	if (!ReadPrice(handle,OrderSymbol(),price)) return(false);
	if (!ReadStopLoss(handle,stoploss)) return(false);
	if (!ReadTakeProfit(handle,takeprofit)) return(false);
	if (!ReadExpiration(handle,expiration)) return(false);
	if (!ReadArrowColor(handle,arrow_color)) return(false);
			
	OrderModify(ticket,price,stoploss,takeprofit,expiration,arrow_color); nLastError = GetLastError(); 
	if (nLastError > 1)
	{
		Print("Function CSVfileOrderModify() returning false after error ",ErrorDescription(nLastError)," sending cmd (",ticket,",",price,",",stoploss,",",takeprofit,",",StrToTime(expiration),",",arrow_color,")");
		return(false);
	}
	else
	{
		if (bTradeDebug) Print("Function CSVfileOrderModify() returning true sending cmd (",ticket,",",price,",",stoploss,",",takeprofit,",",StrToTime(expiration),",",arrow_color,")");
		int handle1 = FileOpen(strCommandFileLogName,FILE_READ|FILE_WRITE|FILE_CSV,',');
		if (handle1 > 0 && GetLastError() == 0)
		{
			FileSeek(handle1,0,SEEK_END);
			FileWrite(handle1,TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS)," OrderModify",ticket,price,stoploss,takeprofit,expiration,arrow_color);
			FileClose(handle1);
		}
		else
		{
			Print("Problem writing to ",strCommandFileLogName);
		}
		return(true);
	}
}

bool CSVfileOrderDelete(int handle)
{
	// bool OrderDelete( int ticket) 
	int ticket, nLastError;

	if (!CheckHandle(handle)) return(false);
	if (!ReadTicket(handle,ticket)) return(false);
	
	OrderDelete(ticket); nLastError = GetLastError();
	if (nLastError > 1)
	{
		Print("Function CSVfileOrderDelete() returning false after error ",ErrorDescription(nLastError)," deleting ticket # ",ticket);
		return(false);
	}
	else
	{
		if (bTradeDebug) Print("Function CSVfileOrderDelete() returning true deleting order # ",ticket);
		int handle1 = FileOpen(strCommandFileLogName,FILE_READ|FILE_WRITE|FILE_CSV,',');
		if (handle1 > 0 && GetLastError() == 0)
		{
			FileSeek(handle1,0,SEEK_END);
  			FileWrite(handle1,TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS)," OrderDelete",ticket);
  			FileClose(handle1);
  		}
  		else
  		{
  			Print("Problem writing to ",strCommandFileLogName);
  		}
		return(true);
	}
}
 
bool CSVfileOrderClose(int handle)
{
// bool OrderClose( int ticket, double lots, double price, int slippage, color Color=CLR_NONE) 
	int ticket,slippage,nLastError;
	double volume,price;
	color arrow_color;

	if (!CheckHandle(handle)) return(false);
	if (!ReadTicket(handle,ticket)) return(false);
	if (!ReadVolume(handle,volume)) return(false);
	OrderSelect(ticket,SELECT_BY_TICKET);
	if (!ReadPrice(handle,OrderSymbol(),price)) return(false);
	if (!ReadSlippage(handle,slippage)) return(false);
	if (!ReadArrowColor(handle,arrow_color)) return(false);
 
	OrderClose(ticket,volume,price,slippage,arrow_color); nLastError = GetLastError();
	if (nLastError > 1)
	{
		Print("Function CSVfileOrderClose() returning false after error ",ErrorDescription(nLastError)," closing ticket # ",ticket," with parameters (",volume,",",price,",",slippage,",",arrow_color,")");
		return(false);
	}
	else
	{
		if (bTradeDebug) Print("Function CSVfileOrderClose() returning true closing ticket # ",ticket," with parameters (",volume,",",price,",",slippage,",",arrow_color,")");
		int handle1 = FileOpen(strCommandFileLogName,FILE_READ|FILE_WRITE|FILE_CSV,',');
		if (handle1 > 0 && GetLastError() == 0)
		{
			FileSeek(handle1,0,SEEK_END);
			FileWrite(handle1,TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS)," OrderClose",ticket,volume,price,slippage,arrow_color);
			FileClose(handle1);
		}
		else
		{
			Print("Problem writing to ",strCommandFileLogName);
		}
		return(true);
	}
}

int FindOrderFromComment(string strComment)
{
	int nPosition;
   for ( nPosition=0 ; nPosition<OrdersTotal() ; nPosition++ )
   {
      OrderSelect(nPosition, SELECT_BY_POS, MODE_TRADES);
      if (OrderComment() == strComment)
      {
         return(OrderTicket());
      }
   }
   return(-1);
}

void SleepSeconds(int nSeconds)
{
	for (int i = 0 ; i<nSeconds ; i++) Sleep(1000);
}


bool CheckHandle(int handle)
{
   if (handle <= 0)
   {
      Print("Invalid file handle");
      return(false);
   }
   else
   {
   	return(true);
   }
}
   
bool ReadSymbol(int handle, string& symbol)
{
	int nLastError;
   symbol = FileReadString(handle); nLastError = GetLastError();
   symbol = StringTrimLeft(StringTrimRight(symbol));
   if (nLastError > 1 && nLastError != ERR_NOT_INITIALIZED_STRING)
  	{
      Print("Function ReadSymbol() returning false after error ",ErrorDescription(nLastError));
     	return(false);
  	}
  	else
  	{
  		if (bTradeDebug) Print("Function ReadComment() returning true and \"",symbol,"\"");
  		return(true);
  	}
}

bool ReadCmd(int handle, int& cmd)
{
	int nLastError;
   string strCmd = FileReadString(handle); nLastError = GetLastError();
   if (nLastError > 1 && nLastError != ERR_NOT_INITIALIZED_STRING)
  	{
      Print("Function ReadCmd() returning false after error ",ErrorDescription(nLastError));
      return(false);
  	}

   cmd = StrToCmd(StringTrimLeft(StringTrimRight(strCmd)));
   if (cmd == -1)
   {
      Print("Function ReadCmd() returning false after error ",ErrorDescription(GetLastError()));
      return(false);
   }
	else
	{
	   if (bTradeDebug) Print("Function ReadCmd() returning true and ",cmd);
  		return(true);
  	}
}

bool ReadVolume(int handle, double& volume)
{
	int nLastError;
   volume = FileReadNumber(handle); nLastError = GetLastError();
   if (nLastError > 1)
  	{
      Print("Function ReadVolume() returning false after error ",ErrorDescription(nLastError));
     	return(false);
  	}
	else
	{
	   if (bTradeDebug) Print("Function ReadVolume() returning true and ",volume);
	   return(true);
	}
}

bool ReadPrice(int handle, string strSymbol, double& price)
{
	int nLastError;
   string strPrice = FileReadString(handle); nLastError = GetLastError();
   if (nLastError > 1 && nLastError != ERR_NOT_INITIALIZED_STRING)
  	{
      Print("Function ReadPrice() returning false after error ",ErrorDescription(nLastError));
     	return(false);
  	}
  	
   if (strPrice == "Ask") 
   {
   	price = MarketInfo(strSymbol,MODE_ASK);
   }
   else if (strPrice == "Bid") 
   {
   	price = MarketInfo(strSymbol,MODE_BID);
	}
   else 
   {
   	price = StrToDouble(strPrice); nLastError = GetLastError();
   }
   if (nLastError > 1)
  	{
      Print("Function ReadPrice() returning false after error ",ErrorDescription(nLastError));
     	return(false);
  	}
	else
	{
	   if (bTradeDebug) Print("Function ReadPrice() returning true and ",price);
	   return(true);
	}
}
   
bool ReadSlippage(int handle, int& slippage)
{
	int nLastError;
   slippage = FileReadNumber(handle)+0.1; nLastError = GetLastError();
   if (nLastError > 1)
  	{
      Print("Function ReadSlippage() returning false after error ",ErrorDescription(nLastError));
     	return(false);
  	}
	else
	{
	   if (bTradeDebug) Print("Function ReadSlippage() returning true and ",slippage);
	   return(true);
	}
}

bool ReadStopLoss(int handle, double& stoploss)
{
	int nLastError;
   stoploss = FileReadNumber(handle); nLastError = GetLastError();
   if (nLastError > 1)
  	{
      Print("Function ReadStoploss() returning false after error ",ErrorDescription(nLastError));
     	return(false);
  	}
	else
	{
	   if (bTradeDebug) Print("Function ReadStopLoss() returning true and ",stoploss);
	   return(true);
	}
}

bool ReadTakeProfit(int handle, double& takeprofit)
{
	int nLastError;
   takeprofit = FileReadNumber(handle); nLastError = GetLastError();
   if (nLastError > 1)
  	{
      Print("Function ReadStoploss() returning false after error ",ErrorDescription(nLastError));
     	return(false);
  	}
	else
	{
	   if (bTradeDebug) Print("Function ReadTakeProfit() returning true and ",takeprofit);
	   return(true);
	}
}
  	
bool ReadComment(int handle, string& comment)
{
	int nLastError;
   comment = FileReadString(handle); nLastError = GetLastError();
   comment = StringTrimLeft(StringTrimRight(comment));
   if (nLastError > 1 && nLastError != ERR_NOT_INITIALIZED_STRING)
  	{
      Print("Function ReadComment() returning false after error ",ErrorDescription(nLastError));
     	return(false);
  	}
	else
	{
	   if (bTradeDebug) Print("Function ReadComment() returning true and \"",comment,"\"");
	   return(true);
	}
}
  	
bool ReadMagic(int handle, int& magic)
{
	int nLastError;
   magic = FileReadNumber(handle)+0.1; nLastError = GetLastError();
   if (nLastError > 1)
  	{
      Print("Function ReadMagic() returning false after error ",ErrorDescription(nLastError));
     	return(false);
  	}
	else
	{
	   if (bTradeDebug) Print("Function ReadMagic() returning true and ",magic);
	   return(true);
	}
}

bool ReadExpiration(int handle, datetime& expiration)
{
	int nLastError;
   string strExpiration = FileReadString(handle); nLastError = GetLastError();
   if (nLastError > 1 && nLastError != ERR_NOT_INITIALIZED_STRING)
	{
      Print("Function ReadExpiration() returning false after error ",ErrorDescription(nLastError));
   	return(false);
  	}
   
   strExpiration = StringTrimLeft(StringTrimRight(strExpiration));
   if (strExpiration == "0")
   {
   	expiration = 0;
   }
   else
   {
   	expiration = StrToTime(strExpiration); nLastError = GetLastError();
   if (nLastError > 1)
  		{
	      Print("Function ReadExpiration() returning false after error ",ErrorDescription(nLastError));
     		return(false);
  		}
  	}

	if (bTradeDebug) Print("Function ReadExpiration() returning true and ",expiration);
	return(true);
}
  	
bool ReadArrowColor(int handle, color& arrow_color)
{
	int nLastError;
   string strColor = FileReadString(handle); nLastError = GetLastError();
   int nRightBracketPos = StringFind(strColor,")");
   if (nRightBracketPos != -1) strColor = StringTrimLeft(StringTrimRight(StringSubstr(strColor,0,nRightBracketPos)));
   arrow_color = StrToColor(strColor);
   if (nLastError > 1 && nLastError != ERR_END_OF_FILE && nLastError != ERR_NOT_INITIALIZED_STRING)
  	{
      Print("Function ReadArrowColor() returning false after error ",ErrorDescription(nLastError));
     	return(false);
  	}
	else
	{
	   if (bTradeDebug) Print("Function ReadArrowColor() returning true and ",arrow_color);
	   return(true);
	}
}

bool ReadTicket(int handle, int& ticket)
{
	int nLastError;
   int nExternalTicket = FileReadNumber(handle)+0.1; nLastError = GetLastError();
   if (nLastError > 1)
  	{
      Print("Function ReadTicket() returning false after error ",ErrorDescription(nLastError));
     	return(false);
  	}
	ticket = FindOrderFromComment(nExternalTicket);
   if (ticket == -1)
  	{
      Print("Function ReadTicket() could not find order");
     	return(false);
  	}
	else
	{
	   if (bTradeDebug) Print("Function ReadTicket() returning true and ",ticket);
	   return(true);
	}
}


int StrToCmd(string str)
{
   if (str == "OP_BUY") return(OP_BUY);
   if (str == "OP_SELL") return(OP_SELL);
   if (str == "OP_BUYSTOP") return(OP_BUYSTOP);
   if (str == "OP_SELLSTOP") return(OP_SELLSTOP);
   if (str == "OP_BUYLIMIT") return(OP_BUYLIMIT);
   if (str == "OP_SELLLIMIT") return(OP_SELLLIMIT);
	return(-1);
}   

color StrToColor(string str)
{
	if (str == "Black") return(Black);
	if (str == "DarkGreen") return(DarkGreen); 
	if (str == "DarkSlateGray") return(DarkSlateGray); 
	if (str == "Olive") return(Olive); 
	if (str == "Green") return(Green); 
	if (str == "Teal") return(Teal); 
	if (str == "Navy") return(Navy); 
	if (str == "Purple") return(Purple); 
	if (str == "Maroon") return(Maroon); 
	if (str == "Indigo") return(Indigo);
	if (str == "MidnightBlue") return(MidnightBlue); 
	if (str == "DarkBlue") return(DarkBlue); 
	if (str == "DarkOliveGreen") return(DarkOliveGreen); 
	if (str == "SaddleBrown") return(SaddleBrown); 
	if (str == "ForestGreen") return(ForestGreen); 
	if (str == "OliveDrab") return(OliveDrab); 
	if (str == "SeaGreen") return(SeaGreen); 
	if (str == "DarkGoldenrod") return(DarkGoldenrod); 
	if (str == "DarkSlateBlue") return(DarkSlateBlue); 
	if (str == "Sienna") return(Sienna); 
	if (str == "MediumBlue") return(MediumBlue); 
	if (str == "Brown") return(Brown); 
	if (str == "DarkTurquoise") return(DarkTurquoise); 
	if (str == "DimGray") return(DimGray); 
	if (str == "LightSeaGreen") return(LightSeaGreen); 
	if (str == "DarkViolet") return(DarkViolet); 
	if (str == "FireBrick") return(FireBrick); 
	if (str == "MediumVioletRed") return(MediumVioletRed); 
	if (str == "MediumSeaGreen") return(MediumSeaGreen); 
	if (str == "Chocolate") return(Chocolate); 
	if (str == "Crimson") return(Crimson); 
	if (str == "SteelBlue") return(SteelBlue); 
	if (str == "Goldenrod") return(Goldenrod); 
	if (str == "MediumSpringGreen") return(MediumSpringGreen); 
	if (str == "LawnGreen") return(LawnGreen); 
	if (str == "CadetBlue") return(CadetBlue); 
	if (str == "DarkOrchid") return(DarkOrchid); 
	if (str == "YellowGreen") return(YellowGreen); 
	if (str == "LimeGreen") return(LimeGreen); 
	if (str == "OrangeRed") return(OrangeRed); 
	if (str == "DarkOrange") return(DarkOrange); 
	if (str == "Orange") return(Orange); 
	if (str == "Gold") return(Gold); 
	if (str == "Yellow") return(Yellow); 
	if (str == "Chartreuse ") return(Chartreuse);
	if (str == "Lime") return(Lime); 
	if (str == "SpringGreen") return(SpringGreen); 
	if (str == "Aqua") return(Aqua); 
	if (str == "DeepSkyBlue") return(DeepSkyBlue); 
	if (str == "Blue") return(Blue); 
	if (str == "Magenta") return(Magenta); 
	if (str == "Red") return(Red); 
	if (str == "Gray") return(Gray); 
	if (str == "SlateGray") return(SlateGray); 
	if (str == "Peru") return(Peru); 
	if (str == "BlueViolet") return(BlueViolet); 
	if (str == "LightSlateGray") return(LightSlateGray); 
	if (str == "DeepPink") return(DeepPink); 
	if (str == "MediumTurquoise") return(MediumTurquoise);
	if (str == "DodgerBlue") return(DodgerBlue); 
	if (str == "Turquoise") return(Turquoise); 
	if (str == "RoyalBlue") return(RoyalBlue); 
	if (str == "SlateBlue") return(SlateBlue); 
	if (str == "DarkKhaki") return(DarkKhaki); 
	if (str == "IndianRed") return(IndianRed); 
	if (str == "MediumOrchid") return(MediumOrchid); 
	if (str == "GreenYellow") return(GreenYellow); 
	if (str == "MediumAquamarine") return(MediumAquamarine); 
	if (str == "DarkSeaGreen") return(DarkSeaGreen); 
	if (str == "Tomato") return(Tomato); 
	if (str == "RosyBrown") return(RosyBrown); 
	if (str == "Orchid") return(Orchid); 
	if (str == "MediumPurple") return(MediumPurple); 
	if (str == "PaleVioletRed") return(PaleVioletRed); 
	if (str == "Coral") return(Coral); 
	if (str == "CornflowerBlue") return(CornflowerBlue); 
	if (str == "DarkGray") return(DarkGray); 
	if (str == "SandyBrown") return(SandyBrown); 
	if (str == "MediumSlateBlue") return(MediumSlateBlue); 
	if (str == "Tan") return(Tan); 
	if (str == "DarkSalmon") return(DarkSalmon); 
	if (str == "BurlyWood") return(BurlyWood); 
	if (str == "HotPink") return(HotPink); 
	if (str == "Salmon") return(Salmon); 
	if (str == "Violet") return(Violet); 
	if (str == "LightCoral") return(LightCoral); 
	if (str == "SkyBlue") return(SkyBlue); 
	if (str == "LightSalmon") return(LightSalmon); 
	if (str == "Plum") return(Plum); 
	if (str == "Khaki") return(Khaki); 
	if (str == "LightGreen") return(LightGreen); 
	if (str == "Aquamarine") return(Aquamarine); 
	if (str == "Silver") return(Silver); 
	if (str == "LightSkyBlue") return(LightSkyBlue); 
	if (str == "LightSteelBlue") return(LightSteelBlue); 
	if (str == "LightBlue") return(LightBlue); 
	if (str == "PaleGreen") return(PaleGreen); 
	if (str == "Thistle") return(Thistle); 
	if (str == "PowderBlue") return(PowderBlue); 
	if (str == "PaleGoldenrod") return(PaleGoldenrod); 
	if (str == "PaleTurquoise") return(PaleTurquoise); 
	if (str == "LightGray") return(LightGray); 
	if (str == "Wheat") return(Wheat); 
	if (str == "NavajoWhite") return(NavajoWhite); 
	if (str == "Moccasin") return(Moccasin); 
	if (str == "LightPink") return(LightPink); 
	if (str == "Gainsboro") return(Gainsboro); 
	if (str == "PeachPuff") return(PeachPuff); 
	if (str == "Pink") return(Pink); 
	if (str == "Bisque") return(Bisque); 
//	if (str == "LightGoldenRod") return(LightGoldenRod); -- doesn't exist
	if (str == "BlanchedAlmond") return(BlanchedAlmond); 
	if (str == "LemonChiffon") return(LemonChiffon); 
	if (str == "Beige") return(Beige); 
	if (str == "AntiqueWhite") return(AntiqueWhite); 
	if (str == "PapayaWhip") return(PapayaWhip); 
	if (str == "Cornsilk") return(Cornsilk); 
	if (str == "LightYellow") return(LightYellow); 
	if (str == "LightCyan") return(LightCyan); 
	if (str == "Linen") return(Linen); 
	if (str == "Lavender") return(Lavender); 
	if (str == "MistyRose") return(MistyRose); 
	if (str == "OldLace") return(OldLace); 
	if (str == "WhiteSmoke") return(WhiteSmoke); 
	if (str == "Seashell") return(Seashell); 
	if (str == "Ivory") return(Ivory); 
	if (str == "Honeydew") return(Honeydew); 
	if (str == "AliceBlue") return(AliceBlue); 
	if (str == "LavenderBlush") return(LavenderBlush); 
	if (str == "MintCream") return(MintCream); 
	if (str == "Snow") return(Snow); 
	if (str == "White") return(White); 
	return(-1);
}

string CmdToStr(int cmd)
{
   switch(cmd)
   {
   case OP_BUY: return("OP_BUY");
   case OP_SELL: return("OP_SELL");
   case OP_BUYSTOP: return("OP_BUYSTOP");
   case OP_SELLSTOP: return("OP_SELLSTOP");
   case OP_BUYLIMIT: return("OP_BUYLIMIT");
   case OP_SELLLIMIT: return("OP_SELLLIMIT");
   default: return("OP_UNKNOWN");
   }
}      

void ReportOrders()
{
	int handle = 0;
	int nTry = 0;
	int nMaxTries = 10;
	int nTryDelay_mSec = 500;
	
	// external program may be reading strOrdersReportFileName, so retry
	while (handle <= 0 && nTry < nMaxTries)
	{
		handle = FileOpen(strOrdersReportFileName,FILE_WRITE|FILE_CSV,",");
		nTry++;
		Sleep(nTryDelay_mSec);
	}
	
	FileWrite(handle,"OrderOpenTime","OrderComment","OrderMagicNumber","OrderSymbol","OrderType","OrderLots","OrderOpenPrice","OrderStopLoss","OrderTakeProfit");
	for (int i = 0 ; i < OrdersTotal() ; i++)
	{
		OrderSelect(i,SELECT_BY_POS);
		FileWrite(handle,TimeToStr(OrderOpenTime()),OrderComment(),OrderMagicNumber(),OrderSymbol(),CmdToStr(OrderType()),OrderLots(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
	}
	FileClose(handle);
}			

void FileRename(string source, string dest)
{
	// only works for short files
	int handle = 0;
	int nTry = 0;
	int nMaxTries = 10;
	int nTryDelay_mSec = 500;
	string everything;
	
	// external program may be reading strOrdersReportFileName, so retry
	while (handle <= 0 && nTry < nMaxTries)
	{
		handle = FileOpen(source,FILE_READ|FILE_BIN);
		everything = FileReadString(handle,500);
		FileClose(handle);
		FileDelete(source);
		nTry++;
		Sleep(nTryDelay_mSec);
	}

	handle = FileOpen(dest,FILE_WRITE|FILE_BIN);
	FileWriteString(handle,everything,StringLen(everything));
	FileClose(handle);
}
	
	

