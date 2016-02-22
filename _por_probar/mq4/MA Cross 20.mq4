//+------------------------------------------------------------------+
//|                                                MA Cross.mq4 .mq4 |
//|                                             c_323_h@hotmail.com  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "c_323_h@hotmail.com "
#property link      ""

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
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
extern double Lots=0.5;
extern double StopLoss=20;
extern double TakeProfit=30;

int start()
{
   double MA1, MA2,MA3,MA4;
   int total,ticket,cnt;
   
//initial data checks
  if(Bars<100)
  {
   Print("Bars less than 100");
   return(0); 
  } 
  if(TakeProfit<30)
   {
    Print("Take Profit < 30");
   } 
//to simplify coding
  MA1=iMA(NULL,0,5,0,1,0,0);
  MA2=iMA(NULL,0,5,0,1,0,1);
  MA3=iMA(NULL,0,20,0,1,0,0);
  MA4=iMA(NULL,0,20,0,1,0,1);
  
//identifying open orders
  total=OrdersTotal();
  if(total<1)
  {
   if(AccountFreeMargin()<(1000*Lots))
   {
    Print("No Money. FreeMargin=",AccountFreeMargin());
    return(0);
   }
   
//check for long possibility

  if(MA1 < MA3 && MA2 > MA4)
   {
    Alert("Long Crossover",Symbol());
    {
     ticket=OrderSend(Symbol
(),OP_BUY,Lots,Ask,3,StopLoss,Ask+TakeProfit*Point,0,0,Green);
     if(ticket>0)
     Print("Crossover Buying:", Symbol());
     if (OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print
("Buy Order Opened:", OrderOpenPrice());
    }
    return(0);
   }

//check for short position
  if(MA1 > MA3 && MA2 < MA4)
  {
   Alert("Short Crossover",Symbol());
   {
    ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,StopLoss,Bid-
TakeProfit*Point,0,0,Red);
    if(ticket>0)
    Print("Crossover Selling:", Symbol());
    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("Sell 
Order Opened:",OrderOpenPrice());
   }
   return(0);
  }
  return(0);
  
//for control of open orders
  for(cnt=0;cnt<total;cnt++)
  {
   OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
   if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())
   {
    if(OrderType()==OP_BUY)
    {
//long positions
  if(MA1 > MA3 && MA2 < MA4)
  {
   OrderClose(OrderTicket(),OrderLots(),Bid,3,Blue);
   return(0);
  }
else
//short positions
  {
   if(MA1 < MA3 && MA2 < MA4)
   {
    OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet);
    return(0);
   } 
  }
 }
 }
 }
 }
 return(0);
 }


