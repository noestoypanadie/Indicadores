//+------------------------------------------------------------------+
//|                                               Support&Resist.mq4 |
//|                                          Don Perry, Gene Katsuro |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Don Perry, Gene Katsuro"
#property link      "http://www.metaquotes.net"

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
extern int period=55;
extern int SL = 40;
extern int TakeProfit = 50;
extern double Lots=1;
extern int risk = 5;
extern int incTp=0;
extern int TrailingStop = 18;
double PipsCaptured;
extern double expiryhour=1;
datetime date;
extern double variance=5;
extern int maxtrades=15;
extern int Selectivity=14;
extern bool MM = true;
bool SellApp=true;
bool BuyApp=true;
int digit;
bool selling,buying=false;
double RSi,RSi2;
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
  if(MM==true) Lots = LotSize();
   //   Print(AVGlo,AVGhi); 
   
   RSi= iRSI(NULL,0 ,Selectivity,PRICE_WEIGHTED,0);
      RSi2= iRSI(NULL,0 ,Selectivity,PRICE_WEIGHTED,1);
       
       
      if(RSi>55&&RSi2<=45&&!buying&&maxtrades>OrdersTotal())
      {
      //buy
      OrderSend(Symbol(),OP_BUY,Lots,Ask,2,Ask-(SL*Point),Ask+(TakeProfit*Point),"RSI Sell",16384, Minute()-100 ,Lime);
      buying=true;
      selling = false;
      }

  if(RSi<45&&RSi2>=50&&! selling&&maxtrades>OrdersTotal())
      {
      //buy
    OrderSend(Symbol(),OP_SELL,Lots,Bid,2,Bid+(SL*Point),Bid-(TakeProfit*Point),"RSI Sell",16384,Minute()-100,Orange);
  buying=false;
      selling = true;
      }
      
      
Print("Orders total"+OrdersTotal());

  int total  = OrdersTotal();
 
   
   for( int  cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY)   // long position is opened
           {
            // check for trailing stop
            if(TrailingStop>0)  
              {                 
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                     if(OrderTakeProfit()-Ask<incTp*Point)
                     {
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit()+incTp*Point,0,Pink);
                   // Print("-=--=--=--=--=--=--"+"is the ask, TP="+OrderTakeProfit());
                     }
                     if(OrderOpenPrice()<Ask-(10*Point)&&OrderStopLoss()<Ask)
                     {OrderModify(OrderTicket(),OrderOpenPrice(),Ask+(incTp*Point),OrderTakeProfit(),0,Pink);
                     }
                     return(0);
                    }
                 }
              }
           }
         else // go to short position
           {
            // check for trailing stop
            if(TrailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit()-incTp*Point,0,Red);
                    if(Bid-OrderTakeProfit()<incTp*Point)
                     {
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit()-incTp*Point,0,Pink);
                   //  Print("-=--=--=--=--=--=--"+Bid+"is the ask, TP="+OrderTakeProfit());
                     }
                      if(OrderOpenPrice()>Ask+(10*Point)&&OrderStopLoss()>Ask)
                     {OrderModify(OrderTicket(),OrderOpenPrice(),Bid-incTp*Point,OrderTakeProfit(),0,Pink);
                     }
                     
                     return(0);
                    }
                 }
              }
           }
        }
     }
     //Print("total Pips= ",PipsCaptured);
 
   return(0);
  }
//+------------------------------------------------------------------+
double LotSize()
{
     double lotMM = MathCeil(AccountFreeMargin() * risk / 10000) / 10;
	  if (lotMM < 0.1) lotMM = Lots;
	  if (lotMM > 1.0) lotMM = MathCeil(lotMM);
	  if  (lotMM > 100) lotMM = 100;
	  return (lotMM);
}