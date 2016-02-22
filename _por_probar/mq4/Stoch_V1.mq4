//+------------------------------------------------------------------+
//|                                                        Stoch.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//|   Perky 02 Nov 2006.                                             |
//| Added Money Management..                                         | 
//|                                                                  |
//| Needs a nice trail stop?                                         |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"
//----
extern double TakeProfit =999;
extern double Lots = 1;
extern double TrailingStop = 30;
extern bool    UseTrailingStop = true;
extern int     TrailingStopType = 2;        // Type 1 moves stop immediately, Type 2 waits til value of TS is reached
extern double StopLoss = 40;
extern double Risk = 1.5;
extern double LotLimit = 50;
extern double Per = 3;
extern int Slippage=3;
extern int     RecalSLRange = 8;


extern bool       Lot_Compounding=True;  // use Moneymanagement and compound lots as profits increase
extern double     MMRisk=0.3;              // Risk Factor
extern double     LossMax=1000;             // Maximum Loss by 1 Lot
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Lotsi;
int totalTries = 5; 
int retryDelay = 1000;

int start()
  {
   HandleOpenTrades();
   double s = GlobalVariableGet("SELLLIMIT");
   double b = GlobalVariableGet("BUYLIMIT");
   double ds = GlobalVariableGet("DateS");
   double db = GlobalVariableGet("DateB");
//----
   if(ds != DayOfWeek())
     {
       GlobalVariableDel("SELLLIMIT");
       GlobalVariableDel("BUYLIMIT");
       GlobalVariableDel("DatesS");
       GlobalVariableDel("DatesB");
     }
   double H3,H4,L3,L4,SH4,SH3,BL3,BL4;
//----
   if(OrdersTotal() < 1 && Hour() == 23 && Minute() == 59) 
       return(0);
//----
   if(OrdersTotal() > 0 && Hour() == 23 && Minute() == 59) 
     {
       int total = OrdersTotal();
       //----
       for(int i = total - 1; i >= 0; i--)
         {
           OrderSelect(i, SELECT_BY_POS);
           int type = OrderType();
           bool result = false;
           //----
           switch(type)
             {
               //Close opened long positions
               case OP_BUY       : result = OrderClose(OrderTicket(), OrderLots(), 
                                                       MarketInfo(OrderSymbol(), MODE_BID), 
                                                       5, Red );
                                   break;
               //Close opened short positions
               case OP_SELL      : result = OrderClose(OrderTicket(), OrderLots(), 
                                                       MarketInfo(OrderSymbol(), MODE_ASK), 
                                                       5, Red );
                                   break;
               //Close pending orders
               case OP_BUYLIMIT  :
               case OP_BUYSTOP   :
               case OP_SELLLIMIT :
               case OP_SELLSTOP  : result = OrderDelete(OrderTicket());
             }
           //----
           if(result == false)
             {
               Alert("Order " , OrderTicket() , " failed to close. Error:" , GetLastError());
               Sleep(3000);
             }  
         }
     }
   H4 = NormalizeDouble(((((High[1] - Low[1])*1.1) / 2) + Close[1]),4);
   H3 = NormalizeDouble(((((High[1] - Low[1])*1.1) / 4) + Close[1]),4);
   L3 = NormalizeDouble((Close[1] - ((High[1] - Low[1])*1.1) / 4),4);
   L4 = NormalizeDouble((Close[1] - ((High[1] - Low[1])*1.1) / 2),4);
//----
   if(db != DayOfWeek() && s == 0) 
     {
       Lotsi=Lots;
       if( Lot_Compounding )Lotsi = MoneyManagement (  Lot_Compounding, Lots, MMRisk, LossMax);

       SH3 = OrderSend(Symbol(), OP_SELLLIMIT, Lotsi, H4, 3, H4 + StopLoss*Point, 
                       H4 - TakeProfit*Point, "H3", 0, 0, Red);
       //----
       if(SH3 < 0)
         {
           GlobalVariableSet("SELLLIMIT", 0);
         }
       else 
         {
           GlobalVariableSet("SELLLIMIT", 1);
           GlobalVariableSet("DateS", DayOfWeek());   
         }
     }
//----
   if(db != DayOfWeek() && b == 0) 
     {
       Lotsi=Lots;
       if(Lot_Compounding) Lotsi = MoneyManagement (  Lot_Compounding, Lots, MMRisk, LossMax);

       BL3 = OrderSend(Symbol(), OP_BUYLIMIT, Lotsi, L4, 3, L4 - StopLoss*Point, 
                       L4 + TakeProfit*Point, "L3", 0, 0, Green);  
       //----
       if(BL3 < 0)
         {
           GlobalVariableSet("BUYLIMIT", 0);  
         }
       else 
         {
           GlobalVariableSet("BUYLIMIT", 1);
           GlobalVariableSet("DateB", DayOfWeek());   
         }
     }
  }       
//+------------------------------------------------------------------+
// ---- Money Management
double MoneyManagement ( bool flag, double Lots, double risk, double maxloss)
   {
   Lotsi=Lots;
	    
   if ( flag ) Lotsi=NormalizeDouble(Lots*AccountFreeMargin()*risk/maxloss,1);   
     
   if (Lotsi<0.1) Lotsi=0.1;  
   return(Lotsi);
   }
   
   
 //+------------------------------------------------------------------+
//| HandleTrailingStop                                               |
//| Type 1 moves the stoploss without delay.                         |
//| Type 2 waits for price to move the amount of the trailStop       |
//| before moving stop loss then moves like type 1                   |
//| Type 3 uses up to 3 levels for trailing stop                     |
//|      Level 1 Move stop to 1st level                              |
//|      Level 2 Move stop to 2nd level                              |
//|      Level 3 Trail like type 1 by fixed amount other than 1      |
//| Possible future types                                            |
//| Type 4 uses 2 for 1, every 2 pip move moves stop 1 pip           |
//| Type 5 uses 3 for 1, every 3 pip move moves stop 1 pip           |
//+------------------------------------------------------------------+
int HandleTrailingStop(int type, int ticket, double op, double os, double tp)
{
    double pt, TS=0, myAsk, myBid;
    double bos,bop,opa,osa;
    
    switch(type)
    {
       case OP_BUY:
       {
		 myBid = MarketInfo(Symbol(),MODE_BID);
       switch(TrailingStopType)
       {
        case 1: pt = Point*StopLoss;
                if(myBid-os > pt)
                 ModifyOrder(type, ticket,op,myBid-pt,tp, Aqua);
                break;
        case 2: pt = Point*TrailingStop;
                if(myBid-op > pt && os < myBid - pt)
                 ModifyOrder(type, ticket,op,myBid-pt,tp, Aqua);
                break;
       }
       return(0);
       break;
       }
       case  OP_SELL:
       {
		    myAsk = MarketInfo(Symbol(),MODE_ASK);
          switch(TrailingStopType)
          {
           case 1: pt = Point*StopLoss;
                   if(os - myAsk > pt) ModifyOrder(type, ticket,op,myAsk+pt,tp, Aqua);
                   break;
           case 2: pt = Point*TrailingStop;
                   if(op - myAsk > pt && os > myAsk+pt) ModifyOrder(type, ticket,op,myAsk+pt,tp, Aqua);
                   break;
          }
       }
       return(0);
    }
}
//+------------------------------------------------------------------+
//| Modify Open Position Controls                                    |
//|  Try to modify position 3 times                                  |
//+------------------------------------------------------------------+
bool ModifyOrder(int nOrderType, int ord_ticket,double op, double price,double tp, color mColor = CLR_NONE)
{
    int cnt, err;
    double myStop;
    
    myStop = ValidStopLoss (nOrderType, price);
    cnt=0;
    while (cnt < totalTries)
    {
       if (OrderModify(ord_ticket,op,myStop,tp,0,mColor))
       {
         return(true);
       }
       else
       {
          err=GetLastError();
          //if (err > 1) Print(cnt," Error modifying order : (", ord_ticket , ") " + ErrorDescription(err), " err ",err);
          if (err>0) cnt++;
          Sleep(retryDelay);
       }
    }
    return(false);
}

// 	Adjust stop loss so that it is legal.
double ValidStopLoss(int cmd, double sl)
{
   
   if (sl == 0) return(0.0);
   
   double mySL, myPrice;
   double dblMinStopDistance = MarketInfo(Symbol(),MODE_STOPLEVEL)*MarketInfo(Symbol(), MODE_POINT);
   
   mySL = sl;
   
// Check if SlopLoss needs to be modified

   switch(cmd)
   {
   case OP_BUY:
      myPrice = MarketInfo(Symbol(), MODE_BID);
	   if (myPrice - sl < dblMinStopDistance) 
		mySL = myPrice - dblMinStopDistance;	// we are long
		break;
      
   case OP_SELL:
      myPrice = MarketInfo(Symbol(), MODE_ASK);
	   if (sl - myPrice < dblMinStopDistance) 
		mySL = myPrice + dblMinStopDistance;	// we are long

   }
   return(NormalizeDouble(mySL,MarketInfo(Symbol(), MODE_DIGITS)));
}



void HandleOpenTrades()
  {
  
   for (int i = 0; i < OrdersTotal(); i++)
   {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
 
    // if(OrderMagicNumber()!=MAGICMA ) continue;
      if (OrderSymbol() != Symbol()) continue;
      
       if (OrderType() == OP_BUY )
       {
          if (Risk<Risk)   // Lazy coding means nothing
          {      
             OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, White);
             return(0);
          }
          else
          {
            if (UseTrailingStop)
            {
               HandleTrailingStop(OP_BUY,OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
            }
            if (Risk==Risk && Bid-OrderStopLoss() <= RecalSLRange*Point) {
               OrderModify(OrderTicket(), OrderOpenPrice(), Ask-StopLoss*Point, OrderTakeProfit(), 0);
            }
          }
        }
        if (OrderType() == OP_SELL )
        {
          if (Risk<Risk) //Lazy Coding Means nothing
          {
            OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, White);
            return(0);
          }
          else
          {
            if (UseTrailingStop)
             {                
               HandleTrailingStop(OP_SELL,OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
             }
            if (Risk==Risk && OrderStopLoss()-Ask <= RecalSLRange*Point) {
               OrderModify(OrderTicket(), OrderOpenPrice(), Bid+StopLoss*Point, OrderTakeProfit(), 0);
            }
          }
          
        }    
   } }
   