//+------------------------------------------------------------------+
//|                                                          S-R.mq4 |
//|                 Copyright © 2005, tageiger aka fxid10t@yahoo.com |
//|                                        http://www.metatrader.org |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, tageiger aka fxid10t@yahoo.com"
#property link      "http://www.metatrader.org"

extern double  MaximumRisk    =0.02;
extern double  DecreaseFactor =3;
extern int     Lot.Margin     =1000;

extern int     Max.Trendlines =55;

extern double  Magic          =321;
extern string  comment        ="m S-R";

int b,s,ticket,ChartPeriod;
double buy,sell,btsl,stsl;
double spread;spread=Ask-Bid;
int slip;slip=spread/Point;
double fifteen;

int init(){return(0);}
int deinit(){return(0);}
int start(){

   if(IsTesting())  {
      ChartPeriod=Period();
      fifteen=iCustom(Symbol(),0,"Support Resistance",ChartPeriod,144,13,1,5,
      true,RosyBrown,Aqua,DeepPink,PaleVioletRed,Red,DarkOrange,DeepSkyBlue,Lime,0,0);}

   PosCounter();
   if(ObjectsTotal()==0) {return(0);}
   BuySell();
   if(b==0 && Ask<buy && Bid>sell && buy>0 && sell>0)  {
      ticket=OrderSend(Symbol(),
                        OP_BUYSTOP,
                        LotsOptimized(),
                        buy,
                        slip,//slippage
                        sell,
                        0,//TakeProfit(),
                        Period()+comment,
                        Magic,
                        Orderexpiration(),//OrderExpiration
                        Aqua);
                        if(ticket>0)   {
                            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                  {   Print(ticket); }
                            else Print("Error Opening BuyStop Order: ",GetLastError());
                            return(0);}}
   if(s==0 && Bid>sell && Ask<buy && buy>0 && sell>0) {     
      ticket=OrderSend(Symbol(),
                        OP_SELLSTOP,
                        LotsOptimized(),
                        sell,
                        slip,//slippage
                        buy,
                        0,//TakeProfit(),
                        Period()+comment,
                        Magic,
                        Orderexpiration(),//OrderExpiration
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
         if(OrderType()==OP_BUY)       b++;
         if(OrderType()==OP_BUYSTOP)   b++;}}}

void BuySell()  {
   //buy=0;sell=0;
   for(int c=0;c<ObjectsTotal();c++)  {
      if(ObjectGetValueByShift(ObjectName(c),0)>Ask) {
         buy=ObjectGetValueByShift(ObjectName(c),0)+spread;}
      if(ObjectGetValueByShift(ObjectName(c),0)<Bid)  {
         sell=ObjectGetValueByShift(ObjectName(c),0)-spread;}}}

void TrailStop()  {
   btsl=0;stsl=0;
   for(int i=0;i<OrdersTotal();i++) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) {
         if(OrderType()==OP_BUY) {
            for(int p=0;p<ObjectsTotal();p++)   {
               if(ObjectGetValueByShift(ObjectName(p),0)-spread<Bid &&
                  ObjectGetValueByShift(ObjectName(p),0)-spread>OrderOpenPrice() &&
                  ObjectGetValueByShift(ObjectName(p),0)-spread>OrderStopLoss()) {
                  btsl=ObjectGetValueByShift(ObjectName(p),0)-spread;}
               if(btsl>0 && IsTradeAllowed())  {
                  OrderModify(OrderTicket(),OrderOpenPrice(),btsl,OrderTakeProfit(),OrderExpiration(),Olive);}}}
         if(OrderType()==OP_SELL)   {
            for(int k=0;k<ObjectsTotal();k++)   {
               if(ObjectGetValueByShift(ObjectName(k),0)+spread>Ask &&
                  ObjectGetValueByShift(ObjectName(k),0)+spread<OrderOpenPrice() &&
                  ObjectGetValueByShift(ObjectName(k),0)+spread<OrderStopLoss()) {
                  stsl=ObjectGetValueByShift(ObjectName(k),0)+spread;}
                  if(stsl>0 && IsTradeAllowed())  {
                  OrderModify(OrderTicket(),OrderOpenPrice(),stsl,OrderTakeProfit(),OrderExpiration(),Sienna);}}}}}}

void OrderMod()   {
   for(int i=0;i<OrdersTotal();i++) {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) {

         if(OrderType()==OP_BUYSTOP)   {
            for(int p=0;p<ObjectsTotal();p++)   {
               if(ObjectGetValueByShift(ObjectName(p),0)+spread>Ask &&
                  ObjectGetValueByShift(ObjectName(p),0)+spread<OrderOpenPrice()) {
                     buy=ObjectGetValueByShift(ObjectName(p),0)+spread; }
               if(ObjectGetValueByShift(ObjectName(p),0)-spread<Bid &&
                  ObjectGetValueByShift(ObjectName(p),0)-spread>OrderOpenPrice()) {
                     sell=ObjectGetValueByShift(ObjectName(p),0)-spread;   }}
            if(IsTradeAllowed() && buy<OrderOpenPrice()) {
               OrderModify(OrderTicket(),NormalizeDouble(buy,Digits),OrderStopLoss(),OrderTakeProfit(),OrderExpiration(),Blue);}
            if(IsTradeAllowed() && sell>OrderStopLoss()) {
               OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(sell,Digits),OrderTakeProfit(),OrderExpiration(),Blue);}}

         if(OrderType()==OP_SELLSTOP)  {
            for(int k=0;k<ObjectsTotal();k++)   {
               if(ObjectGetValueByShift(ObjectName(k),0)-spread<Bid &&
                  ObjectGetValueByShift(ObjectName(k),0)-spread>OrderOpenPrice()) {
                     sell=ObjectGetValueByShift(ObjectName(k),0)-spread;   }
               if(ObjectGetValueByShift(ObjectName(p),0)+spread>Ask &&
                  ObjectGetValueByShift(ObjectName(p),0)+spread<OrderOpenPrice()) {
                     buy=ObjectGetValueByShift(ObjectName(p),0)+spread; }}
            if(IsTradeAllowed() && sell>OrderOpenPrice())  {
               OrderModify(OrderTicket(),NormalizeDouble(sell,Digits),OrderStopLoss(),OrderTakeProfit(),OrderExpiration(),Red);}
            if(IsTradeAllowed() && buy<OrderStopLoss())  {
               OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(buy,Digits),OrderTakeProfit(),OrderExpiration(),Red);}}}}}

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
   if((Minute()==0 && Seconds()<=15) || (Minute()==15 && Seconds()<=15) ||
      (Minute()==30 && Seconds()<=15) || (Minute()==45 && Seconds()<=15)) {ObjectsDeleteAll(0,OBJ_TREND);}
   if(ObjectsTotal()>Max.Trendlines) {ObjectsDeleteAll(0,OBJ_TREND);}}

datetime Orderexpiration()   {
double hr=Hour();
string date=TimeToStr(CurTime(),TIME_DATE);
string hour=DoubleToStr(hr,0);
string minutes=":59";
return(StrToTime(date+" "+hour+minutes));}//end timedelete

void Comments()   {
   if(!IsTesting()) {
   Comment("Last Tick: ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS),"\n",
           "Total S/R Lines: ",ObjectsTotal());  }}
 