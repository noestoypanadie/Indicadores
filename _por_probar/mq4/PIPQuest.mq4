//+------------------------------------------------------------------+
//|                                                     PIPQuest.mq4 |
//|                                                         emsjoflo |
//|                                  automaticforex.invisionzone.com |
//+------------------------------------------------------------------+
#property copyright "emsjoflo"
#property link      "automaticforex.invisionzone.com"

//---- input parameters
extern int       nPips=65;
extern int       UseTrStopLevelAsTrailingStop=1;
extern double    lots=0.01;
extern int       StopLoss=0;
extern int       Slippage=4;
extern double ATRmultiplier= 0.45;

double   atr,stop,atrstop,TrStopLevel,SL;
datetime LastOrderTime;
int      i, buys, sells;
int       BarsBackToGetTrStopLevel=1;  //don't change this, gives unreliable results
int       ExitOnBarAfterArrow=1; // don't change this either.  
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
TrStopLevel=iCustom(NULL,0,"PIPQind",nPips,4,BarsBackToGetTrStopLevel); 
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
            if (iCustom(NULL,0,"PIPQind",nPips,1,ExitOnBarAfterArrow)>0) OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,Orange);
            else 
               {
               buys++;
               if (UseTrStopLevelAsTrailingStop==1 && TrStopLevel > OrderStopLoss())OrderModify(OrderTicket(),OrderOpenPrice(),TrStopLevel,OrderTakeProfit(),0,Khaki);
               }
            }
         if (OrderType()== OP_SELL) 
            {
            if (iCustom(NULL,0,"PIPQind",nPips,0,ExitOnBarAfterArrow)>0) OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Yellow);
            else sells++;
               {
               if (UseTrStopLevelAsTrailingStop==1 && TrStopLevel < OrderStopLoss())OrderModify(OrderTicket(),OrderOpenPrice(),TrStopLevel,OrderTakeProfit(),0,Khaki);
               }
            }
         }
      }
   }
 
if (iCustom(NULL,0,"PIPQind",nPips,0,1)>0 && buys ==0 && (CurTime()-LastOrderTime)/60 > Period())
   {
   //Print("Buy condition");
   atr=iATR(NULL,0,14,1);
   stop=Low[Lowest(NULL,0,MODE_LOW,3,1)];
   atrstop =NormalizeDouble(TrStopLevel-atr*ATRmultiplier,MarketInfo(Symbol(),MODE_DIGITS));
   if (atrstop > stop) stop = atrstop;
   if (StopLoss >1) SL=Ask-StopLoss*Point;
   else SL = stop;
   OrderSend(Symbol(),OP_BUY,lots,Ask,Slippage,SL,0,"sr",123,0,Green);
   LastOrderTime=CurTime();
   }
 if (iCustom(NULL,0,"PIPQind",nPips,1,1)>0 && sells ==0 && (CurTime()-LastOrderTime)/60 > Period())
   {
   //Print ("Sell condition");
   atr=iATR(NULL,0,14,1);
   stop=High[Highest(NULL,0,MODE_HIGH,3,1)];
   atrstop = NormalizeDouble(TrStopLevel+atr*ATRmultiplier,MarketInfo(Symbol(),MODE_DIGITS));
   if (atrstop < stop) stop =atrstop;
   if (StopLoss>1) SL=Bid+StopLoss*Point;
   else SL = stop;
   OrderSend(Symbol(),OP_SELL,lots,Bid,Slippage,SL,0,"sr",123,0,Red);
   LastOrderTime=CurTime();
   }   
   
   
   
//----
   return(0);
  }
//+------------------------------------------------------------------+