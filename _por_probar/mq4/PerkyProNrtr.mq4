//+------------------------------------------------------------------+
//|                                                     perky.mq4    |
//|                      perky Aint no turkey (most of the time)     |
//+------------------------------------------------------------------+

// Version 1.0 
extern double Lots=1;
extern int StopLoss = 40;
extern int TrailingStop = 0;
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
  if (Period() != PERIOD_M30)
  {
   // Alert("Please run on M30 chart");
  }
}
   // Bar handling
datetime bartime=0;                      // used to determine when a bar has moved
int      bartick=0;                       //Tick counter

int start()
{
// bar counting
   if(bartime!=Time[0]) 
     {
      bartime=Time[0];
      bartick++; 
      TradeAllowed=true;
     }
  
    
      proup  =iCustom(Symbol(),Period(),"Prosource",0,SignalCandle); //up
      prodown=iCustom(Symbol(),Period(),"Prosource",1,SignalCandle);//down 
     NRTRup  =iCustom(Symbol(),Period(),"NRTR_color_line",0,SignalCandle); //up
     NRTRdown=iCustom(Symbol(),Period(),"NRTR_color_line",1,SignalCandle);//down 
    

Comment ("UP ",NRTRup,"DN ",NRTRdown,"Proroup ",proup,"Prodown ",prodown);

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
   
  int NumTrades = 0;
  
  for (int i = 0; i < OrdersTotal(); i++)
  {
    OrderSelect(i, SELECT_BY_POS);
 
    if (OrderSymbol() == Symbol())
    {
      if (OrderType() == OP_BUY )
      {
          if( proup >9999 || NRTRup==0)      
             OrderClose(OrderTicket(), 1, Bid, Slippage);        return(0);
      }
     if (OrderType() == OP_SELL )
      {
          if( prodown>9999 || NRTRdown==0)
      OrderClose(OrderTicket(), 1, Ask, Slippage);
      }    
      NumTrades++;
    }
  }
  
  if (NumTrades == 0) 
  {
       
  
      if( TradeAllowed && proup<9999 && NRTRup>0)  
      {
      OrderSend(Symbol(), OP_BUY, Lots, Ask, 2, Ask - StopLoss * Point, Ask + ProfitTarget * Point, 0,LimeGreen); 
      trade=false;
      return(0);
    }
     
       

      if(TradeAllowed && prodown<9999 && NRTRdown>0) 
      {
      OrderSend(Symbol(), OP_SELL, Lots, Bid, 2, Bid + StopLoss * Point, Bid - ProfitTarget * Point, 0,Red); 
      trade=false;
      return(0);
    }
  }
  
  if (TrailingStop > 0)
  {
    for (i = 0; i < OrdersTotal(); i++)
    {
    
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);

      if ((OrderSymbol() == Symbol()) && (OrderType() == OP_BUY) )
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

      if ((OrderSymbol() == Symbol()) && (OrderType() == OP_SELL))
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

  return(0);
}
//+------------------------------------------------------------------+