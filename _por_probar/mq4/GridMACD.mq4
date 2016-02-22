#property copyright "pengie"

extern string EAName = "GridMACD";
extern int magic = 1012;
extern int initialGridInterval = 15;
extern int subsequentGridInterval = 15;
extern int maxOrders = 25;
extern int maxProfit = 250;
extern double lots = 0.1;
extern int slippage = 3;
extern int minOppOrders = 3;  // Close if breakeven or slight profit if there is opposite orders that are more than or equal to minOppOrders.
extern int maxOppOrders = 10;  // Close if there are opposite orders that are more than or equal to maxOppOrders.
extern bool shutdownGrid = false; // If true, will close all orders and not open any new orders.

double buyEntry = 0.0;
double sellEntry = 0.0;
int curBuy = 0;
int curSell = 0;

int init()
{
	magic = GenerateMagicNumber(magic, Symbol(), Period());
	EAName = GenerateComment(EAName, magic, Period());
	curBuy = CountOrders(Symbol(), magic, OP_BUY);
	curSell = CountOrders(Symbol(), magic, OP_SELL);	
	
	return (0);
}

int deinit()
{
	return (0);
}

int start()
{  
   int ticket;
   if (buyEntry==0.0 || sellEntry==0.0 || buyEntry==10000.0)
   {
      double minBuyEntry = 10000;
      double maxSellEntry = 0;
      for (ticket=GetFirstTicketByMagic(magic); ticket!=0; ticket=GetNextTicket())
      {
        OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
        switch (OrderType())
        {
           case OP_BUY:
              if (OrderOpenPrice()<minBuyEntry) minBuyEntry = OrderOpenPrice();
              break;
      
           case OP_SELL:
              if (OrderOpenPrice()>maxSellEntry) maxSellEntry = OrderOpenPrice();
              break;
        }   
      }
      buyEntry = minBuyEntry - initialGridInterval*Point;
      sellEntry = maxSellEntry + initialGridInterval*Point;   
   }

   double prevMACD = iMACD(Symbol(), 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 2);
   double curMACD = iMACD(Symbol(), 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
	
	int totalOrders = CountOrdersIfMagic(magic);
	if (((prevMACD<0 && curMACD>0) || (prevMACD>0 && curMACD<0)) && totalOrders==0 && !shutdownGrid)
	{
      buyEntry = Ask;
      curBuy = 1;
      OrderSend(Symbol(), OP_BUYSTOP, lots, buyEntry+initialGridInterval*Point, slippage, 0, 0, EAName, magic , 0, Green);
      	    
      sellEntry = Bid;
      curSell = 1;
      OrderSend(Symbol(), OP_SELLSTOP, lots, sellEntry-initialGridInterval*Point, slippage, 0, 0, EAName, magic , 0, Red);   
	}
	
	if (CountOrders(Symbol(), magic, OP_BUY)>0 && CountOrders(Symbol(), magic, OP_BUYSTOP)==0 && totalOrders<maxOrders)
	{
      if (OrderSend(Symbol(), OP_BUYSTOP, lots, buyEntry+initialGridInterval*Point+curBuy*subsequentGridInterval*Point, slippage, 0, 0, EAName, magic , 0, Green)==-1)
      {
         Print(Symbol(), ", Buystop=", buyEntry+initialGridInterval*Point+curBuy*subsequentGridInterval*Point);
      }
      curBuy++;
	}

	if (CountOrders(Symbol(), magic, OP_SELL)>0 && CountOrders(Symbol(), magic, OP_SELLSTOP)==0 && totalOrders<maxOrders)
	{
      if (OrderSend(Symbol(), OP_SELLSTOP, lots, sellEntry-initialGridInterval*Point-curSell*subsequentGridInterval*Point, slippage, 0, 0, EAName, magic , 0, Red)==-1)
      {
         Print(Symbol(), ", Sellstop=", sellEntry-initialGridInterval*Point-curSell*subsequentGridInterval*Point);
      }
      curSell++;
	}
	
	int totalPips = 0;
	double totalProfits = 0.0;
	for (ticket=GetFirstTicketByMagic(magic); ticket!=0; ticket=GetNextTicket())
	{
      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
      switch (OrderType())
      {
         case OP_BUY:
            totalPips += (Bid-OrderOpenPrice())/Point;
            totalProfits += OrderProfit();
            break;
            
         case OP_SELL:
            totalPips += (OrderOpenPrice()-Ask)/Point;
            totalProfits += OrderProfit();
            break;
      }   
	}
	Comment(StringConcatenate("Total pips=",totalPips,"\nTotal profits=",totalProfits,"\n"));
	
	int buyOrders = CountOrders(Symbol(), magic, OP_BUY);
	int sellOrders = CountOrders(Symbol(), magic, OP_SELL);
	int oppOrders = 0;
	if (buyOrders > sellOrders) oppOrders = sellOrders;
	else oppOrders = buyOrders;
	int stopGrid = 0;
	if ((oppOrders>=minOppOrders && totalPips>=0) || oppOrders>=maxOppOrders) stopGrid = 1;	
	if (shutdownGrid || totalPips>=maxProfit || stopGrid || totalOrders==maxOrders)
	{
		DeleteAllPendingOrders(magic);
		CloseAllOrders(magic);
		curBuy = 0;
		curSell = 0;
		buyEntry = 0.0;
		sellEntry = 0.0;	
	}
	
	return (0);
}

int DeleteAllPendingOrders(int magic)
{
	for (int ticket=GetFirstTicketByMagic(magic); ticket!=0; ticket=GetNextTicket())
	{
      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
      switch (OrderType())
      {
         case OP_BUYSTOP:
         case OP_SELLSTOP:
            OrderDelete(ticket);
            break;
      }   
	}
	return (0);
}

int CloseAllOrders(int magic)
{
	for (int ticket=GetFirstTicketByMagic(magic); ticket!=0; ticket=GetNextTicket())
	{
      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
      switch (OrderType())
      {
         case OP_BUY:
            OrderClose(ticket, OrderLots(), Bid, slippage, CLR_NONE);
            break;
            
         case OP_SELL:
            OrderClose(ticket, OrderLots(), Ask, slippage, CLR_NONE);
            break;
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

int CountOrders(string symbol="", int magicNumber=-1, int cmd=-1)
{
	int totalOrders = 0;
	int maxOrders = OrdersTotal();
	for (int i=0; i<maxOrders; i++)
	{
		OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
		if ((symbol=="" || OrderSymbol()==symbol) &&
			  (magicNumber==-1 || OrderMagicNumber()==magicNumber) &&
			  (cmd==-1 || OrderType()==cmd)) 
		{
			totalOrders++;	
		}
	}
	return (totalOrders);
}

int CountOrdersIfMagic(int magicNumber)
{
	return (CountOrders("", magicNumber, -1));
}

int t_index = 0;
string t_symbol = "";
int t_magicNumber = -1;
int t_cmd = -1;

int GetFirstTicketByMagic(int magicNumber)
{
	return (GetFirstTicket("", magicNumber, -1));
}

int GetFirstTicket(string symbol="", int magicNumber=-1, int cmd=-1)
{
	t_symbol = symbol;
	t_magicNumber = magicNumber;
	t_cmd = cmd;
	
	int maxOrders = OrdersTotal();
	for (t_index=maxOrders-1; t_index>=0; t_index--)
	{
		OrderSelect(t_index, SELECT_BY_POS, MODE_TRADES);
		if ((t_symbol=="" || OrderSymbol()==t_symbol) &&
			  (t_magicNumber==-1 || OrderMagicNumber()==t_magicNumber) &&
			  (t_cmd==-1 || OrderType()==t_cmd))
		{			
			return (OrderTicket());
		}	
	}
	return (0);
}

int GetNextTicket()
{
	for (t_index--; t_index>=0; t_index--)
	{
		OrderSelect(t_index, SELECT_BY_POS, MODE_TRADES);
		if ((t_symbol=="" || OrderSymbol()==t_symbol) &&
			  (t_magicNumber==-1 || OrderMagicNumber()==t_magicNumber) &&
			  (t_cmd==-1 || OrderType()==t_cmd))
		{
			return (OrderTicket());
		}	
	}
	return (0);
}