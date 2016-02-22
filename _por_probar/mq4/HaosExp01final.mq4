//+------------------------------------------------------------------+
//|                                               HaosExp01final.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright " Copyright © 2005, HomeSoft Corp."
#property link      " spiky@sinet.spb.ru"
#include <stdlib.mqh>


//+------------------------------------------------------------------+
//| Common External variables                                        |
//+------------------------------------------------------------------+
extern double Lots = 0.10;
extern double StopLoss = 1000.00;
extern double TakeProfit = 1000.00;
extern double TrailingStop = 0.00;

//+------------------------------------------------------------------+
//| External variables                                               |
//+------------------------------------------------------------------+
extern double mgod = 2006;
extern double per = 24;
extern double tp = 96;
extern double cbars = 300;
extern double test = 0;
extern double MM = 1;
extern double depth = 15;
extern double deviation = 5;
extern double backstep = 3;
extern double stop = 0.75;
extern double kh = 20;
extern double mstl = 5;

//+------------------------------------------------------------------+
//| Special Convertion Functions                                     |
//+------------------------------------------------------------------+

int LastTradeTime;

bool MOrderModify( int ticket, double price, double stoploss, double takeprofit, datetime expiration, color arrow_color=CLR_NONE)
{
LastTradeTime = CurTime();
price = MathRound(price*10000)/10000;
stoploss = MathRound(stoploss*10000)/10000;
takeprofit = MathRound(takeprofit*10000)/10000;
return ( OrderModify( ticket, price, stoploss, takeprofit, expiration, arrow_color) );
}

int MOrderSend( string symbol, int cmd, double volume, double price, int slippage, double stoploss, double takeprofit, string comment="", int magic=0, datetime expiration=0, color arrow_color=CLR_NONE)
{
LastTradeTime = CurTime();
price = MathRound(price*10000)/10000;
stoploss = MathRound(stoploss*10000)/10000;
takeprofit = MathRound(takeprofit*10000)/10000;
return ( OrderSend( symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic, expiration, arrow_color ) );
}

int OrderValueTicket(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderTicket());
}

int OrderValueType(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderType());
}

double OrderValueLots(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderLots());
}

double OrderValueOpenPrice(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderOpenPrice());
}

double OrderValueStopLoss(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderStopLoss());
}

double OrderValueTakeProfit(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderTakeProfit());
}

double OrderValueProfit(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderProfit());
}

string OrderValueSymbol(int index)
{
OrderSelect(index, SELECT_BY_POS);
return(OrderSymbol());
}

void SetArrow(datetime ArrowTime, double Price, double ArrowCode, color ArrowColor)
{
int err;
string ArrowName = DoubleToStr(ArrowTime,0);
if (ObjectFind(ArrowName) != -1) ObjectDelete(ArrowName);
if(!ObjectCreate(ArrowName, OBJ_ARROW, 0, ArrowTime, Price))
{
err=GetLastError();
Print("error: can't create Arrow! code #",err," ",ErrorDescription(err));
return;
}
else
{
ObjectSet(ArrowName, OBJPROP_ARROWCODE, ArrowCode);
ObjectSet(ArrowName, OBJPROP_COLOR , ArrowColor);
ObjectsRedraw();
}
}

//+------------------------------------------------------------------+
//| End                                                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+

int init()
{
return(0);
}
int start()
{
//+------------------------------------------------------------------+
//| Local variables                                                  |
//+------------------------------------------------------------------+
int cnt = 0;
double summa = 0;
double pl = 0;
double s = 0;
double b = 0;
double mlot = 0;
double zznul = 0;
double cci = 0;
double zzone = 0;
double ssum = 0;
double fzz = 0;
double szz = 0;
double vtr = 0;
double msum = 0;
double sumblk = 0;
double stopor = 0;
string candl = "";
double bsum = 0;
double j = 0;
bool ft = true;
double ccione = 0;
double zzold = 0;
double blok = 0;
double trs = 0;
double top = 0;
double trend = 0;
double delta = 0;
double ks = 0;
double kb = 0;
double tpr = 0;
double stpr = 0;
double btpr = 0;
double mods = 0;
double modb = 0;
double risk = 0;


if( mgod != Year() /*or Month!=12*/ ) return(0);
j=j+1;if( Minute() == 0 ) j=0;
if( Hour() == 0 ) top=Close[tp];
if( ft ) { cnt=0;
while( fzz == szz ) {cnt=cnt+1;
fzz=iCustom(NULL, 0, "HistoZZ",cbars,depth,deviation,backstep,0,cnt-1);
szz=iCustom(NULL, 0, "HistoZZ",cbars,depth,deviation,backstep,0,cnt);
if( fzz != szz ) zzold=szz;} ft=false;top=Close[tp];}
if( CurTime()-LastTradeTime<15 ) return(0);
if( MM == 0 ) { mlot=Lots;risk=0.20;}
if( MM == 1 ) { risk=0.25;
if( AccountFreeMargin()<=10000 && AccountFreeMargin()>1500 ) mlot=Lots;
if( AccountFreeMargin()>10000 ) mlot=2*Lots;
if( AccountFreeMargin()>=15000 ) mlot=3*Lots;
if( AccountFreeMargin()>=20000 ) mlot=4*Lots;
if( AccountFreeMargin()>=25000 ) mlot=5*Lots;
if( AccountFreeMargin()>=30000 ) mlot=6*Lots;
if( AccountFreeMargin()>=35000 ) mlot=7*Lots;
if( AccountFreeMargin()>=40000 ) mlot=8*Lots;
if( AccountFreeMargin()>=45000 ) mlot=9*Lots;
if( AccountFreeMargin()>=50000 ) mlot=10*Lots;
if( AccountFreeMargin()>=55000 ) mlot=12*Lots;
if( AccountFreeMargin()>=60000 ) mlot=15*Lots;}
trs=0;
for(cnt=tp;cnt>=0 ;cnt--){
trs=trs+(Close[cnt]-Open[cnt]);}
vtr=MathRound((10*trs/tp)/Point);


//-----------------------------------Подсчёт активных ордеров и профита по ним---------------------------------------

s=0;b=0;summa=0;ssum=0;bsum=0;
for(cnt=1;cnt<=OrdersTotal() ;cnt++){
if(  OrderValueSymbol(cnt) == Symbol() && (OrderValueType(cnt) == OP_SELL || OrderValueType(cnt) == OP_BUY) )
summa=summa+OrderValueProfit(cnt);
if(  OrderValueType(cnt) == OP_SELL && OrderValueSymbol(cnt) == Symbol() ) {
ssum=ssum+OrderValueProfit(cnt);s=s+1;}
if(  OrderValueType(cnt) == OP_BUY && OrderValueSymbol(cnt) == Symbol() ) {
bsum=bsum+OrderValueProfit(cnt);b=b+1;} }

if( s+b == 0 ) { msum=0;pl=0;stopor=0;sumblk=0;mods=0;modb=0;}
if( s>1 && mods == 1 ) mods=0; if( s == 0 ) mods=0;
if( b>1 && modb == 1 ) modb=0; if( b == 0 ) modb=0;

if( summa>=500*mlot ) sumblk=1;

if( s+b == 1 && sumblk == 1 ) {
if( msum<summa ) msum=summa;
stopor=NormalizeDouble((summa/msum),2);
if( stopor<=stop ) pl=1;}

//------------------------------------------------Трейлинг-Стоп-----------------------------------------------------

if( TrailingStop>0 && s+b>0 ) {
for(cnt=1;cnt<=OrdersTotal() ;cnt++){
if( OrderValueSymbol(cnt) == Symbol() && OrderValueProfit(cnt)>0 ) {
if( (Bid-OrderValueOpenPrice(cnt))>(Point*TrailingStop) ) {
if( OrderValueStopLoss(cnt)<(Bid-Point*TrailingStop) ) {
MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
Bid-Point*TrailingStop,OrderValueTakeProfit(cnt),0,Red);return(0);} }

if( (OrderValueOpenPrice(cnt)-Ask)>(Point*TrailingStop) ) {
if( OrderValueStopLoss(cnt)>(Ask+Point*TrailingStop) ) {
MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
Ask+Point*TrailingStop,OrderValueTakeProfit(cnt),0,Red);return(0);} } } } }

//-----------------------Процедура модификации стопа до безъубыточности профитной позиции-----------------------------

if( (s == 1 && ssum>0 && mods == 0) || (b == 1 && bsum>0 && modb == 0) ) {
for(cnt=1;cnt<=OrdersTotal() ;cnt++){

if(  OrderValueSymbol(cnt) == Symbol() && OrderValueType(cnt) == OP_SELL && mods == 0
&& s>0 && ((OrderValueOpenPrice(cnt)-Close[0])/Point)>15 ) {
MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
OrderValueOpenPrice(cnt)-mstl*Point,OrderValueTakeProfit(cnt),0,Gold);mods=1;return(0);}

if(  OrderValueSymbol(cnt) == Symbol() && OrderValueType(cnt) == OP_BUY && modb == 0
&& b>0 && ((Close[0]-OrderValueOpenPrice(cnt))/Point)>15 ) {
MOrderModify(OrderValueTicket(cnt),OrderValueOpenPrice(cnt),
OrderValueOpenPrice(cnt)+mstl*Point,OrderValueTakeProfit(cnt),0,Gold);modb=1;return(0);} } }

//--------------------------------------------Индикаторный блок-----------------------------------------------------

cci=iCCI(NULL, 0, 14, PRICE_CLOSE, 0);ccione=iCCI(NULL, 0, 14, PRICE_CLOSE, 1);

zznul=iCustom(NULL, 0, "HistoZZ",cbars,depth,deviation,backstep,0,0);
zzone=iCustom(NULL, 0, "HistoZZ",cbars,depth,deviation,backstep,0,1);
if( zznul != 0 && zzone != 0 && zznul != zzone ) zzold=zzone;
if( zzold<0 ) zzold=0;
if( zznul != 0 && zzold != 0 ) tpr=MathRound(0.75*MathAbs(zznul-zzold)/Point);
trend=MathRound((Close[0]-top)/Point);
if( trend>15 ) { ks=1;kb=2;}
if( trend<-15 ) { ks=2;kb=1;}
if( trend<=15 && trend>=-15 ) { ks=1;kb=1;}
delta=MathRound((MathAbs(Close[0]-zzold))/Point);
if( zzold == 0 ) delta=0;

if( ssum != 0 ) btpr=tpr ; else btpr=delta;
if( bsum != 0 ) stpr=tpr ; else stpr=delta;

if( Close[0]>Open[0] ) candl="White";
if( Close[0]<Open[0] ) candl="Black";
if( Close[0] == Open[0] ) candl="Dodjy";

//----------------------------------------Закрытие активных позиций по профиту-------------------------------------

if( s+b>2 && summa>=600*mlot ) pl=1;
if( summa>=mlot*300 && s+b == 1 ) pl=1;
if( s+b == 2 && summa>50 ) pl=1;

if( pl == 1 ) {
for(cnt=1;cnt<=OrdersTotal() ;cnt++){
if( OrderValueType(cnt) == OP_SELL && OrderValueSymbol(cnt) == Symbol() ) {
OrderClose(OrderValueTicket(cnt),OrderValueLots(cnt),Ask,5,Red);return(0);}

if( OrderValueType(cnt) == OP_BUY && OrderValueSymbol(cnt) == Symbol() ) {
OrderClose(OrderValueTicket(cnt),OrderValueLots(cnt),Bid,5,Red);return(0);} } }

if( summa<-MathRound(risk*AccountFreeMargin()) && s+b>=2 ) {
for(cnt=1;cnt<=OrdersTotal() ;cnt++){
if( OrderValueType(cnt) == OP_SELL && OrderValueSymbol(cnt) == Symbol() ) {
OrderClose(OrderValueTicket(cnt),OrderValueLots(cnt),Ask,5,Red);return(0);}

if( OrderValueType(cnt) == OP_BUY && OrderValueSymbol(cnt) == Symbol() ) {
OrderClose(OrderValueTicket(cnt),OrderValueLots(cnt),Bid,5,Red);return(0);} } }

//-----------------------------------------------Отладочная информация----------------------------------------------

if( stpr<10 ) stpr=10;if( btpr<10 ) btpr=10;

if( test == 1 ) {
Print("Data: ",Month()," ",Day(),"  Time: ",Hour()," ",Minute(),"  0ZZ=",zznul,"  ZZOld=",zzold,"  0CCI=",MathRound(cci),
      "  FMargin=",MathRound(AccountFreeMargin()),"  STpr=",stpr,"  BTPr=",btpr,"  Ssum=",MathRound(ssum),"  Bsum=",MathRound(bsum),
      "  Profit=",MathRound(summa));}

if( test == 0 ) {
Comment("Data: ",Month()," ",Day(),"  Time: ",Hour()," ",Minute(),"   JInd=",j,"'#10'","0ZZ=",zznul,"  ZZOld=",zzold,
        "  1CCI=",MathRound(ccione),"  0CCI=",MathRound(cci),"  Stop=",stopor,"  STPr=",stpr,"  BTPr=",btpr,"  Trend=",trend,
        "  Vtr=",vtr,"  Ssum=",MathRound(ssum),"  Bsum=",MathRound(bsum),"  Profit=",MathRound(summa));}

//------------------------------------Выставление хедж-ордеров и доливка позиций--------------------------------------

if( s+b == 2 ) {
if( b == 1 && s == 1 && cci>=250 && bsum<-150 && trend<-15 && vtr<0  ) {
Alert("Выставлен хедж-ордер по цене: ",Bid);if( summa<-500 ) { btpr=100;kh=40;}
MOrderSend(Symbol(),OP_SELL,kh*mlot,Bid,3,Bid+StopLoss*Point,Bid-stpr*Point,"",16384,0,Violet);blok=1;return(0);}
if( s == 1 && b == 1 && cci<=-250 && ssum<-150 && trend>15 && vtr>0 ) {
Alert("Выставлен хедж-ордер по цене: ",Ask);if( summa<-500 ) { btpr=100;kh=40;}
MOrderSend(Symbol(),OP_BUY,kh*mlot,Ask,3,Ask-StopLoss*Point,Ask+btpr*Point,"",16384,0,Gold);blok=1;return(0);} }

//--------------------------------------------------Торгующий блок----------------------------------------------------

if( s+b<=1 ) blok=0;

if( s+b<=1 && zznul != zzold ) {
if( s == 0 && zznul>zzold && cci>200 && blok == 0 ) {
if( b == 1 && s == 0 && bsum<-150 && trend<-15 && vtr<=0 ) { stpr=100;mlot=kh*Lots;}
   Alert("Выставлен ордер на продажу по цене: ",Bid);
   SetArrow(Time[0],High,242,GreenYellow);
   MOrderSend(Symbol(),OP_SELL,ks*mlot,Bid,3,Bid+StopLoss*Point,Bid-stpr*Point,"",16384,0,Violet);return(0);}
if( b == 0 && zznul<zzold && cci<-200 && blok == 0 ) {
if( b == 0 && s == 1 && ssum<-150 && trend>15 && vtr>=0 ) { btpr=100;mlot=kh*Lots;}
   Alert("Выставлен ордер на покупку по цене: ",Ask);
   SetArrow(Time[0],Low,241,Violet);
   MOrderSend(Symbol(),OP_BUY,kb*mlot,Ask,3,Ask-StopLoss*Point,Ask+btpr*Point,"",16384,0,Gold);return(0);} }
   
//-------------------------------------------------------End-----------------------------------------------------------