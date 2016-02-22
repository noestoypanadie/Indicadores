// Conversion by MojoFX on Moving Average expert structure

#define MAGICMA  20050610

extern double  Lots               = 0.1;
extern double  MaximumRisk        = 0.02;
extern double  DecreaseFactor     = 3;

extern int     TakeProfit         = 100;
extern int     TrailingStop       = 50;

//---- change here to revert to original version
extern int     WilliamsP          = 24;
extern double  WilliamsL          = -75;
extern double  WilliamsH          = -25;

bool     condBuy,condSell;
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//----
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//---- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//---- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//---- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         //----
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//---- return lot size
   if(lot<0.1) lot=0.1;
   if(DecreaseFactor<0) lot = Lots;
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
   {
   if(Volume[0]>1) return;
   
   int res;
   double WPRs,WPRb;
   double PriceOpen,NewPrice,Buy_Tp,Sell_Tp;
   
   int wDir = getDirection();   

//---- change here to revert to original
	WPRs    = iWPR(NULL,0,WilliamsP,1) > WilliamsL; //-75
	WPRb    = iWPR(NULL,0,WilliamsP,1) < WilliamsH; //-25
   
   condBuy  = (wDir == 1 && WPRb &&
              iWPR(NULL,0,WilliamsP,0) < iWPR(NULL,0,WilliamsP,1) );
   
   condSell = (wDir == -1 && WPRs &&
              iWPR(NULL,0,WilliamsP,0) > iWPR(NULL,0,WilliamsP,1) );   
   
//---- sell conditions
   if (condSell) {
      PriceOpen = Low[1]-1*Point;
      if (PriceOpen > (Bid-16*Point))
         {
         if (TakeProfit > 0)
            { Sell_Tp = PriceOpen-TakeProfit*Point; } else { Sell_Tp = 0; }
            
         res = OrderSend(Symbol(),OP_SELLSTOP,LotsOptimized(),PriceOpen,3,
                        High[1]+1*Point,Sell_Tp,"TSD1",MAGICMA,0,Red);
         
         return;
         
         } else {
         
         NewPrice = Bid-16*Point;
         if (TakeProfit > 0)
            { Sell_Tp = NewPrice-TakeProfit*Point; } else { Sell_Tp = 0; }
            
         res = OrderSend(Symbol(),OP_SELLSTOP,LotsOptimized(),NewPrice,3,
                        High[1]+1*Point,Sell_Tp,"TSD1",MAGICMA,0,Red);
                        
         return;
         } // end if priceopen    
      } // end if condSell

//---- buy conditions
   if (condBuy) {
   
      PriceOpen = High[1]+1*Point;
      if (PriceOpen > (Ask+16*Point))
         {
         if (TakeProfit > 0)
            { Buy_Tp = PriceOpen+TakeProfit*Point; } else { Buy_Tp = 0; }
                     
         res=OrderSend(Symbol(),OP_BUYSTOP,LotsOptimized(),PriceOpen,3,
                        Low[1]-1*Point,Buy_Tp,"TSD1",MAGICMA,0,GreenYellow);
         
         return;         
         } else {         
         NewPrice = Ask + 16 * Point;
         
         if (TakeProfit > 0)
            { Buy_Tp = NewPrice+TakeProfit*Point; } else { Buy_Tp = 0; }
            
         res=OrderSend(Symbol(),OP_BUYSTOP,LotsOptimized(),NewPrice,3,
                        Low[1]-1*Point,Buy_Tp,"TSD1",MAGICMA,0,GreenYellow);
                        
         return;
         }
      } // end CondBuy         
   } // end CheckForOpen()
      
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
   {      
   // trade on fresh bar
   if(Volume[0]>1) return;
  
   double PriceOpen,NewPrice,Buy_Tp,Sell_Tp;
   
   int wDir = getDirection();

   for(int i=0;i<OrdersTotal();i++)
      {
      if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)        break;
      if (OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
        
      //---- trailing stop  
      if (OrderType() == OP_BUY) {
         if (Bid - OrderOpenPrice() > TrailingStop*MarketInfo(OrderSymbol(),MODE_POINT)) {
            if ((OrderStopLoss() < Bid-TrailingStop*MarketInfo(OrderSymbol(),MODE_POINT)) || (OrderStopLoss() == 0)) {
               OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailingStop*MarketInfo(OrderSymbol(),MODE_POINT),OrderTakeProfit(),SteelBlue);
               }
            }
         } else 
      if (OrderType() == OP_SELL) {
         if (OrderOpenPrice() - Ask > TrailingStop * MarketInfo(OrderSymbol(),MODE_POINT)) {
            if ((OrderStopLoss() > Ask+TrailingStop*MarketInfo(OrderSymbol(),MODE_POINT)) || (OrderStopLoss() == 0)) {
               OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailingStop*MarketInfo(OrderSymbol(),MODE_POINT),OrderTakeProfit(),Magenta);
               }
            }
         }          

      if (OrderType() == OP_BUYSTOP && wDir == 1)
         {
         if (High[1]<High[2])
            {
            if (High[1]>Ask+16*Point) 
               OrderModify(OrderTicket(),High[1]+1*Point,Low[1]-1*Point,OrderTakeProfit(),0,SteelBlue);
               else 
               OrderModify(OrderTicket(),Ask+16*Point,Low[1]-1*Point,OrderTakeProfit(),0,SteelBlue);               
            }         
         }
      
      if (OrderType() == OP_SELLSTOP && wDir == -1)
         {
         if (Low[1]>Low[2])
            {
            if (Low[1]<Bid-16*Point)
               OrderModify(OrderTicket(),Low[1]-1*Point,High[1]+1*Point,OrderTakeProfit(),0,Magenta);
               else
               OrderModify(OrderTicket(),Bid-16*Point,High[1]+1*Point,OrderTakeProfit(),0,Magenta);
            }            
         }   
      
      //---- pending orders deletion
      if ( OrderType() == OP_BUYSTOP && wDir == -1 ) OrderDelete(OrderTicket());
      if ( OrderType() == OP_SELLSTOP && wDir == 1 ) OrderDelete(OrderTicket());
      
     } // end for
   } // end CheckForClose()

//+------------------------------------------------------------------+
//| Start function                                                   |
//+------------------------------------------------------------------+
void start()
   {

   // check for history and trading
   if (Bars<100 || IsTradeAllowed()==false) return;
   
   // calculate open orders by current symbol
   if (CalculateCurrentOrders(Symbol())==0) CheckForOpen(); else CheckForClose();
   } // end start()
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get direction                                                    | 
//+------------------------------------------------------------------+
int getDirection()
   {
   double MacdC,MacdP,MacdP2;
   int wDir;
   
	MacdC  = iMACD(NULL,PERIOD_W1,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
	MacdP  = iMACD(NULL,PERIOD_W1,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
	MacdP2 = iMACD(NULL,PERIOD_W1,12,26,9,PRICE_CLOSE,MODE_MAIN,2);
	
	if (MacdP >  MacdP2) wDir =  1;
	if (MacdP <  MacdP2) wDir = -1;
	if (MacdP == MacdP2) wDir = 0;
	
	Comment("Direction = ",wDir);
	
	return(wDir);	
   } // end start()
//+------------------------------------------------------------------+