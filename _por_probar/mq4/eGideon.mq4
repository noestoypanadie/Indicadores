//+------------------------------------------------------------------+
//|                                                     Envelope.mq4 |
//|                                   tageiger aka fxid10t@yahoo.com |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "tageiger aka fxi10t@yahoo.com"
#property link      "http://www.metaquotes.net"

//---- input parameters
extern int        BS_EnvPeriod         =6;//ma length
extern int        BS_EnvTimeFrame      =30; //envelope time frame: 0=chart,60=1hr,240=4hr, etc.
extern int        BS_EnvMaMethod       =0; //0=sma,1=ema,2=smma,3=lwma.
extern double     BS_EnvDeviation      =0.1;//envelope width

extern int        TP1_EnvPeriod        =6;//ma length
extern int        TP1_EnvTimeFrame     =30; //envelope time frame: 0=chart,60=1hr,240=4hr, etc.
extern int        TP1_EnvMaMethod      =0; //0=sma,1=ema,2=smma,3=lwma.
extern double     TP1_EnvDeviation     =0.25;//envelope width

extern int        TP2_EnvPeriod        =6;//ma length
extern int        TP2_EnvTimeFrame     =30; //envelope time frame: 0=chart,60=1hr,240=4hr, etc.
extern int        TP2_EnvMaMethod      =0; //0=sma,1=ema,2=smma,3=lwma.
extern double     TP2_EnvDeviation     =0.4;//envelope width

extern int        SL_EnvPeriod      =4;//ma length
extern int        SL_EnvTimeFrame   =30; //envelope time frame: 0=chart,60=1hr,240=4hr, etc.
extern int        SL_EnvMaMethod    =0; //0=sma,1=ema,2=smma,3=lwma.
extern double     SL_EnvDeviation   =0.05;//envelope width

extern int        TS_EnvPeriod      =1;//ma length
extern int        TS_EnvTimeFrame   =30; //envelope time frame: 0=chart,60=1hr,240=4hr, etc.
extern int        TS_EnvMaMethod    =0; //0=sma,1=ema,2=smma,3=lwma.
extern double     TS_EnvDeviation   =0.05;//envelope width

extern int        OSMA_Fast         =12;//ma length
extern int        OSAM_Slow         =26; //envelope time frame: 0=chart,60=1hr,240=4hr, etc.
extern int        OSMA_Signal       =9; //0=sma,1=ema,2=smma,3=lwma.

extern int        Enable_TSL        =0;//0=Original StopLoss  1=Enable TS Envelope TSL
extern int        TimeBegin         =0;//server time order placement begins
extern int        TimeEnd           =18;//server time order placement ends
extern int        TimeDelete        =23;//server time unexecuted orders deleted
extern double     Lift              =4.0;
extern double     CounterSL         =10.0;
extern double     Lots              =0.1;
extern double     MaximumRisk       =0.02;
extern double     DecreaseFactor    =3;

extern int        WaitBarsForProfit =4;
int               b1,b2,b3,s1,s2,s3;
double            TSL               =0;
string            comment           ="Minute eGideon.1 ";
string            TradeSymbol;      TradeSymbol=Symbol();

int init()  {  return(0);  }
int deinit(){  return(0);  }
int start() {
   int   BUY_uline,SELL_lline,TP1_uline,TP1_lline,TP2_uline,TP2_lline,SL_uline,SL_lline,TS_uline;
   int   TS_lline,OSMA1,OSMA2,BS_EnvPeriod, BS_EnvTimeFrame, BS_EnvMethod, BS_EnvDeviation;
   int   TP1_EnvPeriod,TP1_EnvTimeFrame,TP1_EnvMethod,TP1_EnvDeviation;
   int   TP2_EnvPeriod,TP2_EnvTimeFrame,TP2_EnvMethod,TP2_EnvDeviation;
   int   SL_EnvPeriod,SL_EnvTimeFrame,SL_EnvMethod,SL_EnvDeviation;
   int   TS_EnvPeriod,TS_EnvTimeFrame,TS_EnvMethod,TS_EnvDeviation;
   int   OSMA_Fast,OSMA_Slow,OSMA_Signal, OSMA_Period;
   int   WaitBarsForProfit;
   int   CounterTP,cnt, ticket,total=OrdersTotal();

   BUY_uline=iEnvelopes(NULL,BS_EnvTimeFrame,BS_EnvPeriod,BS_EnvMethod,0,PRICE_CLOSE,BS_EnvDeviation,MODE_UPPER,0);
   SELL_lline=iEnvelopes(NULL,BS_EnvTimeFrame,BS_EnvPeriod,BS_EnvMethod,0,PRICE_CLOSE,BS_EnvDeviation,MODE_LOWER,0);

   TP1_uline=iEnvelopes(NULL,BS_EnvTimeFrame,BS_EnvPeriod,BS_EnvMethod,0,PRICE_OPEN,BS_EnvDeviation,MODE_UPPER,0);
   TP1_lline=iEnvelopes(NULL,BS_EnvTimeFrame,BS_EnvPeriod,BS_EnvMethod,0,PRICE_OPEN,BS_EnvDeviation,MODE_LOWER,0);

   TP2_uline=iEnvelopes(NULL,BS_EnvTimeFrame,BS_EnvPeriod,BS_EnvMethod,0,PRICE_OPEN,BS_EnvDeviation,MODE_UPPER,0);
   TP2_lline=iEnvelopes(NULL,BS_EnvTimeFrame,BS_EnvPeriod,BS_EnvMethod,0,PRICE_OPEN,BS_EnvDeviation,MODE_LOWER,0);

   SL_uline=iEnvelopes(NULL,BS_EnvTimeFrame,BS_EnvPeriod,BS_EnvMethod,0,PRICE_OPEN,BS_EnvDeviation,MODE_UPPER,0);
   SL_lline=iEnvelopes(NULL,BS_EnvTimeFrame,BS_EnvPeriod,BS_EnvMethod,0,PRICE_OPEN,BS_EnvDeviation,MODE_LOWER,0);

   TS_uline=iEnvelopes(NULL,BS_EnvTimeFrame,BS_EnvPeriod,BS_EnvMethod,0,PRICE_OPEN,BS_EnvDeviation,MODE_UPPER,0);
   TS_lline=iEnvelopes(NULL,BS_EnvTimeFrame,BS_EnvPeriod,BS_EnvMethod,0,PRICE_OPEN,BS_EnvDeviation,MODE_LOWER,0);
   
   OSMA1  = iOsMA (NULL, OSMA_Period, OSMA_Fast, OSMA_Slow, OSMA_Signal,PRICE_CLOSE, 1);
	OSMA2  = iOsMA (NULL, OSMA_Period, OSMA_Fast, OSMA_Slow, OSMA_Signal,PRICE_CLOSE, 2);
	

   if(TotalTradesThisSymbol(TradeSymbol)==0) {  b1=0;b2=0;b3=0;s1=0;s2=0;s3=0;   }
   if(TotalTradesThisSymbol(TradeSymbol)>0)  {
      for(cnt=0;cnt<total;cnt++) {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==TradeSymbol) {
         if(OrderMagicNumber()==21)  {b1=OrderTicket(); }
         if(OrderMagicNumber()==41)  {b2=OrderTicket(); }
         if(OrderMagicNumber()==61)  {b3=OrderTicket(); }
         if(OrderMagicNumber()==11)  {s1=OrderTicket(); }
         if(OrderMagicNumber()==31)  {s2=OrderTicket(); }
         if(OrderMagicNumber()==51)  {s3=OrderTicket(); } }  }  }
   
      if(b1==0)   {  
         if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
            if(BUY_uline<Close[0] && OSMA1>0 && OSMA2>0 && OSMA1>OSMA2 && Open[0]<BUY_uline) {
               ticket=OrderSend(Symbol(),
                                 OP_BUY,
                                 LotsOptimized(),
                                 NormalizeDouble(BUY_uline,Digits),
                                 0,
                                 NormalizeDouble(SL_lline,Digits),
                                 NormalizeDouble(TP1_uline,Digits),
                                 Period()+comment+"Buy TP1",
                                 21,
                                 0,
                                 Aqua);
                                 if(ticket>0)   {
                                    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                       {  b1=ticket;  Print(ticket); }
                                    else Print("Error Opening BuyStop Order: ",GetLastError());
                                    return(0);  }  }  }  }         
      if(b2==0)   {  
         if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
            if(BUY_uline<Close[0] && OSMA1>0 && OSMA2>0 && OSMA1>OSMA2 && Open[0]<BUY_uline) {
               ticket=OrderSend(Symbol(),
                                 OP_BUY,
                                 LotsOptimized(),
                                 NormalizeDouble(BUY_uline,Digits)+(Lift*Point),
                                 0,
                                 NormalizeDouble(SL_lline,Digits),
                                 NormalizeDouble(TP2_uline,Digits),
                                 Period()+comment+"Buy TP2",
                                 41,
                                 0,
                                 Aqua);
                                 if(ticket>0)   {
                                    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                       {  b1=ticket;  Print(ticket); }
                                    else Print("Error Opening BuyStop Order: ",GetLastError());
                                    return(0);  }  }  }  }         
      if(b3==0)   {  
         if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
            if(BUY_uline<Close[0] && OSMA1>0 && OSMA2>0 && OSMA1<OSMA2 && Open[0]<BUY_uline)  {
               CounterTP=(NormalizeDouble(SL_lline,Digits));
               ticket=OrderSend(Symbol(),
                                 OP_SELL,
                                 LotsOptimized(),
                                 (NormalizeDouble(BUY_uline,Digits)),
                                 0,
                                 CounterSL,
                                 CounterTP,
                                 Period()+comment+"CounterSELL",
                                 61,
                                 0,
                                 Aqua);
                                 if(ticket>0)   {
                                    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                       {  b1=ticket;  Print(ticket); }
                                    else Print("Error Opening BuyStop Order: ",GetLastError());
                                    return(0);  }  }  }  }         
      if(s1==0)   {
         if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
            if(SELL_lline>Close[0] && OSMA1<0 && OSMA2<0 && OSMA1<OSMA2 && Open[0]>SELL_lline)  {
               ticket=OrderSend(Symbol(),
                                 OP_SELL,
                                 LotsOptimized(),
                                 (NormalizeDouble(SELL_lline,Digits)),
                                 0,
                                 (NormalizeDouble(SL_uline,Digits)),
                                 (NormalizeDouble(TP1_lline,Digits)),
                                 Period()+comment+"Sell TP1",
                                 11,
                                 0,
                                 Aqua);
                                 if(ticket>0)   {
                                    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                       {  b1=ticket;  Print(ticket); }
                                    else Print("Error Opening BuyStop Order: ",GetLastError());
                                    return(0);  }  }  }  }         
      if(s2==0)
         {
         if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
            if(SELL_lline>Close[0] && OSMA1<0 && OSMA2<0 && OSMA1<OSMA2 && Open[0]>SELL_lline)  {
               ticket=OrderSend(Symbol(),
                                 OP_SELL,
                                 LotsOptimized(),
                                 (NormalizeDouble(SELL_lline,Digits)),
                                 0,
                                 (NormalizeDouble(SL_uline,Digits)),
                                 (NormalizeDouble(TP2_lline,Digits)),
                                 Period()+comment+"Sell TP2",
                                 31,
                                 0,
                                 Aqua);
                                 if(ticket>0)   {
                                    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))  
                                       {  b1=ticket;   Print(ticket);   }
                                    else Print("Error Opening BuyStop Order: ",GetLastError());
                                    return(0);  }  }  }  }
      if(s3==0)   {
         if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
            if(SELL_lline>Close[0] && OSMA1<0 && OSMA2<0 && OSMA1>OSMA2 && Open[0]>SELL_lline)   {
               CounterTP=(NormalizeDouble(SL_uline,Digits));
               ticket=OrderSend(Symbol(),
                                 OP_BUY,
                                 LotsOptimized(),
                                 (NormalizeDouble(SELL_lline,Digits)),
                                 0,
                                 CounterSL,
                                 CounterTP,
                                 Period()+comment+"CounterBUY",
                                 51,
                                 0,
                                 Aqua);
                                 if(ticket>0)   {
                                    if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                       {  b1=ticket;  Print(ticket); }
                                    else Print("Error Opening BuyStop Order: ",GetLastError());
                                    return(0);  }  }  }  }
   
   for(cnt=0;cnt<total;cnt++) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);            
         if(OrderType()==OP_BUY) {
            if(Enable_TSL==0) {TSL=NormalizeDouble(SL_uline,Digits); }
            if(Enable_TSL==1) {TSL=NormalizeDouble(TS_uline,Digits); }
            if(Bid>OrderOpenPrice())   {
               if((/*Close[0]>BUY_uline) && (*/TSL>OrderStopLoss())) {
                  double bsl;bsl=TSL;
                  OrderModify(OrderTicket(),
                              OrderOpenPrice(),
                              bsl,
                              OrderTakeProfit(),
                              0,//Order expiration server date/time
                              Green);  }  }  }
         if(OrderType()==OP_SELL)   {
            if(Enable_TSL==0) {TSL=NormalizeDouble(SL_lline,Digits); }
            if(Enable_TSL==1) {TSL=NormalizeDouble(TS_lline,Digits); }        
            if(Ask<OrderOpenPrice())   {
               if((/*Close[0]<SELL_lline) && (*/TSL<OrderStopLoss()))   {
                  double ssl;ssl=TSL;
                  OrderModify(OrderTicket(),
                              OrderOpenPrice(),
                              ssl,
                              OrderTakeProfit(),
                              0,//Order expiration server date/time
                              Red); }  }  }      
         //CLOSE OPEN Orders when....//
         if(LocalTime()-OrderOpenTime()>(BS_EnvTimeFrame*60*60)*WaitBarsForProfit && OrderType()==OP_BUYSTOP)  {
            OrderDelete(OrderTicket());
            if(OrderTicket()==b1) {b1=0; return;}
            if(OrderTicket()==b2) {b2=0; return;}
            if(OrderTicket()==b3) {b3=0; return;}  }
         if(LocalTime()-OrderOpenTime()>(BS_EnvTimeFrame*60*60)*WaitBarsForProfit && OrderType()==OP_SELLSTOP)  {
            OrderDelete(OrderTicket());
            if(OrderTicket()==s1) {s1=0; return;}
            if(OrderTicket()==s2) {s2=0; return;}
            if(OrderTicket()==s3) {s3=0; return;}  }
         //CLOSE PENDING Orders when....//
         if(Hour()==TimeDelete && OrderType()==OP_BUYSTOP)  {
            OrderDelete(OrderTicket());
            if(OrderTicket()==b1) {b1=0; return;}
            if(OrderTicket()==b2) {b2=0; return;}
            if(OrderTicket()==b3) {b3=0; return;}  }
         if(Hour()==TimeDelete && OrderType()==OP_SELLSTOP) {
            OrderDelete(OrderTicket());
            if(OrderTicket()==s1) {s1=0; return;}
            if(OrderTicket()==s2) {s2=0; return;}
            if(OrderTicket()==s3) {s3=0; return;}  }
         OrderSelect(b1,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {b1=0;}
         OrderSelect(b2,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {b2=0;}
         OrderSelect(b3,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {b3=0;}
         OrderSelect(s1,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {s1=0;}
         OrderSelect(s2,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {s2=0;}     
         OrderSelect(s3,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {s3=0;}
   }
if(!IsTesting())  PrintComments();
return(0);   
}

//Functions

double LotsOptimized()  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//---- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//---- calcuulate number of losses orders without a break
   if(DecreaseFactor>0) {
     for(int i=orders-1;i>=0;i--)   {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         //----
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++; }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);   }
   //---- return lot size//
   if(lot<0.1) lot=0.1;
   return(lot);
}//end LotsOptimized//

int TotalTradesThisSymbol(string TradeSymbol) 
{
   int i, TradesThisSymbol=0;
   
   for(i=0;i<OrdersTotal();i++)  {
      OrderSelect(i,SELECT_BY_POS);
      if(OrderSymbol()==TradeSymbol &&
         OrderMagicNumber()==11 ||
         OrderMagicNumber()==21 || 
         OrderMagicNumber()==31 || 
         OrderMagicNumber()==41 || 
         OrderMagicNumber()==51 || 
         OrderMagicNumber()==61)   {  TradesThisSymbol++;  }
      }  //end for
  return(TradesThisSymbol);
}//end TotalTradesThisSymbol


void PrintComments() 
{  
   Comment("Current Time: ",Hour(),":",Minute(),"\n");  
}

