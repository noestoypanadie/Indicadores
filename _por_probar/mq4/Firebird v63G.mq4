//+-----------------------------------------------------------------------------+
//|                              Firebird v0.63 - MA envelope exhaustion system |
//+-----------------------------------------------------------------------------+
#property copyright "Copyright © 2005, TraderSeven"
#property link      "TraderSeven@gmx.net"
 
//            \\|//             +-+-+-+-+-+-+-+-+-+-+-+             \\|// 
//           ( o o )            |T|r|a|d|e|r|S|e|v|e|n|            ( o o )
//    ~~~~oOOo~(_)~oOOo~~~~     +-+-+-+-+-+-+-+-+-+-+-+     ~~~~oOOo~(_)~oOOo~~~~
// Firebird calculates a 10 day SMA and then shifts it up and down 2% to for a channel.
// For the calculation of this SMA either close (more trades) or H+L (safer trades) is used.
// When the price breaks a band a postion in the opposite of the current trend is taken.
// If the position goes against us we simply open an extra position to average.
// 50% of the trades last a day. 45% 2-6 days 5% longer or just fail.
//
//01010100 01110010 01100001 01100100 01100101 01110010 01010011 01100101 01110110 01100101 01101110 
// Credits fly to:
// Vooch for the backtesting fix.
// Hugues Du Bois for the multi currency code.
// Jackie Griffin for some debugging.
// Many people in the MT forum for testing and feedback
// Ron added [2006 03 08 (Mar 08)]
//   maxDrawDown and maxOrders to track DD and number of open orders 
//   Divergence to protect from trends
//----------------------- USER INPUT
extern int MA_length = 10;
extern int MA_timeframe = 15;              // hdb did I add this ? lol
extern int MAtype = 0;//0=close, 1=HL		 
extern double Percent = 0.05;
extern int TradeOnFriday = 1; // >0 trades on friday
extern int slip = 100;//exits only
extern double Lots = 0.1; // modified by Renato
extern int TakeProfit = 20;
extern int Stoploss = 200;// total loss on all open positions in pips // modified by Renato
//extern double TrailingStop = 5;

// Ron added for iFXAnalyzer
extern int    Fast_Period=23;
extern int    Fast_Price = PRICE_OPEN;
extern int    Slow_Period=84;
extern int    Slow_Price = PRICE_OPEN;
extern double DivergenceLimit=0.002;
extern bool Use_V63D_Divergence = false;   // 0 - Use original method for divergence, 1 - use in iFXAnalyzer

extern int PipStep = 40;//if position goes this amount of pips against you add another.
extern double IncreasementType = 0;//0=just add every PipStep,  >0 =OrdersToal()^x *Pipstep

double Stopper=0;
double KeepStopLoss=0;
double KeepAverage;
double dummy;
double spread=0;
double CurrentPipStep;
int    OrderWatcher=0;

// Ron Adds
int maxDD=0;
int maxOO=0;

extern int DVLimit = 10; // included by Renato
extern int PipsGoal = 500; // included by Renato
extern int PipsLoss = 500; // included by Renato
color clOpenBuy = DodgerBlue; // included by Renato
color clModiBuy = DodgerBlue; // included by Renato
color clCloseBuy = DodgerBlue; // included by Renato
color clOpenSell = Red; // included by Renato
color clModiSell = Red; // included by Renato
color clCloseSell = Red; // included by Renato
color clDelete = White; // included by Renato
string Name_Expert = "Firebird v63D"; // included by Renato
string NameFileSound = "expert.wav"; // included by Renato
int MODE_DIV=0; // included by Renato
int MODE_SLOPE=1; // included by Renato
int MODE_ACEL=2; // included by Renato
//extern int GMT = 2; // InterbankFX // included by Renato
extern int GMT = 0; // InterbankFX // included by Renato  Changed back to 0 by MrPip
extern int DST = 0; // 0=Standard 1=Daylight Saving // included by Renato
extern int OpeningHour = 0; // included by Renato
extern int ClosingHour = 24; // included by Renato
extern int writelog = 0;

// MrPip adds
int MagicNumber;  // Made a global variable to aid in modularizing expert code
int Direction;    //1=long, 11=avoid long, 2=short, 22=avoid short
double LastPrice;
double PriceTarget;
double AveragePrice;

int init() {
  LogWrite(Symbol()+",M"+Period());
}

//----------------------- MAIN PROGRAM LOOP
int start()
{
   int flag, retval, total, myTotal;
   
LogWrite(TimeToStr(CurTime())+" - "+"Bid="+Bid);

MagicNumber=MagicfromSymbol(); 
Comment(MagicNumber);

//SetupGlobalVariables();



//Comment("Percent=",Percent); // included by Renato

int OpeningDay;

if ( DayOfWeek()==6 && Hour()>=20 ) { Comment("weekend"); return(0); } // included by Renato
if ( !(IsTesting() || IsDemo()) ) { if (LossCheck()) { Alert("excessive loss!"); PlaySound("alert.wav"); return(0); }} // included by Renato

//Ron Adds
double diverge;
if(AccountBalance()-AccountEquity() > maxDD) maxDD=AccountBalance()-AccountEquity();
if(MyOrdersTotal()>maxOO) maxOO=OrdersTotal(); //modified by Renato
diverge=divergence(Fast_Period,Slow_Period,Fast_Price,Slow_Price,0);
Comment("maxDrawDown=",maxDD,"  maxOrdersOpen=",maxOO," Current Divergence = ",diverge);

//----------------------- CALCULATE THE NEW PIPSTEP
CurrentPipStep=PipStep;
if(IncreasementType>0)
  {
  CurrentPipStep=MathSqrt(MyOrdersTotal())*PipStep; // modified by Renato
  CurrentPipStep=MathPow(MyOrdersTotal(),IncreasementType)*PipStep; // modified by Renato
  } 
LogWrite("CurrentPipStep="+CurrentPipStep);

//----------------------- 
 Direction=0;//1=long, 11=avoid long, 2=short, 22=avoid short
if (Day()!=5 || TradeOnFriday >0)
{
   total=OrdersTotal(); 
   myTotal = MyOrdersTotal();
   LogWrite("OrdersTotal="+total);
   LogWrite("MyOrdersTotal="+myTotal);
   if(myTotal==0) OpeningDay=DayOfYear(); // modified by Renato
   
   if (myTotal > 0)
    LastPrice = GetPreviousOpenPrice();
   else
    
          
LogWrite("LastPrice="+LastPrice);

flag = CheckJustClosedOrder();

if(flag!=1) 
{   
   
//----------------------- PREVIOUS OPEN PRICE

OrderWatcher=0;
LastPrice = GetPreviousOpenPrice();

LogWrite("LastPrice="+LastPrice);

//Print("ordersymbol = ", OrderSymbol(), " OrderOpenPrice= ", DoubleToStr(OrderOpenPrice(), 10), " lastprice= ",DoubleToStr(LastPrice, 10 ));

// Ron added divergence check
if(MathAbs(diverge)<=DivergenceLimit) {

if ( Hour()<OpeningHour+GMT+DST || Hour()>ClosingHour+GMT+DST ) Comment("bad hours.");  else { // included by Renato
/*if ( (iFXAnalyser(0,MODE_DIV,0)>DVLimit*Point
      && iFXAnalyser(0,MODE_SLOPE,0)>0 ) 
  || (iFXAnalyser(0,MODE_DIV,0)<-DVLimit*Point
      && iFXAnalyser(0,MODE_SLOPE,0)<0 ) ) { Comment("trending market!");} else {// included by Renato*/


//----------------------- ENTER POSITION BASED ON OPEN
if(MAtype==0)
{
  retval = EnterPositionBasedOnOpen();
  if (retval == 1)   // Opened Short position
  {
      OrderWatcher=1;
      Direction=2;
  }
  if (retval == 2)   // Opened Long Position
  {
      OrderWatcher=1;
      Direction=1;
  }
  
}
   
        
//----------------------- ENTER POSITION BASED ON HIGH/LOW
if(MAtype==1)
{
  retval = EnterPositionBasedOnHL();
  if (retval == 1)
  {
      OrderWatcher=1;
      Direction=2;
  }
  if (retval == 2)
  {
      OrderWatcher=1;
      Direction=1;
  }
}

} // included by Renato
} // included by Ron
} // end of flag test                  
//----------------------- CALCULATE AVERAGE OPENING PRICE 

myTotal = MyOrdersTotal();

if (myTotal>0 && OrderWatcher==1)
{

   AveragePrice = CalculateAverageOpeningPrice(myTotal);
   Comment("AveragePrice: ",AveragePrice,"  myTotal: ",myTotal); // modified by Renato 
}

//----------------------- RECALCULATE STOPLOSS & PROFIT TARGET BASED ON AVERAGE OPENING PRICE
// ReCalcSLTP_FromAverage();
  
//      Comment("AveragePrice= ", AveragePrice);

//----------------------- IF NEEDED CHANGE ALL OPEN ORDERS TO THE NEWLY CALCULATED PROFIT TARGET    
if(OrderWatcher==1 && myTotal>1)// check if average has really changed
  { 
    ChangeOpenOrders(false, myTotal, AveragePrice);
  }
//----------------------- KEEP TRACK OF STOPLOSS TO AVOID RUNAWAY MARKETS
    
//if (myTot>0) // modified by Renato
if (myTotal > 0) KeepTrackOfStopLoss(AveragePrice);

    
}
}

void SetupGlobalVariables()
{

  switch(MagicNumber) {// included by Renato
  case 26910: // EURUSD,M30 // optmized 06/03/20
//     MA_length=18; // George's setting
//    MA_timeframe=30;
//     MAtype=0;
     Percent=0.15; // George's setting
     TradeOnFriday=1;
     slip=100;
//     Lots=0.05;
//     TakeProfit=30; // George's setting
//     Stoploss=300;
     PipStep=5; 
     IncreasementType=0.0;
     DVLimit = 8; // included by Renato
     OpeningHour = 6; // included by Renato
     ClosingHour = 14; // included by Renato
     break;
  case 25803: // GBPUSD,M30
//     MA_length=18;
//     MA_timeframe=30;
//     MAtype=0;
     Percent=0.25;
     TradeOnFriday=1;
     slip=100;
//     Lots=0.05;
//     TakeProfit=30;
//     Stoploss=100;
     PipStep=5;
     IncreasementType=0.0;
     DVLimit = 8; // included by Renato
     OpeningHour = 7; // included by Renato
     ClosingHour = 15; // included by Renato
     break;
  case 26715: // EURCHF,M30 // optmized 06/03/20
     MA_length=18; 
     MA_timeframe=30; 
     MAtype=0; 
     Percent=0.1; 
     TradeOnFriday=1; 
     slip=100; 
     Lots=0.05; 
     TakeProfit=10; 
     Stoploss=300; 
     PipStep=7; 
     IncreasementType=0.0; 
     DVLimit = 6; // included by Renato
     OpeningHour = 6; // included by Renato
     ClosingHour = 14; // included by Renato
     break;
/*case : // USDCHF,M30
   DVLimit = 8; // included by Renato
   OpeningHour = 6; // included by Renato
   ClosingHour = 14; // included by Renato
   break;*/
/*case : // USDJPY,M30
   DVLimit = 8; // included by Renato
   OpeningHour = 23; // included by Renato
   ClosingHour = 7; // included by Renato
   break;*/
/*case : // USDAUD,M30
   DVLimit = 8; // included by Renato
   OpeningHour = 23; // included by Renato
   ClosingHour = 6; // included by Renato
   break;*/
/*default:
   if (!(IsTesting() || IsDemo())) 
   Alert("This advisor is suited for the EURUSD,M30 or GBPUSD,M30 charts only"); 
   return(0);
   break;
*/

  }
}


// Modules moved using cut/paste and modified by MrPip

double GetPreviousOpenPrice()
{
   int cnt;
   double LstPrice;
   
   for(cnt=OrdersTotal()-1;cnt>=0;cnt--){
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
//   Print("ordersymbol = ", OrderSymbol(), " OrderOpenPrice= ", DoubleToStr(OrderOpenPrice(), 10));
      if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==GetCommentForOrder()) )  // hdb - only symbol and magic  // modified by Renato
      {
           LstPrice=OrderOpenPrice();
//           Comment("LastPrice= ",DoubleToStr(LastPrice, 10));
//           Print("cnt= ", cnt, " ordersymbol = ", OrderSymbol(), " OrderOpenPrice= ", DoubleToStr(OrderOpenPrice(), 10), " lastprice= ",DoubleToStr(LastPrice, 10 ));
           break;
      } 
   }
   return(LstPrice);
}

/////////////////////////////////////////////////////////////////////////////////////////
// BACKTESTER FIX:  DO NOT PLACE AN ORDER IF WE JUST CLOSED
// AN ORDER WITHIN Period() MINUTES AGO
/////////////////////////////////////////////////////////////////////////////////////////
int CheckJustClosedOrder()
{
int cnt;
datetime orderclosetime;
string   rightnow;
int      rightnow2;
int      TheHistoryTotal=HistoryTotal();
int      difference;
int      flag=0;
   for(cnt=0;cnt<TheHistoryTotal;cnt++) 
    {
    if(OrderSelect(cnt,SELECT_BY_POS,MODE_HISTORY)==true)
       {
        if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==GetCommentForOrder()) )       // hdb - only symbol and magic  // modified by Renato
            {
               orderclosetime=OrderCloseTime();
               rightnow=Year()+"-"+Month()+"-"+Day()+" "+Hour()+":"+Minute()+":"+Seconds();
               rightnow2=StrToTime(rightnow);
               difference=rightnow2-orderclosetime;
               if(Period()*60*2>difference) 
                  { // At least 2 periods away!
                   flag=1;   // Throw a flag
                   break;
                  }
              }
         }
     }
     return(flag);
}

//----------------------- ENTER POSITION BASED ON OPEN
int EnterPositionBasedOnOpen()
{
   int ret;
   double myMA =iMA(NULL,MA_timeframe,MA_length,0,MODE_SMA,PRICE_OPEN,0);
   double RVI=iRVI(NULL,0,10,MODE_MAIN,0)-iRVI(NULL,0,10,MODE_MAIN,1); // included by Renato
   
//   Print(" Top, Bid ",myMA*(1+Percent/100),"  ",Bid);
//   if((myMA*(1+Percent/100))<Bid) Print(" Top, Bid ",myMA*(1+Percent/100),"  ",Bid);

   // Go SHORT -> Only sell if >= 30 pips above previous position entry 
   if( (myMA*(1+Percent/100))<Bid && Direction!=22 && (Bid>=(LastPrice+(CurrentPipStep*Point)) || MyOrdersTotal()==0) && RVI<0 ) // modified by Renato
 	  {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,slip,Bid+(Stoploss*Point),Bid-(TakeProfit*Point),GetCommentForOrder(),MagicNumber,0,clOpenSell);  // modified by Renato
      ret = 1;
     }   
   if((myMA*(1-Percent/100))>Ask && Direction!=11 && (Ask<=(LastPrice-(CurrentPipStep*Point)) || MyOrdersTotal()==0) && RVI>0 ) // Go LONG -> Only buy if >= 30 pips below previous position entry // modified by Renato
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,slip,Ask-(Stoploss*Point),Ask+(TakeProfit*Point),GetCommentForOrder(),MagicNumber,0,clOpenBuy);  // modified by Renato
      ret = 2;
     }
     return(ret); 
}

//----------------------- ENTER POSITION BASED ON HIGH/LOW
int EnterPositionBasedOnHL()
{
   int ret;
   if((iMA(Symbol(),MA_timeframe,MA_length,0,MODE_SMA,PRICE_HIGH,0)*(1+Percent/100))<Bid 
   && Direction!=22 && (Bid>=(LastPrice+(CurrentPipStep*Point)) || MyOrdersTotal()==0)) // Go SHORT -> Only sell if >= 30 pips above previous position entry	// modified by Renato
 	     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,slip,Bid+(Stoploss*Point),Bid-(TakeProfit*Point),GetCommentForOrder(),MagicNumber,0,clOpenSell);  // modified by Renato
      ret = 1;
     }   
   if((iMA(Symbol(),MA_timeframe,MA_length,0,MODE_SMA,PRICE_LOW,0)*(1-Percent/100))>Ask && Direction!=11 && (Ask<=(LastPrice-(CurrentPipStep*Point)) || MyOrdersTotal()==0)) // Go LONG -> Only buy if >= 30 pips below previous position entry	 // modified by Renato
        {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,slip,Ask-(Stoploss*Point),Ask+(TakeProfit*Point),GetCommentForOrder(),MagicNumber,0,clOpenBuy);  // modified by Renato
      ret = 2;
     }
     return(ret); 
} 

//----------------------- CALCULATE AVERAGE OPENING PRICE 
double CalculateAverageOpeningPrice(int myTot)
{
   int cnt;
   double AvePrice;

   AvePrice=0;  
//   int myOrderType = -1;            // hdb
//   myTotal = 0;                     // hdb - count of relevant trades

     for(cnt=OrdersTotal() - 1;cnt>=0;cnt--)
     {
       OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

       if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==GetCommentForOrder()) )  // hdb - only symbol and magic // modified by Renato
        {
          AvePrice=AvePrice+OrderOpenPrice();
//        myOrderType = OrderType();           // hdb - keep order type   
//          myTotal = myTotal+1;                 // hdb - count of relevant trades
        }
     }
   AvePrice=AvePrice/MathMax(myTot,1);        // hdb myTotal
   return(AvePrice);
}

//----------------------- RECALCULATE STOPLOSS & PROFIT TARGET BASED ON AVERAGE OPENING PRICE
//void ReCalcSLTP_FromAverage()
//{
// OrderSelect(0, SELECT_BY_POS, MODE_TRADES);   // hdb removed    
/*
    if(myOrderType==OP_BUY  && OrderWatcher==1 && myTotal>1)  // Calculate profit/stop target for long 
      {
      PriceTarget=AveragePrice+(TakeProfit*Point);
      Stopper=AveragePrice-(((Stoploss*Point)/myTotal)); 
      }
    if(myOrderType==OP_SELL && OrderWatcher==1 && myTotal>1) // Calculate profit/stop target for short
      {
      PriceTarget=AveragePrice-(TakeProfit*Point);
      Stopper=AveragePrice+(((Stoploss*Point)/myTotal)); 
      }
*/
//}

//----------------------- RECALCULATE STOPLOSS & PROFIT TARGET BASED ON AVERAGE OPENING PRICE
//----------------------- IF NEEDED CHANGE ALL OPEN ORDERS TO THE NEWLY CALCULATED PROFIT TARGET    
void ChangeOpenOrders(bool ChangeIt, int myTot, double AvePrice)
{
   int cnt, total;
   
   total=OrdersTotal(); 
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);  
      if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==GetCommentForOrder()) )  // hdb - only symbol and magic // modified by Renato
      {
         if(OrderType()==OP_BUY )  // Calculate profit/stop target for long // modified by Renato
         {
           PriceTarget=AvePrice+(TakeProfit*Point);
           Stopper=AvePrice-(((Stoploss*Point)/myTot)); 
         }
         if(OrderType()==OP_SELL ) // Calculate profit/stop target for short // modified by Renato
         {
           PriceTarget=AvePrice-(TakeProfit*Point);
           Stopper=AvePrice+(((Stoploss*Point)/myTot)); 
         }
         if (ChangeIt) OrderModify(OrderTicket(),0,Stopper,PriceTarget,0,Yellow);//set all positions to averaged levels
      } 
   }
}

//----------------------- KEEP TRACK OF STOPLOSS TO AVOID RUNAWAY MARKETS
// Sometimes the market keeps trending so strongly the system never reaches it's target.
// This means huge drawdown. After stopping out it falls in the same trap over and over.
// The code below avoids this by only accepting a signal in teh opposite direction after a SL was hit.
// After that all signals are taken again. Luckily this seems to happen rarely. 
void KeepTrackOfStopLoss(double AvePrice)
{
   int myOrderType, total, cnt;
   
   myOrderType = -1;                // hdb
   total=OrdersTotal(); 
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);            
      if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==GetCommentForOrder()) )  // hdb - only symbol and magic // modified by Renato
      {
         KeepStopLoss=OrderStopLoss();
         myOrderType = OrderType();           // hdb - keep order type   
      }
   }
   
   KeepAverage=AvePrice;
   Direction =0;
   if(myOrderType==OP_BUY) 
      { Direction=1;  } //long 
     else 
      { if (myOrderType==OP_SELL) Direction=2;  }//short

   if(KeepStopLoss!=0)
   {
     spread=MathAbs(KeepAverage-KeepStopLoss)/2;
     dummy=(Bid+Ask)/2;
     if (KeepStopLoss<(dummy+spread) && KeepStopLoss>(dummy-spread))
     {
     // a stoploss was hit
        if(Direction==1) Direction=11;// no more longs
        if(Direction==2) Direction=22;// no more shorts
     }
     KeepStopLoss=0;
   }
}


int MagicfromSymbol() { // included by Renato 
   int MagicNumber=0;  
   for (int i=0; i<5; i++) {  
      MagicNumber=MagicNumber*3+StringGetChar(Symbol(),i);  
   }  
   MagicNumber=MagicNumber*3+Period();  
   return(MagicNumber);  
}  

void CloseTheseTrades() { // included by Renato
   for (int i=0; i<OrdersTotal(); i++) {  
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {  
         if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicfromSymbol()) && (OrderComment()==GetCommentForOrder()) ) {  
            if (OrderType()==OP_BUY)  
               OrderClose(OrderTicket(),OrderLots(),Bid,GetSlippage(),clCloseBuy); 
            if (OrderType()==OP_SELL)  
               OrderClose(OrderTicket(),OrderLots(),Ask,GetSlippage(),clCloseSell); 
            if (OrderType()==OP_SELLSTOP || OrderType()==OP_SELLLIMIT ||  
                OrderType()==OP_BUYSTOP || OrderType()==OP_BUYLIMIT)  
               OrderDelete(OrderTicket()); 
         } 
      } 
   } 
} 

void CloseLoosingTrades() { // included by Renato
   for (int i=0; i<OrdersTotal(); i++) {  
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {  
         if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicfromSymbol()) && (OrderComment()==GetCommentForOrder()) ) {  
            if (OrderType()==OP_BUY)  
               if ( iFXAnalyser(240,MODE_DIV,0)<-DVLimit*Point )  
                 OrderClose(OrderTicket(),OrderLots(),Bid,GetSlippage(),clCloseBuy); 
            if (OrderType()==OP_SELL)  
               if ( iFXAnalyser(240,MODE_DIV,0)>DVLimit*Point )  
                 OrderClose(OrderTicket(),OrderLots(),Ask,GetSlippage(),clCloseSell); 
         } 
      } 
   } 
} 

double iFXAnalyser(int FXA_Period, int mode, int shift)// Made local function by MrPip
{
  double ind_buffer0, ind_buffer1, ind_buffer2;
 
   switch(mode)
   {
// MODE_DIV
      case 0 : ind_buffer0=iMA(NULL,FXA_Period,Fast_Period,0,MODE_SMA,Fast_Price,shift)
                          -iMA(NULL,FXA_Period,Slow_Period,0,MODE_SMA,Slow_Price,shift);
                     return (ind_buffer0);
                     break;

//---- Shaun's Slope counted in the 2-nd buffer
// MODE_SLOPE
      case 1 : ind_buffer1=(iMA(NULL,FXA_Period,Fast_Period,0,MODE_SMA,Fast_Price,shift)
                           -iMA(NULL,FXA_Period,Slow_Period,0,MODE_SMA,Slow_Price,shift))
                           -(iMA(NULL,FXA_Period,Fast_Period,0,MODE_SMA,Fast_Price,shift+1)
                            -iMA(NULL,FXA_Period,Slow_Period,0,MODE_SMA,Slow_Price,shift+1));
                       return (ind_buffer1);
                       break;
                       
//---- Shaun's Slope of Slope counted in the 3-3d buffer
// MODE_ACEL
      case 2 : ind_buffer2=((iMA(NULL,FXA_Period,Fast_Period,0,MODE_SMA,Fast_Price,shift)
                            -iMA(NULL,FXA_Period,Slow_Period,0,MODE_SMA,Slow_Price,shift))
                           -(iMA(NULL,FXA_Period,Fast_Period,0,MODE_SMA,Fast_Price,shift+1)
                            -iMA(NULL,FXA_Period,Slow_Period,0,MODE_SMA,Slow_Price,shift+1))
                           -(iMA(NULL,FXA_Period,Fast_Period,0,MODE_SMA,Fast_Price,shift+1)
                            -iMA(NULL,FXA_Period,Slow_Period,0,MODE_SMA,Slow_Price,shift+1))
                           -(iMA(NULL,FXA_Period,Fast_Period,0,MODE_SMA,Fast_Price,shift+2)
                            -iMA(NULL,FXA_Period,Slow_Period,0,MODE_SMA,Slow_Price,shift+2)));
                        return (ind_buffer2);
                        break;
       }
}

// Ron added for divergence filter
double divergence(int F_Period, int S_Period, int F_Price, int S_Price, int mypos)
  {
   int i;
   double maF1, maF2, maS1, maS2;
   double dv1, dv2;
   maF1=iMA(Symbol(),0,F_Period,0,MODE_SMA,F_Price,mypos);
   maS1=iMA(Symbol(),0,S_Period,0,MODE_SMA,S_Price,mypos);
   dv1=maF1-maS1;
   maF2=iMA(Symbol(),0,F_Period,0,MODE_SMA,F_Price,mypos+1);
   maS2=iMA(Symbol(),0,S_Period,0,MODE_SMA,S_Price,mypos+1);
   if (Use_V63D_Divergence)
   {
      dv2=((maF1-maS1)-(maF2-maS2));
   }
   else
   {
     dv2=maF2-maS2;
   }
   return(dv1-dv2);
  }


bool GoalCheck() { // included by Renato
   int handle = FileOpen(LogFileName(),FILE_CSV|FILE_READ,";");  
   if (handle>0) { 
      int lsteqty = FileReadNumber(handle); 
      FileClose(handle); 
   } 
   else lsteqty = 0; 
   if (lsteqty==0) {   
     handle = FileOpen(LogFileName(),FILE_CSV|FILE_WRITE,";");  
     FileWrite(handle,AccountEquity());  
     FileClose(handle); 
   } 
   else if (AccountEquity()-lsteqty>=PipsGoal*GetSizeLot()) return(True); 
        else return(False);  
} 

bool LossCheck() { // included by Renato
   int handle = FileOpen(LogFileName(),FILE_CSV|FILE_READ,";");  
   if (handle>0) { 
      int lsteqty = FileReadNumber(handle); 
      FileClose(handle); 
   } 
   else lsteqty = 0; 
   if (lsteqty==0) {   
     handle = FileOpen(LogFileName(),FILE_CSV|FILE_WRITE,";");  
     FileWrite(handle,AccountEquity());  
     FileClose(handle); 
   } 
   if (lsteqty-AccountEquity()>=PipsLoss*GetSizeLot()) return(True); 
   else return(False);  
} 

string LogFileName() { // included by Renato
    string stryear = DoubleToStr(Year(),0); 
    string strmonth = DoubleToStr(Month(),0); 
    if (StringLen(strmonth)<2) strmonth = "0"+strmonth; 
    string strday = DoubleToStr(Day(),0); 
    if (StringLen(strday)<2) strday = "0"+strday; 
    return(stryear+strmonth+strday+".log"); 
} 

void LogWrite(string content) {
  if (writelog==1) {
    int handle = FileOpen(Name_Expert+".log",FILE_CSV|FILE_WRITE,";");  
    FileSeek(handle,0,SEEK_END);
    FileWrite(handle,content);  
    FileFlush(handle);
    FileClose(handle); 
  }
}

int MyOrdersTotal() { // included by Renato
   int Mytotal=0; 
   for (int i=0; i<OrdersTotal(); i++) { 
     if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
       if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicfromSymbol()) && (OrderComment()==GetCommentForOrder()) ) 
          Mytotal++; 
   }  
   return(Mytotal); 
} 

string GetCommentForOrder() { return(Name_Expert); }  // included by Renato
double GetSizeLot() { return(Lots);}  // included by Renato
double GetSlippage() { return((Ask-Bid)/Point); } // included by Renato

//----------------------- TO DO LIST
// 1st days profit target is the 30 pip line *not* 30 pips below average as usually. -----> Day()
// Trailing stop -> trailing or S/R or pivot target
// Realistic stop loss
// Avoid overly big positions
// EUR/USD  30 pips / use same value as CurrentPipStep
// GBP/CHF  50 pips / use same value as CurrentPipStep 
// USD/CAD  35 pips / use same value as CurrentPipStep 

//----------------------- OBSERVATIONS
// GBPUSD not suited for this system due to not reversing exhaustions. Maybe use other types of MA
// EURGBP often sharp reversals-> good for trailing stops?
// EURJPY deep pockets needed.