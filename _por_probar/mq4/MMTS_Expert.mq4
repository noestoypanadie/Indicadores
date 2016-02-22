//+------------------------------------------------------------------+
//|                                                  MMTS_Expert.mq4 |
//|                      Copyright © 2006, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern int Order_Hour=13;   
extern int Entry_Pips=4;
extern int CloseOrdersHour=20;
extern bool ShowComments=true;
extern double Lots = 1.0;
extern double StopLoss = 30;
extern double TakeProfit = 150; 
extern double TrailingStop = 0;
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
int cnt,OpenSells,OpenSellStops,OpenBuys,OpenBuyStops,ticket;

if (Hour() >= Order_Hour)
{
for(cnt=0;cnt<OrdersTotal();cnt++)
{
// check selection result because order may be closed or deleted at this time!
OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
if (OrderSymbol()==Symbol())//check for opened position and symbol
   {
   if (OrderType()==OP_SELL) {OpenSells++;}
   if (OrderType()==OP_SELLSTOP) {OpenSellStops++;}
   if (OrderType()==OP_BUY) {OpenBuys++;}
   if (OrderType()==OP_BUYSTOP) {OpenBuyStops++;}
   }
}
}

if (Hour() >= Order_Hour)
{
for(cnt=0;cnt<OrdersTotal();cnt++)
{
// check selection result because order may be closed or deleted at this time!
OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
if (OrderSymbol()==Symbol())//check for opened position and symbol
   {
   if (OrderType()==OP_SELLSTOP && OpenBuys>0) OrderDelete( OrderTicket());   
   if (OrderType()==OP_BUYSTOP && OpenSells>0) OrderDelete( OrderTicket());
   if (Hour() >= CloseOrdersHour && Minute() >= 45 && OrderType()==OP_SELL) OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet);   
   if (Hour() >= CloseOrdersHour && Minute() >= 45 && OrderType()==OP_BUY) OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet);  
   }
}
}


double spread=(Ask-Bid);//+Entry_Pips);
double buyPrice=0.0;
double sellPrice=0.0;
double high=0.0,low=0.0,newsSpread=0.0;
datetime AlertTime;
//if (High - Low > 50 Point) return;
 
if (Hour()==Order_Hour && Minute() < 15)
   {
   if (High[1] > High[2])
      {
      buyPrice=High[1] + spread + Entry_Pips*Point;
      high=High[1];
      }
   else//if (High[1] < High[2])
      {
      buyPrice=High[2] + spread + Entry_Pips*Point;
      high=High[2];
      }
   if (Low[1] < Low[2])
      {
      sellPrice=Low[1] - Entry_Pips*Point;
      low=Low[1];
      }
   else//if (Low[1] > Low[2])
      {
      sellPrice=Low[2] - Entry_Pips*Point;
      low=Low[2];
      }     
   }

/*
if (newsSpread > 0.0050) return;
{
if (CurTime() > AlertTime) 
   {
   Alert("Meta Alert!!! "," newsSpread >.0014 = ",newsSpread);
   AlertTime=CurTime() + (Period() - MathMod(Minute(), Period()))*60; 
   }  
}
*/
       
buyPrice  = NormalizeDouble(buyPrice,4);
sellPrice = NormalizeDouble(sellPrice,4);

//newsSpread=(high-low)/spread;//*10000;

if (Hour()==Order_Hour && Minute() < 15 && newsSpread < 50)
{
	if (OpenSellStops < 1 && OpenSells < 1 && OpenBuys < 1)  
       {
        ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,sellPrice,3,sellPrice+StopLoss*Point,sellPrice-TakeProfit*Point,"MMTS Sell Stop Order ",16386,0,Red);
        if(ticket>0)
          {
           if (OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELLSTOP order opened : ",OrderOpenPrice());
          }
        else Print("Error opening SELLSTOP order  16386 : ",GetLastError());
        //ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,"MMTS Market Sell Order ",16386,0,Red); 
        return(0); 
       }	       
       
	if (OpenBuyStops < 1 && OpenBuys < 1 && OpenSells < 1)  
       {
        ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,buyPrice,3,buyPrice-StopLoss*Point,buyPrice+TakeProfit*Point,"MMTS Buy Stop Order ",16384,0,White);
        if(ticket>0)
          {
           if (OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUYSTOP order opened : ",OrderOpenPrice());
          }
        else Print("Error opening BUYSTOP order  16385 : ",GetLastError());
        //ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,"MMTS Market Buy Order ",16385,0,White); 
        return(0); 
       }	
}	

if (ShowComments==True)         
{
Comment("buyPrice : ",buyPrice, " sellPrice : ",sellPrice," Hour : ",Hour()," newsSpread = ",newsSpread,"\n",
"High = ",high," Low = ",low);
}
//----
   return(0);
  }
//+------------------------------------------------------------------+