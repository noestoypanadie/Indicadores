//+------------------------------------------------------------------+
//|                                     Your_Choice_MA_Cross_v1c.mq4 |
//|                                Copyright © 2006, transport.david |
//|                                        transport.david@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, transport.david"
#property link      "transport.david@gmail.com"

extern int UserAcceptsAllLiability = true;
extern int    magic        =   99;
extern double Lots         =  0.1;
extern int	  StopLoss     =   40;
extern int	  TakeProfit   =   40;
extern int    TrailingStop =   20;

extern int mafastperiod = 5;
extern int mafastshift  = 0;
extern int mafastmethod = 1; // use 0 through 3 for optimizing , default = 1 ( MODE_EMA )
extern int mafastprice  = 0; // use 0 through 6 for optimizing , default = 0 ( PRICE_CLOSE )

extern int maslowperiod = 8;
extern int maslowshift  = 0;
extern int maslowmethod = 1; // use 0 through 3 for optimizing , default = 1 ( MODE_EMA )
extern int maslowprice  = 1; // use 0 through 6 for optimizing , default = 1 ( PRICE_OPEN )

double OpenTrades, fast1, fast2, slow1, slow2;

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
  if (UserAcceptsAllLiability != true) return(0);
  if (UserAcceptsAllLiability == true)
   {
    int i;
    
    // Count Open Trades ---------------------------------------------------
    
    OpenTrades = 0;
    
    for(i = 0; i < OrdersTotal(); i++)
     {
       OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      
      if ( (OrderSymbol() == Symbol()) && (OrderMagicNumber() == magic) )
       {
         OpenTrades++;
       }
     } 
     
     // Calculate Indicators -------------------------------------------------
     
     fast1 = iMA(Symbol(),0,mafastperiod,mafastshift,mafastmethod,mafastprice,1);
     fast2 = iMA(Symbol(),0,mafastperiod,mafastshift,mafastmethod,mafastprice,2);
     slow1 = iMA(Symbol(),0,maslowperiod,maslowshift,maslowmethod,maslowprice,1);
     slow2 = iMA(Symbol(),0,maslowperiod,maslowshift,maslowmethod,maslowprice,2);
     
     // Open Trades ----------------------------------------------------------
     
     //Long
     if ( (OpenTrades <= 0) &&
          (fast1 > slow1)   &&
          (fast2 < slow2)      )
      {
        OrderSend(Symbol(),
                  OP_BUY,
                  Lots,
                  Ask,
                  3,
                  Ask-StopLoss*Point,
                  Ask+TakeProfit*Point,
                  "Your_Choice_MA_Cross_v1b",
                  magic,
                  0,
                  Blue);
      }
      
     //Short
     if ( (OpenTrades <= 0) &&
          (fast1 < slow1)   &&
          (fast2 > slow2)      )
      {
        OrderSend(Symbol(),
                  OP_SELL,
                  Lots,
                  Bid,
                  3,
                  Bid+StopLoss*Point,
                  Bid-TakeProfit*Point,
                  "Your_Choice_MA_Cross_v1b",
                  magic,
                  0,
                  Red);
      }
     
     // Close Trades ---------------------------------------------------------
     
     for(i = 0; i < OrdersTotal(); i++)
      {
        OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
       
       if ( (OrderSymbol() == Symbol())   &&
            (OrderType() == OP_BUY)       &&
            (OrderMagicNumber() == magic) &&
            (fast1 < slow1)               &&
            (fast2 > slow2)                  )
        {
          OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,White);
        }
       
       if ( (OrderSymbol() == Symbol())   &&
            (OrderType() == OP_SELL)      &&
            (OrderMagicNumber() == magic) &&
            (fast1 > slow1)               &&
            (fast2 < slow2)                  )
        {
          OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,White);
        }
      }
     
     // Trailing Stop  ---------------------------------------------------------
     
     for(i = 0; i < OrdersTotal(); i++)
      {
        OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
       
       if ( (OrderType() == OP_BUY) && (OrderMagicNumber() == magic) )
        {
         if ( (OrderClosePrice() - OrderOpenPrice()) > (TrailingStop*Point) )
          {
           if ( OrderStopLoss() < (OrderClosePrice() - TrailingStop*Point) )
            {
              OrderModify(OrderTicket(),
                          OrderOpenPrice(),
                          OrderClosePrice() - TrailingStop*Point,
                          OrderTakeProfit(),
                          Red);
            }
          }
        }
       
       if ( (OrderType() == OP_SELL) && (OrderMagicNumber() == magic) )
        {
         if ( (OrderOpenPrice() - OrderClosePrice()) > (TrailingStop*Point) )
     	    {
           if ( (OrderStopLoss() > (OrderClosePrice() + TrailingStop*Point)) ||
                (OrderStopLoss() == 0)                                          )
            {
              OrderModify(OrderTicket(),
                          OrderOpenPrice(),
                          OrderClosePrice() + TrailingStop*Point,
                          OrderTakeProfit(),
                          Red);
            }
     	    }
  	     }
  	   }
  	}
  return(0);
 }
   
//+------------------------------------------------------------------+