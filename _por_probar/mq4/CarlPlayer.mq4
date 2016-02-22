//+------------------------------------------------------------------+
//|                                                   CarlPlayer.mq4 |
//|                                     Copyright © 2006, MQLService |
//|                                        http://www.mqlservice.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, MQLService"
#property link      "http://www.mqlservice.com"
/*
Hi everyone :)

I just signed up couple a days ago and excited to join this forum. I'm
currently in awe with the professionalism shown in this forum and hope
to contribute too in the future.

I've been trading a simple scalper trading method for the past couple
of months with consistent success but I have to sit at my computer and
watch for the trading to setup. So I guess what I am asking for is for
someone to program an indicator and or an expert advisor for me (I'm
not a programmer) based in my method. 

Here's the scalper system in a nutshell:

Could be applied to any of the 4 major currency pairs and I use a 5
minute candlestick chart with a 10 period Exponential Moving Average.
Buy or sell when price had closed either above or below an 10 EMA. 

Rules for entering a trade:

1. Three or more consecutive candles to close either above (for a LONG
trade) or below (for a SHORT trade) the 10 EMA. These three or more
consecutive candles bodies and wicks included MUST NOT TOUCH the 10
EMA line.

2. If the 1st criteria is met, The bodies (only the bodies not the
wicks) of these three candles must equal 10 or more pips before I
consider entering the trade. These candles can be any color (bullish
and bearish combined its OK -- the color of the candles DOES NOT
matter) as long they are not touching the 10 EMA and they equal 10 or
more pips we are go to trade.

If you do not see three consecutive candles whose bodies are equal at
least 10 pips total then you must wait for the next candle to close to
add 10 or more pips before entering a trade.

Example: If the first candles body is 4 pips and the second candles
body is 2 pips and the third candles body is 2 pips that is only 8
pips total so you must wait till the next candle closes, lets say the
next candle closed at 3 pips now you have a total of 11 pips. All
candles bodies and wicks MUST NOT touch the 10 EMA line. 

3. Trade MUST be in the same direction of the 10 EMA.

4. If all of these requirements are met then a trade can be entered.
Long if candles are above 10 EMA or Short if candles are below the 10
EMA. 

5. Trade in dual lots (i.e. 2, 4,10, 20, etc.) to take full advantage
of short-term trends, I'll explain ahead.

6. Take Profits at 10 PIPS. Exit half open positions at 10 pips profit
and move the rest to break even, trail 10 pips afterwards, You may
ride the trend for as long as each candle opens in the direction of
the trend (long trend candle opens bullish short trend candle opens
bearish, and candle is above or below the 10 EMA).

5. Initial STOP LOSS should be set 10 pips above or below the highest
or lowest candle wick. As an example, when long look for the lowest
candles body or wick to the 10 EMA line add ( or subtract) 10 pips to
that to get your stop loss.

That's it. I'll highly appreciate if anyone could really help me
coding my system, as far as an indicator its concern, basically an
alert (visual. sound or both) to let me know when three or more
candles close above or below the 10 EMA line (not touching the line)
will do. Any questions and/or recommendations are welcomed.
*/

#include <stdlib.mqh>

//---- input parameters
extern double    Lot1=0.1;
extern double    Lot2=0.2;
extern int       StopLoss=10;
extern int       TakeProfit=10;
extern int       TrailingStop=10;
extern int       MinBodySum=10; 

#define MAGIC 20061116

int init()
{
  return(0);
}

int deinit()
{
  return(0);
}

int start()
{
  bool bSigLong  = true;
  bool bSigShort = true;
  int  nBodySum  = 0;
  int  nLowest = 100000;
  int  nHighest = 0;
  int  nBarsShort = -1;
  int  nBarsLong  = -1;
  for(int i=1; i <= 4; i++)
  {
    int nEMA10 = MathRound(iMA(NULL, 0, 10, 0, MODE_EMA, PRICE_CLOSE, i)/Point);
    int nHigh  = MathRound(High[i]/Point);
    int nLow   = MathRound(Low[i]/Point);
    nBodySum  += MathRound(MathAbs(Open[i]-Close[i])/Point);
    nLowest    = MathMin(nLowest, nLow);
    nHighest   = MathMax(nHighest, nHigh);
    if(nLow <= nEMA10) { if(bSigLong) nBarsLong = i-1; bSigLong = false;}
    if(nHigh >= nEMA10){ if(bSigShort) nBarsShort = i-1; bSigShort = false;}
    if(i == 3)
    if(nBodySum >= MinBodySum)
      break;
    if(i == 4)
    if(nBodySum < MinBodySum)
    {
      bSigLong  = false;
      bSigShort = false;
    }
  }
  //if(!IsTesting()) Comment("nbL=",nBarsLong,"(",bSigLong,"); nbS=",nBarsShort,"(",bSigShort,")");
  if(bSigLong)
  {
    while(IsPosition(OP_SELL, Symbol(), MAGIC)) OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 5);
    if(!IsPosition(OP_BUY, Symbol(), MAGIC))
    {
      OrderSend(Symbol(), OP_BUY, Lot1, Ask, 5, (nLowest-StopLoss)*Point, 0, "CarlPlayer", MAGIC);
      OrderSend(Symbol(), OP_BUY, Lot2, Ask, 5, (nLowest-StopLoss)*Point, Bid+TakeProfit*Point, "CarlPlayer", MAGIC);
    }
  }
  if(bSigShort)
  {
    while(IsPosition(OP_BUY, Symbol(), MAGIC)) OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 5);
    if(!IsPosition(OP_SELL, Symbol(), MAGIC))
    {
      OrderSend(Symbol(), OP_SELL, Lot1, Bid, 5, (nHighest+StopLoss)*Point, 0, "CarlPlayer", MAGIC);
      OrderSend(Symbol(), OP_SELL, Lot2, Bid, 5, (nHighest+StopLoss)*Point, Ask-TakeProfit*Point, "CarlPlayer", MAGIC);
    }
  }
  // Break Even & Trailing Stop
  if(IsPosition(OP_BUY, Symbol(), MAGIC))
    if(MathRound((OrderClosePrice()-OrderOpenPrice())/Point) >= TakeProfit)
    {
      if(OrderStopLoss() < OrderOpenPrice()) // Move to BE
        OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), OrderExpiration());
      if(OrderStopLoss() < OrderClosePrice()-TrailingStop*Point) // TS
        OrderModify(OrderTicket(), OrderOpenPrice(), OrderClosePrice()-TrailingStop*Point, OrderTakeProfit(), OrderExpiration());
    }
  if(IsPosition(OP_SELL, Symbol(), MAGIC))
    if(MathRound((OrderOpenPrice()-OrderClosePrice())/Point) >= TakeProfit)
    {
      if(OrderStopLoss() > OrderOpenPrice()) // Move to BE
        OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), OrderExpiration());
      if(OrderStopLoss() > OrderClosePrice()+TrailingStop*Point) // TS
        OrderModify(OrderTicket(), OrderOpenPrice(), OrderClosePrice()+TrailingStop*Point, OrderTakeProfit(), OrderExpiration());
    }
    
  return(0);
}

bool IsPosition(int type, string symbol, int magic)
{
  for(int i=OrdersTotal()-1; i >= 0; i--)
    if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
    if(OrderType() == type)
    if(OrderSymbol() == symbol)
    if(OrderMagicNumber() == magic)
      return(true);
    }else
      Print("OrderSelect() error - ", ErrorDescription(GetLastError()));
  return(false);
}

//+---- Programmed by Michal Rutka ----------------------------------+