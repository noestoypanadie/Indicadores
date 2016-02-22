//+------------------------------------------------------------------+
//|                                                     macd_adx.mq4 |
//|                                                     emsjoflo     |
//+------------------------------------------------------------------+
#property copyright "emsjoflo"
//If you make money with this expert, please let me know emsjoflo@yaho.com
// I also accept donations ;)
//It is only a bare-bones expert with no safeties.  Let me know if you want me to modify it for your purposes.



//---- input parameters
extern int       DMILevels=25;
extern int       ADXLevel=15; 
extern double    lots=0.1;
extern int       StopLoss=60 ;
extern int       Slippage=4;
//I'm not sure where the best place to define variables is...so I put them here and it works
double   macd,macdsig,ADX,PlusDI,MinusDI,ADXpast,PlusDIpast,MinusDIpast,SL;
int      i, buys, sells;
datetime lasttradetime;
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
//get moving average info
macd=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
macdsig=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
ADX=iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,1);
PlusDI=iADX(NULL,0,14,PRICE_CLOSE,MODE_PLUSDI,1);
MinusDI=iADX(NULL,0,14,PRICE_CLOSE,MODE_MINUSDI,1);
ADXpast=iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,2);
PlusDIpast=iADX(NULL,0,14,PRICE_CLOSE,MODE_PLUSDI,2);
MinusDIpast=iADX(NULL,0,14,PRICE_CLOSE,MODE_MINUSDI,2);


//check for open orders first 
if (OrdersTotal()>0)
   {
   buys=0;
   sells=0;
   for (i=0;i<OrdersTotal();i++)
      {
      OrderSelect(i,SELECT_BY_POS);
      if (OrderSymbol()==Symbol())
         {
         if (OrderType()== OP_BUY)
            {
            if (macd > 0 && macdsig > 0 && macd < macdsig) OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,Orange);
            else buys++;
            }
         if (OrderType()== OP_SELL) 
            {
            if (macd < 0 && macdsig < 0 && macd > macdsig) OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Lime);
            else sells++;
            }
         }
      }
   }
if (ADX > ADXpast && ADX> ADXLevel && PlusDI > MinusDI && PlusDI > PlusDIpast && PlusDI > DMILevels && macd < 0 && macdsig < 0 && macd > macdsig && buys == 0 && (CurTime()-lasttradetime)/60 > Period())
   {
   //Print("Buy condition");
   if (StopLoss >1) SL=Ask-StopLoss*Point;
   OrderSend(Symbol(),OP_BUY,lots,Ask,Slippage,SL,0,"macd_adx",123,0,Lime);
   lasttradetime=CurTime();
   
   }
if (ADX > ADXpast && ADX> ADXLevel && PlusDI < MinusDI && MinusDI > MinusDIpast && MinusDI > DMILevels && macd > 0 && macdsig > 0 && macd < macdsig && sells ==0 && (CurTime()-lasttradetime)/60 > Period())
   {
   //Print ("Sell condition");
   if (StopLoss>1) SL=Bid+StopLoss*Point;
   OrderSend(Symbol(),OP_SELL,lots,Bid,Slippage,SL,0,"macd_adx",123,0,Red);
   }   
   
   
   
//----
   return(0);
  }
//+------------------------------------------------------------------+





















