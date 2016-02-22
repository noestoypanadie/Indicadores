//+------------------------------------------------------------------+
//|                                               PIVOTEMA3.mq4 |
//                                                
//            

#property copyright "orBanAway aka cucurucu"
#property link      ""

extern int     timeframe      = 0;
extern double  stopLoss       = 50; 
extern double  TakeProfit     = 350;
extern double  TrailingStop   = 50;
extern string  Name_Expert    = "PivotEMA3";
extern int     Slippage       = 3;
extern bool    UseSound       = true;
extern string  NameFileSound  = "shotgun.wav";
extern double  Lots           = 1;
extern double  ProfitModifySL = 50;
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

  
   TrailingPositionsBuy(TrailingStop);  
   TrailingPositionsSell(TrailingStop);
 
return (0); }//end start

// - - - - - - FUNCTIONS - - - - - - -
 
void fModifyStopLoss(double tStopLoss) 
{ 
   bool result = OrderModify(OrderTicket(),OrderOpenPrice(),tStopLoss,OrderTakeProfit(),0,NULL); 
}

bool ExistPositions()   {
   for(int i=0;i<OrdersTotal(); i++)  {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderComment()==Name_Expert) return(True);
         else return(false); }   }

void TrailingPositionsBuy(int trailingStop) { 
   for(int i=0;i<OrdersTotal();i++) { 
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderComment()==Name_Expert) { 
            if(OrderType()==OP_BUY) { 
               if(Bid-OrderOpenPrice()>trailingStop*Point) { 
                  if(OrderStopLoss()<Bid-trailingStop*Point || OrderStopLoss()==0)   {
                     ModifyStopLoss(Bid-trailingStop*Point); }}}}}} 

void TrailingPositionsSell(int trailingStop) { 
   for(int i=0;i<OrdersTotal();i++) { 
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderComment()==Name_Expert) { 
            if(OrderType()==OP_SELL) { 
               if(OrderOpenPrice()-Ask>trailingStop*Point) { 
                  if(OrderStopLoss()>Ask+trailingStop*Point || OrderStopLoss()==0)  {  
                     ModifyStopLoss(Ask+trailingStop*Point);}}}}}} 
 
void ModifyStopLoss(double ldStopLoss) { 
   bool fm;
   fm = OrderModify(OrderTicket(),OrderOpenPrice(),ldStopLoss,OrderTakeProfit(),0,0); 
   if (fm && UseSound) PlaySound(NameFileSound); 
} 

void OpenBuy() { 
   double ldLot, ldStop, ldTake; 
   string lsComm; 
   ldLot = GetSizeLot(); 
   ldStop = Ask-Point*stopLoss; 
   ldTake = NormalizeDouble(GetTakeProfitBuy(),Digits); 
   lsComm = GetCommentForOrder(); 
   OrderSend(Symbol(),OP_BUY,ldLot,NormalizeDouble(Ask,Digits),Slippage,ldStop,ldTake,lsComm,0,0,Blue); 
   if (UseSound) PlaySound(NameFileSound);   }
 
void OpenSell() { 
   double ldLot, ldStop, ldTake; 
   string lsComm; 
   ldLot = GetSizeLot(); 
   ldStop = Bid+Point*stopLoss; 
   ldTake = NormalizeDouble(GetTakeProfitSell(),Digits); 
   lsComm = GetCommentForOrder(); 
   OrderSend(Symbol(),OP_SELL,ldLot,NormalizeDouble(Bid,Digits),Slippage,ldStop,ldTake,lsComm,0,0,Red); 
   if (UseSound) PlaySound(NameFileSound);   }

// close all open and pending orders

void closeAllOrders()  {
   for(int c=0;c<OrdersTotal();c++) {
     OrderSelect(c,SELECT_BY_POS,MODE_TRADES); 
         if (OrderType() == OP_BUY)  {
            OrderClose(OrderTicket(), OrderLots(),Bid,3, Red);  }
         if (OrderType() == OP_SELL)  {
            OrderClose(OrderTicket(), OrderLots(), Ask,3, Red);  }   
         if (OrderType() > 1)  { OrderDelete(OrderTicket()); }
   }
} 

// end closeAllOrders() 

string GetCommentForOrder() { return(Name_Expert); } 
double GetSizeLot() { return(Lots); } 
double GetTakeProfitBuy() { return(Ask+TakeProfit*Point); } 
double GetTakeProfitSell() { return(Bid-TakeProfit*Point); } 