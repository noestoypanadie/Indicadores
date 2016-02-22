//+------------------------------------------------------------------+
//|                                                                  |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"

//---- input parameters
extern int       Stoploss=10;
extern int       Takeprofit=5;
extern int       Slip=5;

double Opentrades,orders,first,mode,cnt,Ilo,sym,b;

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

   Opentrades=0;
   for (cnt=0;cnt<OrdersTotal();cnt++) 
   {
      if ( OrderSelect (cnt, SELECT_BY_POS) == false )  continue;
      if ( OrderSymbol()==Symbol()) Opentrades=Opentrades+1;
   }


   if (Opentrades==0)  //and iATR(5,2)<StopLoss*Point 
   
     {
   
   if ( iMA(Symbol(),0,3,0,MODE_EMA,PRICE_CLOSE,1)>iMA(Symbol(),0,18,0,MODE_EMA,PRICE_CLOSE,1) && 
        iMA(Symbol(),0,3,0,MODE_EMA,PRICE_CLOSE,2)<=iMA(Symbol(),0,18,0,MODE_EMA,PRICE_CLOSE,2) 
        )
         {
      
         if (iOsMA (Symbol(), 0, 12, 26, 9, PRICE_CLOSE, 1)>0)
            {
            if (iRSI(Symbol(), 0, 14, PRICE_CLOSE, 1)>50)
            {
            }
         OrderSend(Symbol(),OP_BUY,0.1,Ask,Slip,Ask-Stoploss*Point,Ask+Takeprofit*Point,"My order #2",16334,0,Green);
         
            }
         }
      

   if ( iMA(Symbol(),0,3,0,MODE_EMA,PRICE_CLOSE,1)<iMA(Symbol(),0,18,0,MODE_EMA,PRICE_CLOSE,1) && 
        iMA(Symbol(),0,3,0,MODE_EMA,PRICE_CLOSE,2)>=iMA(Symbol(),0,18,0,MODE_EMA,PRICE_CLOSE,2) 
        )
         {
      
         if (iOsMA (Symbol(), 0, 12, 26, 9, PRICE_CLOSE, 1)<0)
            {
            if (iRSI(Symbol(), 0, 14, PRICE_CLOSE, 1)<50)
            {
            }
         OrderSend(Symbol(),OP_SELL,0.1,Bid,Slip,Bid+Stoploss*Point,Bid-Takeprofit*Point,"My order #2",16334,0,Green);
         
            }
         }
      
      }
   
//----
   return(0);
  }
//+------------------------------------------------------------------+