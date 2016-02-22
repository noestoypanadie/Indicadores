//+-----------------------------------------------------------------------------+
//|                              Firebird v0.63 - MA envelope exhaustion system |
//+-----------------------------------------------------------------------------+
#property copyright "Copyright � 2005, TraderSeven"
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
//----------------------- USER INPUT
extern int MA_length = 10;
extern int MA_timeframe = 30;              // hdb did I add this ? lol
extern int MAtype=0;//0=close, 1=HL		 
extern double Percent = 0.1;
extern int TradeOnFriday =1; // >0 trades on friday
extern int slip = 100;//exits only
extern double Lots = 0.3;
extern int TakeProfit = 30;
extern int Stoploss = 2000;// total loss on all open positions in pips
//extern double TrailingStop = 5;
extern int PipStep = 30;//if position goes this amount of pips against you add another.
extern double IncreasementType =0;//0=just add every PipStep,  >0 =OrdersToal()^x *Pipstep
int MagicNumber=12345; // modified by Renato 
MagicNumber = MagicfromSymbol(); // included by Renato 

if ( (StringSubstr(Symbol(),0,6) == "GBPUSD") && (Period() == 30) ) {  // included by Renato from Ron Thompson's <ron@lightpatch.com> data
   MA_length = 18; // included by Renato
   Percent = 0.25; // included by Renato
   TakeProfit = 27;  // included by Renato
   Stoploss = 400; // included by Renato
   PipStep = 5; // included by Renato
   } // included by Renato

if ( (StringSubstr(Symbol(),0,6) == "EURUSD")  && (Period() == 30) ) {  // included by Renato from Ron Thompson's <ron@lightpatch.com> data
   MA_length = 32; // included by Renato
   Percent = 0.15; // included by Renato
   TakeProfit = 41;  // included by Renato
   Stoploss = 100; // included by Renato
   PipStep = 2; // included by Renato
   } // included by Renato
   
double Stopper=0;
double KeepStopLoss=0;
double KeepAverage;
double dummy;
double spread=0;
double CurrentPipStep;
int    OrderWatcher=0;

string Name_Expert = "Firebird v63"; // included by Renato 

//----------------------- MAIN PROGRAM LOOP
int start()
{
double PriceTarget;
double AveragePrice;
int OpeningDay;

//----------------------- CALCULATE THE NEW PIPSTEP
CurrentPipStep=PipStep;
if(IncreasementType>0)
  {
  CurrentPipStep=MathSqrt(MyOrdersTotal())*PipStep; // modified by Renato
  CurrentPipStep=MathPow(MyOrdersTotal(),IncreasementType)*PipStep; // modified by Renato
  } 

//----------------------- 
int Direction=0;//1=long, 11=avoid long, 2=short, 22=avoid short
if (Day()!=5 || TradeOnFriday >0)
{
   int cnt=0, total;
   int myTotal =0;                     // hdb
   total=MyOrdersTotal(); // modified by Renato
   if(total==0) OpeningDay=DayOfYear();
 
    for(cnt=0;cnt<total;cnt++)
     {
     if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==Name_Expert) )    // hdb - only symbol and magic  // modified by Renato
      {
       OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
       double LastPrice=OrderOpenPrice();
       myTotal = myTotal +1;           // hdb - count of relevant trades
      }
    }
//   OrderSelect(total, SELECT_BY_POS, MODE_TRADES);      // removed hdb           

/////////////////////////////////////////////////////////////////////////////////////////
// BACKTESTER FIX:  DO NOT PLACE AN ORDER IF WE JUST CLOSED
// AN ORDER WITHIN Period() MINUTES AGO
/////////////////////////////////////////////////////////////////////////////////////////
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
        if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==Name_Expert) )       // hdb - only symbol and magic  // modified by Renato
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

/////////////////////////////////////////////////////////////////////////////////////////
if(flag!=1) 
{   
   
//----------------------- PREVIOUS OPEN PRICE

OrderWatcher=0;
 
total=MyOrdersTotal(); // modified by Renato
for(cnt=(total-1);cnt>=0;cnt--){
   OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
//   Print("ordersymbol = ", OrderSymbol(), " OrderOpenPrice= ", DoubleToStr(OrderOpenPrice(), 10));
   if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==Name_Expert) )  // hdb - only symbol and magic  // modified by Renato
   {
           LastPrice=OrderOpenPrice();
           Comment("LastPrice= ",DoubleToStr(LastPrice, 10));
//           Print("cnt= ", cnt, " ordersymbol = ", OrderSymbol(), " OrderOpenPrice= ", DoubleToStr(OrderOpenPrice(), 10), " lastprice= ",DoubleToStr(LastPrice, 10 ));
           break;
    } 
}
//Print("ordersymbol = ", OrderSymbol(), " OrderOpenPrice= ", DoubleToStr(OrderOpenPrice(), 10), " lastprice= ",DoubleToStr(LastPrice, 10 ));


//----------------------- ENTER POSITION BASED ON OPEN
if(MAtype==0)
   {

   double myMA =iMA(NULL,MA_timeframe,MA_length,0,MODE_SMA,PRICE_OPEN,0);
   
//   Print(" Top, Bid ",myMA*(1+Percent/100),"  ",Bid);
//   if((myMA*(1+Percent/100))<Bid) Print(" Top, Bid ",myMA*(1+Percent/100),"  ",Bid);

   if((myMA*(1+Percent/100))<Bid && Direction!=22 && (Bid>=(LastPrice+(CurrentPipStep*Point))||total==0)) // Go SHORT -> Only sell if >= 30 pips above previous position entry	
 	  {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,slip,Bid+(Stoploss*Point),Bid-(TakeProfit*Point),Name_Expert,0,0,Red);  // modified by Renato
      OrderWatcher=1;
      Direction=2;
     }   
   if((myMA*(1-Percent/100))>Ask && Direction!=11 && (Ask<=(LastPrice-(CurrentPipStep*Point))||total==0)) // Go LONG -> Only buy if >= 30 pips below previous position entry	 
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,slip,Ask-(Stoploss*Point),Ask+(TakeProfit*Point),Name_Expert,0,0,Blue);  // modified by Renato
      OrderWatcher=1;
      Direction=1;
     } 
   }     
  
//----------------------- ENTER POSITION BASED ON HIGH/LOW
if(MAtype==1)
  {
   if((iMA(NULL,MA_timeframe,MA_length,0,MODE_SMA,PRICE_HIGH,0)*(1+Percent/100))<Bid && Direction!=22 && (Bid>=(LastPrice+(CurrentPipStep*Point))||total==0)) // Go SHORT -> Only sell if >= 30 pips above previous position entry	
 	     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,slip,Bid+(Stoploss*Point),Bid-(TakeProfit*Point),Name_Expert,0,0,Red);  // modified by Renato
      OrderWatcher=1;
      Direction=2;
     }   
  if((iMA(NULL,MA_timeframe,MA_length,0,MODE_SMA,PRICE_LOW,0)*(1-Percent/100))>Ask && Direction!=11 && (Ask<=(LastPrice-(CurrentPipStep*Point))||total==0)) // Go LONG -> Only buy if >= 30 pips below previous position entry	 
        {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,slip,Ask-(Stoploss*Point),Ask+(TakeProfit*Point),Name_Expert,0,0,Blue);  // modified by Renato
      OrderWatcher=1;
      Direction=1;
     } 
  } 

} // end of flag test                  
//----------------------- CALCULATE AVERAGE OPENING PRICE 
   total=MyOrdersTotal(); // modified by Renato
   AveragePrice=0;  
   int myOrderType = -1;            // hdb
   myTotal = 0;                     // hdb - count of relevant trades
        
 if(total>1 && OrderWatcher==1)
 
   {
     for(cnt=0;cnt<total;cnt++)
     {
       OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

       if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==Name_Expert) )  // hdb - only symbol and magic // modified by Renato
        {

        AveragePrice=AveragePrice+OrderOpenPrice();
        myOrderType = OrderType();           // hdb - keep order type   
        myTotal = myTotal +1;                // hdb - count of relevant trades
        }
     }
   AveragePrice=AveragePrice/MathMax(myTotal,1);        // hdb myTotal
   }
//----------------------- RECALCULATE STOPLOSS & PROFIT TARGET BASED ON AVERAGE OPENING PRICE
// OrderSelect(0, SELECT_BY_POS, MODE_TRADES);   // hdb removed    
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
      Comment("AveragePrice", AveragePrice);
//----------------------- IF NEEDED CHANGE ALL OPEN ORDERS TO THE NEWLY CALCULATED PROFIT TARGET    
//if(OrderWatcher==1 && myTotal>1)// check if average has really changed
//if(OrderWatcher==1 && myTotal>1)// check if average has really changed
//  { 
total=MyOrdersTotal(); // modified by Renato
    for(cnt=0;cnt<total;cnt++)
       {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);  
       if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==Name_Expert) )  // hdb - only symbol and magic // modified by Renato
          {
           OrderModify(OrderTicket(),0,Stopper,PriceTarget,0,Yellow);//set all positions to averaged levels
          } 
       } 
       
       
//  }
//Comment("PriceTarget: ",PriceTarget,"  AveragePrice: ",AveragePrice,"  Total: ",total);
//----------------------- KEEP TRACK OF STOPLOSS TO AVOID RUNAWAY MARKETS
// Sometimes the market keeps trending so strongly the system never reaches it's target.
// This means huge drawdown. After stopping out it falls in the same trap over and over.
// The code below avoids this by only accepting a signal in teh opposite direction after a SL was hit.
// After that all signals are taken again. Luckily this seems to happen rarely. 
if (MyOrdersTotal()>0) // modified by Renato
   {
    myOrderType = -1;                // hdb
    myTotal = 0;                     // hdb - count of relevant trades
    total=MyOrdersTotal(); // modified by Renato
    for(cnt=0;cnt<total;cnt++)
       {
       OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);            
       if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==Name_Expert) )  // hdb - only symbol and magic // modified by Renato
          {
            KeepStopLoss=OrderStopLoss();
            AveragePrice=AveragePrice+OrderOpenPrice();
            myTotal = myTotal +1;                // hdb - count of relevant trades
            myOrderType = OrderType();           // hdb - keep order type   
          }
       }
   
   AveragePrice=AveragePrice/MathMax(myTotal,1);        // hdb myTotal
   KeepAverage=AveragePrice;
   Direction =0;
   if(myOrderType==OP_BUY) 
      { Direction=1;  } //long 
     else 
      { if (myOrderType==OP_SELL) Direction=2;  }//short
   }

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
}

int MagicfromSymbol() { // included by Renato 
// examples: // included by Renato 
//pair   M1 M5 M15   M30   H1	H4	D1	W1	MN // included by Renato 
//EURUSD 4190125	4190129	4190139	4190154	4190184	4190364	4191564	4200204	4233324 // included by Renato 
//EURJPY	4188508 // included by Renato 
//EURCHF	4187254 // included by Renato 
//EURGBP	4187746 // included by Renato 
//EURCAD	4187101 // included by Renato 
//EURAUD	4187286 // included by Renato 
   int magic=0; // included by Renato 
   for (int i=0; i<6; i++) { // included by Renato 
      magic=magic*7+StringGetChar(Symbol(),i); // included by Renato 
   } // included by Renato 
   magic=magic*3+Period(); // included by Renato 
   return(magic); // included by Renato 
} // included by Renato 

int MyOrdersTotal() { // included by Renato
   int total=0; // included by Renato
   for (int i=0; i<MyOrdersTotal(); i++) { // included by Renato
     if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) // included by Renato
       if ( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && (OrderComment()==Name_Expert) ) total++; // included by Renato
   }  // included by Renato
   return(total); // included by Renato
} // included by Renato

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