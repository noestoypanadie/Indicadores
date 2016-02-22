//+------------------------------------------------------------------+
//| RealHour.mq4                                                     |
//| Bernard Citra                                                    |
//|                                                                  |
//| Matthew 6:33                                                     |
//| "But seek ye first The Kingdom of God, and His righteousness;    |
//|  and all these things shall be added unto you."                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Bernard Citra"

//--->Input Parameter
extern int     Start = 10; //FXDD server GMT+3
extern int     Finish = 18;
extern double  Lot = 0.1;
extern int     Trigger = 15;
extern int     Limit = 150;
extern int     StopLoss = 80;
extern int     BreakEven = 30;

//+------------------------------------------------------------------+
//| Main Program                                                     |
//|                                                                  |
//+------------------------------------------------------------------+
int start()
{
  int Ticket;
  int TicketBuy = 0;
  int TicketSell = 0;
  int MN=1;
   
  string Text="RealHour"+Symbol();
  
  //set the order
  if (Hour()==Start && Minute()==1)
  { 
    setOrder(Text,MN);  
  }
  
  //Delete the opposite pending order once the 1st order is hit
  for (int i=0; i<OrdersTotal(); i++)
  {
    OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
    if (OrderType() == OP_BUY)
      TicketBuy = 1;
    if (OrderType() == OP_SELL)
      TicketSell = 1;
  }
  
  for (int n=0; n<OrdersTotal(); n++)
  {
    OrderSelect(n,SELECT_BY_POS,MODE_TRADES);
    if (OrderType() == OP_SELLSTOP && TicketBuy == 1)
      OrderDelete(OrderTicket());
    if (OrderType() == OP_BUYSTOP && TicketSell == 1)
      OrderDelete(OrderTicket());
  }    
  
  //Manage Open Order
  for (int l=0; l<OrdersTotal(); l++)
  {
    OrderSelect(l,SELECT_BY_POS,MODE_TRADES);
    if(OrderComment()==Text)
    {
      //close open position at EOD
      if (Hour() == Finish)
      {
        switch (OrderType())
        {
          case OP_BUY: OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
          break;
          case OP_SELL: OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
          break;
          default: OrderDelete(OrderTicket());
          break;
        }
      }
      //BreakEven -> move stoploss to open price
      else
      {
        if (OrderType()==OP_BUY)
        {
          if(High[0]-OrderOpenPrice()>=BreakEven*Point && OrderStopLoss()<OrderOpenPrice())
          {
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);
          }
        }
        if (OrderType()==OP_SELL)
        {
          if(OrderOpenPrice()-Low[0]>=BreakEven*Point && OrderStopLoss()>OrderOpenPrice())
          {
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Green);  
          }
        }
      }
    }
  }
  return (0);
}

//+------------------------------------------------------------------+
//| Set Order Function                                               |
//|                                                                  |
//+------------------------------------------------------------------+

void setOrder (string Text, int MN)
{
  double EntryLong, EntryShort, SLLong, SLShort, TPLong, TPShort;
  int Ticket;
  int Bought = 0;
  int Sold = 0;
    
  //Determine Price Range
  EntryLong   = iHigh(NULL,60,Highest(NULL,60,MODE_HIGH,3,1))+(Trigger+MarketInfo(Symbol(),MODE_SPREAD))*Point;
  EntryShort  = iLow (NULL,60,Lowest(NULL,60,MODE_LOW,3,1))-Trigger*Point;
  SLLong      = EntryLong-StopLoss*Point;
  SLShort     = EntryShort+StopLoss*Point;
  TPLong      = EntryLong+Limit*Point;
  TPShort     = EntryShort-Limit*Point;

  //send order
  for (int j=0;j<OrdersTotal();j++)
  {
     OrderSelect(j,SELECT_BY_POS,MODE_TRADES);
     if(OrderComment()==Text && OrderMagicNumber()==MN)
     {
       if(OrderType()==OP_BUYSTOP || OrderType()==OP_BUY) Bought++;
       if(OrderType()==OP_SELLSTOP || OrderType()==OP_SELL) Sold++;
     }
  }    

  //no buy order then place the pending buy order
  if(Bought==0)
  { 
    Ticket=OrderSend(Symbol(),OP_BUYSTOP,Lot,EntryLong,5,SLLong,TPLong,Text,MN,0,Blue);
  }
  
  //no sell order then place the pending sell order
  if(Sold==0)
  {
    Ticket=OrderSend(Symbol(),OP_SELLSTOP,Lot,EntryShort,5,SLShort,TPShort,Text,MN,0,Magenta);
  }
}