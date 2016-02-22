//+------------------------------------------------------------------+
//|                                         GBP_4BarBreakout_M30.mq4 |
//|                                   Copyright © 2006, Lingyu Jiang |
//+------------------------------------------------------------------+

#property copyright "jiangly@gmail.com"

//---- input parameters
extern double    LotsIfNoMM=1;
extern bool      UseMM=false;
extern double    MMRiskFactor=0.2;
extern double    MMBalanceExcludeAmt=0;
extern double    MMBalanceShareDivisor=1;
extern int       TradeOpenTime=9;                         // Alpari: 9    FXDD: 10
extern int       PipsAddedToRange=10;
extern int       StopLossMax=45;                          // adjust this parameter accroding to your broker's spread
extern int       BreakEvenPlus5At=15;                     // adjust this parameter accroding to your broker's spread 
extern int       TakeProfit=999;
extern int       blTakeProfitOverrideMatchSL=0;
extern int       blCloseAtEOD=1;
extern int       EOD=17;                                  // Alpari: 17   FXDD: 18
extern int       blOneTradeOnly=0;
extern int       RangeMax=43;                             // adjust this parameter accroding to your broker's spread
extern int       blIfRangeMaxStillOpenFarTrade=1;
extern int       OrderHoursExpiry=0;
extern int       blCancelPendingAtStartTime=1;
extern int       MagicNum=212121;
extern string    TradeComment="GBP_4BarBreakout_M30";


//--- MM calculation
double CalculateMMLot()
  {
   double lot_min =MarketInfo(Symbol(),MODE_MINLOT);
   double lot_max =MarketInfo(Symbol(),MODE_MAXLOT);
   double lot_step=MarketInfo(Symbol(),MODE_LOTSTEP);
   double lot;
//--- check data
   if(lot_min<0 || lot_max<=0.0 || lot_step<=0.0) 
     {
      Print("CalculateMMLot: invalid MarketInfo() results [",lot_min,",",lot_max,",",lot_step,"]");
      return(0);
     }
   if(AccountLeverage()<=0)
     {
      Print("CalculateMMLot: invalid AccountLeverage() [",AccountLeverage(),"]");
      return(0);
     }
//--- basic formula
   lot=NormalizeDouble((AccountBalance()-MMBalanceExcludeAmt)/MMBalanceShareDivisor*MMRiskFactor/AccountLeverage()/10.0,2);
//--- additional calculation
//   ...
//--- check min, max and step
   lot=NormalizeDouble(lot/lot_step,0)*lot_step;
   if(lot<lot_min) lot=lot_min;
   if(lot>lot_max) lot=lot_max;
//---
   return(lot);
  }

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+

int start()
  {
   //---- 
   int i,Ticket,LastOrderTime,StartTime,EODTime,CloseUnhitOrdersTime,Bought=0,Sold=0,PeriodToReference=0,ErrTemp=0;
   int PendingTicket,OpenTicket,Last15mATRTrailBarTime,LastH1ATRTrailBarTime;

   double Lots,EntryLong,EntryShort,SLLong,SLShort,TPLong,TPShort,CurrBarTime,LookbackBars,ATRtrail;
   
   if (UseMM) Lots=CalculateMMLot(); else Lots=LotsIfNoMM;
   
   PeriodToReference=0; //I.e. whatever timeframe the chart/backtest is in
      
   if(blCancelPendingAtStartTime == 1 && CurTime()> StartTime-15*60 && CurrBarTime<StartTime)
      {
      for (i=0;i<OrdersTotal();i++)
         {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && (OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP)) OrderDelete(OrderTicket());
         }
      }
      
   LookbackBars = 4;
   //Set orders
   //The first criteria tests for a bug where StrToTime returns the previous date until 3:00 AM.
   if(TimeHour(CurTime()) >= TradeOpenTime && TimeHour(CurTime())<EOD )
      {
      //Determine range

      EntryLong   =iHigh(NULL,PeriodToReference,Highest(NULL,PeriodToReference,MODE_HIGH,LookbackBars,1))+(PipsAddedToRange+MarketInfo(Symbol(),MODE_SPREAD))*Point;
      EntryShort  =iLow (NULL,PeriodToReference,Lowest (NULL,PeriodToReference,MODE_LOW, LookbackBars,1))-PipsAddedToRange*Point;
      
      SLLong      =MathMax(EntryLong-StopLossMax*Point,EntryShort);
      SLShort     =MathMin(EntryShort+StopLossMax*Point,EntryLong);

      if (blTakeProfitOverrideMatchSL==0)
         {
         TPLong      =EntryLong+TakeProfit*Point;
         TPShort     =EntryShort-TakeProfit*Point;
         }
       else
         {
         TPLong      =EntryLong+(EntryLong-SLLong);
         TPShort     =EntryShort-(SLShort-EntryShort);
         }
         
         
      //Check Orders
      for (i=0;i<OrdersTotal();i++)
         {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && (OrderType()==OP_BUYSTOP || OrderType()==OP_BUY)) 
            {
            Bought++;
            //Fix stop if too wide due to slippage
            if (OrderStopLoss()<OrderOpenPrice()-(StopLossMax+2)*Point) OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-StopLossMax*Point,OrderTakeProfit(),OrderExpiration(),Green);
            }
         if(OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && (OrderType()==OP_SELLSTOP || OrderType()==OP_SELL)) 
            {
            Sold++;
            //Fix stop if too wide due to slippage
            if (OrderStopLoss()>OrderOpenPrice()+(StopLossMax+2)*Point) OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+StopLossMax*Point,OrderTakeProfit(),OrderExpiration(),Green);
            }
         }
      
      if (RangeMax != 0 && EntryLong-EntryShort>=RangeMax*Point) //So we can filter out large ranges
         { 
         if (blIfRangeMaxStillOpenFarTrade==1) 
            {
            //Ensures that only the trigger furthest from the current price will be set. If price moves back to the other side of the range within the hour, the second trade will also be set.
            if (iClose(NULL,PeriodToReference,1)-EntryShort < EntryLong-iClose(NULL,PeriodToReference,1)) 
               {
               Sold=1;
               //Print("HERE");
               }
              else
               {
               Bought=1;
               }
            }
           else
            {
            // Ensures that no trades will be opened
            Bought=1;
            Sold=1;
            }
         }
      
      if(Bought==0 && Sold==0 && EntryLong>Ask+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) //no buy order and price not right at the top of the range
         {
         Ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,EntryLong,3,SLLong,TPLong,TradeComment,MagicNum,0,Green);
         }
      if(Bought==0 && Sold==0 && EntryShort<Bid-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) //no sell order and price not right at the bottom of the range
         { 
         Ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,EntryShort,3,SLShort,TPShort,TradeComment,MagicNum,0,Green);
         }
      }
   
   //Manage opened orders

   if (blOneTradeOnly==1  && TimeHour(CurTime()) >= TradeOpenTime) //Delete the second pending trade if the other has been hit and new orders are no longer being placed
      {
      OpenTicket=0;
      PendingTicket=0;
      for (i=0;i<OrdersTotal();i++)
         {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && (OrderType()==OP_BUY || OrderType()==OP_SELL)) {OpenTicket=OrderTicket();}
         if(OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && (OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP)) {PendingTicket=OrderTicket();}
         }
      if (OpenTicket != 0 && PendingTicket != 0) //This assumes that there will only be two trades set at any given time
         {
         OrderDelete(PendingTicket);
         }   
      }


   for (i=0;i<OrdersTotal();i++)
      {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderHoursExpiry>0 && CurrBarTime>=CloseUnhitOrdersTime)
         {
         if(OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)  OrderDelete(OrderTicket());
         if(OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP) OrderDelete(OrderTicket());
         }   
      
      if(blCloseAtEOD==1 && TimeHour(CurTime()) >= EOD)
         {
         if(OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && OrderType()==OP_BUY)      OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
         if(OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && OrderType()==OP_SELL)     OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
         if(OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP)  OrderDelete(OrderTicket());
         if(OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP) OrderDelete(OrderTicket());
         }   
        else 
         {

         //move at BE if profit>BE
         if(BreakEvenPlus5At>0 && OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && OrderType()==OP_BUY)
            {
            if(OrderStopLoss()<OrderOpenPrice() && iHigh(NULL,PeriodToReference,1)-OrderOpenPrice() >= BreakEvenPlus5At*Point)
               {
               OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+5*Point,OrderTakeProfit(),0,Green);
               }   
            }   
         if(BreakEvenPlus5At>0 && OrderMagicNumber()==MagicNum && OrderSymbol()==Symbol() && OrderType()==OP_SELL)
            {
            if(OrderStopLoss()>OrderOpenPrice() && OrderOpenPrice()-(iLow(NULL,PeriodToReference,1)+MarketInfo(Symbol(),MODE_SPREAD)*Point) >= BreakEvenPlus5At*Point)
               {
               OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-5*Point,OrderTakeProfit(),0,Green);
               }
            }
         }
      }
   
   return(0);
  }
//+------------------------------------------------------------------+