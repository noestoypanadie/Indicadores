//+------------------------------------------------------------------+
//|                                                 TradeChannel.mq4 |
//|                                   Copyright © 2005, Yuri Makarov |
//|                                       http://mak.tradersmind.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Yuri Makarov"
#property link      "http://mak.tradersmind.com"

extern double Lots  = 1.0;
extern int Slippage = 5;
extern int TimeOut  = 10000;

double SetLevel(double Level, double NewLevel, string ObjName, int Style)
{
   switch (Style)
   {
   case 1:  // Buy Order line
      ObjectSet(ObjName,OBJPROP_COLOR,Blue);
      ObjectSet(ObjName,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSet(ObjName,OBJPROP_WIDTH,2);
      break;
   case 2:  // Sell Order line
      ObjectSet(ObjName,OBJPROP_COLOR,Red);
      ObjectSet(ObjName,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSet(ObjName,OBJPROP_WIDTH,2);
      break;
   case 3:  // Buy Stop line
      ObjectSet(ObjName,OBJPROP_COLOR,Blue);
      ObjectSet(ObjName,OBJPROP_STYLE,STYLE_DASH);
      ObjectSet(ObjName,OBJPROP_WIDTH,1);
      break;
   case 4:  // Sell Stop line
      ObjectSet(ObjName,OBJPROP_COLOR,Red);
      ObjectSet(ObjName,OBJPROP_STYLE,STYLE_DASH);
      ObjectSet(ObjName,OBJPROP_WIDTH,1);
      break;
   case 5:  // Buy Take line
      ObjectSet(ObjName,OBJPROP_COLOR,Blue);
      ObjectSet(ObjName,OBJPROP_STYLE,STYLE_DOT);
      ObjectSet(ObjName,OBJPROP_WIDTH,1);
      break;
   case 6:  // Sell Take line
      ObjectSet(ObjName,OBJPROP_COLOR,Red);
      ObjectSet(ObjName,OBJPROP_STYLE,STYLE_DOT);
      ObjectSet(ObjName,OBJPROP_WIDTH,1);
      break;
   }
   
   if (MathAbs(NewLevel - Close[0]) < MathAbs(Level - Close[0])) return (NewLevel);
   else return (Level);
}

int start()
{
   int NumObj = ObjectsTotal();
   double Spread = Ask - Bid;
   
   double pBuy  = 0;
   double pSell = 0;
   double pBuyStop = 0;
   double pBuyTake = 0;
   double pSellStop = 0;
   double pSellTake = 0;

   for (int i = 0; i < NumObj; i++)
   {
      string ObjName = ObjectName(i);
      string ObjDesc = ObjectDescription(ObjName);
      double Price = 0;

      switch (ObjectType(ObjName))
      {
      case OBJ_HLINE:
         Price = ObjectGet(ObjName,OBJPROP_PRICE1); 
         break;
      case OBJ_TREND:
         Price = ObjectGetValueByShift(ObjName,0); 
         break;
      }

      if (Price > 0)
      {
         if (ObjDesc == "Buy")  pBuy  = SetLevel(pBuy,  Price, ObjName, 1); else
         if (ObjDesc == "Sell") pSell = SetLevel(pSell, Price, ObjName, 2); else
         if (ObjDesc == "Stop") 
         {
            if (Price < Close[0]) pBuyStop = SetLevel(pBuyStop, Price, ObjName, 3);
            else pSellStop = SetLevel(pSellStop, Price, ObjName, 4); 
         } else
         if (ObjDesc == "Take") 
         {
            if (Price > Close[0]) pBuyTake = SetLevel(pBuyTake, Price, ObjName, 5);
            else pSellTake = SetLevel(pSellTake, Price, ObjName, 6);
         }
      }
   }
   
   int NumOrders = OrdersTotal();
   int NumPos = 0;

   for (i = 0; i < NumOrders; i++)
   {
      OrderSelect(i, SELECT_BY_POS);
      if (OrderSymbol() != Symbol()) continue;
      
      NumPos++;

      double tp = OrderTakeProfit();
      double sl = OrderStopLoss();

      if (OrderType() == OP_BUY)
      {
         if (Bid > pSell && pSell > 0)
         {
            OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Red);
            Sleep(TimeOut);
            return(0);
         }
         if (MathAbs(tp - pBuyTake) > Spread || MathAbs(sl - pBuyStop) > Spread) 
         {
            OrderModify(OrderTicket(), Ask, pBuyStop, pBuyTake, 0);
            Sleep(TimeOut);
            return(0);
         }
      }

      if (OrderType() == OP_SELL)
      {
         if (Ask < pBuy)
         {
            OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, Red);
            Sleep(TimeOut);
            return(0);
         }
         if (MathAbs(tp - pSellTake) > Spread || MathAbs(sl - pSellStop) > Spread) 
         {
            OrderModify(OrderTicket(), Bid, pSellStop, pSellTake, 0);
            Sleep(TimeOut);
            return(0);
         }
      }
   }
   
   if (NumPos > 0) return(0);
   if ((pSell - pBuy) < Spread*2) return(0);
      
   if (Bid > pSell && pSell > pBuyStop)
   {
      OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, pSellStop, pSellTake);
      Sleep(TimeOut);
      return(0);
   }

   if (Ask < pBuy && (pBuy < pSellStop || pSellStop == 0))
   {
      OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, pBuyStop, pBuyTake);
      Sleep(TimeOut);
      return(0);
   }
}

int init()
{
   return(0);
}

int deinit()
{
   return(0);
}


