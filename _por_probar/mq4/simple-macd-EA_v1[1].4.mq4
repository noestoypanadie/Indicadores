//+------------------------------------------------------------------+
//|                                   Simple-MACD-EA.mq4 Version 1.4 |
//|                                                       investor_me|
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "investor_me"
#property link      "investor.me@gmail.com"

#include <stdlib.mqh>

extern double    Lots=1;  // number of lots to trade (usually, 1 lot is $100k) (unlimited)
extern double     TrailingStop=65;   // the amount of the trailing stop needed to maximize profit (unlimited)
extern int MACD_level=250; //(1-12) [low works for GBPUSD], high works for others.
extern int MAGIC=123457;
extern int tp_limit=100;
extern int StopLoss=150;
extern int wait_time_b4_SL=2950;

int      trend=0,last_trend=0, pending_time, ticket, total, pace, tp_cnt;
bool     sell_flag, buy_flag, find_highest=false, find_lowest=false;
double   MACD_Strength=0, trade_lots;
int BUY_ORDER=1;
int SELL_ORDER=2;
         
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  { 
   trade_lots=Lots;
   return(0);
  }

//+------------------------------------------------------------------+
//| expert de-initialization function                                   |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
//+------------------------------------------------------------------+
//| MACD function derives the value of MACD with default settings    |
//+------------------------------------------------------------------+
int best_deal()
  {
   double MACDSignal1,MACDSignal2,MACDSignal3,MACDSignal4,MACDSignal5;
   
//   MACDSignal5=iMA(NULL,0,MACD_level,0,MODE_EMA,Close[0],0)-iMA(NULL,0,MACD_level+1,0,MODE_EMA,Close[0],0);
//   MACDSignal4=iMA(NULL,0,MACD_level,0,MODE_EMA,Close[1],1)-iMA(NULL,0,MACD_level+1,0,MODE_EMA,Close[1],1);
   MACDSignal3=iMA(NULL,0,MACD_level,0,MODE_EMA,Close[0],0)-iMA(NULL,0,MACD_level+1,0,MODE_EMA,Close[0],0);
   MACDSignal2=iMA(NULL,0,MACD_level,0,MODE_EMA,Close[1],1)-iMA(NULL,0,MACD_level+1,0,MODE_EMA,Close[1],2);
   MACDSignal1=iMA(NULL,0,MACD_level,0,MODE_EMA,Close[2],2)-iMA(NULL,0,MACD_level+1,0,MODE_EMA,Close[2],2);

   if ((find_highest && Close[0]>OrderOpenPrice()+Point*5 && MACDSignal1>0) && MACDSignal2>MACDSignal1 && MACDSignal2<MACDSignal3 /* && MACDSignal2<MACDSignal3 && MACDSignal1<MACDSignal2*/)
     { find_highest=false; return (1); } 
   
   else if ((find_lowest && Close[0]<OrderOpenPrice()-Point*5 && MACDSignal1<0) && MACDSignal2<MACDSignal1 && MACDSignal2<MACDSignal3 /*&& MACDSignal2>MACDSignal3 && MACDSignal1>MACDSignal2*/)
     { find_lowest=false; return (1); } 
  
   return (0);
  }
//+--------------------------------------------------------------------------------+
int MACD_Direction ()
  {
   double MACDSignal1,MACDSignal2,ind_buffer1[100], Signal1, Signal2;
   
   MACDSignal2=iMA(NULL,0,MACD_level/10,0,MODE_EMA,Close[0],0)-iMA(NULL,0,MACD_level,0,MODE_EMA,Close[0],0);
   MACDSignal1=iMA(NULL,0,MACD_level/10,0,MODE_EMA,Close[1],1)-iMA(NULL,0,MACD_level,0,MODE_EMA,Close[1],1);

   MACD_Strength=MACDSignal2-MACDSignal1; if (MACD_Strength<0) MACD_Strength=MACD_Strength*(-1);

   if(MACDSignal1<0) return (-1); 
   if(MACDSignal1>0) return (1); 
   else return (0);  
  }
//+--------------------------------------------------------------------------------+
//| ClosePending function closes the open order (mainly due to stoploss condition) |
//+--------------------------------------------------------------------------------+
void ClosePending()
 {
     if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber() == MAGIC) 
        {
          if(OrderType()==OP_BUY)
             {  
               OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); 
               pending_time=0; 
               if (Close[0]>=OrderOpenPrice()) trade_lots=Lots; else trade_lots=Lots/10;
             }  
          else
             {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); 
               pending_time=0; 
               if (Close[0]<=OrderOpenPrice()) trade_lots=Lots; else trade_lots=Lots/10;
             }  
        }
 }
//+------------------------------+
//| The order send function      |
//+------------------------------+
void do_order(int type)
 {
   int stop_loss = 0;
   int err;
   if (type==BUY_ORDER)
      {
             if (StopLoss != 0) {
               stop_loss = Bid-Point*StopLoss;
             }
            ticket=OrderSend(Symbol(),OP_BUY,trade_lots,Ask,3,Bid-Point*StopLoss,0,"Simple MACD 1.4",MAGIC,0,White); // buy
             if(ticket>0)
                     { 
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           { Print("BUY order opened : ",OrderOpenPrice()); } // buy order successful
                        pace=tp_limit; tp_cnt=0; pending_time=0;  find_highest=true;
                     }
              else {
                  err = GetLastError();
                  Print("Error opening BUY order : ",ErrorDescription(err));
              }
              buy_flag=false;
      }
  else if (type==SELL_ORDER)
      {
             if (StopLoss != 0) {
               stop_loss = Ask+Point*StopLoss;
             }
             ticket=OrderSend(Symbol(),OP_SELL,trade_lots,Bid,3,Ask+Point*StopLoss,0,"Simple MACD 1.4",MAGIC,0,Red);
             if(ticket>0)
                     {
                       if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                         { Print("SELL order opened : ",OrderOpenPrice()); }
                       pace=tp_limit; tp_cnt=0; pending_time=0; find_lowest=true;
                     }
             else {
                 err = GetLastError();
                 Print("Error opening SELL order : ", ErrorDescription(err));
             }
             sell_flag=false;
      }
 
 }
//+------------------------------+
//| The trailing stop function   |
//+------------------------------+
int trailing_stop(int type)
 {
     pace++;
     if(TrailingStop>0 && type==BUY_ORDER && pace>tp_limit && tp_cnt<tp_limit) // check for trailing stop value
        { 
         if(Bid-OrderOpenPrice()>Point*TrailingStop)
          { 
           if(OrderStopLoss()<Bid-Point*TrailingStop)
            {
             OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
             if (Close[0]>=OrderOpenPrice()) trade_lots=Lots; else trade_lots=Lots/10;
             pace=0; tp_cnt++; return (1);
            }
          }
        }

     else if(TrailingStop>0 && type==SELL_ORDER && pace>tp_limit && tp_cnt<tp_limit)
        { 
         if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
          { 
           if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
            {
             OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
             if (Close[0]<=OrderOpenPrice()) trade_lots=Lots; else trade_lots=Lots/10;
             pace=0; tp_cnt++; return (1); 
            }
          }
        }
   if (TrailingStop>0 && tp_cnt>=tp_limit) ClosePending();
 }

//+------------------------------+
//| The main start function      |
//+------------------------------+
int start()
  {
   int count; 

   if(Bars<100) {  Print("bars less than 100"); return(0); } 

   last_trend=trend;
   trend=MACD_Direction();
   
   total=OrdersTotal(); 

   for(count=0;count<total;count++) 
      {
         OrderSelect(count, SELECT_BY_POS, MODE_TRADES);
         if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber() == MAGIC)
            {  
               if(OrderType()==OP_BUY) 
                  {  
                     trailing_stop(BUY_ORDER);

                     if (Close[0]>=OrderOpenPrice()+Point*5) pending_time=0;
                     else if (Close[0]<OrderOpenPrice()+Point*5) pending_time++;

/*
                     if (trend<0 && last_trend>0 && Close[0]>OrderOpenPrice()+Point*5) 
                        { 
                           ClosePending(); return (0);
                        } 
*/
                     if (best_deal()==1)
                        { 
                           ClosePending(); 
                           pending_time=0; 
                           find_highest=false;
                           return (0);
                        } 

                     if (find_highest && pending_time>wait_time_b4_SL && Close[0]<=OrderOpenPrice()+Point*(pending_time-wait_time_b4_SL))
                        { 
                           ClosePending(); 
                           pending_time=0; 
                           find_highest=false;
                           return (0);
                        } 
                  }
                else 
                  { 
                     trailing_stop(SELL_ORDER);
/*
                     if (trend>0 && last_trend<0 && Close[0]<OrderOpenPrice()-Point*5) 
                        { 
                           ClosePending(); return (0);
                        } 
*/
                     if (Close[0]<=OrderOpenPrice()-Point*5) pending_time=0;
                     else if (Close[0]>OrderOpenPrice()-Point*5) pending_time++;

                     if (best_deal()==1)
                        { 
                           ClosePending(); 
                           pending_time=0; 
                           find_lowest=false;
                           return (0);
                        } 

                     if (find_lowest && pending_time>wait_time_b4_SL && Close[0]>=OrderOpenPrice()-Point*(pending_time-wait_time_b4_SL))
                        { 
                           ClosePending(); 
                           pending_time=0; 
                           find_lowest=false;
                           return (0);
                        } 
                   }
               return (0);
             }
      }

   if (trend>0 && last_trend<0 /*&& MACD_Strength>Point*0.001*/)  
         { buy_flag=true; sell_flag=false; last_trend=trend; Print ("crossed +:",TimeToStr(Time[0],TIME_MINUTES)); }

   else if (trend<0 && last_trend>0 /*&& MACD_Strength>Point*0.001*/)  
         { sell_flag=true; buy_flag=false; last_trend=trend;  Print ("crossed -:",TimeToStr(Time[0],TIME_MINUTES)); }

   if (buy_flag==true) do_order(BUY_ORDER); 
   if (sell_flag==true) do_order(SELL_ORDER); 
 }

