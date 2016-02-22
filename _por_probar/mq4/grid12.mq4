//+------------------------------------------------------------------+
//|                                                     MakeGrid.mq4 |
//|                                            Copyright © 2005, hdb |
//|                                       http://www.dubois1.net/hdb |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, hdb"
#property link      "http://www.dubois1.net/hdb"
//#property version      "1.2beta"

extern string GridName = "Grid";       // identifies the grid. allows for several co-existing grids
extern double Lots = 0.1;              // 
extern double GridSize = 6;            // pips between orders - grid or mesh size
extern double GridSteps = 10;          // total number of orders to place
extern double TakeProfit = 6 ;         // number of ticks to take profit. normally is = grid size but u can override
extern double StopLoss = 10;            // if u want to add a stop loss. normal grids dont use stop losses
extern double UpdateInterval = 15;     // update orders every x minutes
extern bool   wantLongs = true;        //  do we want long positions
extern bool   wantShorts = true;       //  do we want short positions
extern bool   wantBreakout = true;     // do we want longs above price, shorts below price
extern bool   wantCounter = false;      // do we want longs below price, shorts above price
extern bool   limitEMA34 = false;      // do we want longs above ema only, shorts below ema only
extern double LastUpdate = 0;          // counter used to note time of last update
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
        if ( OrderSymbol()==Symbol() && OrderComment() == GridName )  // only look if mygrid and symbol...
         {  int type = OrderType();
            if (MathAbs( OrderOpenPrice() - atRate) < inRange) // dont look for exact price but price proximity (less than gridsize)
              { if ( ( checkLongs && ( type == OP_BUY || type == OP_BUYLIMIT  || type == OP_BUYSTOP ) )  || (!checkLongs && ( type == OP_SELL || type == OP_SELLLIMIT  || type == OP_SELLSTOP ) ) )
                 { return(true); }
              }
         }
      } 

   return(false);
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
   Print("Updating");
   point = MarketInfo(Symbol(),MODE_POINT);
   startrate = ( Ask + point*GridSize/2 ) / point / GridSize;    // round to a number of ticks divisible by GridSize
   k = startrate ;
   k = k * GridSize ;
   startrate = k * point - GridSize*GridSteps/2*point ;          // calculate the lowest entry point
   
   double EMA34=iMA(NULL,0,34,0,MODE_EMA,PRICE_CLOSE,0);
   
   for( i=0;i<GridSteps;i++)
   {
     traderate = startrate + i*point*GridSize;
     if ( wantLongs && (!limitEMA34 || traderate > EMA34))
       {
         if (!IsPosition(traderate,point*GridSize,true) )           // test if i have no open orders close to my price: if so, put one on
          {
             double myStopLoss = 0;
             if ( StopLoss > 0 )
               { myStopLoss = traderate-point*StopLoss ; }
               
             if ( traderate > Ask ) 
              { entermode = OP_BUYSTOP; } 
              else 
              { entermode = OP_BUYLIMIT ; } 
             if ( (traderate > Ask ) && (wantBreakout) || ((traderate < Ask ) && (wantCounter)) ) 
              { ticket=OrderSend(Symbol(),entermode,Lots,traderate,0,myStopLoss,traderate+point*TakeProfit,GridName,16384,0,Green); }
          }
       }

     if ( wantShorts && (!limitEMA34 || traderate < EMA34))
       {
         if (!IsPosition(traderate,point*GridSize,false) )           // test if i have no open orders close to my price: if so, put one on
          {
             myStopLoss = 0;
             if ( StopLoss > 0 )
               { myStopLoss = traderate+point*StopLoss ; }
             if ( traderate > Bid ) 
              { entermode = OP_SELLLIMIT; } 
              else 
              { entermode = OP_SELLSTOP ; } 
              
              if ( (traderate < Bid ) && (wantBreakout) || ((traderate > Bid ) && (wantCounter)) ) 
                { ticket=OrderSend(Symbol(),entermode,Lots,traderate,0,myStopLoss,traderate-point*TakeProfit,GridName,16384,0,Red); }
          }
       }

    }
   }
   return(0);
  }

