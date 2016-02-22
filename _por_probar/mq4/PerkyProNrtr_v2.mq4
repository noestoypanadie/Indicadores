//+------------------------------------------------------------------+
//|                                                     perky.mq4    |
//|                      perky Aint no turkey (most of the time)     |
//|                                                                  |
//| 10/182006 Robert Hill                                            |
//|            Cleaned up code for easier modification and speed     |
//|            by making more modular and calling custom indicators  |
//|            only where needed.                                    |
//+------------------------------------------------------------------+

// Version 1.0 
extern int UseNRTR = 0;
extern double Lots=1;
extern int StopLoss = 40;
extern int TrailingStop = 25;
extern int ProfitTarget = 999;
extern int SignalCandle=1;
extern int Slippage = 3;
extern double BIG_JUMP=30.0;       // Check for too-big candlesticks (avoid them)
extern double DOUBLE_JUMP=55.0;
   // Check for pairs of big candlesticks
   extern  int ADXbarrier=24;    
   double proup,prodown,NRTRup,NRTRdown;
    bool trade=false;
    bool TradeAllowed=false;
   
int init() 
{
//  if (Period() != PERIOD_M30)
//  {
   // Alert("Please run on M30 chart");
//  }
}

int GetTotalTrades()
{
  int NumTrades = 0;
  
  for (int i = 0; i < OrdersTotal(); i++)
  {
    OrderSelect(i, SELECT_BY_POS);
 
    if (OrderSymbol() == Symbol())
    {
      if (OrderType() == OP_BUY ) NumTrades++;
      if (OrderType() == OP_SELL ) NumTrades++;
    }
  }
  return (NumTrades);
}

void HandleOpenTrades()
  {
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
 
      if (OrderSymbol() == Symbol())
      {
        if (OrderType() == OP_BUY )
        {
          if( BuyExitSignal())
          {      
             OrderClose(OrderTicket(), OrderLots(), Bid, Slippage);
             return(0);
          }
          else
          {
            if (TrailingStop > 0)
            {
	           if (Ask - OrderOpenPrice() > TrailingStop * Point)
  	  	        {
		          if (OrderStopLoss() < Ask - TrailingStop * Point)
		          {
	               OrderModify(OrderTicket(), OrderOpenPrice(), Ask - TrailingStop * Point, Ask + ProfitTarget * Point, 0);
                  return(0);
                }
              }
            }
          }
        }
        if (OrderType() == OP_SELL )
        {
          if( SellExitSignal())
          {
            OrderClose(OrderTicket(), OrderLots(), Ask, Slippage);
            return(0);
          }
          else
          {
            if (TrailingStop > 0)
            {
              if (OrderOpenPrice() - Bid > TrailingStop * Point)
              {
                if (OrderStopLoss() > Bid + TrailingStop * Point)
                {
                  OrderModify(OrderTicket(), OrderOpenPrice(), Bid + TrailingStop * Point, Bid - ProfitTarget * Point, 0);
                  return(0);
                }
	  	        }
            }
          }
          
        }    
      }
   }
 }
 
bool BuySignal()
{
     proup  =iCustom(Symbol(),Period(),"Prosource",0,SignalCandle); //up
     
     if (UseNRTR == 1)
     {
       NRTRup  =iCustom(Symbol(),Period(),"NRTR_color_line",0,SignalCandle); //up
     }
     else
     { 
       NRTRup  =1; //up
     } 
     if (proup<9999 && NRTRup>0) return(true);
     return(false);
}


bool SellSignal()
{
     prodown=iCustom(Symbol(),Period(),"Prosource",1,SignalCandle);//down 
     
     if (UseNRTR == 1)
     {
       NRTRdown=iCustom(Symbol(),Period(),"NRTR_color_line",1,SignalCandle);//down
     }
     else
     { 
       NRTRdown=1;//down
     } 
     if (prodown<9999 && NRTRdown>0) return (true);
     return (false);
 }

bool BuyExitSignal()
{
     proup  =iCustom(Symbol(),Period(),"Prosource",0,SignalCandle); //up
     
     if (UseNRTR == 1)
     {
       NRTRup  =iCustom(Symbol(),Period(),"NRTR_color_line",0,SignalCandle); //up
       
       if( proup >9999 || NRTRup==0) return(true);
     }
     else
     { 
       if( proup > 9999) return(true);
     }
     return(false); 

 }

bool SellExitSignal()
{
     prodown=iCustom(Symbol(),Period(),"Prosource",1,SignalCandle);//down 
     
     if (UseNRTR == 1)
     {
       NRTRdown=iCustom(Symbol(),Period(),"NRTR_color_line",1,SignalCandle);//down
       if( prodown>9999 || NRTRdown==0) return(true);
     }
     else
     { 
          if( prodown>9999) return(true);
     }
     return(false); 
 }

 
int start()
{
   // Bar handling
datetime bartime=0;                      // used to determine when a bar has moved
int      bartick=0;                       //Tick counter
// bar counting
   if(bartime!=Time[0]) 
     {
      bartime=Time[0];
      bartick++; 
      TradeAllowed=true;
     }

// Was there a sudden jump?  Ignore it...
 // if((MathAbs(Open[1]-Open[0])/Point)>=BIG_JUMP) {
   // return(0);
 // }
 // if((MathAbs(Open[2]-Open[1])/Point)>=BIG_JUMP) {
   // return(0);
  //}
  //if((MathAbs(Open[3]-Open[2])/Point)>=BIG_JUMP) {
   // return(0);
 // }
 // if((MathAbs(Open[4]-Open[3])/Point)>=BIG_JUMP) {
   // return(0);
 // }
 // if((MathAbs(Open[5]-Open[4])/Point)>=BIG_JUMP) {
    //return(0);
  //}
  //if((MathAbs(Open[2]-Open[0])/Point)>=DOUBLE_JUMP) {
    //return(0);
  //}
 // if((MathAbs(Open[3]-Open[1])/Point)>=DOUBLE_JUMP) {
    //return(0);
 // }
  //if((MathAbs(Open[4]-Open[2])/Point)>=DOUBLE_JUMP) {
   // return(0);
 // }
 // if((MathAbs(Open[5]-Open[3])/Point)>=DOUBLE_JUMP) {
   // return(0);
 // }
   
  
  if (GetTotalTrades() > 0) HandleOpenTrades();
  
  if (GetTotalTrades() == 0) 
  {
      if( TradeAllowed && BuySignal())  
      {
      OrderSend(Symbol(), OP_BUY, Lots, Ask, 2, Ask - StopLoss * Point, Ask + ProfitTarget * Point, 0,LimeGreen); 
      TradeAllowed=false;
      return(0);
      }
     
      if(TradeAllowed && SellSignal()) 
      {
      OrderSend(Symbol(), OP_SELL, Lots, Bid, 2, Bid + StopLoss * Point, Bid - ProfitTarget * Point, 0,Red); 
      TradeAllowed=false;
      return(0);
      }
  }
  
  return(0);
}
//+------------------------------------------------------------------+