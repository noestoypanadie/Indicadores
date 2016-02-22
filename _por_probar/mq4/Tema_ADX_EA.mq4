//+------------------------------------------------------------------+
//|                                                 Tema_ADX_EA.mq4  |
//|                                                         Rodrigo  |
//|                                     http://rbrayner.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Rodrigo Brayner"
#property link      "http://rbrayner.blogspot.com"

//---- Input Parameters
extern double    takeProfit=100.0;
extern double    stopLoss=15.0;
extern double    lots=0.1;
extern double    trailingStop=15.0;
extern int       emaPeriod = 14;
extern double    adxTradeCondition = 25.0;
extern int SignalBar = 1;


//----- Global Variables
double ema;
double emaOfEma;
double emaOfEmaOfEma;
double tema;
double adx;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
  
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }

int Crossed (double _ema , double _emaOfEma, double _emaOfEmaOfEma, double _tema)
   {
      static int lastDirection = 0;
      static int currentDirection = 0;
      
      if(_tema>_emaOfEmaOfEma && _ema>_emaOfEma) currentDirection = 1; //up
      if(_tema<_emaOfEmaOfEma && _ema<_emaOfEma)currentDirection = -1; //down



      if(currentDirection != lastDirection) //changed 
      {
            lastDirection = currentDirection;
            return (lastDirection);
      }
      else
      {
            return (0);
      }
   } 
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//---- 
   
   int cnt, ticket, total;
   double myTema, myEma;
   
   if(Bars<100)
     {
      Print("ERROR: Bars less than 100!");
      return(0);  
     }
   if(takeProfit<10)
     {
      Print("ERROR: TakeProfit less than 10!");
      return(0);  // check TakeProfit
     }
     
   adx = iADX(NULL,0,14,PRICE_HIGH,MODE_MAIN,SignalBar);

   ema = iMA(NULL,0,emaPeriod,0,MODE_EMA,PRICE_CLOSE,SignalBar);
   
//   emaOfEma = iMAOnArray(ema,Bars,emaPeriod,0,MODE_EMA,0);
//   emaOfEmaOfEma = iMAOnArray(emaOfEma,Bars,emaPeriod,0,MODE_EMA,0);
//   tema = 3 * ema - 3 * emaOfEma + emaOfEmaOfEma;

   emaOfEma = iCustom(NULL,0,"TEMA_RLH",emaPeriod,1,SignalBar);
   emaOfEmaOfEma = iCustom(NULL,0,"TEMA_RLH",emaPeriod,2,SignalBar);
   tema = 3 * ema - 3 * emaOfEma + emaOfEmaOfEma;
   
   int isCrossed  = Crossed (ema,emaOfEma,emaOfEmaOfEma,tema);
   
   total  = OrdersTotal(); 
   if(total < 1) 
     {
       if(isCrossed == 1 && adx > adxTradeCondition ) // Goind up
         {
            ticket=OrderSend(Symbol(),OP_BUY,lots,Ask,3,Bid-stopLoss*Point,Ask+takeProfit*Point,"TemaEA [BUY]",12345,0,Blue);
            if(ticket>0)
              {
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
              }
            else Print("Error opening BUY order : ",GetLastError()); 
            return(0);
         }
         if(isCrossed == -1  && adx > adxTradeCondition ) // Goind down
         {

            ticket=OrderSend(Symbol(),OP_SELL,lots,Bid,3,Ask+stopLoss*Point,Bid-takeProfit*Point,"TemaEA [SELL]",12345,0,Red);
            if(ticket>0)
              {
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
              }
            else Print("Error opening SELL order : ",GetLastError()); 
            return(0);
         }
         return(0);
     }
   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY)   // long position is opened
           {
            // should it be closed?
           if(isCrossed == -1)
                {
                 OrderClose(OrderTicket(),OrderLots(),Bid,3,White); // close position
                 return(0); // exit
                }
            // check for trailing stop
            if(trailingStop>0)  
              {                 
               if(Bid-OrderOpenPrice()>Point*trailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*trailingStop)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*trailingStop,OrderTakeProfit(),0,Blue);
                     return(0);
                    }
                 }
              }
           }
         else // go to short position
           {
            // should it be closed?
            if(isCrossed == 1)
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close position
               return(0); // exit
              }
            // check for trailing stop
            if(trailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*trailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*trailingStop)) || (OrderStopLoss()==0))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*trailingStop,OrderTakeProfit(),0,Red);
                     return(0);
                    }
                 }
              }
           }
        }
     }
   return(0);
  }
//+------------------------------------------------------------------+