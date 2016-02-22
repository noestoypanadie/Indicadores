//+------------------------------------------------------------------+
//|                                                     bbkc.mq4 |
//|                 Copyright © 2005, tageiger aka fxid10t@yahoo.com |
//|                                        http://www.metatrader.org |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, tageiger aka fxid10t@yahoo.com"
#property link      "http://www.metatrader.org"

extern int        BB.Period         =20;
extern int        BB.Deviation      =2;

extern int        KC.Period         =10;

extern int        Spread.Multiplier =1;
extern int        Atr.Period        =13;
extern double     Atr.Multiplier    =1.5;

extern double     MaximumRisk       =0.02;   //%account balance to risk per position
extern double     DecreaseFactor    =3;      //lot size divisor(reducer) during loss streak

extern int        MagicNumber       =851;
extern string     comment           ="m bbkc";

int b,s,ticket;
double spread;spread=Ask-Bid;

int init(){return(0);}
int deinit(){return(0);}
int start(){
   
   PosCounter();
   if(BB.hi()<=KC.hi() && b==0)  {Buy();}
   if(BB.lo()>=KC.lo() && s==0)  {Sell();}
   
   for(int j=0;j<OrdersTotal();j++) {
   OrderSelect(j,SELECT_BY_POS,MODE_TRADES);
   if(OrderSymbol()==Symbol() && OrderComment()==Period()+comment)   {
      if(OrderType()==(OP_BUY || OP_SELL))         {TSL();}
      if(OrderType()==(OP_BUYSTOP || OP_SELLSTOP)) {OrderMod();}}}
      
   if(!IsTesting())  {Comments();}
   
return(0);
}
//functions
void PosCounter() {
   b=0;s=0;
   for(int cnt=0;cnt<=OrdersTotal();cnt++)   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber) {
         if(OrderType()== OP_SELLSTOP) s++;
         if(OrderType()==OP_SELL)      s++;
         if(OrderType()==OP_BUYSTOP)   b++;
         if(OrderType()==OP_BUY)       b++;}}}

double BB.hi()  {
   double bbhi;
   bbhi=iBands(Symbol(),0,BB.Period,BB.Deviation,0,PRICE_CLOSE,MODE_UPPER,0);
   return(NormalizeDouble(bbhi,Digits));}
double BB.lo()  {
   double bblo;
   bblo=iBands(Symbol(),0,BB.Period,BB.Deviation,0,PRICE_CLOSE,MODE_LOWER,0);
   return(NormalizeDouble(bblo,Digits));}
double KC.hi()  {
   double kchi;
   kchi=iCustom(Symbol(),0,"Keltner_Channels",KC.Period,0,0);
   Print("KC.hi:",kchi);
   return(NormalizeDouble(kchi,Digits));}
double KC.lo() {
   double kclo;
   kclo=iCustom(Symbol(),0,"Keltner_Channels",KC.Period,2,0);
   Print("KC.lo:",kclo);
   return(NormalizeDouble(kclo,Digits));}

void Buy()  {if(b==0){ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              KC.hi(),
                              0,//slippage
                              B.sl(),
                              0,//takeprofit
                              Period()+comment,
                              MagicNumber,
                              0,//OrderExpiration
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  Print(ticket); PosCounter();}
                              else Print("Error Opening BuyStop Order: ",GetLastError());
                              return(0);   }}}

void Sell() {if(s==0){ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              KC.lo(),
                              0,//slippage
                              S.sl(),
                              0,//takeprofit
                              Period()+comment,
                              MagicNumber,
                              0,//OrderExpiration
                              Magenta);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  Print(ticket); PosCounter(); }
                              else Print("Error Opening SellStop Order: ",GetLastError());
                              return(0);   }}}

double LotsOptimized()  {
   double lot;
   int    orders=HistoryTotal();
   int    losses=0;
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,2);
   if(DecreaseFactor>0) {
      for(int i=orders-1;i>=0;i--)  {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++; }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,2);   }
   if(lot<0.05) lot=0.05;
return(lot);   }//end LotsOptimized

double B.sl()  {
   double b.lo;
   b.lo=Low[Lowest(Symbol(),0,MODE_LOW,BB.Period,0)];
   return(b.lo-(spread*Spread.Multiplier));}

double S.sl()  {
   double s.hi;
   s.hi=High[Highest(Symbol(),0,MODE_HIGH,BB.Period,0)];
   return(s.hi+(spread*Spread.Multiplier));}

void TSL()   {
   double tsl;
   tsl=iATR(Symbol(),0,Atr.Period,0)*Atr.Multiplier; 
   for(int z=0;z<OrdersTotal();z++) {
   OrderSelect(z,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderComment()==Period()+comment && OrderMagicNumber()==MagicNumber){
         if(OrderType()==OP_BUY && OrderProfit()>OrderSwap()) {
            if(Bid-NormalizeDouble(tsl,Digits)>OrderStopLoss())  {
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           Bid-NormalizeDouble(tsl,Digits),
                           OrderTakeProfit(),
                           OrderExpiration(),
                           CadetBlue);}}
         if(OrderType()==OP_SELL && OrderProfit()>OrderSwap()) {
            if(Ask+NormalizeDouble(tsl,Digits)<OrderStopLoss())  {
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           Ask+NormalizeDouble(tsl,Digits),
                           OrderTakeProfit(),
                           OrderExpiration(),
                           Sienna);}}}}}

void OrderMod()   {
}

void Comments()   {
Comment("Last Tick: ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS),"\n",
        "Upper BB:",BB.hi()," Upper KC:",KC.hi(),"\n",
        "Lower BB:",BB.lo()," Lower KC:",KC.lo());}