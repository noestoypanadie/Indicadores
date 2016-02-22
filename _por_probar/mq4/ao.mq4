//+------------------------------------------------------------------+
//|                                                           ao.mq4 |
//|                                       Copyright © 2005, tageiger |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, tageiger aka fxid10t"
#property link      "http://www.metaquotes.net"
#include <WinUser32.mqh>
 
extern int        slip              =2;
extern double     MaximumRisk       =0.02;   //%account balance to risk per position
extern double     DecreaseFactor    =3;      //lot size divisor(reducer) during loss streak   
extern string     comment           ="m ao";
extern int        magic             =1965;

int ticket,b,s,c;

int init(){return(0);}
int deinit(){return(0);}
int start(){

if(!IsTesting()){

if(Period()!=15 && c<=0) {
int ret=MessageBox("The AO expert was designed for 15m\n charts,do you wish to continue?","FYI",MB_YESNO|MB_ICONQUESTION);
c++;
if(ret==IDNO) return(0);}}

PosCounter();
//double AO=iCustom(Symbol(),0,"Awesome",0,0,0);

if((AOC()>AOP()) && (AOP()<(0.0000)) && b==0) {
   ticket=OrderSend(Symbol(),
                     OP_BUY,
                     LotsOptimized(),
                     Ask,
                     slip,
                     bsl(),
                     0,//tp
                     Period()+comment,
                     magic,
                     0,//OrderExpiration
                     Blue);
                     if(ticket>0)   {
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {  Print(ticket); }
                        else Print("Error Opening Buy Order: ",GetLastError());
                        return(0);  }}//buy
             
if((AOC()<AOP()) && (AOP()>(0.0000)) && s==0) {
   ticket=OrderSend(Symbol(),
                     OP_SELL,
                     LotsOptimized(),
                     Bid,
                     slip,
                     ssl(),
                     0,//tp
                     Period()+comment,
                     magic,
                     0,//OrderExpiration
                     DeepPink);
                     if(ticket>0)   {
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {  Print(ticket); }
                     else Print("Error Opening Sell Order: ",GetLastError());
                     return(0);  }}//sell

for(int i=0;i<OrdersTotal();i++) {
   OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
   if(OrderSymbol()==Symbol() && OrderComment()==Period()+comment && 
      OrderType()==OP_BUY && (AOC()<AOP()) && (AOP()>(0.0000)) && OrderProfit()>0)  {
      OrderClose(OrderTicket(),OrderLots(),Bid,slip,Red);}
   if(OrderSymbol()==Symbol() && OrderComment()==Period()+comment && 
      OrderType()==OP_SELL && (AOC()>AOP()) && (AOP()<(0.0000)) && OrderProfit()>0) {
      OrderClose(OrderTicket(),OrderLots(),Ask,slip,Green);}   }
      
if(!IsTesting()) {Comment("AO Last:",AOC(),"\n"," AO Prev:",AOP());}

return(0);
}
//+------------------------------------------------------------------+
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

double bsl()   {
   double Lval;
   Lval=Low[Lowest(Symbol(),0,MODE_LOW,34,0)];
   if(Ask-Lval<Point*150) Lval=Ask+Point*150;
   return(Lval);}

double ssl()   {
   double Hval;
   Hval=High[Highest(Symbol(),0,MODE_HIGH,34,0)];
   if(Hval-Bid<Point*150) Hval=Bid-Point*150;
   return(Hval);}

void PosCounter() {
   b=0;s=0;
   for(int cnt=0;cnt<=OrdersTotal();cnt++)   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic &&
         OrderComment()==Period()+comment) {
         if(OrderType() == OP_SELL) s++;
         if(OrderType() == OP_BUY ) b++;}}}

double AOC()   {
return(iMA(Symbol(),0,5,0,MODE_SMA,PRICE_MEDIAN,0)-iMA(Symbol(),0,34,0,MODE_SMA,PRICE_MEDIAN,1));}

double AOP()   {
return(iMA(Symbol(),0,5,0,MODE_SMA,PRICE_MEDIAN,1)-iMA(Symbol(),0,34,0,MODE_SMA,PRICE_MEDIAN,2));}

