//+------------------------------------------------------------------+
//|                         Steve Cartwright Trader Camel CCI MACD.mq4 |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

 extern double Lots = 1;
 extern double TakeProfit = 50;
 extern double InitialStop = 10;
 extern double TrailingStop = 10;
 
 int cnt,total,ticket;
 int SigPos,MinDist;
 
 double     MACDSP1,     MACDSP2;
 double     MACDHP1,     MACDHP2;
 double       MASP1,       MASP2;
 double CAMELHIGHP1, CAMELHIGHP2;
 double  CAMELLOWP1,  CAMELLOWP2;
 double CCIP1;
 
 

int init()
  {
   return(0);
  }


int deinit()
  {
   return(0);
  }


int start()
  {

   int Flag;
   
   double Spread;
   double ATR;
   double StopMA;
   int cnt, tmp;
   double SetupHigh, SetupLow;
 
   // Error checking
   if(Bars<100)                        {Print("bars less than 100");       return(0); }
   if(TakeProfit<10)                   {Print("TakeProfit less than 10");  return(0); }
   if(AccountFreeMargin()<(1000*Lots)) {Print("We have no Free Margin");   return(0); }


   // -ron- why is SP1 using SIGNAL, and HP1 using MAIN??????

   MASP1=iMA(NULL,0,3,0,MODE_SMA,PRICE_CLOSE,1);
   MACDSP1=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
   MACDHP1=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,1);

   MASP2=iMA(NULL,0,3,0,MODE_SMA,PRICE_CLOSE,2);
   MACDSP2=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,2);
   // -ron-  this was 1, changed to 2
   MACDHP2=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,2);


   CAMELLOWP1= iMA(NULL,0,34,0,MODE_EMA,PRICE_LOW, 1);
   CAMELHIGHP1=iMA(NULL,0,34,0,MODE_EMA,PRICE_HIGH,1);

   CCIP1=iCCI(NULL,0,20,PRICE_CLOSE,1);

   StopMA=iMA(NULL,0,24,0,MODE_SMA,PRICE_CLOSE,1);
   MinDist=MarketInfo(Symbol(),MODE_STOPLEVEL);
   Spread=(Ask-Bid);

   if(0==1)  //-ron- so this code never executes??  why is it here?
     {
      total=OrdersTotal();
      if (total>0)
        {
         for(cnt=0;cnt<total;cnt++)
           {  
            //LONG
            OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
            if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
              {
               if(OrderStopLoss() < OrderOpenPrice())
                 {
                  if (OrderStopLoss() < Bid -(Point*(MinDist*2)))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid -(Point*(2*MinDist)),OrderTakeProfit(),0,Lime);
                    }
                 }
              }
           }
              
         // SHORT
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
           {
            if(OrderStopLoss() > OrderOpenPrice())
              {
               if (OrderStopLoss() > Ask + (Point*(MinDist*2)))
                 {
                  OrderModify(OrderTicket(),OrderOpenPrice(),Ask+(Point*(MinDist*2)),OrderTakeProfit(),0,Lime);
                 }
              }
           }
        }
     }      // -ron-  the end of (0=1)


   // If Orders are in force then check for closure against Technicals LONG & SHORT
   //CLOSE LONG Entries

   // -ron- removed if total=0 check, cause you're not going to have thousands
   //       of orders open at a time, and it doesn't really save time
   // -ron- modified to accept any Symbol()
   // -ron- turned this around to start from the bottom
   // -ron- fixed logic to actually allow an order on the proper symbol 
   for(cnt=OrdersTotal();cnt>0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY && MACDHP1<MACDSP1)
           //LONG Closure Rules
           {
            OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet);
           }
         if(OrderType()==OP_SELL && MACDHP1>MACDSP1)
           //SHORT Closure Rules {   
           {
            OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet);
           }
        }
     }  // for loop return

// -ron- This is WRONG, the 1st if was closed above this bracket, and
//       the orcercount loop was always running.
//
//  }   // close 1st if 


   //TRAILING STOP: LONG
   if(0==1)
     {
      for(cnt=OrdersTotal();cnt>0;cnt--)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            if(OrderType()==OP_BUY)
              {
               if(TrailingStop>0)  
                 {                 
                  if(Bid-OrderOpenPrice()>Point*TrailingStop)
                    {
                     if(OrderStopLoss()<Bid-Point*TrailingStop)
                       {
                        OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,White);
                        return(0);
                       }
                    }
                 }
              }
            if(OrderType()==OP_SELL)
              {
               if(TrailingStop>0)  
                 {                 
                  if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                    {
                     if(OrderStopLoss()>Ask+(Point*TrailingStop)) 
                       {
                        OrderModify(OrderTicket(),OrderOpenPrice(),Ask+(Point*TrailingStop),OrderTakeProfit(),0,Yellow);
                        return(0);
                       }
                    }
                 }
              }
           }
        } // end FOR loop
     } // end bracket for on/off switch


   //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   //#########################  NEW POSITIONS ?  ######################################
   //Possibly add in timer to stop multiple entries within Period
   // Check Margin available
   // ONLY ONE ORDER per SYMBOL
   // Loop around orders to check symbol doesn't appear more than once
   // Check for elapsed time from last entry to stop multiple entries on same bar


   for(cnt=HistoryTotal();cnt>0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         if( CurTime()-OrderCloseTime()<(Period()*60) )
           {
            return(0);
           }
        }
      }

   // -ron-  WHY are you returning now?
   //        on any open order for this symbol???
   for(cnt=OrdersTotal();cnt>0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         return(0);
        }
     }
     
   //ENTRY RULES: LONG 
   //High[1] > High[2] && Low[1] > Low[2])
   if(CCIP1 > 100 && MACDHP1>0 && Close[1]>CAMELHIGHP1)
     {
      //Bid-(Point*(MinDist+2))
      ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"MaxMin Long",16384,0,Orange);
      Alert("Order opened for: ",Symbol());
      if(ticket>0)
        {
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
        }
         else 
        {
         Print("Error opening BUY order : ",GetLastError()); 
        }
      return(0); 
     } 
   //Low[1] < Low[2] && High[1] < High[2])
   if(CCIP1<-100 && MACDSP1<0 && Close[1]<CAMELLOWP1)
     {
      ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"MaxMin Short",16384,0,Red);
      if(ticket>0)
        {
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
        }
         else 
        {
         Print("Error opening SELL order : ",GetLastError()); 
        }
      return(0); 
      }
   return(0);
  }

