//+------------------------------------------------------------------+
//|                                                     Envelope.mq4 |
//|                  Copyright © 2006,tageiger aka fxid10t@yahoo.com |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006,tageiger aka fxid10t@yahoo.com"
#property link      "http://www.metaquotes.net"

extern bool       Use.gbpjpy.preset?=true;   //enable GBPJPYm presets
extern bool       Use.eurusd.preset?=true;   //enable EURUSDm presets

extern int        EnvTimeFrame      =5;      //envelope time frame: 0=chart,60=1hr,240=4hr, etc.
extern int        EnvelopePeriod    =144;    //moving average length
extern int        EnvMaMethod       =1;      //0=sma,1=ema,2=smma,3=lwma.
extern int        MaShift           =0;      //shift relative to current bar indicator data is posted
extern double     EnvelopeDeviation =0.4;    //envelope width

extern double     Trigger.Deviation =0.4;    //envelope width

extern bool       UseMaElineTSL?    =true;   //enable moving average or Opposite Envelope line trailing SL
extern int        MaElineTSL        =0;      //see notes below
   /*0=iMA trailing SL  
     1=Opposite Envelope line trailing SL
     2=Near Envelope line trailing SL (for 15m or greater periods, when price breaks out of the envelopes)*/

extern bool       BreakEvenTSL?     =false;  //enable break even trailing stoploss
extern int        BreakEvenPips     =1;      //pips above/below OrderOpenPrice for breakeven SL

extern bool       FastMaTSL?        =false;  //enable fast ma trailing stoploss
extern int        FastMaPeriod      =55;     //FastMaTSL moving average length
extern int        FastMaMethod      =0;      //0=sma,1=ema,2=smma,3=lwma.
extern int        FastMaShift       =0;      //shift relative to current bar indicator data is posted

extern bool       FixedPipTSL?      =false;  //enable fixed pip trailing stoploss
extern int        FixedPipTSLPips   =0;      //pips to trail
extern int        FixedPipTSLTrigger=0;      //pips in profit before trailing stoploss is triggered

extern int        TimeBegin         =0;      //server time order placement begins
extern int        TimeEnd           =18;     //server time order placement ends
extern double     TimeDelete        =23;     //server time unexecuted orders deleted

extern double     FirstTP           =21.0;   //1st TP in pips
extern double     SecondTP          =34.0;   //2nd TP in pips
extern double     ThirdTP           =55.0;   //3rd TP in pips

extern bool       Use.Money.Mgt     =true;   //if false, uses Minimum.Lot
extern double     Minimum.Lot       =0.01;    //Smallest lot size to trade, Use.MM true or false
extern double     MaximumRisk       =0.02;   //%account balance to risk per position
extern double     DecreaseFactor    =2;      //lot size divisor(reducer) during loss streak
extern double     Lot.Margin        =50;     //Margin required to trade 1 lot   

extern bool       DeleteOrders?     =false;  //deletes pending stop orders if true
extern bool       CloseOrders?      =false;  //closes open orders if true, regardless of profit status.
extern int        Slippage          =2;      //applies to closeorders()

int               b1,b2,b3,s1,s2,s3;
double            ssl,bsl,TSL;
string            comment           ="m e.3.05";
string            TradeSymbol,date;

int init(){return(0);}
int deinit(){return(0);}
int start() {
   if(Use.gbpjpy.preset? && Symbol()=="GBPJPYm") {gbpjpy.preset();}
  if(Use.eurusd.preset? && Symbol()=="EURUSDm") {eurusd.preset();}

   TradeSymbol=Symbol();
   if(!IsTesting())  {ObjectsDeleteAll(0,22);}

   double   btp1,btp2,btp3,stp1,stp2,stp3;
   double   bline=0,sline=0,ma=0,bt.line=0,st.line=0;
   int      cnt, ticket,total=OrdersTotal();

   ma=iMA(NULL,EnvTimeFrame,EnvelopePeriod,MaShift,EnvMaMethod,PRICE_CLOSE,0);
   bline=iEnvelopes(NULL,EnvTimeFrame,EnvelopePeriod,EnvMaMethod,0,PRICE_CLOSE,EnvelopeDeviation,MODE_UPPER,0);
   sline=iEnvelopes(NULL,EnvTimeFrame,EnvelopePeriod,EnvMaMethod,0,PRICE_CLOSE,EnvelopeDeviation,MODE_LOWER,0);
   bt.line=iEnvelopes(NULL,EnvTimeFrame,EnvelopePeriod,EnvMaMethod,0,PRICE_CLOSE,Trigger.Deviation,MODE_UPPER,0);
   st.line=iEnvelopes(NULL,EnvTimeFrame,EnvelopePeriod,EnvMaMethod,0,PRICE_CLOSE,Trigger.Deviation,MODE_LOWER,0);
   if(bline<bt.line || sline>st.line)  {return(0);}
   if(TimeBegin>TimeEnd)   {return(0);}

   if(TotalTradesThisSymbol(TradeSymbol)==0) {  b1=0;b2=0;b3=0;s1=0;s2=0;s3=0;   }
   if(TotalTradesThisSymbol(TradeSymbol)>0)  {
      for(cnt=0;cnt<total;cnt++) {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==TradeSymbol) {
         if(OrderMagicNumber()==21)  {b1=OrderTicket(); }
         if(OrderMagicNumber()==41)  {b2=OrderTicket(); }
         if(OrderMagicNumber()==61)  {b3=OrderTicket(); }
         if(OrderMagicNumber()==11)  {s1=OrderTicket(); }
         if(OrderMagicNumber()==31)  {s2=OrderTicket(); }
         if(OrderMagicNumber()==51)  {s3=OrderTicket(); } }  }  }

   if(DeleteOrders?) deleteorders();
   if(CloseOrders?)  closeorders();
   
   if(b1==0)   {  
      if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
         if(bt.line>Close[0] && st.line<Close[0])   {
            btp1=(NormalizeDouble(bline,Digits))+(FirstTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(bline,Digits)),
                              0,
                              (NormalizeDouble(sline,Digits)),
                              btp1,
                              Period()+comment+"b1 "+TimeToStr(CurTime(),TIME_DATE),
                              21,
                              0,//timedelete(),
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  b1=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);  }  }  }  }         

   if(b2==0)   {
      if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
         if(bt.line>Close[0] && st.line<Close[0])   {      
            btp2=(NormalizeDouble(bline,Digits))+(SecondTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(bline,Digits)),
                              0,
                              (NormalizeDouble(sline,Digits)),
                              btp2,
                              Period()+comment+"b2 "+TimeToStr(CurTime(),TIME_DATE),
                              41,
                              0,//timedelete(),
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {   b2=ticket; Print(ticket); }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);  }  }  }  }                              
   if(b3==0)   {
      if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
         if(bt.line>Close[0] && st.line<Close[0])   {      
            btp3=(NormalizeDouble(bline,Digits))+(ThirdTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(bline,Digits)),
                              0,
                              (NormalizeDouble(sline,Digits)),
                              btp3,
                              Period()+comment+"b3 "+TimeToStr(CurTime(),TIME_DATE),
                              61,
                              0,//timedelete(),
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  b3=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);  }  }  }  }                     

   if(s1==0)   {
      if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
         if(bt.line>Close[0] && st.line<Close[0])   {      
            stp1=NormalizeDouble(sline,Digits)-(FirstTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(sline,Digits)),
                              0,
                              (NormalizeDouble(bline,Digits)),
                              stp1,
                              Period()+comment+"s1 "+TimeToStr(CurTime(),TIME_DATE),
                              11,
                              0,//timedelete(),
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s1=ticket;  Print(ticket); }
                                 else Print("Error Opening SellStop Order: ",GetLastError());
                                 return(0);  }  }  }  }

   if(s2==0)   {
      if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
         if(bt.line>Close[0] && st.line<Close[0])   {      
            stp2=NormalizeDouble(sline,Digits)-(SecondTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(sline,Digits)),
                              0,
                              (NormalizeDouble(bline,Digits)),
                              stp2,
                              Period()+comment+"s2 "+TimeToStr(CurTime(),TIME_DATE),
                              31,
                              0,//timedelete(),
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s2=ticket;  Print(ticket); }
                                 else Print("Error Opening SellStop Order: ",GetLastError());
                                 return(0);  }  }  }  }                     
   if(s3==0)   {
      if(Hour()>=TimeBegin && Hour()<TimeEnd)   {
         if(bt.line>Close[0] && st.line<Close[0])   {      
            stp3=NormalizeDouble(sline,Digits)-(ThirdTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(sline,Digits)),
                              0,
                              (NormalizeDouble(bline,Digits)),
                              stp3,
                              Period()+comment+"s3 "+TimeToStr(CurTime(),TIME_DATE),
                              51,
                              0,//timedelete(),
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s3=ticket;  Print(ticket); }
                                 else Print("Error Opening SellStop Order: ",GetLastError());
                                 return(0);  }  }  }  }

   for(cnt=0;cnt<total;cnt++) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);            
      if(OrderType()==OP_BUY && IsTradeAllowed() && OrderSymbol()==Symbol() &&
        (OrderMagicNumber()==21 || OrderMagicNumber()==41 || OrderMagicNumber()==61)) {
         if(BreakEvenTSL?)    {TSL=breakevenTSL();}
         if(FastMaTSL?)       {TSL=fastmaTSL();}
         if(FixedPipTSL?)     {TSL=fixedpipTSL();}
         if(UseMaElineTSL?)   {
            if(MaElineTSL==0) {TSL=NormalizeDouble(ma,Digits);}
            if(MaElineTSL==1) {TSL=NormalizeDouble(sline,Digits);}
            if(MaElineTSL==2) {TSL=NormalizeDouble(bline,Digits);}}
         if(Bid>OrderOpenPrice() && TSL>OrderStopLoss() && TSL>OrderOpenPrice())  {
               bsl=TSL;  if(bsl==0 || bsl<OrderStopLoss()) {return(0);}
               OrderModify(b1,
                           OrderOpenPrice(),
                           bsl,
                           OrderOpenPrice()+FirstTP*Point,
                           OrderExpiration(),
                           Green);
               OrderModify(b2,
                           OrderOpenPrice(),
                           bsl,
                           OrderOpenPrice()+SecondTP*Point,
                           OrderExpiration(),
                           Green);
               OrderModify(b3,
                           OrderOpenPrice(),
                           bsl,
                           OrderOpenPrice()+ThirdTP*Point,
                           OrderExpiration(),
                           Green);}  }
      if(OrderType()==OP_SELL && IsTradeAllowed() && OrderSymbol()==Symbol() &&
        (OrderMagicNumber()==11 || OrderMagicNumber()==31 || OrderMagicNumber()==51))   {
         if(BreakEvenTSL?)    {TSL=breakevenTSL();}
         if(FastMaTSL?)       {TSL=fastmaTSL();}
         if(FixedPipTSL?)     {TSL=fixedpipTSL();}
         if(UseMaElineTSL?)   {
         if(MaElineTSL==0) {TSL=NormalizeDouble(ma,Digits);}
         if(MaElineTSL==1) {TSL=NormalizeDouble(bline,Digits);}
         if(MaElineTSL==2) {TSL=NormalizeDouble(sline,Digits);}}
         if(Ask<OrderOpenPrice() && TSL<OrderStopLoss() && TSL<OrderOpenPrice())  {
               ssl=TSL; if(ssl==0 || ssl>OrderStopLoss()) {return(0);}
               OrderModify(s1,
                           OrderOpenPrice(),
                           ssl,
                           OrderOpenPrice()-FirstTP*Point,
                           OrderExpiration(),
                           Red);
               OrderModify(s2,
                           OrderOpenPrice(),
                           ssl,
                           OrderOpenPrice()-SecondTP*Point,
                           OrderExpiration(),
                           Red);
               OrderModify(s3,
                           OrderOpenPrice(),
                           ssl,
                           OrderOpenPrice()-ThirdTP*Point,
                           OrderExpiration(),
                           Red);}  }

   if(b1>0 && date!=TimeToStr(CurTime(),TIME_DATE))  {
      OrderSelect(b1,SELECT_BY_TICKET);
      OrderModify(b1,NormalizeDouble(bline,Digits),NormalizeDouble(sline,Digits),
                  NormalizeDouble(bline,Digits)+FirstTP*Point,0,0);}
   if(b2>0 && date!=TimeToStr(CurTime(),TIME_DATE))  {
      OrderSelect(b2,SELECT_BY_TICKET);
      OrderModify(b2,NormalizeDouble(bline,Digits),NormalizeDouble(sline,Digits),
                  NormalizeDouble(bline,Digits)+SecondTP*Point,0,0);}
   if(b3>0 && date!=TimeToStr(CurTime(),TIME_DATE))  {
      OrderSelect(b3,SELECT_BY_TICKET);
      OrderModify(b3,NormalizeDouble(bline,Digits),NormalizeDouble(sline,Digits),
                  NormalizeDouble(bline,Digits)+ThirdTP*Point,0,0);}
   if(s1>0 && date!=TimeToStr(CurTime(),TIME_DATE))  {
      OrderSelect(s1,SELECT_BY_TICKET);
      OrderModify(s1,NormalizeDouble(sline,Digits),NormalizeDouble(bline,Digits),
                  NormalizeDouble(bline,Digits)-FirstTP*Point,0,0);}
   if(s2>0 && date!=TimeToStr(CurTime(),TIME_DATE))  {
      OrderSelect(s2,SELECT_BY_TICKET);
      OrderModify(s2,NormalizeDouble(sline,Digits),NormalizeDouble(bline,Digits),
                  NormalizeDouble(bline,Digits)-SecondTP*Point,0,0);}
   if(s3>0 && date!=TimeToStr(CurTime(),TIME_DATE))  {
      OrderSelect(s3,SELECT_BY_TICKET);
      OrderModify(s3,NormalizeDouble(sline,Digits),NormalizeDouble(bline,Digits),
                  NormalizeDouble(bline,Digits)-ThirdTP*Point,0,0);}
   date=TimeToStr(CurTime(),TIME_DATE);

   OrderSelect(b1,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {b1=0; SendMail(Symbol()+" "+OrderComment(),"$"+DoubleToStr(OrderProfit(),2)); }
   OrderSelect(b2,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {b2=0; SendMail(Symbol()+" "+OrderComment(),"$"+DoubleToStr(OrderProfit(),2)); }
   OrderSelect(b3,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {b3=0; SendMail(Symbol()+" "+OrderComment(),"$"+DoubleToStr(OrderProfit(),2)); }
   OrderSelect(s1,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {s1=0; SendMail(Symbol()+" "+OrderComment(),"$"+DoubleToStr(OrderProfit(),2)); }
   OrderSelect(s2,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {s2=0; SendMail(Symbol()+" "+OrderComment(),"$"+DoubleToStr(OrderProfit(),2)); }     
   OrderSelect(s3,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {s3=0; SendMail(Symbol()+" "+OrderComment(),"$"+DoubleToStr(OrderProfit(),2)); }   }
   if(!IsTesting())  {  PrintComments();  }
return(0);   
}

//Functions.................................................

double LotsOptimized()  {
   double lot;int IncreaseFactor=100;
   int    orders=HistoryTotal();
   int    losses=0;
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/Lot.Margin,2);
   Minimum.Lot=lot;
   if(DecreaseFactor>0) {
      for(int i=orders-1;i>=0;i--)  {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++; }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,2);}
   if(lot<Minimum.Lot) lot=Minimum.Lot;
   if(Use.Money.Mgt==false)   {lot=Minimum.Lot;}
return(lot);   }//end LotsOptimized

int TotalTradesThisSymbol(string TradeSymbol) {
   int i, TradesThisSymbol=0;
   for(i=0;i<OrdersTotal();i++)  {
      OrderSelect(i,SELECT_BY_POS);
      if(OrderSymbol()==TradeSymbol &&
        (OrderMagicNumber()==11 ||
         OrderMagicNumber()==21 || 
         OrderMagicNumber()==31 || 
         OrderMagicNumber()==41 || 
         OrderMagicNumber()==51 || 
         OrderMagicNumber()==61))   {  TradesThisSymbol++;  }   }
return(TradesThisSymbol);  }//end TotalTradesThisSymbol

void PrintComments() {  Comment("Last Tick: ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS));}/*,"\n",
                                "Delete Time: ",TimeToStr(timedelete(),TIME_DATE|TIME_MINUTES));  }*/
   
void deleteorders()   {
   TimeBegin=Hour()+1;
   OrderSelect(b1,SELECT_BY_TICKET);
   if(OrderType()==OP_BUYSTOP)   {
      OrderDelete(OrderTicket());
      b1=0;}
   OrderSelect(b2,SELECT_BY_TICKET);
   if(OrderType()==OP_BUYSTOP)   {
      OrderDelete(OrderTicket());
      b2=0;}
   OrderSelect(b3,SELECT_BY_TICKET);
   if(OrderType()==OP_BUYSTOP)   {
      OrderDelete(OrderTicket());
      b3=0;}
   OrderSelect(s1,SELECT_BY_TICKET);
   if(OrderType()==OP_SELLSTOP)   {
      OrderDelete(OrderTicket());
      s1=0;}
   OrderSelect(s2,SELECT_BY_TICKET);
   if(OrderType()==OP_SELLSTOP)   {
      OrderDelete(OrderTicket());
      s2=0;}
   OrderSelect(s3,SELECT_BY_TICKET);
   if(OrderType()==OP_SELLSTOP)   {
      OrderDelete(OrderTicket());
      s3=0;}  }//end deleteorders()

int closeorders()   {
   TimeBegin=Hour()+1;
   OrderSelect(b1,SELECT_BY_TICKET);
   if(OrderType()==OP_BUY) {
      OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,DarkOrchid);
      b1=0;}
   OrderSelect(b2,SELECT_BY_TICKET);
   if(OrderType()==OP_BUY) {
      OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,DarkOrchid);
      b2=0;}
   OrderSelect(b3,SELECT_BY_TICKET);
   if(OrderType()==OP_BUY) {
      OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,DarkOrchid);
      b3=0;}
   OrderSelect(s1,SELECT_BY_TICKET);
   if(OrderType()==OP_SELL) {
      OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,DarkOrange);
      s1=0;}
   OrderSelect(s2,SELECT_BY_TICKET);
   if(OrderType()==OP_SELL) {
      OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,DarkOrange);
      s2=0;}
   OrderSelect(s3,SELECT_BY_TICKET);
   if(OrderType()==OP_SELL) {
      OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,DarkOrange);
      s3=0;}   }//end closeorders()

/*
datetime timedelete()   {
string date=TimeToStr(CurTime(),TIME_DATE);
string hour=DoubleToStr(TimeDelete,0);
string minutes=":00";
return(StrToTime(date+" "+hour+minutes));}//end timedelete
*/
double breakevenTSL()   {
   double beTSL;
   for(int cnt=0;cnt<OrdersTotal();cnt++) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()==OP_BUY && OrderSymbol()==Symbol() &&
        (OrderMagicNumber()==21 ||
         OrderMagicNumber()==41 ||
         OrderMagicNumber()==61))   {
            if(Bid-OrderOpenPrice()>=Point*FirstTP) {
            beTSL=OrderOpenPrice()+(BreakEvenPips*Point);}}
      if(OrderType()==OP_SELL && OrderSymbol()==Symbol() &&
        (OrderMagicNumber()==11 ||
         OrderMagicNumber()==31 ||
         OrderMagicNumber()==51))   {
            if(OrderOpenPrice()-Ask>=Point*FirstTP) {
            beTSL=OrderOpenPrice()-(BreakEvenPips*Point);}}}
return(beTSL);}

double fastmaTSL()   {
   double fmaTSL;
   fmaTSL=iMA(Symbol(),EnvTimeFrame,FastMaPeriod,FastMaShift,FastMaMethod,PRICE_CLOSE,0);
return(NormalizeDouble(fmaTSL,Digits));}

double fixedpipTSL() {
   double fpTSL=0;
   for(int cnt=0;cnt<OrdersTotal();cnt++) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()==OP_BUY && OrderSymbol()==Symbol() &&
        (OrderMagicNumber()==21 ||
         OrderMagicNumber()==41 ||
         OrderMagicNumber()==61))   {
            if(Bid-OrderOpenPrice()>(FixedPipTSLTrigger*Point) &&
               OrderStopLoss()<Bid-Point*FixedPipTSLPips) {
            fpTSL=Bid-Point*FixedPipTSLPips;}}
      if(OrderType()==OP_SELL && OrderSymbol()==Symbol() &&
        (OrderMagicNumber()==11 ||
         OrderMagicNumber()==31 ||
         OrderMagicNumber()==51))   {
            if(OrderOpenPrice()-Ask>(FixedPipTSLTrigger*Point) &&
               OrderStopLoss()>Ask+Point*FixedPipTSLPips) {
            fpTSL=Ask+Point*FixedPipTSLPips;}}}
return(fpTSL);}


///presets
void  gbpjpy.preset()   {
EnvTimeFrame=60; EnvelopePeriod=144; EnvMaMethod=1; MaShift=0; EnvelopeDeviation=0.6; UseMaElineTSL?=false; 
MaElineTSL=1; BreakEvenTSL?=false; BreakEvenPips=1; FastMaTSL?=true; FastMaPeriod=55; FastMaMethod=0; 
FastMaShift=8; FixedPipTSL?=false; FixedPipTSLPips=0; FixedPipTSLTrigger=0; TimeBegin=0; TimeEnd=1; 
TimeDelete=23; FirstTP=144; SecondTP=233; ThirdTP=377;   }

void  eurusd.preset()   {
EnvTimeFrame=60; EnvelopePeriod=21; EnvMaMethod=1; MaShift=0; EnvelopeDeviation=0.2; Trigger.Deviation=0.2;
UseMaElineTSL?=true; MaElineTSL=2; BreakEvenTSL?=false; BreakEvenPips=1; FastMaTSL?=false; FastMaPeriod=55;
FastMaMethod=0; FastMaShift=0; FixedPipTSL?=false; FixedPipTSLPips=0; FixedPipTSLTrigger=0; TimeBegin=2;
TimeEnd=15; TimeDelete=23; FirstTP=337; SecondTP=337; ThirdTP=337;    }
   
  