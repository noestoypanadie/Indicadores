//+------------------------------------------------------------------+
//|                                  automated trading program 1.mq4 |
//|                              Copyright © 2006, fxid10t@yahoo.com |
//|                               http://www.forexprogramtrading.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, fxid10t@yahoo.com"
#property link      "http://www.forexprogramtrading.com"

extern int     Trigger.Period=5;
extern int     Filter.Period.1=15;
extern int     Filter.Period.2=60;

extern double  tsl.divisor=0.25;
extern int     stoploss.pips=100;

extern bool    Use.Money.Management?=false;//if false, lot=Minimum.Lot
extern double  Minimum.Lot=0.01;
extern double  MaximumRisk=0.02;
extern int     Lot.Margin=50;
extern int     Magic=1775;
extern string  comment="m ATP.1";

int b.ticket, s.ticket, slip;
string DR, new.trigger.signal;
double filter1, filter2, trigger.current, avg.rng, rng, sum.rng, x;
double trigger.previous=2;

int init(){HideTestIndicators(true); slip=(Ask-Bid)/Point; trigger.previous=2; return(0);}
int deinit(){return(0);}
int start(){
if(new.trigger.signal!=TimeToStr(iTime(Symbol(),Trigger.Period,0),TIME_DATE|TIME_MINUTES)) {
   trigger.previous=trigger.current;
   new.trigger.signal=TimeToStr(iTime(Symbol(),Trigger.Period,0),TIME_DATE|TIME_MINUTES);}

trigger.current=GlobalVariableGet("GLS-StarTrend_"+Symbol()+Period()+"_"+Trigger.Period+"_Signal");
if(GetLastError()!=0) return(false);   
filter1=GlobalVariableGet("GLS-StarTrend_"+Symbol()+Period()+"_"+Filter.Period.1+"_Signal");
if(GetLastError()!=0) return(false);
filter2=GlobalVariableGet("GLS-StarTrend_"+Symbol()+Period()+"_"+Filter.Period.2+"_Signal");
if(GetLastError()!=0) return(false);

PosCounter();
x=Daily.Range()*tsl.divisor;
if(b.ticket==0 && filter1==1 && filter2==1 && trigger.current==1 && (trigger.previous==-1 || trigger.previous==0)){
   b.ticket=OrderSend(Symbol(),
                      OP_BUY,
                      LotCalc(),
                      NormalizeDouble(Ask,Digits),
                      slip,
                      NormalizeDouble(Ask-Point*stoploss.pips,Digits),
                      0,
                      Period()+comment,
                      Magic,0,Blue);
                      if(b.ticket>0)   {
                        if(OrderSelect(b.ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {   Print(b.ticket);   }
                        else Print("Error Opening Buy Order: ",GetLastError());
                        return(0);}}

if(s.ticket==0 && filter1==-1 && filter2==-1 && trigger.current==-1 && (trigger.previous==1 || trigger.previous==0)){
   s.ticket=OrderSend(Symbol(),
                      OP_SELL,
                      LotCalc(),
                      NormalizeDouble(Bid,Digits),
                      slip,
                      NormalizeDouble(Bid+Point*stoploss.pips,Digits),
                      0,
                      Period()+comment,
                      Magic,0,Magenta);
                      if(s.ticket>0)   {
                        if(OrderSelect(s.ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {   Print(s.ticket);   }
                        else Print("Error Opening Sell Order: ",GetLastError());
                        return(0);}}

Trail.Stop();
comments();
Mail();
return(0);}
//+------------------------------------------------------------------+
double Daily.Range() {
if(DR==TimeToStr(CurTime(),TIME_DATE)) {return(NormalizeDouble(avg.rng,Digits));}
rng=0;sum.rng=0;avg.rng=0;
for(int i=0;i<iBars(Symbol(),1440);i++) {
   rng=(iHigh(Symbol(),PERIOD_D1,i)-iLow(Symbol(),PERIOD_D1,i));
   sum.rng+=rng;}
double db=iBars(Symbol(),1440);   
avg.rng=sum.rng/db;
DR=TimeToStr(CurTime(),TIME_DATE);
return(NormalizeDouble(avg.rng,Digits));}

void PosCounter() {b.ticket=0;s.ticket=0;
for(int cnt=0;cnt<=OrdersTotal();cnt++)   {
   OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
   if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) {
      if(OrderType()==OP_SELL)   {s.ticket=OrderTicket();}
         if(OrderType()==OP_BUY)    {b.ticket=OrderTicket();} }}}

double LotCalc() {double lot;
if(Use.Money.Management?)   {
//lot=AccountFreeMargin()*(MaximumRisk/Lot.Margin);
lot=NormalizeDouble((AccountFreeMargin()*MaximumRisk)/stoploss.pips,2);}
if(!Use.Money.Management?)  {lot=Minimum.Lot;}
return(lot);}

void comments()   {
if(MarketInfo(Symbol(),MODE_SWAPLONG)>0) string swap="longs.";
else swap="shorts.";
if(MarketInfo(Symbol(),MODE_SWAPLONG)<0 && MarketInfo(Symbol(),MODE_SWAPSHORT)<0) swap="your broker. :(";
Comment("Last Tick: ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS),"\n",
           "Swap favors ",swap,"\n",
           "Average Daily Range: ",Daily.Range(),"\n",
           "Trigger Current: ",trigger.current,"\n",
           "Trigger Previous: ",trigger.previous,"\n",
           new.trigger.signal,"\n",
           "Filter 1: ",filter1,"\n",
           "Filter 2: ",filter2,"\n",
           "Open Long/Short Ticket #","\'","s: ",b.ticket," ",s.ticket,"\n",
           "Trailing Stop: ",x);  }

void Trail.Stop() {
   PosCounter();
//--Long TSL calc...
   //x=minimum wave range
   if(b.ticket>0) {
   double bsl=NormalizeDouble(x,Digits);double b.tsl=0;
      OrderSelect(b.ticket,SELECT_BY_TICKET);
//if stoploss is less than minimum wave range, set bsl to current SL
      if(OrderStopLoss()<OrderOpenPrice() &&
         OrderOpenPrice()-OrderStopLoss()<x) {bsl=OrderOpenPrice()-OrderStopLoss();}
//if stoploss is equal to, or greater than minimum wave range, set bsl to minimum wave range 
      if(OrderStopLoss()<OrderOpenPrice() &&
         OrderOpenPrice()-OrderStopLoss()>=x) {bsl=NormalizeDouble(x,Digits);}
//determine if stoploss should be modified
      if(Bid>(OrderOpenPrice()+bsl) &&
         OrderStopLoss()<(OrderOpenPrice()+(Bid-(OrderOpenPrice()+bsl))*tsl.divisor))   {
         b.tsl=NormalizeDouble(OrderOpenPrice()+((Bid-(OrderOpenPrice()+bsl))*tsl.divisor),Digits);
         Print("b.tsl ",b.tsl);
         OrderModify(b.ticket,OrderOpenPrice(),b.tsl,OrderTakeProfit(),
                     OrderExpiration(),MediumSpringGreen);}}
//--Short TSL calc...
   if(s.ticket>0) {
   double ssl=NormalizeDouble(x,Digits);double s.tsl=0;
      OrderSelect(s.ticket,SELECT_BY_TICKET);
//if stoploss is less than minimum wave range, set ssl to current SL
      if(OrderStopLoss()>OrderOpenPrice() &&
         OrderStopLoss()-OrderOpenPrice()<x) {ssl=OrderStopLoss()-OrderOpenPrice();}
//if stoploss is equal to, or greater than minimum wave range, set bsl to minimum wave range
      if(OrderStopLoss()>OrderOpenPrice() &&
         OrderStopLoss()-OrderOpenPrice()>=x)   {ssl=NormalizeDouble(x,Digits);}
//determine if stoploss should be modified
      if(Ask<(OrderOpenPrice()-ssl) &&
         OrderStopLoss()>(OrderOpenPrice()-((OrderOpenPrice()-ssl)-Ask)/tsl.divisor))   {
         s.tsl=NormalizeDouble(OrderOpenPrice()-(((OrderOpenPrice()-ssl)-Ask)/tsl.divisor),Digits);
         Print("s.tsl ",s.tsl);
         OrderModify(s.ticket,OrderOpenPrice(),s.tsl,OrderTakeProfit(),
                     OrderExpiration(),MediumVioletRed);}}   }//end Trail.Stop 

void Mail() {
OrderSelect(b.ticket,SELECT_BY_TICKET);
if(OrderCloseTime()>0)  {
   SendMail(OrderComment(),"Buy Order Closed, "+OrderProfit()+" "+Bid+"/"+Ask);}
OrderSelect(s.ticket,SELECT_BY_TICKET);
if(OrderCloseTime()>0)  {
   SendMail(OrderComment(),"Sell Order Closed, "+OrderProfit()+" "+Bid+"/"+Ask);}}

