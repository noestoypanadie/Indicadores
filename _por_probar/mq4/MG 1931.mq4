//+------------------------------------------------------------------+
//|                                                  MakeGrid193.mq4 |
//|                                            Copyright © 2005, hdb |
//|                                       http://www.dubois1.net/hdb |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, hdb"
#property link      "http://www.dubois1.net/hdb"
//#property version      "1.93"
// DISCLAIMER ***** IMPORTANT NOTE ***** READ BEFORE USING ***** 
// This expert advisor can open and close real positions and hence do real trades and lose real money.
// This is not a 'trading system' but a simple robot that places trades according to fixed rules.
// The author has no pretentions as to the profitability of this system and does not suggest the use
// of this EA other than for testing purposes in demo accounts.
// Use of this system is free - but u may not resell it - and is without any garantee as to its
// suitability for any purpose.
// By using this program you implicitly acknowledge that you understand what it does and agree that 
// the author bears no responsibility for any losses.
// Before using, please also check with your broker that his systems are adapted for the frequest trades
// associated with this expert.
// 1.8 changes
// made wantLongs and wantShorts into local variables. Previously, if u set UseMACD to true, 
//       it did longs and shorts and simply ignored the wantLongs and wantShorts flags. 
//       Now, these flags are not ignored.
// added a loop to check if there are 'illicit' open orders above or below the EMA when the limitEMA34
//       flag is used. These accumulate over time and are never removed and is due to the EMA moving.
// removed the switch instruction as they dont seem to work - replaced with if statements
// made the EMA period variable
//
// 1.9 changes - as per kind suggestions of Gideon
// Added a routine to delete orders and positions if they are older than keepOpenTimeLimit hours.
// Added OsMA as a possible filter. Acts exactly like MACD.
// Added 4 parameters for MACD or OsMA so that we can optimise
// Also cleaned up the code a bit.
// 1.92 changes by dave
// added function openPOsitions to count the number of open positions
// modified the order logic so that openPOsitions is not > GridMaxOpen 
// 1.93 added long term direction indicator 
// Added tradeForMinutes  - will only trade for this time then stop till EA is reset.
//
// modified by cori. Using OrderMagicNumber to identify the trades of the grid
extern int    uniqueGridMagic = 11111; // Magic number of the trades. must be unique to identify
                                       // the trades of one grid    
extern double Lots = 0.01;              // 
extern double GridSize = 30;            // pips between orders - grid or mesh size
extern double GridSteps = 10;          // total number of orders to place
extern double TakeProfit = 20;         // number of ticks to take profit. normally is = grid size but u can override
extern double StopLoss = 0;          // if u want to add a stop loss. normal grids dont use stop losses
extern int    trailStop = 0;           // will trail if > 0
extern double UpdateInterval = 1;      // update orders every x minutes
extern bool   wantLongs = true;        // do we want long positions
extern bool   wantShorts = true;       // do we want short positions
extern bool   wantBreakout = true;    // do we want longs above price, shorts below price
extern bool   wantCounter = true;      // do we want longs below price, shorts above price
extern bool   limitEMA = false;        // do we want longs above ema only, shorts below ema only
extern int    EMAperiod = 34;          // the length of the EMA.. was previously fixed at 34
extern double GridMaxOpen = 0;         // maximum number of open positions : implemented in v1.92
extern bool   UseMACD = false;          // if true, will use macd >0 for longs only, macd <0 for shorts only
                                       // on crossover, will cancel all pending orders. Works in conjunction with wantLongs and wantShorts.
extern bool   UseOsMA = false;         // if true, will use OSMA > 0 for longs only, OSMA <0 for shorts only. used in same way as MACD. 
                                       // If both UseMACD and UseOSMA atr true, OSMA is taken.
extern bool CloseOpenPositions = false; // if UseMACD, do we also close open positions with a loss?
extern bool   doHouseKeeping = false;   // this will remove long orders below the 34 ema and vv if limitEMA flag is true
extern double keepOpenTimeLimit = 0;   // in hours - if > 0, all open orders or positions will be closed after this period. fractions are permitted
extern int    emaFast = 36;            // parameters for MACD and OSMA
extern int    emaSlow = 50;            // parameters for MACD and OSMA
extern int    signalPeriod = 33;        // parameters for MACD and OSMA
extern int    timeFrame = 0;           // parameters for MACD and OSMA
extern int    minFromPrice = 0;        // minimum distance from price to place trades.
extern int    tradeForMinutes=0;       // will trade for this number of minutes after being initialised. 
                                       // add/readd the EA before news and it will trade for these minutes then close out all positions at end
extern int    gridOffset = 0;          // positions are opened at price modulo GridSize and offset with this parameter.
                                       // used essentially to enter at non round numbers
// the following flags set bounds on the prices at which orders may be placed
// this code was developed for and is kindly made public by Exc_ite2

extern double longGridCenter = 0;      // defines the center point of a fixed width long grid                                       
extern double shortGridCenter = 0;     // defines the center point of a fixed width short grid                                       

extern double longGridLow = 0;         // defines the bottom of a fixed width long grid
extern double longGridHigh = 0;        // defines the top of a fixed width long grid

extern double shortGridLow = 0;         // defines the bottom of a fixed width short grid
extern double shortGridHigh = 0;        // defines the top of a fixed width short grid

extern double profitTarget = 15000;     // if > 0, will close out all positions once the $ target has been met

extern bool   suspendGrid = false;       // if set to true, will close all unfilled Orders 
extern bool   shutdownGrid = false;      // if set to true, will close all orders and positions.
                                       
// modified by cori. internal variables only
string   GridName = "Grid";              // identifies the grid. allows for several co-existing grids - old variable.. shold not use any more
double   LastUpdate = 0;                 // counter used to note time of last update
double   startTime = 0;                  // counter to note trade start time.
double   closedProfit = 0;               // counts closed p&l
double   openProfit = 0;                 // counts open p&l
double   accumulatedProfit = 0;          // for back testing only
bool     haveHitTarget = false;          //  if there is a target, this flag says we have hit it
int      openLongs = 0;                  //  how many longs are open 
int      openShorts = 0;                 // how many shorts are open 
bool     gridActive = true;              // is the grid active
bool     gridOneShot = false;       // is this a one shot? if so, it stops after the profitTarget has been reached

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
 #property show_inputs                  // shows the parameters - thanks Slawa...    
//----
   GridName = StringConcatenate( "Grid-", Symbol(),"-",uniqueGridMagic );
   return(0);
  }
//+------------------------------------------------------------------------+
//| tests if there is an open position or order in the region of atRate    |
//|     will check for longs if checkLongs is true, else will check        |
//|     for shorts                                                         |
//+------------------------------------------------------------------------+

bool IsPosition(double atRate, double inRange, bool checkLongs )
  {
     int totalorders = OrdersTotal();
     for(int i=0;i<totalorders;i++)                                // scan all orders and positions...
      {
        OrderSelect(i, SELECT_BY_POS);
// modified by cori. Using OrderMagicNumber to identify the trades of the grid // hdb added or gridname for compatibility
        if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
         {  int type = OrderType();
            if (MathAbs( OrderOpenPrice() - atRate ) < (inRange*0.9)) // dont look for exact price but price proximity (less than gridsize) - added 0.9 because of floating point errors
              { if ( ( checkLongs && ( type == OP_BUY || type == OP_BUYLIMIT  || type == OP_BUYSTOP ) )  || (!checkLongs && ( type == OP_SELL || type == OP_SELLLIMIT  || type == OP_SELLSTOP ) ) )
                 { 
                    return(true); 
                 }
              }
         }
      } 
   return(false);
  }

//+------------------------------------------------------------------+
//| Delete order after x hours                                     |
//+------------------------------------------------------------------+
void DeleteAfter( double xHours )    // delete pending orders or open positions after x hours
  {
  int totalorders = OrdersTotal();
  for(int i=totalorders-1;i>=0;i--)
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
// we use iTime so it works in backtesting
     if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
        {
            if (( MathAbs(iTime(Symbol(),5,0)-OrderOpenTime()) >= xHours*60*60 ) && (iTime(Symbol(),5,0)>0))
            {  bool result = false;
               //Close opened long position
               if ( OrderType() == OP_BUY )  result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
               //Close opened short position
               if ( OrderType() == OP_SELL )  result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
               //Close pending order
               if ( OrderType() > 1 ) result = OrderDelete( OrderTicket() );
           }
        }
	  
  } // proc DeleteAfter()


//+------------------------------------------------------------------------+
//| cancells all pending orders                                      |
//+------------------------------------------------------------------------+

void CloseAllPendingOrders( )
  {
     int totalorders = OrdersTotal();
     for(int i=totalorders-1;i>=0;i--)                                // scan all orders and positions...
      {
        OrderSelect(i, SELECT_BY_POS);
// modified as per cori. Using OrderMagicNumber to identify the trades of the grid // hdb added or gridname for compatibility
        if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
         {  
          if ( OrderType() > 1 ) bool result = OrderDelete( OrderTicket() );
         }
      } 
   return;
  }
//+------------------------------------------------------------------------+
//| cancells all pending orders    and closes open positions               |
//+------------------------------------------------------------------------+

void ClosePendingOrdersAndPositions()
{
  int totalorders = OrdersTotal();
  for(int i=totalorders-1;i>=0;i--)
 {
    OrderSelect(i, SELECT_BY_POS);
    bool result = false;
// modified by cori. Using OrderMagicNumber to identify the trades of the grid // hdb added or gridname for compatibility
    if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
     {
           //Close opened long positions
           if ( OrderType() == OP_BUY )  result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
           //Close opened short positions
           if ( OrderType() == OP_SELL )  result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
           //Close pending orders
           if ( OrderType() > 1 ) result = OrderDelete( OrderTicket() );
      }
  }
  return;
}

//+------------------------------------------------------------------------+
//| cancells all open orders which fall on the wrong side of the EMA                                     |
//+------------------------------------------------------------------------+

void CloseOrdersfromEMA( double theEMAValue )
  {
     int totalorders = OrdersTotal();
     for(int i=totalorders-1;i>=0;i--)                                // scan all orders and positions...
      {
        OrderSelect(i, SELECT_BY_POS);
        if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
         {  
          int type = OrderType();
          bool result = false;
//if (type > 1) Print(type,"  ",theEMAValue,"  ",OrderOpenPrice());
          if ( type == OP_BUYLIMIT && OrderOpenPrice() <= theEMAValue ) result = OrderDelete( OrderTicket() ); 
          if ( type == OP_BUYSTOP && OrderOpenPrice() <= theEMAValue ) result = OrderDelete( OrderTicket() ); 
          if ( type == OP_SELLLIMIT && OrderOpenPrice() >= theEMAValue ) result = OrderDelete( OrderTicket() ); 
          if ( type == OP_SELLSTOP && OrderOpenPrice() >= theEMAValue ) result = OrderDelete( OrderTicket() ); 
         }
      } 
   return;
  }

//+------------------------------------------------------------------------+
//| counts the number of open positions                                    |
//+------------------------------------------------------------------------+

int openPositions(  )
  {  int op =0;
     int totalorders = OrdersTotal();
     for(int i=totalorders-1;i>=0;i--)                                // scan all orders and positions...
      {
        OrderSelect(i, SELECT_BY_POS);
        if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
         {  
          int type = OrderType();
          if ( type == OP_BUY ) {op=op+1;} 
          if ( type == OP_SELL ) {op=op+1;} 
         }
      } 
   return(op);
  }

//+------------------------------------------------------------------+
//| Close on profit target                                           |
//+------------------------------------------------------------------+
void TestForProfit( int forMagic, double profittarget, bool testOpen, bool testHistory )                   // based on trailing stop code from MT site... but modified as per Hiro
  {
    if (profittarget > 0 )
     {
         closedProfit = 0;                // counts closed p&l

         if (testHistory == true) {
            int total = HistoryTotal();
            for(int i=0;i<total;i++)                                // scan all closed / cancelled transactions
              {
              OrderSelect(i, SELECT_BY_POS, MODE_HISTORY );
              if ( OrderSymbol() == Symbol() && OrderMagicNumber() == forMagic )  // only look if mygrid and symbol...
                {
                 closedProfit = closedProfit + OrderProfit();
               }
              }
          } else {
             accumulatedProfit =0;
          }
          
         openProfit = 0;                  // counts open p&l

         if (testOpen == true) {
            total = OrdersTotal();
            openLongs = 0;
            openShorts = 0;
            for(i=0;i<total;i++)                                // scan all open orders and positions
              {
              OrderSelect(i, SELECT_BY_POS );
              if ( OrderSymbol() == Symbol() && OrderMagicNumber() == forMagic )  // only look if mygrid and symbol...
                {
                  openProfit = openProfit + OrderProfit();
                  int type = OrderType();
                  if ( type == OP_BUY ) {openLongs=openLongs+1;} 
                  if ( type == OP_SELL ) {openShorts=openShorts+1;} 
                }
              }
           }
         if ( ( closedProfit + openProfit) >= (profittarget + accumulatedProfit) ) 
            {
               Print("Closing grid due to profit target");
               ClosePendingOrdersAndPositions();
               accumulatedProfit = accumulatedProfit + closedProfit + openProfit;
               haveHitTarget = true;
               if (gridOneShot==true) { gridActive = false; }
            }
     }
  }


//+------------------------------------------------------------------+
//| Trailing stop procedure                                          |
//+------------------------------------------------------------------+
void TrailIt( int byPips )                   // based on trailing stop code from MT site... thanks MT!
  {
  if (byPips >=5)
  {
  for (int i = 0; i < OrdersTotal(); i++) {
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
     if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
        {
            if (OrderType() == OP_BUY) {
               //if (Bid > (OrderValue(cnt,VAL_OPENPRICE) + TrailingStop * Point)) {
               //   OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet);
               //   break;
               //}
               if (Bid - OrderOpenPrice() > byPips * MarketInfo(OrderSymbol(), MODE_POINT)) {
                  if (OrderStopLoss() < Bid - byPips * MarketInfo(OrderSymbol(), MODE_POINT)) {
                     OrderModify(OrderTicket(), OrderOpenPrice(), Bid - byPips * MarketInfo(OrderSymbol(), MODE_POINT), OrderTakeProfit(), Red);
                  }
               }
            } else if (OrderType() == OP_SELL) {
               if (OrderOpenPrice() - Ask > byPips * MarketInfo(OrderSymbol(), MODE_POINT)) {
                  if ((OrderStopLoss() > Ask + byPips * MarketInfo(OrderSymbol(), MODE_POINT)) || 
                        (OrderStopLoss() == 0)) {
                     OrderModify(OrderTicket(), OrderOpenPrice(),
                        Ask + byPips * MarketInfo(OrderSymbol(), MODE_POINT), OrderTakeProfit(), Red);
                  }
               }
            }
        }
	  }
	  }

  } // proc TrailIt()


//+------------------------------------------------------------------+
//| DetermineLots                                                    |
//| Attempt at money management                                      |
//+------------------------------------------------------------------+
double DetermineLots()
{
   double MyLots, AB;
   
   MyLots = Lots;
   AB = AccountBalance();
   if (AB > 15000) MyLots = 0.02;
   if (AB > 20000) MyLots = 0.05;
   if (AB > 50000) MyLots = 0.1;
   if (AB > 75000) MyLots = 0.5;
   if (AB > 100000) MyLots = 1;
   
   return (MyLots);
}

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//---- 
   int    i, j,k, ticket, entermode, totalorders;
   bool   doit;
   double point, startrate, traderate, temp;
//---- setup parameters 

 if ( TakeProfit <= 0 )                 // 
   { TakeProfit = GridSize; }

 bool myWantLongs = wantLongs;
 bool myWantShorts = wantShorts;

//---- test if we want to shutdown or suspend
   if (suspendGrid == true) {       // close unfilled orders and then test if profit target
      CloseAllPendingOrders();
   }
   if (shutdownGrid == true) {      // close all positions and orders. then exit.. there is nothing more to do
      ClosePendingOrdersAndPositions();
      return(0);
   }
   if (haveHitTarget == true) {     // in case we hit target and there are still some open orders and positions
      ClosePendingOrdersAndPositions();
      if (gridOneShot==true) { gridActive = false; }
   }
//----
   if (gridActive == false) {       // if grid not active, do nothing.
     return(0);
   }

//----

  if (MathAbs(CurTime()-LastUpdate)> UpdateInterval*60)           // we update the first time it is called and every UpdateInterval minutes
   {
   
   if (profitTarget >0) 
      {
        TestForProfit(uniqueGridMagic, profitTarget, true, false );
        if (!IsTesting()) {
            Comment(" v 1.93  "," Server time is ",TimeToStr(CurTime( )),
               "\n",
//               "\n","                  Closed p&l  = ",closedProfit,
               "\n","                  Open p&l    = ",openProfit,
//               "\n","                  Total p&l   = ",closedProfit + openProfit,  
               "\n","                  Long, Short = ",openLongs,"  ",openShorts, 
               "\n","                  Net pos     = ",openLongs-openShorts,
               "\n",
               "\n","                  Balance     = ",AccountBalance(),
               "\n","                  Equity      = ",AccountEquity(),
               "\n","                  Margin      = ",AccountMargin(),
               "\n","                  Free mrg    = ",AccountFreeMargin(),
               );
            }
      }

   
   
   LastUpdate = CurTime();
   Lots = DetermineLots();
   point = MarketInfo(Symbol(),MODE_POINT);
   startrate = ( Ask + point*GridSize/2 ) / point / GridSize;    // round to a number of ticks divisible by GridSize
   k = startrate ;
   k = k * GridSize ;
   startrate = k * point - GridSize*GridSteps/2*point ;          // calculate the lowest entry point
   double myEMA=iMA(NULL,0,EMAperiod,0,MODE_EMA,PRICE_CLOSE,0);
   int currentOpen = 0;
   if ( GridMaxOpen > 0 ) {
      currentOpen = openPositions();
      if (currentOpen >= GridMaxOpen) {CloseAllPendingOrders(); }
   }
   
   if (limitEMA) { if (doHouseKeeping) CloseOrdersfromEMA(myEMA);}
   if (keepOpenTimeLimit > 0) DeleteAfter(keepOpenTimeLimit);
   if (trailStop >0) TrailIt(trailStop);
   if ( UseMACD || UseOsMA)  
     {
      if ( UseMACD ) 
        {
            double Trigger0=iMACD(NULL,timeFrame,emaFast,emaSlow,signalPeriod,PRICE_CLOSE,MODE_MAIN,0);
            double Trigger1=iMACD(NULL,timeFrame,emaFast,emaSlow,signalPeriod,PRICE_CLOSE,MODE_MAIN,1);
            double Trigger2=iMACD(NULL,timeFrame,emaFast,emaSlow,signalPeriod,PRICE_CLOSE,MODE_MAIN,2);
        }
      if ( UseOsMA ) 
        {
             Trigger0=iOsMA(NULL,timeFrame,emaFast,emaSlow,signalPeriod,PRICE_CLOSE,0);
             Trigger1=iOsMA(NULL,timeFrame,emaFast,emaSlow,signalPeriod,PRICE_CLOSE,1);
             Trigger2=iOsMA(NULL,timeFrame,emaFast,emaSlow,signalPeriod,PRICE_CLOSE,2);
        }

    
       if( (Trigger0 > 0) && (Trigger1 > 0)  &&  (Trigger2 < 0 ))     // cross up
        {
         CloseAllPendingOrders();
         if ( CloseOpenPositions == true ) { ClosePendingOrdersAndPositions(); }
        }
       if( (Trigger0<0) && (Trigger1<0)  &&  (Trigger2>0))     // cross down
        {
         CloseAllPendingOrders();
         if ( CloseOpenPositions == true ) { ClosePendingOrdersAndPositions(); }
        }
       myWantLongs = false;
       myWantShorts = false;
       if( (Trigger0>0) && (Trigger1>0)  &&  (Trigger2>0) && (wantLongs==true) )     // is well above zero
        {
         myWantLongs = true;
        }
       if( (Trigger0<0) && (Trigger1<0)  &&  (Trigger2<0) && (wantShorts== true) )     // is well below zero
        {
         myWantShorts = true;
        }
   }
   int myGridSteps = GridSteps;
   if (( GridMaxOpen > 0 ) && (currentOpen >= GridMaxOpen)) {
      myGridSteps = 0;
   }
   
    if (suspendGrid == true) {       //profit target and exit conditions tested so finished
      return(0);
   }

Print("Trigs ",    Trigger0,"  ",Trigger1,"  ",Trigger2,"  ",myWantLongs,"  ",myWantShorts,"  ",myGridSteps," ema ",myEMA," price ",Bid );

 //Print("start  1 ",startrate);     
 
   for( i=0;i<myGridSteps;i++)
   {
     startrate = ( Ask + point*GridSize/2 ) / point / GridSize;    // round to a number of ticks divisible by GridSize
     k = startrate ;
     k = k * GridSize ;
     startrate = k * point - GridSize*GridSteps/2*point ;          // calculate the lowest entry point
     traderate = startrate + i*point*GridSize + gridOffset*point;

     if ( myWantLongs && (!limitEMA || traderate > myEMA))
       { if (longGridCenter > point) {
          temp = GridSteps / 2;
          k = temp;
          startrate = longGridCenter - k * GridSize * point;
         } else {
            startrate = ( Ask + point*GridSize/2 ) / point / GridSize;    // round to a number of ticks divisible by GridSize
            k = startrate ;
            k = k * GridSize ;
            startrate = k * point - GridSize*GridSteps/2*point ;          // calculate the lowest entry point
         }
         traderate = startrate + i*point*GridSize + gridOffset*point;
         // now test if traderate within limits
         doit = true;
         if (traderate < longGridLow) {doit = false;}
         if ((traderate > longGridHigh) && (longGridHigh > point)) {doit = false;}
         
         if (( IsPosition(traderate,point*GridSize,true) == false ) && (doit == true))          // test if i have no open orders close to my price: if so, put one on
          {
            double myStopLoss = 0;
             if ( StopLoss > 0 )
               { myStopLoss = traderate-point*StopLoss ; }
             if ( traderate > Ask ) 
              { entermode = OP_BUYSTOP; } 
              else 
              { entermode = OP_BUYLIMIT ; } 
              if ( ((traderate > (Ask +minFromPrice*Point) ) && (wantBreakout)) || ((traderate <= (Ask-minFromPrice*Point) ) && (wantCounter)) ) 
              { 
                  // modified by cori. Using OrderMagicNumber to identify the trades of the grid
                 ticket=OrderSend(Symbol(),entermode,Lots,traderate,0,myStopLoss,traderate+point*TakeProfit,GridName,uniqueGridMagic,0,Green); 
             }
          }
       }
     if ( myWantShorts && (!limitEMA || traderate < myEMA))
       { if (shortGridCenter > point) {
          temp = GridSteps / 2;
          k = temp;
          startrate = shortGridCenter - k * GridSize * point ;
         } else {
            startrate = ( Ask + point*GridSize/2 ) / point / GridSize;    // round to a number of ticks divisible by GridSize
            k = startrate ;
            k = k * GridSize ;
            startrate = k * point - GridSize*GridSteps/2*point ;          // calculate the lowest entry point
         }
        traderate = startrate + i*point*GridSize + gridOffset*point;
          // now test if traderate within limits
        doit = true;
        if (traderate < shortGridLow) {doit = false;}
        if ((traderate > shortGridHigh) && (shortGridHigh > point)) {doit = false;}

        if ((IsPosition(traderate,point*GridSize,false)== false ) && (doit == true))          // test if i have no open orders close to my price: if so, put one on
          { 
             myStopLoss = 0;
             if ( StopLoss > 0 )
               { myStopLoss = traderate+point*StopLoss ; }
             if ( traderate > Bid ) 
              { entermode = OP_SELLLIMIT; } 
              else 
              { entermode = OP_SELLSTOP ; } 
              if ( ((traderate < (Bid -minFromPrice*Point) ) && (wantBreakout)) || ((traderate >= (Bid+minFromPrice*Point) ) && (wantCounter)) ) 
                { 
                   // modified by cori. Using OrderMagicNumber to identify the trades of the grid
                   ticket=OrderSend(Symbol(),entermode,Lots,traderate,0,myStopLoss,traderate-point*TakeProfit,GridName,uniqueGridMagic,0,Red); 
                }
          }
       }
    }
   }
   return(0);
  }
//+------------------------------------------------------------------+