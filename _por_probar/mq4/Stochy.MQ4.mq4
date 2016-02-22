//+------------------------------------------------------------------+
//|                                                  Stoch.mq4     |
//|                         For Eur/Usd 1H
//|                                   Copyright © 2005, Jacob Yego |
//|                                       http://PointForex.com    |                                        
//+------------------------------------------------------------------+

extern double TakeProfit = 250;
extern double Lots = 1.0;
extern double TrailingStop = 60;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
   
   double EMA1;
   double EMA2;
   double EMA3;
   double EMA4;
   double ATR;
   double RSI;
   double CCI;
   double Stoch;
   double Stochsig;
   int cnt,ticket,tt=0, total;
// check TakeProfit on a chart of less than 200 bars
   if(Bars<200)
     {
      Print("bars less than 200");
      return(0);  
     }
   if(TakeProfit<10)
     {
      Print("TakeProfit less than 10");
      return(0);  // check TakeProfit
     }
     
// data in internal variables for access speed
   
   EMA1=iMA(NULL,0,8,0,MODE_EMA,PRICE_CLOSE,0);
   EMA2=iMA(NULL,0,100,0,MODE_EMA,PRICE_CLOSE,0);
   EMA3=iMA(NULL,0,8,0,MODE_EMA,PRICE_CLOSE,1);
   EMA4=iMA(NULL,0,100,0,MODE_EMA,PRICE_CLOSE,1);

   ATR=iATR(NULL,0,20,0);
   RSI=iRSI(NULL,0,14,PRICE_CLOSE,0);
   CCI= iCCI(NULL,0,14,PRICE_CLOSE,0);
   Stoch=iStochastic(NULL,0,14,3,3,MODE_SMA,0,MODE_MAIN,0);
   Stochsig=iStochastic(NULL,0,14,3,3,MODE_SMA,0,MODE_SIGNAL,0);
   
// to ensure that only one trade per pair is entered to avoid multiplicity
   total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
{
OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
if (OrderSymbol()==Symbol()) tt++;
} 

{
if((total < 2) && tt==0)  // you can change total to whatever 
                          //number of pairs you want to trade
     {
      // no opened orders identified
      if(AccountFreeMargin()<(1000*Lots))
        {
         Print("We have no money. Free Margin = ", AccountFreeMargin());
         return(0);  
        }
      // long position (BUY) possibility

        if( EMA1 > EMA2 && EMA3 < EMA4 && RSI > 50.0 && CCI>0 && Stoch>Stochsig)
        {Alert( "Buy Now");
       }
        {
         ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-2*ATR,Ask+TakeProfit*Point,"Stochy",77777,0,Green);
         if(ticket>0)
           {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
           }
         else Print("Error opening BUY order : ",GetLastError()); 
         return(0); 
        }
      // Short position (SELL) possibility
       if(EMA2 > EMA1 && EMA4 < EMA3 && RSI<50 && CCI<0 && Stoch<Stochsig)
      
       {Alert( "Sell Now");
       }
        {
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+2*ATR,Bid-TakeProfit*Point,"Stochy",77777,0,Red);
         if(ticket>0)
           {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
           }
         else Print("Error opening SELL order : ",GetLastError()); 
         return(0); 
        }
      return(0);
     }
     
   //Exit Strategy   
   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL &&   // check for opened position 
         OrderSymbol()==Symbol())  // check for symbol
        {
         if(OrderType()==OP_BUY)   // long position is opened
           {
            // should it be closed?
            
               if (RSI<30 && EMA2 > EMA1 && EMA4 < EMA3 && CCI<0 && Stoch<Stochsig )
                {
                 OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // close position
                 return(0); // exit
                }
            //  Trailing stop Check
            if(TrailingStop>0)  
              {                 
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                     return(0);
                    }
                 }
              }
           }
         }
         else // Move to short position
           {
            // should it be closed?
            
               if (RSI>70 && EMA1 > EMA2 && EMA3 < EMA4 && CCI>0 && Stoch>Stochsig)
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close position
               return(0); // exit
              }
            // trailing stop check
            if(TrailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
                     return(0);
                    }
                 }
              }
           }
        }
     }
   return(0);
  }
// the end.