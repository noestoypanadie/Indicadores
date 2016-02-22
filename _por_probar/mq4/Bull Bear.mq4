//+------------------------------------------------------------------+
//|                                                     bullbear.mq4 |
//|                                    Copyright © 2006, Yousky Soft |
//|                                            http://yousky.free.fr |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Common External variables                                        |
//+------------------------------------------------------------------+
extern double Lots = 1.00;
extern double StopLoss = 30.00;
extern double TakeProfit = 40.00;
extern double TrailingStop = 5.00;

//+------------------------------------------------------------------+
//| External variables                                               |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Special Convertion Functions                                     |
//+------------------------------------------------------------------+

int LastTradeTime;

bool MOrderDelete( int ticket )
  {
  LastTradeTime = CurTime();
  return ( OrderDelete( ticket ) );
  }

bool MOrderClose( int ticket, double lots, double price, int slippage, color Color=CLR_NONE)
  {
  LastTradeTime = CurTime();
  price = MathRound(price*10000)/10000;
  return ( OrderClose( ticket, lots, price, slippage, Color) );
  }

bool MOrderModify( int ticket, double price, double stoploss, double takeprofit, datetime expiration, color arrow_color=CLR_NONE)
  {
  LastTradeTime = CurTime();
  price = MathRound(price*10000)/10000;
  stoploss = MathRound(stoploss*10000)/10000;
  takeprofit = MathRound(takeprofit*10000)/10000;
  return ( OrderModify( ticket, price, stoploss, takeprofit, expiration, arrow_color) );
  }

int MOrderSend( string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment="", int magic=0, datetime expiration=0, color arrow_color=CLR_NONE)
  {
  LastTradeTime = CurTime();
  price = MathRound(price*10000)/10000;
  stoploss = MathRound(stoploss*10000)/10000;
  takeprofit = MathRound(takeprofit*10000)/10000;
  return ( OrderSend( symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic, expiration, arrow_color ) );
  }

int OrderValueTicket(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderTicket());
}

int OrderValueType(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderType());
}

double OrderValueLots(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderLots());
}

double OrderValueOpenPrice(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderOpenPrice());
}

double OrderValueStopLoss(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderStopLoss());
}

double OrderValueTakeProfit(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderTakeProfit());
}

double OrderValueClosePrice(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderClosePrice());
}

double OrderValueComission(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderCommission());
}

double OrderValueSwap(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderSwap());
}

double OrderValueProfit(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderProfit());
}

string OrderValueSymbol(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderSymbol());
}

string OrderValueComment(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderComment());
}

datetime OrderValueOpenTime(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderOpenTime());
}

datetime OrderValueCloseTime(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderCloseTime());
}

void PrintTrade(int index)
{
  if (OrderSelect(index, SELECT_BY_POS)==true)
    OrderPrint();
}

bool SetTextObject(string name, string text, string font, int font_size, color text_color=CLR_NONE)
{
  ObjectSetText(name, text, font_size, font, text_color);
}

void SetLoopCount(int loops)
{
}

//+------------------------------------------------------------------+
//| End                                                              |
//+------------------------------------------------------------------+

int start()
{
//+------------------------------------------------------------------+
//| Local variables                                                  |
//+------------------------------------------------------------------+
double pos1pre = 0;
double pos2cur = 0;
int cnt = 0;

/*[[
	Name := bullbear
	Author := Copyright © 2003, Company
	Link := http://www.company.com/
	Lots := 1.00
	Stop Loss := 30
	Take Profit := 40
	Trailing Stop := 5
]]*/

//previous position
 
//current position
 
 

pos1pre = iBullsPower(NULL, 0, 13,PRICE_WEIGHTED,1);
pos2cur = iBullsPower(NULL, 0, 13,PRICE_WEIGHTED,0);
 
if( pos1pre >pos2cur  ) 
{
//close long position 
for(cnt=1;cnt<=OrdersTotal();cnt++) {
  if( OrderValueType(cnt) == OP_BUY ) // buy position open  		
  {
   	if( Bid>(OrderValueOpenPrice(cnt)+TrailingStop*Point) ) 
  	{
  		OrderClose(OrderValueTicket(cnt),OrderValueLots(cnt),Bid,3,Violet); // close long
  		return(0);             
  	}
  }
  }
}


if( pos2cur<0 ) 

//close short position

{
for(cnt=1;cnt<=OrdersTotal();cnt++) {
  	if( Ask<(OrderValueOpenPrice(cnt)-TrailingStop*Point) ) 
  	{
  if( OrderValueType(cnt) == OP_SELL ) // sell position open
  		{
  	
  		
  		OrderClose(OrderValueTicket(cnt),OrderValueLots(cnt),Ask,3,Violet); // close short
            return(0);
        	}    
  	} 
   	}
}
if( OrdersTotal()<1 ) 
  {
//no current orders. Check for possible short conditions.
Print("pos1pre = "+pos1pre+"    pos2cur ="+pos2cur); 
  if( pos1pre>pos2cur && pos2cur>0 )     
   {
 
        MOrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,Bid-TakeProfit*Point,"",16384,0,Red); // open short 
        return(0); 
  
   }

//check for long conditions.

if( pos2cur<0  )  
  {
    MOrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,Ask+TakeProfit*Point,"",16384,0,Red); // open long
    return(0); 
   }
}
  return(0);
}