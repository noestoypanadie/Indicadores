//+------------------------------------------------------------------+
//|                                    MA envelope exhausting system |
//+------------------------------------------------------------------+
#property copyright "TraderSeven"
//----------------------- USER INPUT
extern double MA_length = 10;	 
extern double slip = 0;
extern double Lots = 1;
extern double TakeProfit = 30;
extern double Stoploss = 2000;
//extern double TrailingStop = 5;
extern double PipStep = 30;
   //----------------------- SETUP VARS
double PriceTarget;
double AveragePrice;
double LastPrice;
int flag;
//----------------------- MAIN PROGRAM LOOP
int start()
{
   int cnt=0, total;
   double Stopper=0;  
   total=OrdersTotal();
   OrderSelect(total, SELECT_BY_POS, MODE_TRADES);
   LastPrice=OrderOpenPrice();
   OrderSelect(total, SELECT_BY_POS, MODE_TRADES); 
   flag=0;
   if(iMA(NULL,0,MA_length,0,MODE_SMA,PRICE_OPEN,0)*1.02<Bid && (Bid>=(LastPrice+(PipStep*Point)))||(total<1)) // Go SHORT -> Only sell if >= 30 pips above previous position entry	 
     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,slip,Bid+(Stoploss*Point),Bid-(TakeProfit*Point),0,0,HotPink);
      if(total>0)flag=1;
     }   
   if(iMA(NULL,0,MA_length,0,MODE_SMA,PRICE_OPEN,0)*0.98>Ask && (Ask<=(LastPrice-(PipStep*Point)))||total<1) // Go LONG -> Only buy if >= 30 pips below previous position entry	 
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,slip,Ask-(Stoploss*Point),Ask+(TakeProfit*Point),0,0,Lime);
      if(total>0)flag=1;
     }
//----------------------- CALCULATE AVERAGE OPENING PRICE
   total=OrdersTotal();
   AveragePrice=0;
   for(cnt=0;cnt<total;cnt++)
      {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      AveragePrice=AveragePrice+OrderOpenPrice();
      }
   AveragePrice=AveragePrice/total;
//----------------------- RECALCULATE STOPLOSS & PROFIT TARGET BASED ON AVERAGE OPENING PRICE
  OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
  if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())  
    {
    flag=1;
    if(OrderType()==OP_BUY) // Calculate profit/stop target for long 
      {
      PriceTarget=AveragePrice+(TakeProfit*Point);
      Stopper=AveragePrice-(Stoploss*Point); 
      }
     else // Calculate profit/stop target for short
      {
      PriceTarget=AveragePrice-(TakeProfit*Point);
      Stopper=AveragePrice+(Stoploss*Point);   
      }
    }
//----------------------- IF NEEDED CHANGE ALL OPEN ORDERS TO NEWLY CALCULATED PROFIT TARGET    
  if(flag==1)// check if average has really changed
    {   
    for(cnt=0;cnt<total;cnt++)
       {
       PriceTarget=total;
       OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);            
       OrderModify(OrderTicket(),0,Stopper,PriceTarget,0,Yellow);// set all positions to averaged levels
       }
    }
}

