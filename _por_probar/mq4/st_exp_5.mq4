//+-------------------+
//| 1MA Expert        |
//+-------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;
extern double stoploss=22;
extern double takeprofit=35;

//
// make sure to leave this unset
// It triggers the 1st buy.
//
// Also, define here so it has global scope
// at least, within this expert
//
int prevTime;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//|------------------------------------------------------------------|

int init()
  {
   return(0);
  }


//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int start()
  {

   double MovingAvg = 10;

   double   cMA=0, pMA=0;
   double   p=Point();
      
   bool     found=false;
   bool    rising=false;
   bool   falling=false;
   bool    bought=false;
   bool      sold=false;

   int      cnt=0;
   int      err=0;
   
   double oop=0;  //order open price 
   double osl=0;  //order stop loss
   double ccl=0;  //current close price 
   
   int      rty=0;
   

   // Only compute right after each bar move
   // but check for BreakEven adjust each tick
   //
   // RISK MITIGATION
   // Set stoploss to orderprice (break-even) if price is
   // at least OpenPrice+StopLoss on close[0], but only
   // do it ONE TIME, controlled by oop>osl(buy) oop<osl(sell)
   // since we don't want this turning into a trailing stop
   
   if(prevTime==Time[0])
     {
     // Does the Symbol() have an open order
      for(cnt=0;cnt<OrdersTotal();cnt++)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            // yes, get existing prices & bought/sold state
            oop=OrderOpenPrice();
            ccl=Close[0];
            osl=OrderStopLoss();
            if (OrderType()==0) {bought=true;  sold=false;}
            if (OrderType()==1) {bought=false; sold=true;}

            if (bought)
              {
               if (oop>osl && ccl>(oop+(stoploss*p)) )
                 {
                  // One-time move to break even
                  // try up to ten times in case of error
                  for (rty=1; rty<=10; rty++)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),oop,OrderTakeProfit(),0,Red);
                     if(GetLastError()==0)
                       {
                        Print(Symbol()," BOUGHT One time break-even adjustment to ", oop);
                        break;
                       }
                        else
                       {
                        Print(Symbol()," BOUGHT Break-Even modify Error=", err, " LOOP=",rty, " Time=",Time[0]);
                        Sleep(10000);
                       }
                    }
                 }
              } 

            if (sold)
              {
               if (oop<osl && ccl<(oop-(stoploss*p)) )
                 {
                  // One-time move to break even
                  // try up to ten times in case of error
                  for (rty=1; rty<=10; rty++)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),oop,OrderTakeProfit(),0,Red);
                     if(GetLastError()==0)
                       {
                        Print(Symbol()," SOLD One time break-even adjustment to ", oop);
                        break;
                       }
                        else
                       {
                        Print(Symbol()," SOLD Break-Even modify Error=", err, " LOOP=",rty, " Time=",Time[0]);
                        Sleep(10000);
                       }
                    }
                 }
              }

            break;
           }
        }
      // remember, tick hasn't moved, so leave
      return(0);
     }



   prevTime=Time[0];
   
   // don't trade right on the bar
   // it's usually too busy, and try to avoid
   // other trades as they're happening
   if (Symbol()=="AUDUSD") {Print("Sleeping  5000"); Sleep( 5000);}
   if (Symbol()=="EURAUD") {Print("Sleeping 10000"); Sleep(10000);}
   if (Symbol()=="EURCHF") {Print("Sleeping 15000"); Sleep(15000);}
   if (Symbol()=="EURGBP") {Print("Sleeping 20000"); Sleep(20000);}
   if (Symbol()=="EURJPY") {Print("Sleeping 25000"); Sleep(25000);}
   if (Symbol()=="EURUSD") {Print("Sleeping 30000"); Sleep(30000);}
   if (Symbol()=="GBPCHF") {Print("Sleeping 35000"); Sleep(35000);}
   if (Symbol()=="GBPJPY") {Print("Sleeping 40000"); Sleep(40000);}
   if (Symbol()=="GBPUSD") {Print("Sleeping 45000"); Sleep(45000);}
   if (Symbol()=="USDCAD") {Print("Sleeping 50000"); Sleep(50000);}
   if (Symbol()=="USDCHF") {Print("Sleeping 55000"); Sleep(55000);}
   if (Symbol()=="USDJPY") {Print("Sleeping 60000"); Sleep(60000);}
   
   

   // Error checking
   if(Bars<100)                        {Print("Bars less than 100"); return(0);}
   if(AccountFreeMargin()<(1000*Lots)) {Print("We have no money");   return(0);}

   // PRICE_OPEN is the only stable price point for Bar0
   cMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 0);
   pMA=iMA(Symbol(), 0, MovingAvg, 0, MODE_LWMA, PRICE_OPEN, 1);

   if (pMA<cMA) {rising=true;  falling=false;}
   if (pMA>cMA) {rising=false; falling=true;}
   
   // Does the Symbol() have an open order
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         // yes, set found, get the existing bought/sold state
         // and then break, so there's only 1 order per symbol
         found=true;
         osl=OrderStopLoss();
         if (OrderType()==0) {bought=true;  sold=false;}
         if (OrderType()==1) {bought=false; sold=true;}
         break;
        }
         else
        {
         found=false;
        }        
     }
   

   Print("000  pMA=",pMA," cMA=",cMA,"    R=",rising,"B=",bought,"   F=",falling,"S=",sold,"    $=",Open[0]," Time=",Time[0]);


   // If there is no order, then
   // place one based on MA direction
   if (!found && rising)
     {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-(p*stoploss),Ask+(p*takeprofit),"1MA Buy",11123,0,White);
      if(GetLastError()==0)
        {
         Print(Symbol()," OPEN Buy success:",Ask);
        }
         else
        {
         Print(Symbol()," OPEN Buy Error ", err, " Time=",Time[0]);
        }
      return(0);
     }

   if (!found && falling)
     {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+(p*stoploss),Bid-(p*takeprofit),"1MA Sell",11321,0,Red);
      if(GetLastError()==0)
        {
         Print(Symbol()," OPEN Sell success:",Bid);
        }
         else
        {
         Print(Symbol()," OPEN Sell Error ", err, " Time=",Time[0]);
        }
      return(0);
     }


   // if the direction changed, then close the order

   if (rising && sold)       //existing sell
     {
      // Try 10 times to close, reporting each time
      for (rty=1; rty<=10; rty++)
        {
         OrderClose(OrderTicket(),Lots,Ask,0,Red);
         if(GetLastError()==0)
           {
            Print(Symbol()," CLOSE SELL success:",Ask);
            break;
           }
            else
           {
            Print(Symbol()," CLOSE Sell Error=", err, " LOOP=",rty, " Time=",Time[0]);
            Sleep(10000);
           }
        }
     }
   if (falling && bought)  // existing buy
     {
      // Try 10 times to close, reporting each time
      for (rty=1; rty<=10; rty++)
        {
         OrderClose(OrderTicket(),Lots,Bid,0,White);
         if(GetLastError()==0)
           {
            Print(Symbol()," CLOSE BUY success:",Bid);
            break;
           }
            else
           {
            Print(Symbol()," CLOSE Buy Error=", err, " LOOP=",rty, " Time=",Time[0]);
            Sleep(10000);
           }
        }
     }

   return(0);
  }

