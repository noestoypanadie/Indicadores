//+------------------------------------------------------------------+
//|                                               RangeLeaderBar.mq4 |
//|                 Copyright © 2006, Quadrant Pacific Capital Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Quadrant Pacific Capital Corp."
#property link      ""

//+------------------------------------------------------------------+
//| External Variables                                               |
//+------------------------------------------------------------------+

extern double    Lots=1.0;
extern double    StopLoss=1000.0;
extern double    TakeProfit=1000.0;
extern double    TrailingStop=0.0;
extern double    OpenSlippage=3.0;
extern double    CloseSlippage=30.0;
extern double    ModifiedStopLoss=30.0;

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+

double State = 0;
double BarTime = 0;
double PBH = 0;
double PBL = 0;
double PBR = 0;
double PBM = 0;
double PBC = 0;
double CBH = 0;
double CBL = 0;
double CBR = 0;
double CBM = 0;
double CBC = 0;

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+

int init()
{
   return(0);
}
int start()
{
//+------------------------------------------------------------------+
//| Local variables                                                  |
//+------------------------------------------------------------------+

	//set variables previous bar info and current bar info from the previous 2 bars
	PBH=High[2];
	PBL=Low[2];
	PBR=PBH-PBL;
	PBM=(PBH+PBL)/2;
	PBC=Close[2];
	CBH=High[1];
	CBL=Low[1];
	CBR=CBH-CBL;
	CBM=(CBH+CBL)/2;
	CBC=Close[1];
	
	                                                        //Check if Buy state reached
	if(CBR>PBR && CBM>PBH) {                                //if there's already a trade open, check it
		if(OrdersTotal()>0) {                               //if it's a sell close it
			OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
			if(OrderType() == OP_SELL)   OrderClose(OrderTicket(),OrderLots(),Bid,CloseSlippage,Red);
			   else
			   return(0);
			if(OrdersTotal()==0) {                          //if theres no trades open one up
			   Alert("Buying");
			   OrderSend(Symbol(),OP_BUY,Lots,Ask,CloseSlippage,Ask-StopLoss*Point,Ask+TakeProfit*Point,"",0,0,Green);
			}
			   return(0);
		}
	
	   if (CBR>PBR && CBM<PBL) {                                     //Check if Sell state reached
         if(OrdersTotal()>0) {                                     //see if there are any open contracts       
            OrderSelect(0,SELECT_BY_POS,MODE_TRADES);              //if it's a Buy close it
            if(OrderType() == OP_BUY)    OrderClose(OrderTicket(),OrderLots(),Ask,CloseSlippage,Red);
               else
               return(0);
            if(OrdersTotal()==0) {                                  //if theres no trades open one up
               Alert("Selling");
               OrderSend(Symbol(),OP_SELL,Lots,Bid,OpenSlippage,Bid-StopLoss*Point,Bid+TakeProfit*Point,"",0,0,Green);
			   }
               return(0);
         }
      }
   }
}

