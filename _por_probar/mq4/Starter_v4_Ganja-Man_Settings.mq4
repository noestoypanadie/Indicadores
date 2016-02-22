//+------------------------------------------------------------------+
//|  on 4 majors: gpbusd, usdchf, eurusd, usdjpy M15
//|                                          Copyright © 2005, GCM   |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, GCM"
#property link      "http://"
#define MAGICNUM  20051002

extern double TakeProfit = 50;
extern double Lots = 1;
extern double TrailingStop = 10;
extern double StopLoss = 50;
extern int mm = 1;
extern double Riskpercent = 5;
extern int AccountIsMini = 0;
extern int LiveTrading = 1;
extern double DecreaseFactor = 3;
extern double Margincutoff = 800;
extern int Turnon = 1;
extern int MaximumLosses = 3;
extern double Stop = 10;
extern double MAPeriod=120;
string OrderText = "";
double lotMM;
int TradesInThisSymbol;
int cnt=0, total;
datetime LastTime;
double Sl;
double Tr;
int ticket;
int trstop = 0;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
if( Symbol()=="USDJPY"){ StopLoss=35; Print("Stoploss changed to 35");}
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
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
   int    tolosses=0;
//---- select lot size
   lot=NormalizeDouble(MathCeil(AccountBalance()*Riskpercent/10000)/10,1);
   
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
      for(i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(TimeDay(OrderCloseTime()) != TimeDay(CurTime())) continue;
         //----
         if(OrderProfit()<0) tolosses++;
        }
        if (tolosses >= MaximumLosses) trstop=1;
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
  if(lot > 1) 
      lot = MathCeil(lot);

  if(AccountIsMini==1) 
      lot = lot * 10;
//---- return lot size
   if(lot<0.1) lot=0.1;
  if(LiveTrading == 1)
  {
    if (AccountIsMini == 0 && lot < 1.0) 
         lot = 1.0;
  }
  if(lot > 100)
         lot = 100;

   return(lot);
  } 
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//---- 
   double Laguerre;
   double Laguerreprevious;
   double Alpha;
   double MA, MAprevious;
trstop = 0;
if(mm == 1)
{
  lotMM = LotsOptimized();
}
else {
  lotMM = Lots; // Change mm to 0 if you want the Lots parameter to be in effect
}
  Laguerre=iCustom(NULL, 0, "Laguerre", 0, 0);
  Laguerreprevious=iCustom(NULL, 0, "Laguerre", 0, 1);
  Alpha=iCCI(NULL, 0, 14, PRICE_CLOSE, 0);
  MA=iMA(NULL,0,MAPeriod,0,MODE_EMA,PRICE_MEDIAN,0);
  MAprevious=iMA(NULL,0,MAPeriod,0,MODE_EMA,PRICE_MEDIAN,1);
  
   total=OrdersTotal();
   TradesInThisSymbol = 0;
   for(cnt=0;cnt<total;cnt++)
     {
      if ( OrderSelect (cnt, SELECT_BY_POS) == false )  continue;
      if ( OrderSymbol() != Symbol() || OrderMagicNumber() != MAGICNUM)  continue;
      if((OrderType() == OP_BUY || OrderType() == OP_BUYSTOP) && (OrderSymbol()==Symbol()))
          {
             TradesInThisSymbol++;
            if(Laguerre>0.9)
                {
                 OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // close position
                 return(0); // exit
                }
            // check for stop
            if(Stop>0)  
              {                 
               if(Bid-OrderOpenPrice()>=Point*Stop)
                 {
                   OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // close position
                   return(0);
                 }
              }
             if(TrailingStop>0) 
               {                
                if(Bid-OrderOpenPrice()>Point*TrailingStop)
                  {
                   if(OrderStopLoss()<Bid-Point*TrailingStop)
                     {
                      OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Aqua);
                      return(0);
                     }
                  }
               }
          }
      if((OrderType() == OP_SELL || OrderType() == OP_SELLSTOP) && (OrderSymbol()==Symbol()))
          {
             TradesInThisSymbol++;
            if(Laguerre<0.1)
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close position
               return(0); // exit
              }
            // check for stop
            if(Stop>0)  
              {                 
               if(OrderOpenPrice()-Ask>=Point*Stop)
                 {
                   OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close position
                   return(0);
                 }
              }
             if(TrailingStop>0)  
               {                
                if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                  {
                   if(OrderStopLoss()==0.0 || 
                      OrderStopLoss()>(Ask+Point*TrailingStop))
                     {
                      OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Aqua);
                      return(0);
                     }
                  }
               }
          }
     }

if(AccountFreeMargin() < Margincutoff) {
   return(0);}
if(TradesInThisSymbol > 0) {
   return(0);}
if(CurTime() < LastTime) {
   return(0);}
   
OrderText = ""; //Must be blank before going into the main section

	// Is current bar a bull candle?
	if((Turnon == 1) && (Laguerreprevious<=0) && (Laguerre<=0) && (MA>MAprevious) && (Alpha<-5)) 
	{
		OrderText = "BUY";
		Sl = Ask-StopLoss*Point;
		Tr = Ask+TakeProfit*Point;
	}

	// Is current bar a bear candle?
	if((Turnon == 1) && (Laguerreprevious>=1) && (Laguerre>=1) && (MA<MAprevious) && (Alpha>5))
	{
		OrderText = "SELL";
		Sl = Bid+StopLoss*Point;
		Tr = Bid-TakeProfit*Point;
	}
   if(OrderText != "" && TradesInThisSymbol == 0 && trstop == 0) 
   {

	   LastTime = CurTime();
           if(OrderText == "BUY")
           {
	           ticket = OrderSend(Symbol(),OP_BUY,lotMM,Ask,3,Sl,Tr,"starter",MAGICNUM,0,Green);
	           LastTime += 12;
              if(ticket<=0) Print("Error = ",GetLastError());
              return(0);
           }
            else if(OrderText == "SELL")
            {
               ticket = OrderSend(Symbol(),OP_SELL,lotMM,Bid,3,Sl,Tr,"starter",MAGICNUM,0,Red);
               LastTime += 12;
               if(ticket<=0) Print("Error = ",GetLastError());
               return(0);
            }
      return(0);
   }
//----
   return(0);
  }
//+------------------------------------------------------------------+