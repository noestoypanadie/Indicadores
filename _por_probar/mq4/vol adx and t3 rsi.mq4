//+------------------------------------------------------------------+
//|                                           vol adx and t3 rsi.mq4 |
//|                 Copyright © 2005, tageiger aka fxid10t@yahoo.com |
//|                MetaTrader_Experts_and_Indicators@yahoogroups.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, tageiger aka fxid10t@yahoo.com"
#property link      "MetaTrader_Experts_and_Indicators@yahoogroups.com"

extern int        ChartPeriod       =60;
//extern int        TimeBegin         =8;//
//extern int        TimeEnd           =16;//
extern int        ADXPeriod         =14;
extern int        ADXShift          =1;
extern int        ADXTrigger        =20;
extern int        T3_Period         =8;
extern double     T3_Curvature      =0.618;
extern int        CatastrophicSL    =500;
extern int        WishfulTP         =200;
extern int        TSLPeriod         =15;
extern int        TSLBarsBack       =13;
extern int        TSLBarShift       =0;
extern int        slippage          =0;   
extern double     Lots              =0.1;
extern double     MaximumRisk       =0.02;
extern double     DecreaseFactor    =3;
extern int        MagicNumber       =357;

double            Spread;           Spread=Ask-Bid;
string            comment;          comment="m vol adx & t3.rsi v.1";
string            TradeSymbol;      TradeSymbol=Symbol();
double            t3,rsi;
double            e1,e2,e3,e4,e5,e6;
double            c1,c2,c3,c4;
double            n,w1,w2,b2,b3;
int               cnt,ticket;

int init(){
   if(Period()!=ChartPeriod) {Alert("Period() does not equal Chart Period!"); return(0);}
   e1=0; e2=0; e3=0; e4=0; e5=0; e6=0;
   c1=0; c2=0; c3=0; c4=0;
   n=0;
   w1=0; w2=0;
   b2=0; b3=0;

   b2=T3_Curvature*T3_Curvature;
   b3=b2*T3_Curvature;
   c1=-b3;
   c2=(3*(b2+b3));
   c3=-3*(2*b2+T3_Curvature+b3);
   c4=(1+3*T3_Curvature+b3+3*b2);
   n=T3_Period;

   if (n<1) n=1;
   n = 1 + 0.5*(n-1);
   w1 = 2 / (n + 1);
   w2 = 1 - w1;
return(0);}
int deinit(){return(0);}
int start(){
   if(TotalTradesThisSymbol(TradeSymbol)==0)  {
      if(T3.RSI()=="Long" &&
      ADXTrend()=="Long" &&
      VolumeTrend()=="Long" /*&&
      Hour()>=TimeBegin && Hour()<TimeEnd*/)  {
         ticket=OrderSend(Symbol(),
                          OP_BUY,
                          LotsOptimized(),
                          Ask,
                          slippage,
                          Bid-(CatastrophicSL*Point),
                          Ask+(WishfulTP*Point),
                          Period()+comment,
                          MagicNumber,
                          0,//datetime expiration
                          MediumSpringGreen);
                          if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))  {Print(ticket);}
                                 else Print("Error Opening Buy Order: ",GetLastError());
                                 return(0);  }  }
      if(T3.RSI()=="Short" &&
      ADXTrend()=="Short" &&
      VolumeTrend()=="Short" /*&&
      Hour()>=TimeBegin && Hour()<TimeEnd*/) {
         ticket=OrderSend(Symbol(),
                          OP_SELL,
                          LotsOptimized(),
                          Bid,
                          slippage,
                          Ask+(CatastrophicSL*Point),
                          Bid-(WishfulTP*Point),
                          Period()+comment,
                          MagicNumber,
                          0,//datetime expiration
                          Crimson);
                          if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))  {Print(ticket);}
                                 else Print("Error Opening Sell Order: ",GetLastError());
                                 return(0);  }  }  }

   for(cnt=0;cnt<OrdersTotal();cnt++) {
   OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderMagicNumber()==MagicNumber &&  OrderSymbol()==Symbol())   {
         if(OrderType()==OP_BUY)    {
            if(T3.RSI()!="Long" &&
            ADXTrend()!="Long" &&
            VolumeTrend()!="Long" /*||
            Minute()==59*/)  {
               OrderClose(OrderTicket(),
                          OrderLots(),
                          Bid,
                          slippage,
                          MediumVioletRed);  }
            if(Bid>OrderOpenPrice() && btsl()>OrderOpenPrice() && btsl()>OrderStopLoss()) {
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           btsl(),
                           OrderTakeProfit(),
                           0,
                           LightSeaGreen);   }  }
         if(OrderType()==OP_SELL)   {
            if(T3.RSI()!="Short" &&
            ADXTrend()!="Short" &&
            VolumeTrend()!="Short" /*||
            Minute()==59*/)  {
               OrderClose(OrderTicket(),
                          OrderLots(),
                          Ask,
                          slippage,
                          MediumTurquoise);  }
            if(Ask<OrderOpenPrice() && stsl()<OrderOpenPrice() && stsl()<OrderStopLoss()) {
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           stsl(),
                           OrderTakeProfit(),
                           0,
                           FireBrick); }  }  }  }
if(!IsTesting()){PrintComments();}
return(0);
}

//Functions

double btsl()  { return (MathMax((Low[Lowest(Symbol(),TSLPeriod,MODE_LOW,TSLBarsBack,TSLBarShift)]-Spread),
                                 iSAR(Symbol(),Period(),0.02,0.2,0))); }

double stsl()  { return (MathMin((High[Highest(Symbol(),TSLPeriod,MODE_HIGH,TSLBarsBack,TSLBarShift)]+Spread),
                                 iSAR(Symbol(),Period(),0.02,0.2,0))); }

void PrintComments() {  Comment("Current Time:",TimeToStr(CurTime(),TIME_MINUTES),"\n",
                                "VolumeTrend:",VolumeTrend(),"\n",
                                "ADXTrend:",ADXTrend(),"\n",
                                "T3.RSI:",T3.RSI(),"\n",
                                "BTSL:",btsl(),"\n",
                                "STSL:",stsl(),"\n");  }

string T3.RSI(){
   int limit=Bars; string t3rsi;
   for(int i=limit; i>=0; i--)   {
      rsi/*Array[i]*/ = iRSI(Symbol(),0,T3_Period,PRICE_CLOSE,i);
      e1 = w1*rsi/*Array[i]*/ + w2*e1;
      e2 = w1*e1 + w2*e2;
      e3 = w1*e2 + w2*e3;
      e4 = w1*e3 + w2*e4;
      e5 = w1*e4 + w2*e5;
      e6 = w1*e5 + w2*e6;
      t3/*Array[i]*/=c1*e6 + c2*e5 + c3*e4 + c4*e3; }
   //Print("RSI:",rsi," T3:",t3);
   if(rsi>t3) t3rsi="Long";
   if(rsi<t3) t3rsi="Short";
   if(rsi==t3) t3rsi="Flat";
return(t3rsi);
}//end T3.RSI

string ADXTrend(){
   double plus,minus;string adxtrend="Flat";
   plus=iADX(Symbol(),ChartPeriod,ADXPeriod,PRICE_CLOSE,MODE_PLUSDI,ADXShift);
   minus=iADX(Symbol(),ChartPeriod,ADXPeriod,PRICE_CLOSE,MODE_MINUSDI,ADXShift);
   if(plus>minus && plus>ADXTrigger)  {adxtrend="Long";}
   if(minus>plus && minus>ADXTrigger) {adxtrend="Short";}
   //Print("PlusDI:",plus," MinusDI:",minus," adxtrend:",adxtrend);
return(adxtrend);
}//end ADXTrend

string VolumeTrend(){
   int vol.1=Volume[1],vol.2=Volume[2];string voltrend="Flat";
   if(vol.1<vol.2) voltrend="Long";
   if(vol.1>vol.2) voltrend="Short";
   if(vol.1==vol.2) voltrend="Flat";
return(voltrend);
}//end void VolumeTrend

double LotsOptimized()  {
   double lot=Lots;
   int    orders=HistoryTotal();
   int    losses=0;
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
   if(DecreaseFactor>0) {
      for(int i=orders-1;i>=0;i--)  {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++; }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);   }
   if(lot<0.1) lot=0.1;
return(lot);   }//end LotsOptimized

int TotalTradesThisSymbol(string TradeSymbol) {
   int i, TradesThisSymbol=0;
   for(i=0;i<OrdersTotal();i++)  {
      OrderSelect(i,SELECT_BY_POS);
      if(OrderSymbol()==TradeSymbol &&
         OrderMagicNumber()==MagicNumber )   {  TradesThisSymbol++;  }   }
return(TradesThisSymbol);  }//end TotalTradesThisSymbol