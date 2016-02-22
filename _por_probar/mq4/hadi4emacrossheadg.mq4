//+------------------------------------------------------------------+
//|                                                  EMA_CROSS_3.mq4 |
//|                                                      hadias qhta |
//|                                         http://www.forhadifo.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Thanks going to all the members of forex-tsd whom                |
//| without them -After God of course- There's no Coders' hadi.      |
//|                                                                  |
//| I wanna thank specially:                                         |
//| Hiiiiiii, hhhhhhh, hellkhh, hadiiiii, hadi,hadiiiii, hhhhhhh,    |         
//| ciiiiiii, hhhhhh                                                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|Use this code at your risk, I don't guarantee anything.           | 
//|If you've decided to go live with this EA go at your risk.        |
//|I'm not sharing you your profits and it's logical that I'm not    | 
//|  sharing you your losses too.                                    |
//+------------------------------------------------------------------+



#property copyright "hadi4"
#property link      "http://www.forhadi.com"
#define MAGICMA  20060308

//---- Trades limits
extern double    TakeProfit=180;
extern double    TrailingStop=30;
extern double    StopLoss=70;
extern bool      UseStopLoss = false;

extern double slippage = 3;

//Hedging Optimization Results
//Daily
//457	65569.99	149	9.98	440.07	439.99	1.24%	HedgingTakeProfit=115 	HedgingStopLoss=10 	HedgingLevel=10
//428	64989.97	136	21.63	477.87	200.00	0.32%	HedgingTakeProfit=115 	HedgingStopLoss=5 	HedgingLevel=10
//458	64269.99	149	9.57	431.34	439.99	1.26%	HedgingTakeProfit=120 	HedgingStopLoss=10 	HedgingLevel=10
//H1
//296	7940.00	32	3.36	248.13	1000.00	6.00%	HedgingTakeProfit=80 	HedgingStopLoss=70 	HedgingLevel=5
//610	7820.00	24	2.64	325.83	840.00	4.50%	HedgingTakeProfit=90 	HedgingStopLoss=70 	HedgingLevel=10
//309	7310.00	16	5.27	456.88	700.00	5.67%	HedgingTakeProfit=145 	HedgingStopLoss=70 	HedgingLevel=5

//---- Hedging settings
extern double    HedgingTakeProfit=90;
extern double    HedgingStopLoss=70;
extern double    HedgingLevel=10;
extern bool      UseHedging = true;

//---- EMAs paris
extern int ShortEma = 10; 
extern int LongEma = 80;

//---- Crossing options
extern bool ImmediateTrade = true; //Open trades immediately or wait for cross.
extern bool CounterTrend = true; //Use the originally CounterTrend crossing method or not

//---- Money Management
extern double Lots = 1;
extern bool UseMoneyManagement = true; //Use Money Management or not
extern bool AccountIsMicro = true; //Use Micro-Account or not
extern int Risk = 10; //10%

//---- Time Management
extern bool    UseHourTrade = false;  
extern int     FromHourTrade = 8;
extern int     ToHourTrade = 18;

extern bool Show_Settings = false;
extern bool Summarized = false;


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
   if(Show_Settings && Summarized == false) Print_Details();
   else if(Show_Settings && Summarized) Print_Details_Summarized();
   else Comment("");
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
  
bool isNewSumbol(string current_symbol)
  {
   //loop through all the opened order and compare the symbols
   int total  = OrdersTotal();
   for(int cnt = 0 ; cnt < total ; cnt++)
   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      string selected_symbol = OrderSymbol();
      if (current_symbol == selected_symbol)
      return (False);
    }
    return (True);
}

int Crossed()
 {
   double EmaLongPrevious = iMA(NULL,0,LongEma,0,MODE_EMA, PRICE_CLOSE, 1); 
	double EmaLongCurrent = iMA(NULL,0,LongEma,0,MODE_EMA, PRICE_CLOSE, 0);
	double EmaShortPrevious = iMA(NULL,0,ShortEma,0,MODE_EMA, PRICE_CLOSE, 1);
	double EmaShortCurrent = iMA(NULL,0,ShortEma,0,MODE_EMA, PRICE_CLOSE, 0);
	   
	if(ImmediateTrade)
   {
      if (EmaShortCurrent<EmaLongCurrent)return (1); //down trend
      if (EmaShortCurrent>EmaLongCurrent)return (2); //up trend
   }
	   
   if (EmaShortPrevious>EmaLongPrevious && EmaShortCurrent<EmaLongCurrent ) return (1); //down trend
   if (EmaShortPrevious<EmaLongPrevious && EmaShortCurrent>EmaLongCurrent ) return (2); //up trend

   return (0); //elsewhere
 }


//--- Bassed on Alex idea! More ideas are coming
double LotSize()
{
     double lotMM = MathCeil(AccountFreeMargin() *  Risk / 1000) / 100;
	  
	  if(AccountIsMicro==false) //normal account
	  {
	     if (lotMM < 0.1) lotMM = Lots;
	     if ((lotMM > 0.5) && (lotMM < 1)) lotMM = 0.5; //Thanks cucurucu
	     if (lotMM > 1.0) lotMM = MathCeil(lotMM);
	     if  (lotMM > 100) lotMM = 100;
	  }
	  else //micro account
	  {
	     if (lotMM < 0.01) lotMM = Lots;
	     if (lotMM > 1.0) lotMM = MathCeil(lotMM);
	     if  (lotMM > 100) lotMM = 100;
	  }
	  
	  return (lotMM);
}

string BoolToStr ( bool value)
{
   if(value) return ("True");
   else return ("False");
}
void Print_Details()
{
   string sComment = "";
   string sp = "----------------------------------------\n";
   string NL = "\n";

   sComment = sp;
   sComment = sComment + "TakeProfit=" + DoubleToStr(TakeProfit,0) + " | ";
   sComment = sComment + "TrailingStop=" + DoubleToStr(TrailingStop,0) + " | ";
   sComment = sComment + "StopLoss=" + DoubleToStr(StopLoss,0) + " | "; 
   sComment = sComment + "UseStopLoss=" + BoolToStr(UseStopLoss) + NL;
   sComment = sComment + sp;
   sComment = sComment + "ImmediateTrade=" + BoolToStr(ImmediateTrade) + " | ";
   sComment = sComment + "CounterTrend=" + BoolToStr(CounterTrend) + " | " ;
   if(UseHourTrade)
   {
   sComment = sComment + "UseHourTrade=" + BoolToStr(UseHourTrade) + " | ";
   sComment = sComment + "FromHourTrade=" + DoubleToStr(FromHourTrade,0) + " | ";
   sComment = sComment + "ToHourTrade=" + DoubleToStr(ToHourTrade,0) + NL;
   }
   else
   {
   sComment = sComment + "UseHourTrade=" + BoolToStr(UseHourTrade) + NL;
   }

   
   sComment = sComment + sp;
   sComment = sComment + "Lots=" + DoubleToStr(Lots,0) + " | ";
   sComment = sComment + "UseMoneyManagement=" + BoolToStr(UseMoneyManagement) + " | ";
   sComment = sComment + "AccountIsMicro=" + BoolToStr(AccountIsMicro) + " | ";
   sComment = sComment + "Risk=" + DoubleToStr(Risk,0) + "%" + NL;
   sComment = sComment + sp;
  
   Comment(sComment);
}

void Print_Details_Summarized()
{
   string sComment = "";
   string sp = "----------------------------------------\n";
   string NL = "\n";

   sComment = sp;
   sComment = sComment + "TF=" + DoubleToStr(TakeProfit,0) + " | ";
   sComment = sComment + "TS=" + DoubleToStr(TrailingStop,0) + " | ";
   sComment = sComment + "SL=" + DoubleToStr(StopLoss,0) + " | "; 
   sComment = sComment + "USL=" + BoolToStr(UseStopLoss) + NL;
   sComment = sComment + sp;
   sComment = sComment + "IT=" + BoolToStr(ImmediateTrade) + " | ";
   sComment = sComment + "CT=" + BoolToStr(CounterTrend) + " | " ;
   if(UseHourTrade)
   {
   sComment = sComment + "UHT=" + BoolToStr(UseHourTrade) + " | ";
   sComment = sComment + "FHT=" + DoubleToStr(FromHourTrade,0) + " | ";
   sComment = sComment + "THT=" + DoubleToStr(ToHourTrade,0) + NL;
   }
   else
   {
   sComment = sComment + "UHT=" + BoolToStr(UseHourTrade) + NL;
   }

   
   sComment = sComment + sp;
   sComment = sComment + "L=" + DoubleToStr(Lots,0) + " | ";
   sComment = sComment + "MM=" + BoolToStr(UseMoneyManagement) + " | ";
   sComment = sComment + "AIM=" + BoolToStr(AccountIsMicro) + " | ";
   sComment = sComment + "R=" + DoubleToStr(Risk,0) + "%" + NL;
   sComment = sComment + sp;
  
   Comment(sComment);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//---- 

   if (UseHourTrade)
    {
      if (!(Hour()>=FromHourTrade && Hour()<=ToHourTrade)) 
      {
         Comment("Time for trade has not come yet!");
         return(0);
      } 
   }

   int cnt, ticket, ticket2, total;
   
   string comment = "";
   if(CounterTrend==true) comment = "EMAC_Counter";
   if(CounterTrend==false) comment = "EMAC_Pro";
   if(ImmediateTrade==true) comment = comment + "_Immediate";
   if(ImmediateTrade==false) comment = comment + "Postponed";

   if(Bars<100)
     {
      Print("bars less than 100");
      return(0);  
     }
   if(TakeProfit<5)
     {
      Print("TakeProfit less than 10");
      return(0);  // check TakeProfit
     }
   
   int isCrossed  = 0;
   isCrossed = Crossed ();
   
   if(CounterTrend==false)
   {
      if(isCrossed==1) isCrossed=2;
      if(isCrossed==2) isCrossed=1;
   }
   
   if(UseMoneyManagement==true) Lots = LotSize(); //Adjust the lot size
  
   total  = OrdersTotal();
  
   if(total < 1 || isNewSumbol(Symbol())) 
     {
       if(isCrossed == 1)
         {
            
            if(UseStopLoss)
               ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,slippage,Ask-StopLoss*Point,Ask+TakeProfit*Point,comment,MAGICMA,0,Green);
            else
               ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,slippage,0,Ask+TakeProfit*Point,comment,MAGICMA,0,Green);
            
            if(ticket>0)
              {
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
              }
            else Print("Error opening BUY order : ",GetLastError()); 
            
            if(UseHedging) Hedge(ticket,Lots);
            
            return(0);
         }
         if(isCrossed == 2)
         {
            if(UseStopLoss)
               ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,slippage,Bid+StopLoss*Point,Bid-TakeProfit*Point,comment,123,0,Red);
            else
               ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,slippage,0,Bid-TakeProfit*Point,comment,MAGICMA,0,Red);
            
            if(ticket>0)
              {
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
              }
            else Print("Error opening SELL order : ",GetLastError()); 
            
            if(UseHedging) Hedge(ticket,Lots);
            
            return(0);
         }
         return(0);
     }
   
    
       
     
   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber() == MAGICMA)
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
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
                     return(0);
                    }
                 }
              }
           }
        }
     }
     
   return(0);
  }
//+------------------------------------------------------------------+

string GetOrderType( int type)
{
   if(type == OP_BUY) return ("Buying position");
   if(type == OP_SELL) return ("Selling position");
   if(type == OP_BUYLIMIT) return ("Buy Limit pending position");
   if(type == OP_BUYSTOP) return ("Buy Stop pending position");
   if(type == OP_SELLLIMIT) return ("Sell Limit pending position");
   if(type == OP_SELLSTOP) return ("Sell Stop pending position");
}
void Hedge (int order_ticket , double hlots)
{
   int ticket, order_type;
   string hcomment = "EMAC_" + Symbol() + "_Hedging";
    
   if(OrderSelect(order_ticket,SELECT_BY_TICKET,MODE_TRADES)) 
   {
      order_type = OrderType();
      
      if(order_type == OP_SELL) 
      {
         ticket=OpenPendingOrder(OP_SELLSTOP,hlots,HedgingLevel,slippage,HedgingStopLoss,HedgingTakeProfit,hcomment);
         if(ticket>0)
         {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("Hedgin " + GetOrderType(OrderType()) + " placed : ",OrderOpenPrice());
          }
          else Print("Error opening Hedgin " + GetOrderType(OrderType()) + " : ",GetLastError());
            
         ticket=OpenPendingOrder(OP_BUYSTOP,hlots,HedgingLevel,slippage,HedgingStopLoss,HedgingTakeProfit,hcomment);
         if(ticket>0)
         {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("Hedgin " + GetOrderType(OrderType()) + " placed : ",OrderOpenPrice());
          }
          else Print("Error opening Hedgin " + GetOrderType(OrderType()) + " : ",GetLastError());
      }     
      
      if(order_type == OP_BUY) 
      {
         ticket=OpenPendingOrder(OP_BUYSTOP,hlots,HedgingLevel,slippage,HedgingStopLoss,HedgingTakeProfit,hcomment);
         if(ticket>0)
         {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("Hedgin " + GetOrderType(OrderType()) + " placed : ",OrderOpenPrice());
         }
         else Print("Error opening Hedgin " + GetOrderType(OrderType()) + " : ",GetLastError());
            
         ticket=OpenPendingOrder(OP_SELLSTOP,hlots,HedgingLevel,slippage,HedgingStopLoss,HedgingTakeProfit,hcomment);
         if(ticket>0)
         {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("Hedgin " + GetOrderType(OrderType()) + " placed : ",OrderOpenPrice());
          }
          else Print("Error opening Hedgin " + GetOrderType(OrderType()) + " : ",GetLastError());
      }
      
    }
}

int OpenPendingOrder(int pType=OP_BUYLIMIT,double pLots=1,double pLevel=5,int sp=0, double sl=0,double tp=0,string pComment="",int pMagic=123,datetime pExpiration=0,color pColor=Yellow)
{
  switch (pType)
  {
      case OP_BUYLIMIT:
         return(OrderSend(Symbol(),OP_BUYLIMIT,pLots,Ask-pLevel*Point,sp,(Ask-pLevel*Point)-sl*Point,(Ask-pLevel*Point)+tp*Point,pComment,pMagic,pExpiration,pColor));    
         break;
      case OP_BUYSTOP:
         return(OrderSend(Symbol(),OP_BUYSTOP,pLots,Ask+pLevel*Point,sp,(Ask+pLevel*Point)-sl*Point,(Ask+pLevel*Point)+tp*Point,pComment,pMagic,pExpiration,pColor));     
         break;
      case OP_SELLLIMIT:
         return(OrderSend(Symbol(),OP_SELLLIMIT,pLots,Bid+pLevel*Point,sp,(Bid+pLevel*Point)+sl*Point,(Bid+pLevel*Point)-tp*Point,pComment,pMagic,pExpiration,pColor));    
         break;
      case OP_SELLSTOP:
         return(OrderSend(Symbol(),OP_SELLSTOP,pLots,Bid-pLevel*Point,sp,(Bid-pLevel*Point)+sl*Point,(Bid-pLevel*Point)-tp*Point,pComment,pMagic,pExpiration,pColor));    
         break;
  } 
}


