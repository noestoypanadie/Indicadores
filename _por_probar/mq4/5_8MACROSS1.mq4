//+------------------------------------------------------------------+
//|                                                   5_8MACROSS.mq4 |
//|                                Copyright © 2006, transport.david |
//|                                        transport.david@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, transport.david"
#property link      "transport.david@gmail.com"

extern double Lots         =  1;
extern int	  StopLoss     =  0;
extern int	  TakeProfit   = 40;
extern int    TrailingStop =  0;

extern int mafastperiod=5;
extern int mafastshift=0;
extern int mafastmethod =MODE_EMA;
extern int mafastprice=PRICE_CLOSE;


extern int maslowperiod=8;
extern int maslowshift=0;
extern int maslowmethod =MODE_EMA;
extern int maslowprice=PRICE_OPEN;

double fast1, fast2, slow1, slow2;

//---------------------------------------------------------------------

int init()
 {
   return(0);
 }

//---------------------------------------------------------------------

int deinit()
 {
   return(0);
 }

//---------------------------------------------------------------------

int start()
 {
  
// Calculate Indicators -------------------------------------------------
   fast1=iMA(Symbol(),0,mafastperiod,mafastshift,mafastmethod,mafastprice,1);
   fast2=iMA(Symbol(),0,mafastperiod,mafastshift,mafastmethod,mafastprice,2);
   slow1=iMA(Symbol(),0,maslowperiod,maslowshift,maslowmethod,maslowprice,1);
   slow2=iMA(Symbol(),0,maslowperiod,maslowshift,maslowmethod,maslowprice,2);

// Open Trades ----------------------------------------------------------
   
   //LONG
   if (fast1>slow1&&fast2<slow2)
    {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,NULL,0,0,Blue);
    }

   //Short
   if(fast1<slow1&&fast2>slow2)
    {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,0,Bid+StopLoss*Point,Bid-TakeProfit*Point,NULL,0,0,Red);
    }

// Close Trades ---------------------------------------------------------
   
   int i;
   
   for (i = OrdersTotal()-1; i >=0 ; i--)
    {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
     
     if ( (OrderSymbol() == Symbol())   &&
          (OrderType() == OP_BUY)       &&
          (fast1 < slow1)               &&
          (fast2 > slow2)                  )
      {
        OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,White);
      }
     
     if ( (OrderSymbol() == Symbol())   &&
          (OrderType() == OP_SELL)      &&
          (fast1 > slow1)               &&
          (fast2 < slow2)                  )
      {
        OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,White);
      }
    }

// Trailing Stop  ---------------------------------------------------------

   for (i = OrdersTotal()-1; i >=0 ; i--)
    {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
     
     if (OrderType() == OP_BUY)
      {
       if ( (Bid - OrderOpenPrice()) > (TrailingStop*Point) )
      	{
          if ( OrderStopLoss() < (Bid - TrailingStop*Point) )
           {
             OrderModify(OrderTicket(),
                         OrderOpenPrice(),
                         Bid - TrailingStop*Point,
                         OrderTakeProfit(),
                         Red);
           }
         }
      }
     
     if (OrderType() == OP_SELL)
      {
       if ( (OrderOpenPrice() - Ask) > (TrailingStop*Point) )
     	  {
         if ( (OrderStopLoss() > (Ask + TrailingStop*Point)) ||
            (OrderStopLoss() == 0) )
          {
            OrderModify(OrderTicket(),
                        OrderOpenPrice(),
                        Ask + TrailingStop*Point,
                        OrderTakeProfit(),
                        Red);
          }
     	  }
  	   }
  	 }
  
  return(0);
 
 }
   
//+------------------------------------------------------------------+