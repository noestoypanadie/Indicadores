//+------------------------------------------------------------------+
//|                                                       1m S-R.mq4 |
//|                 Copyright © 2005, tageiger aka fxid10t@yahoo.com |
//|                                        http://www.metatrader.org |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, tageiger aka fxid10t@yahoo.com"
#property link      "http://www.metatrader.org"

extern int     ChartPeriod    =1;

extern double  MaximumRisk    =0.02;
extern double  DecreaseFactor =3;
extern int     Lot.Margin     =1000;

extern int     Max.Trendlines =21;

extern int     Magic          =123;
extern string  comment        ="m sr1";

int b,s,ticket;
double buy,sell,btsl,stsl;
double spread;spread=Ask-Bid;
int slip;slip=spread/Point;
double dummy;

int init(){return(0);}
int deinit(){return(0);}
int start(){
   if(Period()==1) Magic=3;
   if(IsTesting())  {
      ChartPeriod=Period();
      dummy=iCustom(Symbol(),0,"Support Resistance",ChartPeriod,144,13,1,5,
      true,RosyBrown,Aqua,DeepPink,PaleVioletRed,Red,DarkOrange,DeepSkyBlue,Lime,0,0);}

   PosCounter();
   BuySell();
   if(b==0 && Ask<buy && Bid>sell)  {
      ticket=OrderSend(Symbol(),
                        OP_BUYSTOP,
                        LotsOptimized(),
                        buy,
                        slip,//slippage
                        sell,
                        buy+(NormalizeDouble((buy-sell)*2,Digits)),//TakeProfit(),
                        Period()+comment,
                        Magic,
                        0,//Orderexpiration(),//OrderExpiration
                        Aqua);
                        if(ticket>0)   {
                            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                  {   Print(ticket); }
                            else Print("Error Opening BuyStop Order: ",GetLastError());
                            return(0);}}
   if(s==0 && Bid>sell && Ask<buy) {     
      ticket=OrderSend(Symbol(),
                        OP_SELLSTOP,
                        LotsOptimized(),
                        sell,
                        slip,//slippage
                        buy,
                        sell-(NormalizeDouble((buy-sell)*2,Digits)),//TakeProfit(),
                        Period()+comment,
                        Magic,
                        0,//Orderexpiration(),//OrderExpiration
                        HotPink);
                        if(ticket>0)   {
                            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                  {   Print(ticket); }
                            else Print("Error Opening SellStop Order: ",GetLastError());
                            return(0);}}   
   TrailStop();
   OrderMod();
   Old.Object.Delete();
   Comments();
return(0);}
//+------------------------------------------------------------------+
void PosCounter() {
   b=0;s=0;
   for(int cnt=0;cnt<=OrdersTotal();cnt++)   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic &&
         OrderComment()==Period()+comment) {
         if(OrderType()==OP_SELL)      s++;
         if(OrderType()==OP_SELLSTOP)  s++;
         if(OrderType()==OP_BUY)       b++;
         if(OrderType()==OP_BUYSTOP)   b++;}}}

void BuySell()  {
   buy=0;sell=0;
   for(int c=0;c<ObjectsTotal();c++)  {
      if(ObjectGetValueByShift(ObjectName(c),0)>Ask) {
         buy=ObjectGetValueByShift(ObjectName(c),0)+spread;}
      if(ObjectGetValueByShift(ObjectName(c),0)<Bid)  {
         sell=ObjectGetValueByShift(ObjectName(c),0);}}
   /*if((buy-sell)<(2*spread)) return(0);*/}

void TrailStop()  {
   btsl=0;stsl=0;
   for(int i=0;i<OrdersTotal();i++) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic &&
         OrderComment()==Period()+comment) {
         if(OrderType()==OP_BUY) {
            for(int p=0;p<ObjectsTotal();p++)   {
               if(ObjectGetValueByShift(ObjectName(p),0)<Bid &&
                  (ObjectGetValueByShift(ObjectName(p),0)>OrderOpenPrice() &&
                   ObjectGetValueByShift(ObjectName(p),0)>OrderStopLoss()) ||
                   OrderStopLoss()<=0) {
                  btsl=ObjectGetValueByShift(ObjectName(p),0);
                  if(btsl>OrderStopLoss() && btsl>OrderOpenPrice()) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),btsl,
                              0,//buy+(NormalizeDouble((buy-sell)*2,Digits)),
                              OrderExpiration(),Olive);break;}}}}
         if(OrderType()==OP_SELL)   {
            for(int k=0;k<ObjectsTotal();k++)   {
               if(ObjectGetValueByShift(ObjectName(k),0)>Ask &&
                  (ObjectGetValueByShift(ObjectName(k),0)<OrderOpenPrice() &&
                   ObjectGetValueByShift(ObjectName(k),0)<OrderStopLoss()) ||
                   OrderStopLoss()<=0) {
                  stsl=ObjectGetValueByShift(ObjectName(k),0)+spread;
                  if(stsl<OrderStopLoss() && stsl<OrderOpenPrice())   {
                  OrderModify(OrderTicket(),OrderOpenPrice(),stsl,
                              0,//sell-(NormalizeDouble((buy-sell)*2,Digits)),
                              OrderExpiration(),Sienna);break;}}}}}}}

void OrderMod()   {
   for(int i=0;i<OrdersTotal();i++) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic &&
         OrderComment()==Period()+comment) {
         if(OrderType()==OP_BUYSTOP)   {
            for(int p=0;p<ObjectsTotal();p++)   {
               if(ObjectGetValueByShift(ObjectName(p),0)>Ask &&
                  ObjectGetValueByShift(ObjectName(p),0)<OrderOpenPrice()) {
                     BuySell();
                     if(buy>0 && sell>0) {
                     if(buy==OrderOpenPrice() && sell==OrderStopLoss() &&
                     buy+(NormalizeDouble((buy-sell)*2,Digits))==OrderTakeProfit()) {break;}
                     OrderModify(OrderTicket(),buy,sell,
                                 0,//buy+(NormalizeDouble((buy-sell)*2,Digits)),OrderExpiration(),
                                 Blue);break;}}}}
         if(OrderType()==OP_SELLSTOP)  {
            for(int k=0;k<ObjectsTotal();k++)   {
               if(ObjectGetValueByShift(ObjectName(k),0)<Bid &&
                  ObjectGetValueByShift(ObjectName(k),0)>OrderOpenPrice()) {
                     BuySell();
                     if(buy>0 && sell>0)  {
                     if(buy==OrderStopLoss() && sell==OrderOpenPrice() &&
                     sell-(NormalizeDouble((buy-sell)*2,Digits))==OrderTakeProfit()) {break;}
                     OrderModify(OrderTicket(),sell,buy,
                                 0,//sell-(NormalizeDouble((buy-sell)*2,Digits)),OrderExpiration(),
                                 Red);break;}}}}}}}

double LotsOptimized()  {
   double lot;
   int    orders=HistoryTotal();
   int    losses=0;
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/Lot.Margin,2);
   if(DecreaseFactor>0) {
      for(int i=orders-1;i>=0;i--)  {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++; }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,2);   }
   if(lot<0.01) lot=0.01;
return(lot);   }//end LotsOptimized

void Old.Object.Delete()   {
   if(ObjectsTotal()==0) {return(0);}
   if(!IsTesting()) {ObjectsDeleteAll(0,22);}
   if(Period()<=5)   {
      if((Minute()==0 && Seconds()<=5)  || (Minute()==5 && Seconds()<=5)  ||
         (Minute()==10 && Seconds()<=5) || (Minute()==15 && Seconds()<=5) ||
         (Minute()==20 && Seconds()<=5) || (Minute()==25 && Seconds()<=5) ||
         (Minute()==30 && Seconds()<=5) || (Minute()==35 && Seconds()<=5) ||
         (Minute()==40 && Seconds()<=5) || (Minute()==45 && Seconds()<=5) ||
         (Minute()==50 && Seconds()<=5) || (Minute()==55 && Seconds()<=5))   {
            ObjectsDeleteAll(0,OBJ_TREND);}}
   if(Period()>5) {
      if((Minute()==0 && Seconds()<=15)  || (Minute()==15 && Seconds()<=15) ||
         (Minute()==30 && Seconds()<=15) || (Minute()==45 && Seconds()<=15)) {
            ObjectsDeleteAll(0,OBJ_TREND);}}
   if(ObjectsTotal()>Max.Trendlines) {ObjectsDeleteAll(0,OBJ_TREND);}}

datetime Orderexpiration()   {
   if(IsTesting()) return(0);
   if(Period()<60)   {
      double hr=Hour()+1;
      string date=TimeToStr(CurTime(),TIME_DATE);
      string hour=DoubleToStr(hr,0);
      string minutes=Minute();
      return(StrToTime(date+" "+hour+minutes));}
   if(Period()>=60)  {
      hr=Hour()+(Period()/60);
      date=TimeToStr(CurTime(),TIME_DATE);
      hour=DoubleToStr(hr,0);
      minutes=Minute();
      return(StrToTime(date+" "+hour+minutes));}}

void Comments()   {
   if(!IsTesting()) {
   Comment("Last Tick: ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS),"\n",
           "Total S/R Lines: ",ObjectsTotal());  }} 