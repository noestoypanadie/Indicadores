//+------------------------------------------------------------------+
//|                                                   The 20's v0.10 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, TraderSeven"
#property link      "TraderSeven@gmx.net"
//----------------------- USER INPUT
extern int TakeProfit=30;	 

//----------------------- MAIN PROGRAM LOOP
double YesterdaysRange;
double Top20;
double Bottom20;
int Lots;Lots=1;
int slip;slip=10;
double Stoploss=200000;
double OrderDay=99;
double Pay=0;
int start()

{
YesterdaysRange=(High[1]-Low[1]);
Top20=High[1]-(YesterdaysRange*0.20);
Bottom20=Low[1]+(YesterdaysRange*0.20);

//if (Open[1]>=Top20 && Close[1]<=Bottom20 && Ask<(Low[1]-0.0010) && OrdersTotal()==0)
if (Open[1]>=Top20 && Close[1]<=Bottom20 && Ask<(Low[1]-0.010) && Day()!=OrderDay)
  { 
  Pay=Low[1];
   OrderSend(Symbol(),OP_BUY,Lots,Ask,slip,Ask-(Stoploss*Point),Ask+(TakeProfit*Point),0,0,Blue);
   OrderDay=Day();
  }
  
if (Close[1]>Top20 && Open[1]<Bottom20 && Bid>(High[1]+0.010) && Day()!=OrderDay)
  { 
   OrderSend(Symbol(),OP_SELL,Lots,Bid,slip,Bid+(Stoploss*Point),Bid-(TakeProfit*Point),0,0,Red);
   OrderDay=Day();
  }  

if(OrdersTotal()>0) 
{
OrderSelect(0, SELECT_BY_POS, MODE_TRADES);
OrderClose(0,1,0,0);
//OrderDay=99;
}
}


