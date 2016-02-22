//+------------------------------------------------------------------+
//|                                                    EMA_CROSS.mq4 |
//|                                                      Coders Guru |
//|                                         http://www.forex-tsd.com |
//|                                                                  |
//| Modified by Robert Hill as follows                               |
//| 6/4/2006 Fixed bugs and added exit on fresh cross option         |
//|          Added use of TakeProfit of 0                            |
//|          Modified for trade on open of closed candle             |
//|          Added  Trades in this symbol and MagicNumber check      |
//|          to allow trades on different currencies at same time    |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| TODO: Add Money Management routine                               |
//+------------------------------------------------------------------+

#property copyright "Coders Guru"
#property link      "http://www.forex-tsd.com"

//---- input parameters
extern double    TakeProfit=130;
extern double    StopLoss = 60;
extern double    Lots=1;
extern double    TrailingStop=30;

extern int ShortEma = 10;
extern int LongEma = 80;
extern bool ExitOnCross = true;
extern int SignalCandle = 0;
extern int MagicNumber = 12345;

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

int FreshCross ()
   {
      double SEma, LEma,SEmaP, LEmaP;
      
      SEma = iMA(NULL,30,ShortEma,0,MODE_EMA,PRICE_CLOSE,SignalCandle);
      LEma = iMA(NULL,30,LongEma,0,MODE_EMA,PRICE_CLOSE,SignalCandle);
      SEmaP = iMA(NULL,30,ShortEma,0,MODE_EMA,PRICE_CLOSE,SignalCandle+1);
      LEmaP = iMA(NULL,30,LongEma,0,MODE_EMA,PRICE_CLOSE,SignalCandle+1);
      
      //Don't work in the first load, wait for the first cross!
      
      if(SEma>LEma && SEmaP < LEmaP) return(1); //up
      if(SEma<LEma && SEmaP > LEmaP) return(2); //down

      return (0); //not changed
   }

//+------------------------------------------------------------------+
//| Check Open Position Controls                                     |
//+------------------------------------------------------------------+
  
int CheckOpenTrades()
{
   int cnt;
   int NumTrades;   // Number of buy and sell trades in this symbol
   
   NumTrades = 0;
   for(cnt=OrdersTotal()-1;cnt>=0;cnt--)
     {
      OrderSelect (cnt, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol() != Symbol()) continue;
      if ( OrderMagicNumber() != MagicNumber)  continue;
      
      if(OrderType() == OP_BUY )  NumTrades++;
      if(OrderType() == OP_SELL ) NumTrades++;
             
     }
     return (NumTrades);
  }

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//---- 

   int cnt, ticket, total;
   double TP;
   
   
   if(Bars<100)
     {
      Print("bars less than 100");
      return(0);  
     }
/*   if(TakeProfit<10)
     {
      Print("TakeProfit less than 10");
      return(0);  // check TakeProfit
     }
*/     
     
   
   
   static int isCrossed  = 0;
   isCrossed = FreshCross ();
   
   total = CheckOpenTrades();
   if(total < 1) 
     {
       if(isCrossed == 1)
         {
            TP = 0;
            if (TakeProfit > 0) TP = Ask + TakeProfit * Point;
            ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,TP,"EMA_CROSS",MagicNumber,0,Green);
            if(ticket>0)
              {
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
              }
            else Print("Error opening BUY order : ",GetLastError()); 
            return(0);
         }
         if(isCrossed == 2)
         {
            TP = 0;
            if (TakeProfit > 0) TP = Bid - TakeProfit * Point;
            ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+StopLoss*Point,TP,"EMA_CROSS",MagicNumber,0,Violet);
            if(ticket>0)
              {
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
              }
            else Print("Error opening SELL order : ",GetLastError()); 
            return(0);
         }
         return(0);
     }
     
     
    for(cnt = total-1; cnt >= 0; cnt--)
    {
     RefreshRates();
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
     if ((OrderSymbol() == Symbol())   ) //&& (OrderMagicNumber() == MagicNumber))
     {
  //    OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      //OrderPrint();
      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber)
        {
         if(OrderType()==OP_BUY)   // long position is opened
           {
            // should it be closed?
           
           /* REMOVED - Trailling stop only close */
           if(ExitOnCross && isCrossed == 2)
                {
                 OrderClose(OrderTicket(),OrderLots(),Bid,3,Black); // close position
                 return(0); // exit
                }
           /**/
           
            // check for trailing stop
       if ((TrailingStop > 0) &&
           (MathAbs(OrderClosePrice() - OrderOpenPrice()) > TrailingStop*Point) &&
           (OrderProfit() > 0.00))
        {
         if (  ((OrderType() == OP_BUY) && (OrderClosePrice() - TrailingStop*Point) > OrderStopLoss()) ||
               ((OrderStopLoss() == 0) && (OrderClosePrice() - TrailingStop*Point) >= OrderOpenPrice())  )
             OrderModify(OrderTicket(),OrderOpenPrice(),OrderClosePrice()-TrailingStop*Point,OrderTakeProfit(),0,Black);
                    }
                 }
              }
           }
         else // go to short position
           {
            // should it be closed?
            
            /* REMOVED - Trailling stop only close */
            if(ExitOnCross && isCrossed == 1)
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,Black); // close position
               return(0); // exit
              }
            /* */
            
            // check for trailing stop
 if ((TrailingStop > 0) &&
           (MathAbs(OrderClosePrice() - OrderOpenPrice()) > TrailingStop*Point) &&
           (OrderProfit() > 0.00))
        {
         
         if (  ((OrderType() == OP_SELL) && (OrderClosePrice() + TrailingStop*Point) < OrderStopLoss()) ||
               ((OrderStopLoss() == 0) && (OrderClosePrice() + TrailingStop*Point) <= OrderOpenPrice())  )
             OrderModify(OrderTicket(),OrderOpenPrice(),OrderClosePrice()+TrailingStop*Point,OrderTakeProfit(),0,Black);
             } 
           }
        }
         
        
    

   return(0);
  }
//+------------------------------------------------------------------+