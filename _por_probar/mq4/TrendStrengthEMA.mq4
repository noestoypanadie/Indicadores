#property copyright "pengie, Braindancer"
#property link      "http://www.forex-tsd.com"

extern string EAName = "TrendStrengthEMA";
extern int magic = 2703;

extern int SL = 0;
extern int TP = 0;

extern int slippage = 3;
extern double lots = 0.1;

datetime prevTime, curTime;
int ticket;

int init()
{
   prevTime = Time[0];
   magic = GenerateMagicNumber(magic, Symbol(), Period());
	EAName = GenerateComment(EAName, magic, Period());
	
	int maxOrders = OrdersTotal();
	int t_index;
	for (t_index=0; t_index<maxOrders; t_index++)
	{
		OrderSelect(t_index, SELECT_BY_POS, MODE_TRADES);
		if (magic==OrderMagicNumber())
		{			
			ticket = OrderTicket();
			break;
		}	
	}	
   return (0);
}

int deinit()
{
   return (0);
}

int start()
{
   curTime = Time[0];
   
   if (prevTime != curTime)
   {
      prevTime = curTime;
      
      double tmp = iMA(NULL,0,11,0,MODE_EMA,PRICE_CLOSE,2);     
      double ma1 = tmp-iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,2); 
      double ma2 = tmp-iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,2); 
      double ma3 = tmp-iMA(NULL,0,15,0,MODE_EMA,PRICE_CLOSE,2); 
      double ma4 = tmp-iMA(NULL,0,20,0,MODE_EMA,PRICE_CLOSE,2);  
      double ma5 = tmp-iMA(NULL,0,25,0,MODE_EMA,PRICE_CLOSE,2);
      double ma6 = tmp-iMA(NULL,0,30,0,MODE_EMA,PRICE_CLOSE,2);
      double ma7 = tmp-iMA(NULL,0,40,0,MODE_EMA,PRICE_CLOSE,2);
     
      double prevTS = (ma1+ma2+ma3+ma4+ma5+ma6+ma7)/7;  
      
      tmp = iMA(NULL,0,11,0,MODE_EMA,PRICE_CLOSE,1);     
      ma1 = tmp-iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,1); 
      ma2 = tmp-iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,1); 
      ma3 = tmp-iMA(NULL,0,15,0,MODE_EMA,PRICE_CLOSE,1); 
      ma4 = tmp-iMA(NULL,0,20,0,MODE_EMA,PRICE_CLOSE,1);  
      ma5 = tmp-iMA(NULL,0,25,0,MODE_EMA,PRICE_CLOSE,1);
      ma6 = tmp-iMA(NULL,0,30,0,MODE_EMA,PRICE_CLOSE,1);
      ma7 = tmp-iMA(NULL,0,40,0,MODE_EMA,PRICE_CLOSE,1);
      
      double curTS = (ma1+ma2+ma3+ma4+ma5+ma6+ma7)/7;
      double stoploss, takeprofit;
      if (prevTS<0 && curTS>0)
      {
         OrderClose(ticket, lots, Ask, slippage, CLR_NONE);
         stoploss = 0;
         if (SL != 0) stoploss = Ask-SL*Point;
         takeprofit = 0;
         if (TP != 0) takeprofit = Ask+TP*Point;
         ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, slippage, stoploss, takeprofit, EAName, magic, 0, CLR_NONE);         
      }
      else if (prevTS>0 && curTS<0)
      {
         OrderClose(ticket, lots, Bid, slippage, CLR_NONE);
         stoploss = 0;
         if (SL != 0) stoploss = Bid+SL*Point;
         takeprofit = 0;
         if (TP != 0) takeprofit = Bid-TP*Point;
         ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, slippage, stoploss, takeprofit, EAName, magic, 0, CLR_NONE);         
      }
   }
   return (0);
}

int GenerateMagicNumber(int seed, string symbol, int timeFrame)
{
   int isymbol = 0;
   if (symbol == "EURUSD") isymbol = 1;
   else if (symbol == "GBPUSD") isymbol = 2;
   else if (symbol == "USDJPY") isymbol = 3;
   else if (symbol == "USDCHF") isymbol = 4;
   else if (symbol == "AUDUSD") isymbol = 5;
   else if (symbol == "USDCAD") isymbol = 6;
   else if (symbol == "EURGBP") isymbol = 7;
   else if (symbol == "EURJPY") isymbol = 8;
   else if (symbol == "EURCHF") isymbol = 9;
   else if (symbol == "EURAUD") isymbol = 10;
   else if (symbol == "EURCAD") isymbol = 11;
   else if (symbol == "GBPUSD") isymbol = 12;
   else if (symbol == "GBPJPY") isymbol = 13;
   else if (symbol == "GBPCHF") isymbol = 14;
   else if (symbol == "GBPAUD") isymbol = 15;
   else if (symbol == "GBPCAD") isymbol = 16;
   return (StrToInteger(StringConcatenate(seed, isymbol, timeFrame)));
}

string GenerateComment(string EAName, int magic, int timeFrame)
{
   return (StringConcatenate(EAName, "-", magic, "-", timeFrame));
}