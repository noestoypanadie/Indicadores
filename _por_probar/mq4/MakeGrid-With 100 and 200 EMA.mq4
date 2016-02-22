//+------------------------------------------------------------------+
//|                                                     MakeGrid.mq4 |
//|                                            Copyright © 2005, hdb |
//|                                       http://www.dubois1.net/hdb |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, hdb"
#property link      "http://www.dubois1.net/hdb"
//#property version      "1.6beta"

// modified by cori. Using OrderMagicNumber to identify the trades of the grid
extern int    uniqueGridMagic = 11111;   // Magic number of the trades. must be unique to identify
                                         // the trades of one grid    
extern double Lots = 0.1;              // 
extern double GridSize = 6;            // pips between orders - grid or mesh size
extern double GridSteps = 12;          // total number of orders to place
extern double TakeProfit = 12 ;        // number of ticks to take profit. normally is = grid size but u can override
extern double StopLoss = 0;            // if u want to add a stop loss. normal grids dont use stop losses
extern double UpdateInterval = 1;      // update orders every x minutes
extern bool   wantLongs = true;        //  do we want long positions
extern bool   wantShorts = false;      //  do we want short positions
extern bool   wantBreakout = true;     // do we want longs above price, shorts below price
extern bool   wantCounter = true;      // do we want longs below price, shorts above price
extern bool   limitEMA34 = true;       // do we want longs above ema only, shorts below ema only
extern bool   limitEMA100 = true;       // do we want longs above ema only, shorts below ema only
extern bool   limitEMA200 = true;       // do we want longs above ema only, shorts below ema only
extern double GridMaxOpen = 0;         // maximum number of open positions : not yet implemented..
extern bool   UseMACD = true;          // if true, will use macd >0 for longs only, macd >0 for shorts only
                                       // on crossover, will cancel all pending orders. This will override any
                                       // wantLongs and wantShort settings - at least for now.
extern bool CloseOpenPositions = false;// if UseMACD, do we also close open positions with a loss?

// modified by cori. internal variables only
string GridName = "Grid";       // identifies the grid. allows for several co-existing grids
double LastUpdate = 0;          // counter used to note time of last update

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
 #property show_inputs                  // shows the parameters - thanks Slawa...    
 if ( TakeProfit <= 0 )                 // 
   { TakeProfit = GridSize; }
//----
// added my corri and removed by hdb!! lol.. just to stay compatible with open grids...
//   GridName = StringConcatenate( "Grid", Symbol() );
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
     for(int j=0;j<totalorders;j++)                                // scan all orders and positions...
      {
        OrderSelect(j, SELECT_BY_POS);
// modified by cori. Using OrderMagicNumber to identify the trades of the grid // hdb added or gridname for compatibility
        if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
         {  int type = OrderType();
             if (MathAbs( OrderOpenPrice() - atRate ) < (inRange*0.9)) // dont look for exact price but price proximity (less than gridsize)
              { if ( ( checkLongs && ( type == OP_BUY || type == OP_BUYLIMIT  || type == OP_BUYSTOP ) )  || (!checkLongs && ( type == OP_SELL || type == OP_SELLLIMIT  || type == OP_SELLSTOP ) ) )
                 { 
                    return(true); 
                 }
              }
         }
      } 
   return(false);
  }

//+------------------------------------------------------------------------+
//| cancells all pending orders                                      |
//+------------------------------------------------------------------------+

void CloseAllPendingOrders( )
  {
     int totalorders = OrdersTotal();
     for(int j=totalorders-1;j>=0;j--)                                // scan all orders and positions...
      {
        OrderSelect(j, SELECT_BY_POS);
// modified as per cori. Using OrderMagicNumber to identify the trades of the grid // hdb added or gridname for compatibility
        if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
         {  
          int type = OrderType();
          bool result = false;
          switch(type)
          {
             case OP_BUY       : result = true ;
             case OP_SELL      : result = true ;
            //Close pending orders
            case OP_BUYLIMIT  : result = OrderDelete( OrderTicket() ); 
            case OP_BUYSTOP   : result = OrderDelete( OrderTicket() ); 
            case OP_SELLLIMIT : result = OrderDelete( OrderTicket() ); 
            case OP_SELLSTOP  : result = OrderDelete( OrderTicket() ); 
          }
         }
      } 
   return;
  }


//+------------------------------------------------------------------------+
//| cancells all pending orders    and closes open positions               |
//+------------------------------------------------------------------------+

void CloseOpenOrders()
{
  int total = OrdersTotal();
  for(int i=total-1;i>=0;i--)
 {
    OrderSelect(i, SELECT_BY_POS);
    int type    = OrderType();
    bool result = false;
// modified by cori. Using OrderMagicNumber to identify the trades of the grid // hdb added or gridname for compatibility
    if ( OrderSymbol()==Symbol() && ( (OrderMagicNumber() == uniqueGridMagic) || (OrderComment() == GridName)) )  // only look if mygrid and symbol...
     {
//    Print("Closing 2 ",type);
        switch(type)
         {
           //Close opened long positions
           case OP_BUY       : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
                               break;
           //Close opened short positions
           case OP_SELL      : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
                               break;
           //Close pending orders
           case OP_BUYLIMIT  :
           case OP_BUYSTOP   :
           case OP_SELLLIMIT :
           case OP_SELLSTOP  : result = OrderDelete( OrderTicket() );
         }
      }
    if(result == false)
    {
 //     Alert("Order " , OrderTicket() , " failed to close. Error:" , GetLastError() );
 //     Sleep(3000);
    }  
  }
  return;
}

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//---- 
   int    i, j,k, ticket, entermode, totalorders;
   bool   doit;
   double point, startrate, traderate;
//----
  if (MathAbs(CurTime()-LastUpdate)> UpdateInterval*60)           // we update the first time it is called and every UpdateInterval minutes
   {
   LastUpdate = CurTime();
   point = MarketInfo(Symbol(),MODE_POINT);
   startrate = ( Ask + point*GridSize/2 ) / point / GridSize;    // round to a number of ticks divisible by GridSize
   k = startrate ;
   k = k * GridSize ;
   startrate = k * point - GridSize*GridSteps/2*point ;          // calculate the lowest entry point
   double EMA34=iMA(NULL,0,34,0,MODE_EMA,PRICE_CLOSE,0);
   double EMA100=iMA(NULL,0,100,0,MODE_EMA,PRICE_CLOSE,0);
   double EMA200=iMA(NULL,0,200,0,MODE_EMA,PRICE_CLOSE,0);
   if ( UseMACD )  {
      double Macd0=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
      double Macd1=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
      double Macd2=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,2);
       if( Macd0>0 && Macd1>0  &&  Macd2<0)     // cross up
        {
         CloseAllPendingOrders();
         if ( CloseOpenPositions == true ) { CloseOpenOrders(); }
        }
       if( Macd0<0 && Macd1<0  &&  Macd2>0)     // cross down
        {
         CloseAllPendingOrders();
         if ( CloseOpenPositions == true ) { CloseOpenOrders(); }
        }
       wantLongs = false;
       wantShorts = false;
       if( Macd0>0 && Macd1>0  &&  Macd2>0)     // is well above zero
        {
         wantLongs = true;
        }
       if( Macd0<0 && Macd1<0  &&  Macd2<0)     // is well below zero
        {
         wantShorts = true;
        }
   }
   for( i=0;i<GridSteps;i++)
   {
     traderate = startrate + i*point*GridSize;
     if ( wantLongs && (!limitEMA200 || traderate > EMA200) && (!limitEMA34 || traderate > EMA34) && (!limitEMA100 || traderate > EMA100))
       {
         if ( IsPosition(traderate,point*GridSize,true) == false )           // test if i have no open orders close to my price: if so, put one on
          {
            double myStopLoss = 0;
             if ( StopLoss > 0 )
               { myStopLoss = traderate-point*StopLoss ; }
             if ( traderate > Ask ) 
              { entermode = OP_BUYSTOP; } 
              else 
              { entermode = OP_BUYLIMIT ; } 
              if ( ((traderate > Ask ) && (wantBreakout)) || ((traderate <= Ask ) && (wantCounter)) ) 
              { 
                  // modified by cori. Using OrderMagicNumber to identify the trades of the grid
                 ticket=OrderSend(Symbol(),entermode,Lots,traderate,0,myStopLoss,traderate+point*TakeProfit,GridName,uniqueGridMagic,0,Green); 
             }
          }
       }
     if ( wantShorts && (!limitEMA200 || traderate < EMA200) && (!limitEMA34 || traderate < EMA34) && (!limitEMA100 || traderate < EMA100))
       {
         if (IsPosition(traderate,point*GridSize,false)== false )           // test if i have no open orders close to my price: if so, put one on
          {
             myStopLoss = 0;
             if ( StopLoss > 0 )
               { myStopLoss = traderate+point*StopLoss ; }
             if ( traderate > Bid ) 
              { entermode = OP_SELLLIMIT; } 
              else 
              { entermode = OP_SELLSTOP ; } 
              
              if ( ((traderate < Bid ) && (wantBreakout)) || ((traderate >= Bid ) && (wantCounter)) ) 
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