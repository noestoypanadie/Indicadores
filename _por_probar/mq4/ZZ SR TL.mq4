//+------------------------------------------------------------------+
//|                                                     ZZ SR TL.mq4 |
//|                 Copyright © 2005, tageiger aka fxid10t@yahoo.com |
//|                                        http://www.metatrader.org |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, tageiger aka fxid10t@yahoo.com"
#property link      "http://www.metatrader.org"

extern double  MaximumRisk    =0.10;
extern double  DecreaseFactor =3;

extern int     Lot.Margin     =1000;

extern int     Max.Objects    =8;
extern int     Magic          =1965;

extern int     BarsMax        =144;
extern int     ExtDepth       =12;
extern int     ExtDeviation   =1;
extern int     ExtBackstep    =5;

int hi.a.shift,lo.a.shift,hi.b.shift,lo.b.shift,b,s,ticket;
double hi.b,lo.b,hi.a,lo.a,btsl,stsl,buy.stop,sell.stop,buy.tp,sell.tp,past,pres,B.Profit,S.Profit,tp.range;
datetime time.hi.a,time.lo.a,time.hi.b,time.lo.b;

double   spread;  spread      =Ask-Bid;
int      slip;    slip        =spread/Point;

string         comment        ="m ZZ SR TL";

int init(){return(0);}
int deinit(){return(0);}
int start(){

   hi.a=0;hi.b=0;lo.a=0;lo.b=0;btsl=0;stsl=0;
   hi.a.shift=0;lo.a.shift=0;hi.b.shift=0;lo.b.shift=0;
   buy.stop=0;sell.stop=0;buy.tp=0;sell.tp=0;tp.range=0;
   past=0;pres=0;
   
   Comments();
   PosCounter();
   Old.Object.Delete();

   if(Bars<144) {return(0);}
   int ChartPeriod=Period();
   double sr=iCustom(Symbol(),0,"ZZ SR TL Indicator",ChartPeriod,BarsMax,ExtDepth,ExtDeviation,ExtBackstep,true,0,0,0,0,0,0,0,0,0,0);
   if(ObjectsTotal()==0)   {Print("No TL\'s");return(0);}

   for(int k=0;k<ObjectsTotal();k++)   {
      if(StrToTime(ObjectName(k))<CurTime() &&
         ObjectGetValueByShift(ObjectName(k),0)>=High[iBarShift(Symbol(),0,StrToTime(ObjectName(k)))])  {
         hi.a=High[iBarShift(Symbol(),0,StrToTime(ObjectName(k)))];
         hi.a.shift=iBarShift(Symbol(),0,StrToTime(ObjectName(k)));
         time.hi.a=StrToTime(ObjectName(k)); }
      if(StrToTime(ObjectName(k))<CurTime() &&
         ObjectGetValueByShift(ObjectName(k),0)<=Low[iBarShift(Symbol(),0,StrToTime(ObjectName(k)))])  {
         lo.a=Low[iBarShift(Symbol(),0,StrToTime(ObjectName(k)))];
         lo.a.shift=iBarShift(Symbol(),0,StrToTime(ObjectName(k)));
         time.lo.a=StrToTime(ObjectName(k));}}
        // if(Symbol()=="EURUSD") Print(lo.a," lo.a ",lo.a.shift);}}

   for(int j=0;j<ObjectsTotal();j++)   {
      if(StrToTime(ObjectName(j))<time.hi.a &&
         ObjectGetValueByShift(ObjectName(j),0)>=High[iBarShift(Symbol(),0,StrToTime(ObjectName(j)))])  {
         hi.b=High[iBarShift(Symbol(),0,StrToTime(ObjectName(j)))];
         hi.b.shift=iBarShift(Symbol(),0,StrToTime(ObjectName(j)));
         time.hi.b=StrToTime(ObjectName(j));}
      if(StrToTime(ObjectName(j))<time.lo.a &&
         ObjectGetValueByShift(ObjectName(j),0)<=Low[iBarShift(Symbol(),0,StrToTime(ObjectName(j)))])  {
         lo.b=Low[iBarShift(Symbol(),0,StrToTime(ObjectName(j)))];
         lo.b.shift=iBarShift(Symbol(),0,StrToTime(ObjectName(j)));
         time.lo.b=StrToTime(ObjectName(j));}}
        // if(Symbol()=="EURUSD") Print(lo.b," lo.b ",lo.b.shift);}}

   if(hi.b>0 && hi.a>0) {
      ObjectCreate("buyline",OBJ_TREND,0,time.hi.b,hi.b,time.hi.a,hi.a);
      ObjectSet("buyline",6,Gold);
      ObjectSet("buyline",7,STYLE_SOLID);
      ObjectSet("buyline",8,1);
      ObjectSet("buyline",10,true);
      ObjectSetText("buyline","Buy Line");}

   if(lo.b>0 && lo.a>0) {
      ObjectCreate("sellline",OBJ_TREND,0,time.lo.b,lo.b,time.lo.a,lo.a);
      ObjectSet("sellline",6,Gold);
      ObjectSet("sellline",7,STYLE_SOLID);
      ObjectSet("sellline",8,1);
      ObjectSet("sellline",10,true);
      ObjectSetText("sellline","Sell Line");}

   buy.stop=NormalizeDouble(ObjectGetValueByShift("buyline",0),Digits);
   sell.stop=NormalizeDouble(ObjectGetValueByShift("sellline",0),Digits);
   
   if(hi.b.shift<lo.b.shift)  {  
      tp.range=(NormalizeDouble(ObjectGetValueByShift("buyline",hi.b.shift),Digits)-
               NormalizeDouble(ObjectGetValueByShift("sellline",hi.b.shift),Digits));  }
   if(hi.b.shift>lo.b.shift)  {  
      tp.range=(NormalizeDouble(ObjectGetValueByShift("buyline",lo.b.shift),Digits)-
               NormalizeDouble(ObjectGetValueByShift("sellline",lo.b.shift),Digits));  }
  

   buy.tp=hi.b+tp.range;
   if(buy.tp<(buy.stop+spread))  {buy.tp=buy.stop+tp.range;}
   sell.tp=lo.b-tp.range;
   if(sell.tp>(sell.stop-spread))   {sell.tp=sell.stop-tp.range;}
   
   past=tp.range;
   pres=(NormalizeDouble(ObjectGetValueByShift("buyline",0),Digits)-NormalizeDouble(ObjectGetValueByShift("sellline",0),Digits));
   
   if(past>pres || past==pres || ((pres-past)<(Point*2)))   {    
      if(b==0) {
         ticket=OrderSend(Symbol(),
                           OP_BUYSTOP,
                           LotsOptimized(),
                           buy.stop+spread,
                           0,
                           sell.stop,
                           buy.tp,
                           Period()+comment,
                           Magic,0,Blue);
                           if(ticket>0)   {
                              if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {   Print(ticket);B.Profit=0; }
                              else Print("Error Opening BuyStop Order: ",GetLastError());
                              return(0);}}
      if(s==0) {
         ticket=OrderSend(Symbol(),
                           OP_SELLSTOP,
                           LotsOptimized(),
                           sell.stop,
                           0,
                           buy.stop+spread,
                           sell.tp,
                           Period()+comment,
                           Magic,0,Orange);
                           if(ticket>0)   {
                              if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                  {   Print(ticket);S.Profit=0; }
                              else Print("Error Opening SellStop Order: ",GetLastError());
                              return(0);}}}  

   for(int c=0;c<OrdersTotal();c++) {
      OrderSelect(c,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && IsTradeAllowed()) {
         if(OrderType()==OP_BUY && Bid>(OrderOpenPrice()+(0.118*(OrderTakeProfit()-OrderOpenPrice())))) {
            btsl=OrderOpenPrice()+Point*1;
            if(btsl>OrderStopLoss()) {
            OrderModify(OrderTicket(),OrderOpenPrice(),btsl,OrderTakeProfit(),0,Aqua);}}

         if(OrderType()==OP_SELL && Ask<(OrderOpenPrice()-(0.118*(OrderOpenPrice()-OrderTakeProfit())))) {
            stsl=OrderOpenPrice()-Point*1;
            if(stsl<OrderStopLoss()) {
            OrderModify(OrderTicket(),OrderOpenPrice(),stsl,OrderTakeProfit(),0,HotPink);}}

         if(OrderType()==OP_BUY && Bid>(OrderOpenPrice()+(0.236*(OrderTakeProfit()-OrderOpenPrice())))) {
            if(OrderProfit()>0 && OrderProfit()>B.Profit)   {B.Profit=OrderProfit();} 
               if(OrderProfit()>0 && OrderProfit()<(0.618*B.Profit))  { 
                  OrderClose(OrderTicket(),OrderLots(),Bid,slip,Aqua);}}

         if(OrderType()==OP_SELL && Ask<(OrderOpenPrice()-(0.236*(OrderOpenPrice()-OrderTakeProfit())))) {
            if(OrderProfit()>0 && OrderProfit()>S.Profit)   {S.Profit=OrderProfit();}
               if(OrderProfit()>0 && OrderProfit()<(0.618*S.Profit))  {
                  OrderClose(OrderTicket(),OrderLots(),Ask,slip,HotPink);}}

         if(OrderType()==OP_BUY && Bid>(OrderOpenPrice()+(0.618*(OrderTakeProfit()-OrderOpenPrice())))) {
            btsl=NormalizeDouble((OrderOpenPrice()+(0.382*(Bid-OrderOpenPrice()))),Digits);
            if(btsl>OrderStopLoss())   {
               OrderModify(OrderTicket(),OrderOpenPrice(),btsl,OrderTakeProfit(),0,Aqua);}}
         
         if(OrderType()==OP_SELL && Ask<(OrderOpenPrice()-(0.618*(OrderOpenPrice()-OrderTakeProfit()))))  {
            stsl=NormalizeDouble((OrderOpenPrice()-(0.382*(OrderOpenPrice()-Ask))),Digits);
            if(stsl<OrderStopLoss())   {
               OrderModify(OrderTicket(),OrderOpenPrice(),stsl,OrderTakeProfit(),0,HotPink);}}

         if(OrderType()==OP_BUY && Bid>(OrderOpenPrice()+(0.382*(OrderTakeProfit()-OrderOpenPrice())))) {
            btsl=NormalizeDouble((OrderOpenPrice()+(0.236*(Bid-OrderOpenPrice()))),Digits);
            if(btsl>OrderStopLoss()) {
            OrderModify(OrderTicket(),OrderOpenPrice(),btsl,OrderTakeProfit(),0,Aqua);}}

         if(OrderType()==OP_SELL && Ask<(OrderOpenPrice()-(0.382*(OrderOpenPrice()-OrderTakeProfit())))) {
            stsl=NormalizeDouble((OrderOpenPrice()-(0.236*(OrderOpenPrice()-Ask))),Digits);
            if(stsl<OrderStopLoss()) {
            OrderModify(OrderTicket(),OrderOpenPrice(),stsl,OrderTakeProfit(),0,HotPink);}}

         if(OrderType()==OP_BUYSTOP)   {
            if(OrderOpenPrice()>buy.stop+spread)   {OrderModify(OrderTicket(),buy.stop+spread,sell.stop,buy.tp,0,Blue);}
            if(OrderOpenPrice()<buy.stop+spread)   {OrderModify(OrderTicket(),buy.stop+spread,sell.stop,buy.tp,0,Blue);}}

         if(OrderType()==OP_SELLSTOP)  {
            if(OrderOpenPrice()<sell.stop)  {OrderModify(OrderTicket(),sell.stop,buy.stop+spread,sell.tp,0,Orange);}
            if(OrderOpenPrice()>sell.stop)  {OrderModify(OrderTicket(),sell.stop,buy.stop+spread,sell.tp,0,Orange);}}

         if(pres>(past+Point*1))   {
            if(OrderType()==OP_BUYSTOP())    {OrderDelete(OrderTicket());}
            if(OrderType()==OP_SELLSTOP())   {OrderDelete(OrderTicket());} }
   }}

   Comments();

return(0);}
//+------------------------------------------------------------------+
void Old.Object.Delete()   {
   if(ObjectsTotal()==0) {return(0);}
   if(!IsTesting()) {ObjectsDeleteAll(0,22);}
   if(Period()<=15)   {
      if((Minute()==0 && Seconds()<=10)  || (Minute()==5 && Seconds()<=10)  ||
         (Minute()==10 && Seconds()<=10) || (Minute()==15 && Seconds()<=10) ||
         (Minute()==20 && Seconds()<=10) || (Minute()==25 && Seconds()<=10) ||
         (Minute()==30 && Seconds()<=10) || (Minute()==35 && Seconds()<=10) ||
         (Minute()==40 && Seconds()<=10) || (Minute()==45 && Seconds()<=10) ||
         (Minute()==50 && Seconds()<=10) || (Minute()==55 && Seconds()<=10))   {
            ObjectsDeleteAll(0,OBJ_TREND);}}
   if(Period()>15) {
      if((Minute()==0 && Seconds()<=15)  || (Minute()==15 && Seconds()<=15) ||
         (Minute()==30 && Seconds()<=15) || (Minute()==45 && Seconds()<=15)) {
            ObjectsDeleteAll(0,OBJ_TREND);}}
   if(ObjectsTotal()>Max.Objects) {ObjectsDeleteAll(0,OBJ_TREND);}}

void Comments()   {
   if(!IsTesting()) {
   Comment("Last Tick: ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS),"\n",
           "past: ",past,"\n",
           "pres: ",pres,"\n",
           "slip: ",slip,"\n",
           "tp r: ",tp.range);}}
           //"Total TL\'s: ",ObjectsTotal());}}

void PosCounter() {
   b=0;s=0;
   for(int cnt=0;cnt<=OrdersTotal();cnt++)   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) {
         if(OrderType()==OP_SELL)      s++;
         if(OrderType()==OP_SELLSTOP)  s++;
         if(OrderType()==OP_BUY)       b++;
         if(OrderType()==OP_BUYSTOP)   b++;}}}

double LotsOptimized()  {
   double lot;
   int    orders=HistoryTotal();
   int    losses=0;
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/Lot.Margin,2);
   if(DecreaseFactor>0) {
      for(int i=orders ;i>=0;i--)  {
         //if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++; }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,2);   }
   if(lot<0.01) lot=0.01;
return(lot);   }


