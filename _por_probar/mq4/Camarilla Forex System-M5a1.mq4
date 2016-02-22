#include <stdlib.mqh>
//+------------------------------------------------------------------+
//|                                   Camarilla Forex System-M5a.mq4 |
//|                                                                  |
//|                                                                  |
//|                                        Converted by Mql2Mq4 v1.1 |
//|                                            http://yousky.free.fr |
//|                                    Copyright © 2006, Yousky Soft |
//+------------------------------------------------------------------+

#property copyright " Copyright © 2005 FAB4x, Alejandro Galindo & KillerKhan"
#property link      ""


//+------------------------------------------------------------------+
//| Common External variables                                        |
//+------------------------------------------------------------------+
extern double Lots = 1.00;
extern double StopLoss = 0.00;
extern double TakeProfit = 0.00;
extern double TrailingStop = 0.00;

//+------------------------------------------------------------------+
//| External variables                                               |
//+------------------------------------------------------------------+
extern double StartHour = 0;
extern double StartMinute = 30;
extern double EndHour = 21;
extern double EndMinute = 55;
extern double mm = 0;
extern double risk = 7.5;

//+------------------------------------------------------------------+
//| Special Convertion Functions                                     |
//+------------------------------------------------------------------+

int LastTradeTime;

bool MOrderDelete( int ticket )
{
  LastTradeTime = CurTime();
  return ( OrderDelete( ticket ) );
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

string OrderValueSymbol(int index)
{
  OrderSelect(index, SELECT_BY_POS);
  return(OrderSymbol());
}

bool SetObjectText(string name, string text, string font, int size, color Acolor)
{
  return(ObjectSetText(name, text, size, font, Acolor));
}

bool MoveObject(string name, int type, datetime Atime, double Aprice, datetime Atime2 = 0, double Aprice2 = 0, color Acolor = CLR_NONE, int Aweight = 0, int Astyle = 0)
{
    if (ObjectFind(name) != -1)
    {
      int OType = ObjectType(name);

      if ((OType == OBJ_VLINE) ||
         (OType == OBJ_HLINE) ||
         (OType == OBJ_TRENDBYANGLE) ||
         (OType == OBJ_TEXT) ||
         (OType == OBJ_ARROW) ||
         (OType == OBJ_LABEL))
      {
        return(ObjectMove(name, 0, Atime, Aprice));
      }

      if ((OType == OBJ_GANNLINE) ||
         (OType == OBJ_GANNFAN) ||
         (OType == OBJ_GANNGRID) ||
         (OType == OBJ_FIBO) ||
         (OType == OBJ_FIBOTIMES) ||
         (OType == OBJ_FIBOFAN) ||
         (OType == OBJ_FIBOARC) ||
         (OType == OBJ_RECTANGLE) ||
         (OType == OBJ_ELLIPSE) ||
         (OType == OBJ_CYCLES) ||
         (OType == OBJ_TREND) ||
         (OType == OBJ_STDDEVCHANNEL) ||
         (OType == OBJ_REGRESSION))
      {
        return(ObjectMove(name, 0, Atime, Aprice) && ObjectMove(name, 1, Atime2, Aprice2));
      }

/*
          OBJ_CHANNEL,
          OBJ_EXPANSION,
          OBJ_FIBOCHANNEL,
          OBJ_TRIANGLE,
          OBJ_PITCHFORK
*/
    }
    else
    {
      return(ObjectCreate(name, type, 0, Atime, Aprice, Atime2, Aprice2, 0, 0) && ObjectSet(name, OBJPROP_COLOR, Acolor));
    }
}

//+------------------------------------------------------------------+
//| End                                                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+

int init()
{
   return(0);
}
int start()
{
//+------------------------------------------------------------------+
//| Local variables                                                  |
//+------------------------------------------------------------------+
int cnt = 0;
double lotsi = 0;
double OpenTrades = 0;
double FilledOrders = 0;
double Slippage = 5;
double L3 = 0;
double TimetoOpen = 0;
double TimetoClose = 0;
double tmp = 0;
int i = 0;
double Trades = 2;
string Type = "NONE";
bool Reverse = False;
double mode = 0;
double H4 = 0;
double H3 = 0;
double L4 = 0;
double L1 = 0;
double H1 = 0;
string vQ = "";
string vH4 = "";
string vH3 = "";
string vL4 = "";
string vL3 = "";
string vL1 = "";
string vH1 = "";

//+-------------------------------------------------------------------+
//|                                Made/Modified by Alejandro Galindo |
//|                                                                   |
//|       				  If this work/modification is helpful to you |
//|                      send me a PayPal donation to ag@elcactus.com |
//|                                         any help is apreciated :) |
//|                                                           Thanks. |
//+-------------------------------------------------------------------+
/*[[
	Name := CAMARILLA FOREX SYSTEM M5
	Author := Copyright © 2005 FAB4x, Alejandro Galindo & KillerKhan
	Lots := 1.00
	Stop Loss := 0
	Take Profit := 0
	Trailing Stop := 0
]]*/


if( Period() != 5 ) 
{
	Comment("This expert is for M5 Charts Only!!!");
	return(0);
}

if( TimeYear(Time[0])<2006 ) return(0);  
if( CurTime() - LastTradeTime < 5 ) return(0);

if( mm != 0 ) 
        lotsi=MathCeil(AccountBalance()*risk/10000)/10
; else 
        lotsi=Lots;

vQ = "[" + Symbol() + "] Q";
vH4 = "[" + Symbol() + "] H4";
vH3 = "[" + Symbol() + "] H3";
vL4 = "[" + Symbol() + "] L4";
vL3 = "[" + Symbol() + "] L3";
vL1 = "[" + Symbol() + "] L1";
vH1 = "[" + Symbol() + "] H1";

H4=GlobalVariableGet(vH4);
H3=GlobalVariableGet(vH3);
H1=GlobalVariableGet(vH1);
L1=GlobalVariableGet(vL1);
L4=GlobalVariableGet(vL4);
L3=GlobalVariableGet(vL3);


Comment(" PLACE A BUYSTOP ORDER AT ", H3 ,"  PLACE A SELLSTOP ORDER AT " , L3);

MoveObject("H4",OBJ_HLINE,Time[0], H4,Time[0], H4,Blue,1,STYLE_DOT);
MoveObject("H3",OBJ_HLINE,Time[0],H3,Time[0],H3,Blue,1,STYLE_DOT);
MoveObject("H1",OBJ_HLINE,Time[0],H1,Time[0],H1,MediumVioletRed,1,STYLE_DASH);
MoveObject("L1",OBJ_HLINE,Time[0],L1,Time[0],L1,MediumVioletRed,1,STYLE_DASH);
MoveObject("L3",OBJ_HLINE,Time[0], L3,Time[0], L3,Red,1,STYLE_DOT);
MoveObject("L4",OBJ_HLINE,Time[0],L4,Time[0],L4,Red,1,STYLE_DOT);


SetObjectText("H4_txt","Get Out Here ","Arial",7,White);
MoveObject("H4_txt",OBJ_TEXT,Time[0],H4,Time[0],H4,White);

SetObjectText("H3_txt","Buy Here ","Arial",7,White);
MoveObject("H3_txt",OBJ_TEXT,Time[0],H3,Time[0],H3,White);

SetObjectText("H1_txt","Stop Loss for Short ","Arial",7,White);
MoveObject("H1_txt",OBJ_TEXT,Time[0],H1,Time[0],H1,White);

SetObjectText("L1_txt","Stop Loss for Long ","Arial",7,White);
MoveObject("L1_txt",OBJ_TEXT,Time[0],L1,Time[0],L1,White);

SetObjectText("L3_txt","Sell Here ","Arial",7,White);
MoveObject("L3_txt",OBJ_TEXT,Time[0],L3,Time[0],L3,White);

SetObjectText("L4_txt","Get Out Here ","Arial",7,White);
MoveObject("L4_txt",OBJ_TEXT,Time[0],L4,Time[0],L4,White);



OpenTrades=0;
   for (int Cnt=0; Cnt<OrdersTotal(); Cnt++) {
	if( OrderValueSymbol(cnt) == Symbol() ) 
	{
		OpenTrades++;
		if( OrderValueType(cnt) == OP_SELL || OrderValueType(cnt) == OP_BUY ) 
		{
			FilledOrders++;
		}
	}
}


if( (Hour() == EndHour && Minute()>=EndMinute) ) 
{
	cnt=0;while( cnt<=10000 ) { cnt++; }
	for(cnt=1;cnt<=OrdersTotal();cnt++)	{
		mode = OrderValueType(cnt);
		if( OrderValueSymbol(cnt) == Symbol() ) 
		{	
			Trades=2;
			Type="NONE";
			Reverse=False;
 			if( (mode ==  OP_BUYSTOP) ) MOrderDelete(OrderValueTicket(cnt));			
 		   	if( (mode ==  OP_SELLSTOP) ) MOrderDelete(OrderValueTicket(cnt));			
 			if( (mode ==  OP_BUY) ) OrderClose(OrderValueTicket(cnt),OrderValueLots(cnt),Bid,Slippage,Blue);
 			if( (mode ==  OP_SELL) ) OrderClose(OrderValueTicket(cnt),OrderValueLots(cnt),Ask,Slippage,Red);
 			return(0);
		}
	}
}

if( (Hour() == StartHour && Minute()>=StartMinute) ) 
{
	if( OpenTrades<1  ) 
	{
		Trades=2;
		Type="NONE";
		Reverse=True;
		MOrderSend(Symbol(),OP_BUYSTOP,lotsi,H3,Slippage,H1,H4,"",16384,0,Blue);
		MOrderSend(Symbol(),OP_SELLSTOP,lotsi,L3,Slippage,L1,L4,"",16384,0,Red);
		return(0);
	}
}


// if we only have one Stop order we place the another one to always have ready both sides
if( OpenTrades == 1 && Trades>=1 ) 
{
	for(cnt=1;cnt<=OrdersTotal();cnt++)	{
		if( (OrderValueSymbol(cnt) ==  Symbol()) ) 
		{
			if( OrderValueType(cnt) == OP_SELLSTOP ) 
			{
				Trades=1;
				Type="NONE";
				Reverse=True;
    			MOrderSend(Symbol(),OP_BUYSTOP,lotsi,H3,Slippage,L1,H4,"",16384,0,Blue);
        		return(0);
	    	}

		    if( OrderValueType(cnt) == OP_BUYSTOP ) 
    		{
    			Trades=1;
	    		Type="NONE";
	    		Reverse=True;
				MOrderSend(Symbol(),OP_SELLSTOP,lotsi,L3,Slippage,H1,L4,"",16384,0,Red);		
				return(0);
    		}
    	}
	}
}



// if we have opened positions we take care of them
for(cnt=1;cnt<=OrdersTotal() ;cnt++)
{
	if( OrderValueSymbol(cnt) ==  Symbol() ) 
	{
		if( OrderValueType(cnt) ==  OP_BUY ) 
		{
			for(i=1;i<=OrdersTotal();i++)	{
				if( (OrderValueSymbol(i) == Symbol()) ) 
				{				
					if( OrderValueType(i) == OP_SELLSTOP || OrderValueType(i) == OP_BUYSTOP ) 
					{
						Trades=1;
						Type="SELL";
						Reverse=True;
						MOrderDelete(OrderValueTicket(i));
						return(0);
					}
				}
			}		
		

		if( OrderValueType(cnt) ==  OP_SELL ) 
		{
			for(i=1;i<=OrdersTotal();i++)	{
				if( (OrderValueSymbol(i) == Symbol()) ) 
				{
					if( OrderValueType(i) == OP_SELLSTOP || OrderValueType(i) == OP_BUYSTOP ) 
					{
						Trades=1;
						Type="BUY";
						Reverse=True;
						MOrderDelete(OrderValueTicket(i));
						return(0);
					}
				}
			}				
		}
	}		
}
}
return(0);  return(0);
}