//+------------------------------------------------------------------+
//|                                        volume trader (redux).mq4 |
//|                 Copyright © 2005, tageiger aka fxid10t@yahoo.com |
//|                                        http://www.metatrader.org |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, tageiger aka fxid10t@yahoo.com"
#property link      "http://www.metatrader.org"

extern double  lot      =1;
extern int     SL       =0;
extern int     TP       =0;
extern int     Magic    =666;
extern string  comment  ="m volume trader (redux)";

int volume.previous,volume.previous.1,b.ticket,s.ticket,cnt;
double spread,slip;

int init(){return(0);}
int deinit(){return(0);}

int start(){
   spread=Ask-Bid;slip=spread/Point;

   volume.previous=iVolume(Symbol(),1440,1);
   volume.previous.1=iVolume(Symbol(),1440,2);
   
   PosCounter();
   
   if(s.ticket==0 &&
      volume.previous>volume.previous.1)  {
         s.ticket=OrderSend(Symbol(),
                            OP_SELL,
                            lot,
                            Bid,
                            slip,
                            Bid+(SL*Point),
                            Bid-(TP*Point),
                            Period()+comment,
                            Magic,0,Red);
                            if(s.ticket>0)   {
                               if(OrderSelect(s.ticket,SELECT_BY_TICKET,MODE_TRADES))
                                   {   Print(s.ticket);   }
                               else Print("Error Opening Sell Order: ",GetLastError());
                            return(0);}}
   if(b.ticket==0 &&
      volume.previous<volume.previous.1)  {
         b.ticket=OrderSend(Symbol(),
                            OP_BUY,
                            lot,
                            Ask,
                            slip,
                            Ask-(SL*Point),
                            Ask+(TP*Point),
                            Period()+comment,
                            Magic,0,Blue);
                            if(b.ticket>0)   {
                               if(OrderSelect(b.ticket,SELECT_BY_TICKET,MODE_TRADES))
                                   {   Print(b.ticket);   }
                               else Print("Error Opening Buy Order: ",GetLastError());
                            return(0);}}

   OrderSelect(s.ticket,SELECT_BY_TICKET);
   if(s.ticket==OrderTicket() &&
      volume.previous<volume.previous.1)  {
         OrderClose(s.ticket,OrderLots(),Ask,slip,HotPink);}

   OrderSelect(b.ticket,SELECT_BY_TICKET);
   if(b.ticket==OrderTicket() &&
      volume.previous>volume.previous.1)  {
         OrderClose(b.ticket,OrderLots(),Bid,slip,DarkTurquoise);}
      
   if(!IsTesting()) comments();
return(0);}
//+------------------------------------------------------------------+
void comments() {  Comment("Last Tick Time: ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS),"\n",
                           "Today","\'","s Volume: ",iVolume(Symbol(),1440,0),"\n",
                           "Previous Day Volume: ",volume.previous,"\n",
                           "Day before Previous Volume: ",volume.previous.1); }

void PosCounter() {
   b.ticket=0;s.ticket=0;
   for(cnt=0;cnt<=OrdersTotal();cnt++)   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) {
         if(OrderType()==OP_SELL)   {
            s.ticket=OrderTicket();}
         if(OrderType()==OP_BUY)    {
            b.ticket=OrderTicket();} }}}