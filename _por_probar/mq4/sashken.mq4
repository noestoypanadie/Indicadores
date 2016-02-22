//+------------------------------------------------------------------+
//|                                                 sashken.mq4      |
//|                                             sashken@mail.ru      |
//|                    –” ¿Ã» Õ≈ “–Œ√¿“‹                             |
//+------------------------------------------------------------------+
#property copyright "sashken"
#property link      ""

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
//int start()
 // {
//---- 
   
//----
  // return(0);
 // }
//+------------------------------------------------------------------+
extern double Lots=4;
extern double StopLoss=100;
extern double TakeProfit=140;
extern double MaximumRisk=0.4;
extern int RSI1=7;
extern int RSI2=20;
extern int slip=5;
extern int popitka=5;
extern int bar1=1;
extern int bar0=0;
extern int m2=0;
extern int m1=2;


int start()
{
   double MA1, MA2,MA3,MA4;
   int total,ticket,cnt;

int
         err         = 0,
         c           = 0;
   
//initial data checks
  if(Bars<10)
  {
   Print("Bars less than 10");
   return(0); 
  } 
  if(TakeProfit<15)
   {
    Print("Take Profit < 15");
   } 
//to simplify coding
  MA1=iMA(NULL,0,RSI1,0,m1,bar0,1);
  MA2=iMA(NULL,0,RSI1,0,m1,bar0,2);
  MA3=iMA(NULL,0,RSI2,0,m2,bar1,1);
  MA4=iMA(NULL,0,RSI2,0,m2,bar1,2);
  
//identifying open orders
  total=OrdersTotal();
  if(total<1)
  {
   if(AccountFreeMargin()<(1000*LotSize()))
   {
    Print("No Money. KOLYA MORJOV... FreeMargin=",AccountFreeMargin());
    return(0);
   }
   
//check for long possibility

  if(MA1 < MA3 && MA2 > MA4)
   {
    Alert("Long ",Symbol());
    {
     for(c=0;c<popitka;c++)
      {
         ticket=OrderSend(Symbol(),OP_BUY,LotSize(),Ask,slip,0,Ask+TakeProfit*Point,0,0,Green);
         err=GetLastError();
         if(err==0)
         { 
            break;
         }
         else
         {
            if(err==4 || err==137 ||err==146 || err==136) //Busy errors
            {
               Sleep(5000);
               continue;
            }
            else //normal error
            {
               break;
            }  
         }
      }   
     //ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,Ask+TakeProfit*Point,0,0,Green);
     //ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Bid-Point*StopLoss,Ask+TakeProfit*Point,0,0,Green);
     if(ticket>0)
     Print("Buying: ", Symbol());
     if (OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print
("Buy Order Opened:", OrderOpenPrice());
    }
    return(0);
   }

//check for short position
  if(MA1 > MA3 && MA2 < MA4)
  {
   Alert("Short ",Symbol());
   {
         for(c=0;c<popitka;c++)
      {
         ticket=OrderSend(Symbol(),OP_SELL,LotSize(),Bid,slip,0,Bid-TakeProfit*Point,0,0,Red);
         err=GetLastError();
         if(err==0)
         { 
            break;
         }
         else
         {
            if(err==4 || err==137 ||err==146 || err==136) //Busy errors
            {
               Sleep(5000);
               continue;
            }
            else //normal error
            {
               break;
            }  
         }
      }   
    //ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,Bid-TakeProfit*Point,0,0,Red);
    //ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Ask+Point*StopLoss,Bid-TakeProfit*Point,0,0,Red);
    if(ticket>0)
    Print("Selling: ", Symbol());
    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("Sell Order Opened:",OrderOpenPrice());
   }
   return(0);
  }
  return(0);
  
//for control of open orders
  for(cnt=0;cnt<total;cnt++)
  {
   OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
   if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())
   {
    if(OrderType()==OP_BUY)
    {
//long positions
  if(MA1 > MA3 && MA2 < MA4)
  {
   OrderClose(OrderTicket(),OrderLots(),Bid,slip,Blue);
   return(0);
  }
else
//short positions
  {
   if(MA1 < MA3 && MA2 < MA4)
   {
    OrderClose(OrderTicket(),OrderLots(),Ask,slip,Violet);
    return(0);
   } 
  }
 }
 }
 }
 }
 return(0);
 }
 
 
double LotSize()
{
    double     lot_min        = MarketInfo( Symbol(), MODE_MINLOT  );
    double     lot_max        = MarketInfo( Symbol(), MODE_MAXLOT  );
    double     lot_step       = MarketInfo( Symbol(), MODE_LOTSTEP );
    double     freemargin     = AccountFreeMargin();
    int        leverage       = AccountLeverage();
    int        lotsize        = MarketInfo( Symbol(), MODE_LOTSIZE );
 
    if( lot_min < 0 || lot_max <= 0.0 || lot_step <= 0.0 || lotsize <= 0 ) 
    {
        Print( "LotSize: invalid MarketInfo() results [", lot_min, ",", lot_max, ",", lot_step, ",", lotsize, "]" );
        return(-1);
    }
    if( leverage <= 0 )
    {
        Print( "LotSize: invalid AccountLeverage() [", leverage, "]" );
        return(-1);
    }
 
    double lot = NormalizeDouble( freemargin * MaximumRisk / leverage / 10.0, 2 );
 
    lot = NormalizeDouble( lot / lot_step, 0 ) * lot_step;
    if ( lot < lot_min ) lot = lot_min;
    if ( lot > lot_max ) lot = lot_max;
 
    double needmargin = NormalizeDouble( lotsize / leverage * Ask * lot, 2 );
 
    if ( freemargin < needmargin )
    {
        Print( "LotSize: We have no money. Free Margin = ", freemargin );
        return(-1);
    }
 
    return(lot);
}