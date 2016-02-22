//+------------------------------------------------------------------+
//|                                               PIVOTEMA3.mq4 |
//                                                
//            
// 6/14/2006 Modified by Robert Hill to use different ideas for trailing stop
//           and to show errors if they occur on order processing.
// 6/20/2006 Modified to check for Symbol and Comment match to close orders 

#property copyright "orBanAway aka cucurucu"
#property link      ""
#include <stdlib.mqh>

extern int     timeframe      = 0;
extern double  StopLoss       = 50; 
extern double  TakeProfit     = 150;
extern bool UseTrailingStop = true;
extern int TrailingStopType = 2;        // Type 1 moves stop immediately, Type 2 waits til value of TS is reached
extern double TrailingStop = 50;        // Change to whatever number of pips you wish to trail your position with.
extern double FirstMove = 30;       // Type 3  first level pip gain
extern double FirstStopLoss = 50;       // Move Stop to Breakeven
extern double SecondMove = 40;       // Type 3 second level pip gain
extern double SecondStopLoss = 50;       // Move stop to lock is profit
extern double ThirdMove = 50;
extern double TrailingStop3 = 50;       // Move stop and trail from there
extern string  Name_Expert    = "PivotEMA3";
extern int     Slippage       = 3;
extern bool    UseSound       = false;
extern string  NameFileSound  = "shotgun.wav";
extern double  Lots           = 1;
extern double  ProfitModifySL = 50;
extern int MagicNumber = 22222;
int  t= 0;  
int D,A;

int init(){return(0);}

int deinit(){return(0);}

int start(){
   
   if(Bars<100)   {Print("bars less than 100");return(0);}
   if(TakeProfit<10){Print("TakeProfit less than 10");return(0);}
   
   if(timeframe==0) {timeframe=Period();}

   
   double M=iMA(Symbol(),timeframe,3,0,MODE_EMA,PRICE_OPEN,0); // EMA3 Open
   double M1=iMA(Symbol(),timeframe,3,0,MODE_EMA,PRICE_OPEN,1); // Previous EMA3 Open
   double MC=iMA(Symbol(),timeframe,3,0,MODE_EMA,PRICE_CLOSE,0); // EMA3 Close
 
   double O=iCustom(Symbol(),timeframe,"Heiken Ashi",2,0); //Heiken Ashi Open
   double C=iCustom(Symbol(),timeframe,"Heiken Ashi",3,0); //Heiken Ashi Close
 
   double TR=iATR(Symbol(),timeframe,1,0); //True Range
   double ATR4=iATR(Symbol(),timeframe,4,0); //Average True Range
   double ATR8=iATR(Symbol(),timeframe,8,0);
   double ATR12=iATR(Symbol(),timeframe,12,0);
   double ATR24=iATR(Symbol(),timeframe,24,0);
  
   double TR1=iATR(Symbol(),timeframe,1,1); // Previous True Range
   double A4=iATR(Symbol(),timeframe,4,1); // Previous Average True Range
   double A8=iATR(Symbol(),timeframe,8,1);
   double A12=iATR(Symbol(),timeframe,12,1);
   double A24=iATR(Symbol(),timeframe,24,1);
   double TR2=iATR(Symbol(),timeframe,1,2);
 

   double P=iCustom(Symbol(),1440,"Pivot",0,0); // Daily Pivot

 
if(AccountFreeMargin()<(1000*Lots)){
      Print("We have no money. Free Margin = ", AccountFreeMargin());
      return(0);  }
      

if (!ExistPositions()) t=0;

/*if (t==0) Lots=MathCeil(AccountFreeMargin()/2500); //Money Management - Disabled for now, while still testing!
Print("Lots=",Lots);
Print("FreeMargin=",AccountFreeMargin());
*/    
A=0;
if (A4<ATR4) A=A+1;
if (A8<ATR8) A=A+1;
if (A12<ATR12) A=A+1;
if (A24<ATR24) A=A+1;

  if ((M1<=P) && (C>O) && (M>P) && ((TR>TR1)||(TR1>TR2)) && (A>0) && (MC>M)) 

   { //ENTER LONG 
    if (t==2) {closeAllOrders();t=0;} //Closing shorts
    if (t==0) {OpenBuy();t=1;D=DayOfYear();return(0);}
   }
   
  if ((M1>=P) && (C<O) && (M<P) && ((TR>TR1)||(TR1>TR2)) && (A>0) && (MC<M)) 

   { //ENTER SHORT  
   if (t==1) {closeAllOrders();t=0;} //Closing longs
   if (t==0) {OpenSell();t=2;D=DayOfYear();return(0);}
   } 

//if ((t==1) && (C<O) && (D==DayOfYear()) && (TR>TR1) && (A>0)){closeAllOrders();t=0;return(0);} //closing longs if HA changes colour
//if ((t==2) && (C>O) && (D==DayOfYear()) && (TR>TR1) && (A>0)){closeAllOrders();t=0;return(0);} //closing shorts if HA changes colour

  
   TrailingPositionsBuy();  
   TrailingPositionsSell();
 
return (0); }//end start

// - - - - - - FUNCTIONS - - - - - - -
 
bool ExistPositions()   {
   for(int i=0;i<OrdersTotal(); i++)  {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderComment()==Name_Expert) return(True);
         else return(false); }   }

void TrailingPositionsBuy() { 
   for(int i=0;i<OrdersTotal();i++) { 
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderComment()==Name_Expert) { 
            if(OrderType()==OP_BUY) {
               HandleTrailingStop("BUY",OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit()); 
                     }}}} 

void TrailingPositionsSell() { 
   for(int i=0;i<OrdersTotal();i++) { 
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderComment()==Name_Expert) { 
            if(OrderType()==OP_SELL) { 
               HandleTrailingStop("SELL",OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit()); 
                     }}}} 
 
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
int HandleTrailingStop(string type, int ticket, double op, double os, double tp)
{
    double pt, TS=0;
    double bos,bop,opa,osa;
    
    if (type == "BUY")
    {
       switch(TrailingStopType)
       {
        case 1: pt = Point*StopLoss;
                if(Bid-os > pt) ModifyStopLoss(ticket,op,Bid-pt,tp);
                break;
        case 2: pt = Point*TrailingStop;
                if(Bid-op > pt)
                {
                   if(os < Bid - pt || os == 0) ModifyStopLoss(ticket,op,Bid - pt,tp);
                }
                break;
        case 3: if (Bid - op > FirstMove * Point)
                {
                   TS = op + FirstMove*Point - FirstStopLoss * Point;
                   if (os < TS)
                   {
                    ModifyStopLoss(ticket,op,TS,tp);
                   }
                }
                 
                if (Bid - op > SecondMove * Point)
                {
                   TS = op + SecondMove*Point - SecondStopLoss * Point;
                   if (os < TS)
                   {
                    ModifyStopLoss(ticket,op,TS,tp);
                   }
                }
                 
                if (Bid - op > ThirdMove * Point)
                {
                   TS = Bid  - TrailingStop3*Point;
                   if (os < TS)
                   {
                     ModifyStopLoss(ticket,op,TS,tp);
                   }
                }
                break;
       }
       return(0);
    }
       
    if (type ==  "SELL")
    {
       switch(TrailingStopType)
       {
        case 1: pt = Point*StopLoss;
                if(os - Ask > pt) ModifyStopLoss(ticket,op,Ask+pt,tp);
                break;
        case 2: pt = Point*TrailingStop;
                if(op - Ask > pt)
                {
                   if(os > Ask+pt || os == 0) ModifyStopLoss(ticket,op,Ask+pt,tp);
                }
                break;
        case 3: if (op - Ask > FirstMove * Point)
                {
                   TS = op - FirstMove * Point + FirstStopLoss * Point;
                   if (os > TS)
                   {
                    ModifyStopLoss(ticket,op,TS,tp);
                   }
                }
                if (op - Ask > SecondMove * Point)
                {
                   TS = op - SecondMove * Point + SecondStopLoss * Point;
                   if (os > TS)
                   {
                    ModifyStopLoss(ticket,op,TS,tp);
                   }
                }
                if (op - Ask > ThirdMove * Point)
                {
                  TS = Ask + TrailingStop3 * Point;               
                  if (os > TS)
                  {
                    ModifyStopLoss(ticket,op,TS,tp);
                  }
                }
                break;
       }
    }
    return(0);
}

//+------------------------------------------------------------------+
//| Modify Open Position Controls                                    |
//|  Try to modify position 3 times                                  |
//+------------------------------------------------------------------+
void ModifyStopLoss(int ord_ticket,double ord_op, double ldStopLoss,double ord_tp)
{
    int CloseCnt, err;
    
    CloseCnt=0;
    while (CloseCnt < 3)
    {
       if (OrderModify(ord_ticket,ord_op,ldStopLoss,ord_tp,0,Aqua))
       {
         CloseCnt = 3;
         if (UseSound) PlaySound(NameFileSound); 
       }
       else
       {
          err=GetLastError();
          Print(CloseCnt," Error modifying order : (", err , ") " + ErrorDescription(err));
         if (err>0) CloseCnt++;
       }
    }
}
//+------------------------------------------------------------------+
//| Open Buy                                                         |
//| Open a new trade using Buy                                       |
//| If Stop Loss or TakeProfit are used the values are calculated    |
//| for each trade                                                   |
//+------------------------------------------------------------------+
void OpenBuy()
{
   int err,ticket;
   double ldLot, ldStop, ldTake; 
   string lsComm; 
   ldLot = GetSizeLot(); 
   
   ldStop = 0;
   if ( StopLoss > 0 ) ldStop = Ask - StopLoss * Point ;
   ldTake = 0;
   if (TakeProfit>0) ldTake = NormalizeDouble(GetTakeProfitBuy(),Digits);
   lsComm = GetCommentForOrder(); 
   ticket=OrderSend(Symbol(),OP_BUY,ldLot,NormalizeDouble(Ask,Digits),Slippage,ldStop,ldTake,lsComm,MagicNumber,0,Blue); 
   if(ticket<=0)
   {
      err = GetLastError();
      Print("Error opening BUY order [" + lsComm + "]: (" + err + ") " + ErrorDescription(err)); 
   }
   else
   {
      if (UseSound) PlaySound(NameFileSound);
   }
   
}

//+------------------------------------------------------------------+
//| Open Sell                                                        |
//| Open a new trade using Sell                                      |
//| If Stop Loss or TakeProfit are used the values are calculated    |
//| for each trade                                                   |
//+------------------------------------------------------------------+
void OpenSell()
{
   int err, ticket;
   double ldLot, ldStop, ldTake; 
   string lsComm;
    
   ldLot = GetSizeLot(); 
   
   ldStop = 0;
   if ( StopLoss > 0 ) ldStop = Bid + StopLoss * Point ;
   ldTake = 0;
   if (TakeProfit > 0) ldTake = NormalizeDouble(GetTakeProfitSell(),Digits); 
   lsComm = GetCommentForOrder(); 

   ticket=OrderSend(Symbol(),OP_SELL,ldLot,NormalizeDouble(Bid,Digits),Slippage,ldStop,ldTake,lsComm,MagicNumber,0,Red); 
   if(ticket<=0)
   {
      err = GetLastError();
      Print("Error opening Sell order [" + lsComm + "]: (" + err + ") " + ErrorDescription(err)); 
   }
   else
   {
     if (UseSound) PlaySound(NameFileSound);
   }
   
}

string GetCommentForOrder() { return(Name_Expert); } 
double GetSizeLot() { return(Lots); } 
double GetTakeProfitBuy() { return(Ask+TakeProfit*Point); } 
double GetTakeProfitSell() { return(Bid-TakeProfit*Point); } 

 

// close all open and pending orders

void closeAllOrders()  {
   for(int c=OrdersTotal() - 1;c>=0;c--) {
     OrderSelect(c,SELECT_BY_POS,MODE_TRADES);
        if (OrderSymbol() == Symbol() && OrderComment() == Name_Expert)
        { 
         if (OrderType() == OP_BUY)  {
            CloseOrder(OrderTicket(), OrderLots(),Bid);  }
         if (OrderType() == OP_SELL)  {
            CloseOrder(OrderTicket(), OrderLots(), Ask);  }   
         if (OrderType() > 1)  { OrderDelete(OrderTicket()); }
        }
   }
} 

// end closeAllOrders() 
//+------------------------------------------------------------------+
//| Close Open Position Controls                                     |
//|  Try to close position 3 times                                   |
//+------------------------------------------------------------------+
void CloseOrder(int ticket,double numLots,double close_price)
{
   int CloseCnt, err;
   
   // try to close 3 Times
      
    CloseCnt = 0;
    while (CloseCnt < 3)
    {
       if (OrderClose(ticket,numLots,close_price,Slippage,Red))
       {
         CloseCnt = 3;
       }
       else
       {
         err=GetLastError();
         Print(CloseCnt," Error closing order : (", err , ") " + ErrorDescription(err));
         if (err > 0) CloseCnt++;
       }
    }
}


