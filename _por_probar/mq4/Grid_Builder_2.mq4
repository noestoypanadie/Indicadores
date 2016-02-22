//+------------------------------------------------------------------+
//|                                                  KEHedgeGird.mq4 |
//|                                         Copyright © 2006, Kickas |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Kickas."
#property link      "http://"

//
extern int     MaxLong = 1;
extern int     MaxShort = 2;
extern int     Risk = 15;                    // Over 50 % risk not recommended.
extern double  Lots=0.1;                     // If MoneyManagement is off.
extern int     Slippage=3;                   // Slippage > 1 recommended.
extern bool    AccountIsMicro = false;       // If you use MicroAccount with minilots.
extern bool    UseMoneyManagement = true;    // MoneyManagement. More profit at the long run, but also more risk due to the equity maybe will fall.
extern int     TakeProfit = 10;              // While hedging, this setting will wait until the profit pass the level before trailstoploss will activate.
extern int     Stoploss = 30;
extern int     TrailStopLoss = 7;   
extern int     GridSpace=10;
// Trailingstoploss will be active when profit reach TakeProfit. Profit will be reduced by stoploss. Setting like TP=12 and SL=8 will give minimum 12-8=4 pips in profit.
////////////////////////////////////////////////////
// Internal variables only, please do not change! //
////////////////////////////////////////////////////
bool    sell = false;
bool    buy = false;
double  lotMM = 0;
double sl = 0;
int     i,MagicNumber,err,ticket;
string  comment ="KEHedge";
////////////////////////////////////////////////////
int init()
  {
//---- indicators
//----
   return(0);
  }



int deinit()
  {
//---- 
   double shift=0;
   double HighPrice=0;
   double LowPrice=0;
   
   double Divisor = 0.1/Point;
   
   HighPrice = MathRound(High[Highest(NULL,0,2, Bars - 2,  2)] * Divisor);
   //SL = High[Highest(MODE_HIGH, SLLookback, SLLookback)];
   LowPrice = MathRound(Low[Lowest(NULL,0,1, Bars - 1, 2)] * Divisor);
   for(shift=LowPrice;shift<=HighPrice;shift++)
   {
      ObjectDelete("Grid"+shift);   
   }
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Symbol_To_Value - Used by MagicNumber                            |
//+------------------------------------------------------------------+
int Symbol_To_Value(string symbol) 
{
	if     (symbol=="AUDCAD") { return(10); }
   else if(symbol=="AUDCHF") { return(11); }
   else if(symbol=="AUDJPY") { return(12); }
   else if(symbol=="AUDNZD") { return(13); }
	else if(symbol=="AUDUSD") { return(14); }
	else if(symbol=="CADCHF") { return(20); }
	else if(symbol=="CADJPY") { return(21); }
	else if(symbol=="CHFJPY") { return(30); }
	else if(symbol=="EURAUD") { return(40); }
	else if(symbol=="EURCAD") { return(41); }
	else if(symbol=="EURCHF") { return(42); }
	else if(symbol=="EURGBP") { return(43); }
	else if(symbol=="EURJPY") { return(44); }
   else if(symbol=="EURUSD") { return(45); }
	else if(symbol=="GBPAUD") { return(50); }
	else if(symbol=="GBPCAD") { return(51); }
	else if(symbol=="GBPCHF") { return(52); }
	else if(symbol=="GBPJPY") { return(53); }
	else if(symbol=="GBPUSD") { return(54); }
	else if(symbol=="NZDCHF") { return(60); }
	else if(symbol=="NZDJPY") { return(61); }
	else if(symbol=="NZDUSD") { return(62); }
	else if(symbol=="USDCAD") { return(70); }	
	else if(symbol=="USDCHF") { return(71); }
	else if(symbol=="USDJPY") { return(72); }
   else { Comment("unexpected Symbol"); }
}
//+------------------------------------------------------------------+
//| LotSize - Detemine the size of the Lot(s) if UseManagement is on.|
//+------------------------------------------------------------------+
double LotSize()
{
   if( AccountFreeMargin()/AccountBalance()<(Risk / 100) * 2 ) 
   {
      Print ("Not enough margin to order");
      return(0);
   }
   //lotMM = (AccountFreeMargin() * Risk / 1000) / 100; 
   if (AccountIsMicro == true)
      lotMM = MathFloor(AccountFreeMargin() * Risk/10000) / 100;
   else
      lotMM = MathFloor(AccountFreeMargin() * Risk/10000) / 10;          
   Print(lotMM);
   return (lotMM);
}
//+------------------------------------------------------------------+
//| CountOrders - Counting the orders if avaliable.                  |
//+------------------------------------------------------------------+
int CountOrders(int MagicNO, int OrderTyp) 
{
   int total = OrdersTotal();   
   int extotal = 0; 
   int cnt;  
   for(cnt = 0 ; cnt < total ; cnt++)   
   {      
      OrderSelect(cnt, SELECT_BY_POS,MODE_TRADES);   
      if (OrderMagicNumber()==MagicNO && OrderType() == OrderTyp || (OrderMagicNumber()==MagicNO && OrderTyp == -1))      
      extotal++;    
   }
   return (extotal);
}


//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
   static int LastLong;
   static int LastShort;
   MagicNumber = 10000 + Symbol_To_Value(Symbol())*100;
   if (UseMoneyManagement == true) Lots = LotSize();
   buy=false;
   sell=false;
  
  int    counted_bars=IndicatorCounted();
   double I=0;
   double HighPrice=0;
   double LowPrice=0;
   int GridS=0;
   int SL=0;
//----    

   double Divisor = 0.1/Point;

   HighPrice = MathRound(High[Highest(NULL,0,MODE_HIGH, Bars - 2, 2)] * Divisor);
   //SL = High[Highest(MODE_HIGH, SLLookback, SLLookback)];
   LowPrice = MathRound(Low[Lowest(NULL,0,MODE_LOW, Bars - 1, 2)] * Divisor);
   GridS = GridSpace / 10;
   
   for(I=LowPrice;I<=HighPrice;I++)
   {
	  //Print("mod(I, GridSpace): " + MathMod(I, GridS) + " I= " + I);
	  //Print(LowPrice + " " + HighPrice);
	  if (MathMod(I, GridS) == 0) 
	  {	     
         if (ObjectFind("Grid"+I) != 0)
         {                     
            ObjectCreate("Grid"+I, OBJ_HLINE, 0, Time[1], I/Divisor);            
            ObjectSet("Grid"+I, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSet("Grid"+I, OBJPROP_COLOR, MediumSeaGreen);            
         }
		 //MoveObject(I + "Grid", OBJ_HLINE, Time[Bars - 2], I/1000, Time[1], I/1000, MediumSeaGreen, 1, STYLE_SOLID);
	  }
   }
  

  
   
   if (CountOrders(MagicNumber, -1) == 0) // No orders detected, open new buy and sell order - hedging.
   {
 //  Lots=1;
 // Comment (GridS);
      RefreshRates();
      

      
      ticket = OrderSend(Symbol(),OP_BUYSTOP,Lots,GridS,Slippage,GridS-Stoploss*Point,GridS+TakeProfit*Point,comment,MagicNumber,0,Blue);
      if (ticket < 1)
      {
         err = GetLastError();
         Print ("Error : ",err);
      }
      
      ticket = OrderSend(Symbol(),OP_SELLSTOP,Lots,GridS,Slippage,GridS-Stoploss*Point,GridS+TakeProfit*Point,comment,MagicNumber,0,Red);   
      if (ticket < 1)
      {
         err = GetLastError();
         Print ("Error : ",err);
      }
            ticket = OrderSend(Symbol(),OP_BUYLIMIT,Lots,GridS,Slippage,GridS-Stoploss*Point,GridS+TakeProfit*Point,comment,MagicNumber,0,Blue);
      if (ticket < 1)
      {
         err = GetLastError();
         Print ("Error : ",err);
      }
      
      ticket = OrderSend(Symbol(),OP_SELLLIMIT,Lots,GridS,Slippage,GridS-Stoploss*Point,GridS+TakeProfit*Point,comment,MagicNumber,0,Red);   
      if (ticket < 1)
      {
         err = GetLastError();
         Print ("Error : ",err);
      }
    
    
            
      buy=false;
      sell=false;
   }
   else // Order(s) detected.
   {   
      for (i=0;i<OrdersTotal();i++)
      {
      
         // ************************************
         // Trailing stop
         OrderSelect(i,SELECT_BY_POS);
         if (OrderMagicNumber() == MagicNumber)
         {
            if (OrderType() == OP_BUY)
            {
               if (buy == false)
               {
                  if (OrderProfit() > 0)
                  {
                     if ((Bid - OrderOpenPrice()) > TakeProfit*Point)
                     {
                        if (OrderStopLoss() < (Bid - TrailStopLoss*Point))
                        {
                           sl = Bid - TrailStopLoss*Point;
                           ticket = OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,Pink);
                           if (ticket < 1)
                           {
                              err = GetLastError();
                              Print ("Error : ",err);
                              return(0);
                           }  
                        }
                     }
                  }
               }
            }
        
            if (OrderType() == OP_SELL)
            {
               if (sell == false)
               {
                  if (OrderProfit() > 0)
                  {
                     if ((OrderOpenPrice() - Ask) > TakeProfit*Point) 
                     {   
                        if (OrderStopLoss() == 0 || (Ask + TrailStopLoss*Point) < OrderStopLoss())
                        {
                           sl = Ask + TrailStopLoss*Point;
                           ticket = OrderModify(OrderTicket(),OrderOpenPrice(),sl,OrderTakeProfit(),0,Pink);
                           if (ticket < 1)
                           {
                              err = GetLastError();
                              Print ("Error : ",err);
                              return(0);
                           }
                        }
                     }
                  }
               }
            }         
            // **********************************
            
            if (CountOrders(MagicNumber, OP_BUY) < LastLong && CountOrders(MagicNumber, OP_SELL) < MaxShort)
            {
               // Nyligen stängt köporder, lägg en sälj
               sell = true;
            }   

            if (CountOrders(MagicNumber, OP_SELL) < LastShort && CountOrders(MagicNumber, OP_BUY) < MaxLong)
            {
               // Nyligen stängt köporder, lägg en sälj
               buy = true;
            }   

            
            if (buy == true)
            {
               RefreshRates();
               ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,comment,MagicNumber,0,Blue);
               if (ticket < 1)
               {
                  err = GetLastError();
                  Print ("Error : ",err);
                  return(0);
               }
               return(0);
            }
      
            if (sell == true)
            {
               RefreshRates();
               ticket = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,comment,MagicNumber,0,Red);      
               if (ticket < 1)
               {
                  err = GetLastError();
                  Print ("Error : ",err);
                  return(0);
               }
               return(0);
            }
         }
      }
   }
   LastLong = CountOrders(MagicNumber, OP_BUY);
   LastShort = CountOrders(MagicNumber, OP_SELL);
   return(0);   
}
//+------------------------------------------------------------------+