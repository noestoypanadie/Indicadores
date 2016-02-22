//+------------------------------------------------------------------+
//|                                            InterestPay v1.2.mq4 |
//|                                      Copyright © 2006,  Ross Tod |
//|                                               rosstodd@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006,  Ross Todd"
#property link      "rosstodd@yahoo.com"
extern double Lots       = 1;
extern int CloseShortHr  = 20;
extern int CloseShortMin = 58;
extern int CloseLongHr   = 21;
extern int CloseLongMin  = 2;
extern int OpenHr        = 20;
extern int OpenMin       = 30;
extern int MagicNumber   = 20061002;

bool ShortSent=False;
bool LongSent=False;
bool ContinueOpening=False;
int Slippage = 5;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   int cnt=0;
   int OpenOrders=0;
   bool res=False;
   
   for(cnt=0;cnt<OrdersTotal();cnt++)
   {
     if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
     {
      if ((OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber))
      {
       OpenOrders++;
      }
     }
   }
   
   if (TimeHour(CurTime())==CloseShortHr
       && TimeMinute(CurTime())>=CloseShortMin)
   {
    for(cnt=0;cnt<OrdersTotal();cnt++)
    {
     if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
     {
      if (OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderType()==OP_SELL)
       res=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),Slippage,Red);
     }
    }
   }
   
   if (TimeHour(CurTime())==CloseLongHr
       && TimeMinute(CurTime())>=CloseLongMin)
   {
    for(cnt=0;cnt<OrdersTotal();cnt++)
    {
     if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES))
     {
      if (OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderType()==OP_BUY)
       res=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),Slippage,Blue);
     }
    }
   }
   
   if (TimeHour(CurTime())==OpenHr
       && TimeMinute(CurTime())==OpenMin && OpenOrders<1)
   {
    ContinueOpening=True;
    LongSent=False;
    ShortSent=False;
   }

   if (!ShortSent && ContinueOpening)
   {
    res=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,"InterestPay"+MagicNumber,MagicNumber,0,Red);
    if (res)
     ShortSent=True;     
    else
     Print("Short Send Order error: ", GetLastError());
   }    

   if (!LongSent && ContinueOpening)
   {
    res=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,"SeparationTrade"+MagicNumber,MagicNumber,0,Blue);
    if (res)
     LongSent=True;
    else
     Print("Long Send Order error: ", GetLastError());
   }  
      
   
   if (ShortSent && LongSent)
    ContinueOpening=False;
//----
   return(0);
  }
//+------------------------------------------------------------------+


