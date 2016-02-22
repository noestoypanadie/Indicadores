//+------------------------------------------------------------------+
//|                                                 TEMa_ADX_EA.mq4  |
//|                              EA Based on TEMa indicator and ADX  |
//|                                                 Rodrigo Brayner  |
//|                                                            2006  |
//|                                     http://rbrayner.blogspot.com |
//+------------------------------------------------------------------+

#property copyright "Rodrigo Brayner"
#property link      "http://rbrayner.blogspot.com"

/* Input Parameters */ 
extern double    takeProfit=100.0; // Maximum profit
extern double    stopLoss=15.0; // Maximum stop loss
extern double    lots=0.1;
extern double    trailingStop=20.0;
extern int       emaPeriod = 14;
extern double    adxTradeCondition = 25.0;
extern int       signalBar = 0; // Buy how many bars after cross? 1 means 1 bar after cross, 0 means the current bar etc
extern int       myPlaySound = 0;
extern int       maxActiveOrders = 5;

static int       lastDirection = 0;
static int       currentDirection = 0;
int              adxDirection = 0;
int              isCrossed;
double           adx;
string           name;

//+------------------------------------------------------------------+
// expert initialization function                                    |
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


/***********************************************************/
/************************ FUNCTIONS ************************/
/***********************************************************/

int verifyAdxDirection(int _signalBar)
{
   
   int direction;
   
   int adx1 = iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,_signalBar);
   int adx2 = iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,_signalBar+1);

   if(adx2 > adx1)
      direction = -1; //Downward
   else if(adx2 < adx1)
      direction = 1; //Upward
   else
      direction = 0; //Nome         

   return(direction);      

}

int verifyDirectionTema (int _signalBar)
{

   double ema, emaOfEma, emaOfEmaOfEma, tema;

   bool direction = 0; // No direction

   ema = iMA(NULL,0,emaPeriod,0,MODE_EMA,PRICE_CLOSE,_signalBar);
   emaOfEma = iCustom(NULL,0,"TEMA_RLH",emaPeriod,1,_signalBar);
   emaOfEmaOfEma = iCustom(NULL,0,"TEMA_RLH",emaPeriod,2,_signalBar);
   tema = 3 * ema - 3 * emaOfEma + emaOfEmaOfEma;
   
   if(tema>emaOfEmaOfEma && ema>emaOfEma) direction = 1; // Direction UP
   if(tema<emaOfEmaOfEma && ema<emaOfEma) direction = -1; // Direction DOWN

   return (direction);

}

string sVerifyDirectionTema (int _signalBar)
{
   int direction;
   string sDirection;
   
   direction = verifyDirectionTema(_signalBar);
   
   if ( direction == 1 ) 
      sDirection = "[UP]";
   else if ( direction == -1 )
      sDirection = "[DOWN]";
   else
      sDirection = "[No Direction]";
      
   return (sDirection);
}

void comments()
{

   string sCrossed,sAdx,satisfyCondition,sAdxDirection;
   
   if (isCrossed == 1)
      sCrossed = "[YES, UP]";   
   else if (isCrossed == -1)
      sCrossed = "[YES, DOWN]";
   else
      sCrossed = "[NO]";
         
   if (adx < 25)
      sAdx = "[BELOW 25]";
   else if (adx > 25)
      sAdx = "[ABOVE 25]";
   else
      sAdx = "[EQUAL 25]";

   if (adxDirection == 1)
      sAdxDirection = "[UP]";
   else if (adxDirection == -1)
      sAdxDirection = "[DOWN]";
   else
      sAdxDirection = "[NONE]";

   if ( isCrossed != 0 && adx >= 25 && adxDirection != 0 )
      satisfyCondition = "[CONDITIONS MET... TRADE]"; 
   else
      satisfyCondition = "[CONDITIONS NOT MET... DO NOT TRADE]";            

   Comment("\nLastDirection = ",sVerifyDirectionTema(signalBar+1),"\nCurrentDirection=",sVerifyDirectionTema(signalBar),"\nisCrossed=",sCrossed,"\nadxDirection = ",sAdxDirection,"\nADX = ",adx," = ",sAdx,"\n\n :: ",satisfyCondition," :: ");

}

int crossed (int _currentDirection, int _lastDirection)
{
      
   _currentDirection = currentDirection;
   _lastDirection = lastDirection;
      
   if(_currentDirection != _lastDirection) // Crossed/Changed 
   {
      return (_currentDirection);
   }
   else
   {
      return (0); // No changing
   }
} 

/***********************************************************/
/******************** END FUNCTIONS ************************/
/***********************************************************/



/***********************************************************/
/************************** START **************************/
/***********************************************************/

int start()
{
   
   int cnt, ticket, total;

   if(Bars<100)
   {
      Print("[ERROR] Bars less than 100!");
      return(0);  
   }
   if(takeProfit<10)
   {
      Print("[ERROR] TakeProfit less than 10!");
      return(0);  // check TakeProfit
   }
   
   // Calculate adx value     
   adx = iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,signalBar);
   adxDirection = verifyAdxDirection(signalBar);
   // Calculate direction on bar signalBar+1 | 0 means current bar, 1 means previous bar, 2 means... 
   lastDirection = verifyDirectionTema(signalBar+1);
   // Calculate direction on bar signalBar | 0 means current bar, 1 means previous bar, 2 means...
   currentDirection = verifyDirectionTema(signalBar);
   // Did the EMAs cross? 1 means crossed up, -1 means crossed down, 0 means nothing
   isCrossed  = crossed (currentDirection,lastDirection);
   // Print comments..
   comments();
   
   total  = OrdersTotal(); 
   
   int alreadyTraded = 0;
   
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
         alreadyTraded = 1;
   }
   
   if (alreadyTraded == 0 && total < maxActiveOrders)
   {
       if( isCrossed == 1 && adx >= adxTradeCondition && adxDirection == 1 ) // Goind up
       {
            ticket=OrderSend(Symbol(),OP_BUY,lots,Ask,3,Bid-stopLoss*Point,Ask+takeProfit*Point,"[BUY] TEMa_ADX_EA",12345,0,Blue);
            if(ticket>0)
            {
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("[BUY] Order opened : ",OrderOpenPrice());
               name = "[BUY] " + Hour() + Minute();
               ObjectCreate(name, OBJ_ARROW, 0, CurTime(), Ask);
               ObjectSet(name, OBJPROP_ARROWCODE, SYMBOL_ARROWUP);
               if (myPlaySound == 1) PlaySound("alert.wav");
            }
            else Print("Error opening BUY order : ",GetLastError()); 
            return(0);
       }
       
       if( isCrossed == -1  && adx >= adxTradeCondition && adxDirection == -1 ) // Goind down
       {

          ticket=OrderSend(Symbol(),OP_SELL,lots,Bid,3,Ask+stopLoss*Point,Bid-takeProfit*Point,"[SELL] TEMa_ADX_EA",12345,0,Red);
          if(ticket>0)
          {
             if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("[SELL] Order opened : ",OrderOpenPrice());
             name = "[SELL] " + Hour() + Minute();
             ObjectCreate(name, OBJ_ARROW, 0, CurTime(), CurTime(), Bid);
             ObjectSet(name, OBJPROP_ARROWCODE, SYMBOL_ARROWDOWN);
             if (myPlaySound == 1) PlaySound("alert.wav");
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
           if(isCrossed == -1 && adx > adxTradeCondition)
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
            if(isCrossed == 1 && adx > adxTradeCondition)
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

