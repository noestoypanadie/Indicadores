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

extern int     Max.Trendlines =12;

extern double  Magic          =321;
extern string  comment        ="m S-R limit";

int b,s,ticket;
double buy,sell,btsl,stsl,slsl,blsl;
double spread;spread=Ask-Bid;
int slip;slip=spread/Point;
double One.Min;

int init(){return(0);}
int deinit(){return(0);}
int start(){
   ChartPeriod=Period();
   One.Min=iCustom(Symbol(),0,"Support Resistance",ChartPeriod,144,13,1,5,true,RosyBrown,Aqua,DeepPink,Red,DarkOrange,DeepSkyBlue,Lime,0,0);
   PosCounter();
   BuySell();
   if(s==0 && Ask<buy && Bid>sell && slsl>0)  {
      ticket=OrderSend(Symbol(),
                        OP_SELLLIMIT,
                        LotsOptimized(),
                        buy,
                        slip,//slippage
                        slsl,
                        sell,//TakeProfit(),
                        Period()+comment,
                        Magic,
                        0,//OrderExpiration
                        Aqua);
                        if(ticket>0)   {
                            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                  {   Print(ticket); }
                            else Print("Error Opening BuyStop Order: ",GetLastError());
                            return(0);}}
   if(b==0 && Bid>sell && Ask<buy && blsl>0) {     
      ticket=OrderSend(Symbol(),
                        OP_BUYLIMIT,
                        LotsOptimized(),
                        sell,
                        slip,//slippage
                        blsl,
                        buy,//TakeProfit(),
                        Period()+comment,
                        Magic,
                        0,//OrderExpiration
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
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) {
         if(OrderType()==OP_SELL)      s++;
         if(OrderType()==OP_SELLSTOP)  s++;
         if(OrderType()==OP_SELLLIMIT) s++;
         if(OrderType()==OP_BUY)       b++;
         if(OrderType()==OP_BUYSTOP)   b++;
         if(OrderType()==OP_BUYLIMIT)  b++;}}}

void BuySell()  {
   buy=0;sell=0;
   for(int c=0;c<ObjectsTotal();c++)  {
      if(ObjectGetValueByShift(ObjectName(c),0)>Ask) {
         buy=ObjectGetValueByShift(ObjectName(c),0);}
      if(ObjectGetValueByShift(ObjectName(c),0)>buy)  {double slsl=ObjectGetValueByShift(ObjectName(c),0);}
      if(ObjectGetValueByShift(ObjectName(c),0)<Bid)  {
         sell=ObjectGetValueByShift(ObjectName(c),0);}
      if(ObjectGetValueByShift(ObjectName(c),0)<sell) {double blsl=ObjectGetValueByShift(ObjectName(c),0);}}}

void TrailStop()  {
   btsl=0;stsl=0;
   for(int i=0;i<OrdersTotal();i++) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) {
         if(OrderType()==OP_BUY) {
            for(int p=0;p<ObjectsTotal();p++)   {
               if(ObjectGetValueByShift(ObjectName(p),0)<Bid &&
                  (ObjectGetValueByShift(ObjectName(p),0)>OrderOpenPrice() &&
                   ObjectGetValueByShift(ObjectName(p),0)>OrderStopLoss()) ||
                   OrderStopLoss()<=0) {
                  btsl=ObjectGetValueByShift(ObjectName(p),0);
                  if(btsl>OrderStopLoss()) {
                  OrderModify(OrderTicket(),OrderOpenPrice(),btsl,OrderTakeProfit(),OrderExpiration(),Olive);}}}}
         if(OrderType()==OP_SELL)   {
            for(int k=0;k<ObjectsTotal();k++)   {
               if(ObjectGetValueByShift(ObjectName(k),0)>Ask &&
                  (ObjectGetValueByShift(ObjectName(k),0)<OrderOpenPrice() &&
                   ObjectGetValueByShift(ObjectName(k),0)<OrderStopLoss()) ||
                   OrderStopLoss()<=0) {
                  stsl=ObjectGetValueByShift(ObjectName(k),0);
                  if(stsl<OrderStopLoss())   {
                  OrderModify(OrderTicket(),OrderOpenPrice(),stsl,OrderTakeProfit(),OrderExpiration(),Sienna);}}}}}}}

void OrderMod()   {
   for(int i=0;i<OrdersTotal();i++) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) {
         if(OrderType()==OP_SELLLIMIT)   {
            for(int p=0;p<ObjectsTotal();p++)   {
               if(ObjectGetValueByShift(ObjectName(p),0)>Ask &&
                  ObjectGetValueByShift(ObjectName(p),0)<OrderOpenPrice()) {
                     BuySell();
                     if(buy>0 && sell>0 && slsl>0) {
                     OrderModify(OrderTicket(),buy,buy+Point*10,sell,OrderExpiration(),Blue);}}}}
         if(OrderType()==OP_BUYLIMIT)  {
            for(int k=0;k<ObjectsTotal();k++)   {
               if(ObjectGetValueByShift(ObjectName(k),0)<Bid &&
                  ObjectGetValueByShift(ObjectName(k),0)>OrderOpenPrice()) {
                     BuySell();
                     if(buy>0 && sell>0 && blsl>0)  {
                     OrderModify(OrderTicket(),sell,sell-Point*10,buy,OrderExpiration(),Red);}}}}}}}

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
   if(!IsTesting()) {ObjectsDeleteAll(0,22);}
   if(ObjectsTotal()>=Max.Trendlines) {
   ObjectsDeleteAll(0,OBJ_TREND);}}

void Comments()   {
   if(!IsTesting()) {
   Comment("Last Tick: ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS),"\n",
           "Total S/R Lines: ",ObjectsTotal());  }} 