//+------------------------------------------------------------------+
//|                                  automated trading program 2.mq4 |
//|                              Copyright © 2006, fxid10t@yahoo.com |
//|                               http://www.forexprogramtrading.com |
//| USES iCustom() TO OBTAIN GLS-STARTREND INDICATOR VALUES          |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, fxid10t@yahoo.com"
#property link      "http://www.forexprogramtrading.com"

extern int     Trigger.Period=5;
extern int     Filter.Period.1=15;
extern int     Filter.Period.2=60;

extern double  tsl.divisor=0.382;
extern int     stoploss.pips=100;
extern bool    Use.ADR.for.SL.pips?=false;

extern bool    Use.Money.Management?=false;//if false, lot=Minimum.Lot
extern double  Minimum.Lot=0.01;
extern double  MaximumRisk=0.02;
extern int     Lot.Margin=50;
extern int     Magic=1775;
extern string  comment="m ATP.2";

int b.ticket, s.ticket, slip;
string DR;
double avg.rng, rng, sum.rng, x;
int t0c, t1c, t2c, t3c, t4c, t0p, t1p, t2p, t3p, t4p;
int f10c, f11c, f12c, f13c, f14c, f10p, f11p, f12p, f13p, f14p;
int f20c, f21c, f22c, f23c, f24c, f20p, f21p, f22p, f23p, f24p;

int init(){HideTestIndicators(true); slip=(Ask-Bid)/Point; return(0);}
int deinit(){return(0);}
int start(){
Mail();
Indicator.Values();
PosCounter();
if(Use.ADR.for.SL.pips?) {stoploss.pips=NormalizeDouble(Daily.Range()/Point,Digits);}
x=NormalizeDouble(Daily.Range()*tsl.divisor,Digits);
if(b.ticket==0 && (((t2p==1 || t3p==1 || t4p==1) && (t0c==1 || t1c==1) &&
  (f10c==1 || f11c==1) && (f20c==1 && f21c==1)) || ((t0c==1 || t1c==1) &&
  (f10c==1 || f11c==1) && (f22p==1 || f23p==1 || f24p==1) && (f20c==1 || f21c==1)) ||
  ((t0c==1 || t1c==1) && (f12p==1 || f13p==1 || f14p==1) && (f10c==1 || f11c==1) &&
  (f20c==1 || f21c==1) )))   {
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

if(s.ticket==0 && (((t0p==1 || t1p==1 || t4p==1) && (t2c==1 || t3c==1) &&
  (f12c==1 || f13c==1) && (f22c==1 || f23c==1)) || ((t2c==1 || t3c==1) &&
  (f12c==1 || f13c==1) && (f20p==1 || f21p==1 || f24p==1) && (f22c==1 || f23c==1)) ||
  ((t2c==1 || t3c==1) && (f10p==1 || f11p==1 || f14p==1) && (f12c==1 || f13c==1) &&
  (f22c==1 || f23c==1) )))   {
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
OrderSelect(b.ticket,SELECT_BY_TICKET);
if(OrderProfit()>0 && (t2c==1 || t3c==1) && (t0p==1 || t1p==1)) {OrderClose(OrderTicket(),OrderLots(),Bid,slip,Aqua);}
OrderSelect(s.ticket,SELECT_BY_TICKET);
if(OrderProfit()>0 && (t0c==1 || t1c==1) && (t2p==1 || t3p==1)) {OrderClose(OrderTicket(),OrderLots(),Ask,slip,Magenta);}
Mail();
Trail.Stop();
comments();
return(0);}
//+------------------------------------------------------------------+
void Indicator.Values() {
t0c=iCustom(NULL,Trigger.Period, "GLS-StarTrend", 0, 1); //DarkGreen.
t1c=iCustom(NULL,Trigger.Period, "GLS-StarTrend", 1, 1); //Bright Green.
t2c=iCustom(NULL,Trigger.Period, "GLS-StarTrend", 2, 1); //Dark Red.
t3c=iCustom(NULL,Trigger.Period, "GLS-StarTrend", 3, 1); //Bright Red.
t4c=iCustom(NULL,Trigger.Period, "GLS-StarTrend", 4, 1); //Neutral Yellow.

t0p=iCustom(NULL,Trigger.Period, "GLS-StarTrend", 0, 2); //DarkGreen.
t1p=iCustom(NULL,Trigger.Period, "GLS-StarTrend", 1, 2); //Bright Green.
t2p=iCustom(NULL,Trigger.Period, "GLS-StarTrend", 2, 2); //Dark Red.
t3p=iCustom(NULL,Trigger.Period, "GLS-StarTrend", 3, 2); //Bright Red.
t4p=iCustom(NULL,Trigger.Period, "GLS-StarTrend", 4, 2); //Neutral Yellow. 

f10c=iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 0, 1); //DarkGreen.
f11c=iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 1, 1); //Bright Green.
f12c=iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 2, 1); //Dark Red.
f13c=iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 3, 1); //Bright Red.
f14c=iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 4, 1); //Neutral Yellow.

f10p=iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 0, 2); //DarkGreen.
f11p=iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 1, 2); //Bright Green.
f12p=iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 2, 2); //Dark Red.
f13p=iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 3, 2); //Bright Red.
f14p=iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 4, 2); //Neutral Yellow.

f20c=iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 0, 1); //DarkGreen.
f21c=iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 1, 1); //Bright Green.
f22c=iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 2, 1); //Dark Red.
f23c=iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 3, 1); //Bright Red.
f24c=iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 4, 1); //Neutral Yellow.

f20p=iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 0, 2); //DarkGreen.
f21p=iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 1, 2); //Bright Green.
f22p=iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 2, 2); //Dark Red.
f23p=iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 3, 2); //Bright Red.
f24p=iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 4, 2); /*Neutral Yellow.*/ }

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
lot=NormalizeDouble((AccountFreeMargin()*MaximumRisk)/(MarketInfo(Symbol(),MODE_TICKVALUE)*stoploss.pips),2);}
if(!Use.Money.Management?)  {lot=Minimum.Lot;}
return(lot);}

void comments()   {
if(MarketInfo(Symbol(),MODE_SWAPLONG)>0) string swap="longs.";
else swap="shorts.";
if(MarketInfo(Symbol(),MODE_SWAPLONG)<0 && MarketInfo(Symbol(),MODE_SWAPSHORT)<0) swap="your broker. :(";
Comment("Last Tick: ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS),"\n",
           "Swap favors ",swap,"\n",
           "Average Daily Range: ",Daily.Range(),"\n",
           "Trailing Stop: ",x,"\n",
           "Open Long/Short Ticket #","\'","s: ",b.ticket," ",s.ticket);  }

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
         OrderStopLoss()<(OrderOpenPrice()+(Bid-(OrderOpenPrice()+bsl))))   {
         b.tsl=NormalizeDouble(OrderOpenPrice()+(Bid-(OrderOpenPrice()+bsl)),Digits);
         Print("b.tsl ",b.tsl);
         if(OrderStopLoss()<b.tsl)  {
         OrderModify(b.ticket,OrderOpenPrice(),b.tsl,OrderTakeProfit(),
                     OrderExpiration(),MediumSpringGreen);}}}
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
         OrderStopLoss()>(OrderOpenPrice()-(OrderOpenPrice()-ssl)-Ask))   {
         s.tsl=NormalizeDouble(OrderOpenPrice()-((OrderOpenPrice()-ssl)-Ask),Digits);
         Print("s.tsl ",s.tsl);
         if(OrderStopLoss()>s.tsl)  {
         OrderModify(s.ticket,OrderOpenPrice(),s.tsl,OrderTakeProfit(),
                     OrderExpiration(),MediumVioletRed);}}}   }//end Trail.Stop 

void Mail() {
OrderSelect(b.ticket,SELECT_BY_TICKET);
if(OrderCloseTime()>0)  {
   SendMail(Symbol()+" "+OrderComment(),"Buy Order Closed, $"+DoubleToStr(OrderProfit(),2)+" "+DoubleToStr(Bid,Digits)+"/"+DoubleToStr(Ask,Digits));}
OrderSelect(s.ticket,SELECT_BY_TICKET);
if(OrderCloseTime()>0)  {
   SendMail(Symbol()+" "+OrderComment(),"Sell Order Closed, $"+DoubleToStr(OrderProfit(),2)+" "+DoubleToStr(Bid,Digits)+"/"+DoubleToStr(Ask,Digits));}}

