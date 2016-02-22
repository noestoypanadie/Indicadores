/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^66
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/


//+------------------------------------------------------------------+
//|                                       Cross Angry Miserable .mq4 |
//|                                      Copyright © 2006, Don Perry |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Don Perry"
#property link      "http://www.metaquotes.net"

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
 
double nus1;
double pus1; 
 
double nus2;
double pus2; 
bool crossedUp=false;
 double PipsCaptured;
double LastPrice;
int SBStat=0;
extern int FromHourTrade=6;
extern int ToHourTrade=21;
double RSI,RSI2;
bool Firstry=true;
extern int FastPeriod=18;
extern bool UseHourTrade= true;
extern int SlowPeriod=60;
extern int SL=23;
extern int TakeProfit=100;
extern bool useTS=false;
extern int TrailingStop=18;

extern double Lots=1;
extern int incTp=0;
extern bool USE_La_Nina=true;
extern bool Mild_Nina=true;
extern double mild=0.7;
int bar;
double ten, elev;
 double boot;
 double tradeVal;
 double mint;
 double kloop;
 double RSi,RSi2;
 bool buying2,selling2;
extern int Risk=10;
extern bool MM = true;
extern bool Use_El_Nino=true;
extern bool Mild_nino=true;

extern int MaxTrades=2;
int ticket [];
 double RSITrend=0;
extern int Selectivity=14;
extern int Adx1 = 14;
extern int Adx2 = 14;
bool buying=false,selling=false;
int iTick=0;
double barsAVG=0;
int total;
int cnt;
int index;
bool sellable;
bool buyable;
bool lastbarTraded=false;
string lasttrade="";
double low,high;
double lastPrice;
int init()
  { 
  
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
   
if(useTS){Trailingstop();}
  bar=getPeriod();
   ten=Year();
   
   //we first trail stops
   
  if(checkParams()!=0)
  {
  
  if( UseHourTrade ){
      if((( FromHourTrade <= ToHourTrade ) && ( Hour() < FromHourTrade || Hour() > ToHourTrade ))
         || // Allow for Overnight Trading
         (( FromHourTrade >  ToHourTrade ) && ( Hour() < FromHourTrade && Hour() > ToHourTrade ))
         ||Day()==5
        ) {
         return(0);
      }

   } //Trailingstop();
  elev=Month();
    CheckEquity();
  if(init2()==0)
   {
 

//EMAS1 =iCustom(Symbol(),PERIOD_M30,"KAMA#3",SlowPeriod,0,0);// iMA(NULL,0,SlowPeriod,0,MA_method,PRICE_MEDIAN,0); //slow
//EMAF1 =iCustom(Symbol(),PERIOD_M30,"KAMA#3",FastPeriod,0,0);// iMA(NULL,0,SlowPeriod,0,MA_method,PRICE_MEDIAN,0); //slow

pus1 = iADX(NULL,0,Adx1,PRICE_TYPICAL,MODE_PLUSDI,0); //fast
nus1 =  iADX(NULL,0,Adx2,PRICE_TYPICAL,MODE_MINUSDI,0);  //slow

pus2 = iADX(NULL,0,Adx1,PRICE_TYPICAL,MODE_PLUSDI,1); //fast
nus2 =  iADX(NULL,0,Adx2,PRICE_TYPICAL,MODE_MINUSDI,1);  //slow

bool greater = (pus1>pus2);
bool lesser = (pus1<pus2);

double RSI= iRSI(NULL,0,Selectivity,PRICE_TYPICAL,0);
//RSITrend =  iRSI(NULL,PERIOD_H4,Selectivity,PRICE_WEIGHTED,0);

Lots = LotSize();
 

bool buyable=(RSI>55&&(pus1>nus1)&&(MathAbs(pus1-nus1>6))&&greater);
bool sellable=(RSI<45&&(nus1>pus1)&&(MathAbs(nus1-pus1>6))&&lesser);



 //if(OrdersTotal()<MaxTrades)

//----------------buy---------------------
 if(buyable&&!buying)
 {
 
             
 iTick=OrderSend(Symbol(),OP_BUY,Lots,Ask,2,Ask-(SL*Point),Ask+(TakeProfit*Point),"ADX Buy",16384, Minute()-100 ,Lime);
 
//+(5*Point)

   
 lasttrade="buy";
 lastbarTraded=true;
 
 LastPrice=Ask;
   buying=true;
   selling=false;
}
//-------------------------------------

//---------------sell----------------------
 if(sellable&&!selling)
 {
      
               
    iTick=OrderSend(Symbol(),OP_SELL,Lots,Bid,2,Bid+(SL*Point),Bid-(TakeProfit*Point),"ADX Sell",16384,Minute()-100,Orange);

      
        lasttrade="sell";
 lastbarTraded=true;
 
 LastPrice=Bid;
  buying=false;
   selling=true;
}
//-------------------------------------
}
}

//Print(difference2+":"+difference);



 
  }
//+------------------------------------------------------------------+

double LotSize()
{ if (MM==true)
{
     double lotMM = MathCeil(AccountFreeMargin() * Risk / 10000) / 10;
	  if (lotMM < 0.1) lotMM = Lots;
	  if (lotMM > 1.0) lotMM = MathCeil(lotMM);
	  if  (lotMM > 100) lotMM = 100;
	  return (lotMM);
}
else
{
return(Lots);
}
}
int checkParams()
{if(DayOfWeek()>=5 && Hour()>=21){
         
         return(0);
      }
      
      
  if(Bars<100){
      Print("bars less than 100");
      return(0);
   }
   if(SL<4){
      Print("StopLoss less than 10");
     // return(0);
   }
   if(TakeProfit<4){
      Print("TakeProfit less than 10");
      return(0);
   }
   if(TrailingStop<10){
      Print("StopLoss less than 10");
      return(0);
   }
 return(1);
  

}

 int CheckEquity()
 {double pcnt = 100+(AccountEquity()-AccountBalance())/AccountBalance()*100;
 //Print("Account equity = ",AccountEquity());
//Print("Account balance = ",AccountBalance());
//Print("EQ%= ",pcnt);
 if(false)// pcnt>180)
 { 

 total=OrdersTotal();
 for(cnt=0;cnt<=total;cnt++)
     {OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
     OrderClose(OrderTicket(),OrderLots(),Ask,2,White);
     
     }
    // Print("ALL ORDERS CLOSE-->Locked in EQUITY Profit");
 }
 return(0);
 }
 
 int getPeriod()
 {
 switch(Period())
 {
  case PERIOD_M5:
      return (8);
   break;
 case PERIOD_M15:
      return (10);
   break;
   case PERIOD_M30:
      return (14);
   break;
    case PERIOD_H1:
      return (20);
   break;
   default:
      Print("NOT An Acceptable Timeframe");
      return (0);
      break;

   
 }
 }
int init2()
{
   boot = ten;
   tradeVal=elev;
   mint = 20012+4;
   kloop = 9;
   
   
/* 
   if(boot>=mint )
   if(tradeVal>=kloop)
   {
    return(1);
    }
    if(boot>mint)
    {
   return(1);
    }
    
    else{*/
    return (0);



}

void Trailingstop()
{
total  = OrdersTotal();
 
   
   for(cnt=0;cnt<total;cnt++)
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
    
 
   return(0);
}
 