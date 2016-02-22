//+------------------------------------------------------------------+
//|                                                 Envelope 3.0 mq4 |
//|                                   tageiger aka fxid10t@yahoo.com |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "tageiger aka fxid10t@yahoo.com"
#property link      "http://www.metaquotes.net"

//Global User Variables
extern int        EnvelopePeriod    =144;
extern int        EnvTimeFrame      =0; //envelope time frame: 0=chart,60=1hr,240=4hr, etc.
extern int        EnvMaMethod       =1; //0=sma,1=ema,2=smma,3=lwma.
extern double     EnvelopeDeviation =1;
extern int        MaElineTSL        =0;//0=iMA trailing stoploss  1=Opposite Envelope TSL
extern int        TimeOpen          =0;
extern int        TimeClose         =20;
extern double     FirstTP           =144.0;
extern double     SecondTP          =233.0;
extern double     ThirdTP           =377.0;
extern double     Lots              =0.1;
extern double     MaximumRisk       =0.02;
extern double     DecreaseFactor    =3;

//Global Internal Variables
double            TSL               =0;
string            comment           ="e 3.0";
int               p;                p=EnvelopePeriod;
int               etf;              etf=EnvTimeFrame;
int               mam;              mam=EnvMaMethod;
double            d;                d=EnvelopeDeviation;
double            SPoint;           SPoint      =MarketInfo(Symbol(), MODE_POINT);
double            Spread;           Spread      =Ask-Bid;
double            SDigits;          SDigits     =MarketInfo(Symbol(), MODE_DIGITS);
string            TradeSymbol;      TradeSymbol =Symbol();
int               b1,b2,b3,s1,s2,s3,cnt, ticket, total;
double            btp1,btp2,btp3,stp1,stp2,stp3,bline,sline,ma;
static int        loss,win;

int init()  {  if(Period()!=5)   {Alert("Default EnvelopeDeviation & TPs set for 5min charts"); return(0);  }  }
int deinit(){  return(0);  }
int start() {

   int    orders=HistoryTotal();     // history orders total

   for(int i=orders-1;i>=0;i--)
      {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
      if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         if(OrderProfit()>0) win++;
         if(OrderProfit()<0) loss++;
      }
   if(loss>0 && win>0)  {  if(win>loss)   d=NormalizeDouble((loss/win),2);
                           if(loss>win)   d=NormalizeDouble((win/loss),2); }
   //Print("D:",D," loss:",loss," win:",win);
   if(d<0.1) d=0.1;

   ma=iMA(NULL,etf,p,0,mam,PRICE_CLOSE,0);
   bline=iEnvelopes(NULL,etf,p,mam,0,PRICE_CLOSE,d,MODE_UPPER,0);
   sline=iEnvelopes(NULL,etf,p,mam,0,PRICE_CLOSE,d,MODE_LOWER,0);

   total=OrdersTotal();
   if(TotalTradesThisSymbol(TradeSymbol)==0) {b1=0;b2=0;b3=0;s1=0;s2=0;s3=0;}
   if(TotalTradesThisSymbol(TradeSymbol)>0)  {
      for(cnt=0;cnt<total;cnt++) {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==TradeSymbol) {
         if(OrderMagicNumber()==2)  {b1=OrderTicket(); }
         if(OrderMagicNumber()==4)  {b2=OrderTicket(); }
         if(OrderMagicNumber()==6)  {b3=OrderTicket(); }
         if(OrderMagicNumber()==1)  {s1=OrderTicket(); }
         if(OrderMagicNumber()==3)  {s2=OrderTicket(); }
         if(OrderMagicNumber()==5)  {s3=OrderTicket(); } }  }  }

   if(b1==0)   {  
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(bline>Close[0] && sline<Close[0])   {
            btp1=(NormalizeDouble(bline,SDigits))+(FirstTP*SPoint);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(bline,SDigits)),
                              0,
                              (NormalizeDouble(sline,SDigits)),
                              btp1,
                              "buystop TP1"+comment,
                              2,
                              TimeClose,
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  b1=ticket;  Print(ticket);   }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }         

   if(b2==0)   {
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(bline>Close[0] && sline<Close[0])   {      
            btp2=(NormalizeDouble(bline,SDigits))+(SecondTP*SPoint);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(bline,SDigits)),
                              0,
                              (NormalizeDouble(sline,SDigits)),
                              btp2,
                              "buystop TP2"+comment,
                              4,
                              TimeClose,
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  b2=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }                              

   if(b3==0)   {
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(bline>Close[0] && sline<Close[0])   {      
            btp3=(NormalizeDouble(bline,SDigits))+(ThirdTP*SPoint);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(bline,SDigits)),
                              0,
                              (NormalizeDouble(sline,SDigits)),
                              btp3,
                              "buystop TP3"+comment,
                              6,
                              TimeClose,
                              Aqua);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  b3=ticket;  Print(ticket); }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }                     
   
   if(s1==0)   {
      if(Hour()>TimeOpen && Hour()<TimeClose)   {
         if(bline>Close[0] && sline<Close[0])   {      
            stp1=NormalizeDouble(sline,SDigits)-(FirstTP*SPoint);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(sline,SDigits)),
                              0,
                              (NormalizeDouble(bline,SDigits)),
                              stp1,
                              "sellstop TP1"+comment,
                              1,
                              TimeClose,
                              HotPink);
                              if(ticket>0)   {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {  s1=ticket;  Print(ticket); }
                                 else Print("Error Opening SellStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }

   if(s2==0)
      {
      if(Hour()>TimeOpen && Hour()<TimeClose)
         {
         if(bline>Close[0] && sline<Close[0])
            {      
            stp2=NormalizeDouble(sline,SDigits)-(SecondTP*SPoint);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(sline,SDigits)),
                              0,
                              (NormalizeDouble(bline,SDigits)),
                              stp2,
                              "sellstop TP2"+comment,
                              3,
                              TimeClose,
                              HotPink);
                              if(ticket>0)
                                 {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {
                                    s2=ticket;
                                    Print(ticket);
                                    }
                                 else Print("Error Opening SellStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }                     
   
   if(s3==0)
      {
      if(Hour()>TimeOpen && Hour()<TimeClose)
         {
         if(bline>Close[0] && sline<Close[0])
            {      
            stp3=NormalizeDouble(sline,SDigits)-(ThirdTP*SPoint);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(sline,SDigits)),
                              0,
                              (NormalizeDouble(bline,SDigits)),
                              stp3,
                              "sellstop TP3"+comment,
                              5,
                              TimeClose,
                              HotPink);
                              if(ticket>0)
                                 {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {
                                    s3=ticket;
                                    Print(ticket);
                                    }
                                 else Print("Error Opening SellStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }
   if(TotalTradesThisSymbol(TradeSymbol)>0)  {
      for(cnt=0;cnt<total;cnt++)
         {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);            
         if(OrderSymbol()==TradeSymbol)   {
            if(OrderType()==OP_BUY)
               {
               if(MaElineTSL==0) {TSL=NormalizeDouble(ma,SDigits); }
               if(MaElineTSL==1) {TSL=NormalizeDouble(sline,SDigits); }
               if(Close[0]>OrderOpenPrice())
                  {
                  if((Close[0]>ma) && (TSL>OrderStopLoss()))
                     {
                     double bsl;bsl=TSL;
                     OrderModify(OrderTicket(),
                                 OrderOpenPrice(),
                                 bsl,
                                 OrderTakeProfit(),
                                 0,//Order expiration server date/time
                                 Green);
                     }
                  }
               }
            if(OrderType()==OP_SELL)
               {
               if(MaElineTSL==0) {TSL=NormalizeDouble(ma,SDigits); }
               if(MaElineTSL==1) {TSL=NormalizeDouble(bline,SDigits); }         
               if(Close[0]<OrderOpenPrice())
                  {
                  if((Close[0]<ma) && (TSL<OrderStopLoss()))
                     {
                     double ssl;ssl=TSL;
                     OrderModify(OrderTicket(),
                                 OrderOpenPrice(),
                                 ssl,
                                 OrderTakeProfit(),
                                 0,//Order expiration server date/time
                                 Red);
                     }
                  }
               }      
            if(Hour()==TimeClose && OrderType()==OP_BUYSTOP)
               {
               OrderDelete(OrderTicket());
               if(OrderTicket()==b1) {b1=0; return;}
               if(OrderTicket()==b2) {b2=0; return;}
               if(OrderTicket()==b3) {b3=0; return;}                  
               }
            if(Hour()==TimeClose && OrderType()==OP_SELLSTOP)
               {
               OrderDelete(OrderTicket());
               if(OrderTicket()==s1) {s1=0; return;}
               if(OrderTicket()==s2) {s2=0; return;}
               if(OrderTicket()==s3) {s3=0; return;}
               }
            OrderSelect(b1,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {b1=0;}
            OrderSelect(b2,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {b2=0;}
            OrderSelect(b3,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {b3=0;}
            OrderSelect(s1,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {s1=0;}
            OrderSelect(s2,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {s2=0;}     
            OrderSelect(s3,SELECT_BY_TICKET);   if(OrderCloseTime()>0) {s3=0;}
            }
         }
      }
   return(0);
   }
//Functions

double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//---- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//---- calculate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         //----
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
   if(lot<0.1) lot=0.1;
return(lot);
}//end LotsOptimized

int TotalTradesThisSymbol(string TradeSymbol) {
   int i, TradesThisSymbol=0;
   
   for(i=0;i<OrdersTotal();i++)  {
      OrderSelect(i,SELECT_BY_POS);
      if(OrderSymbol()==TradeSymbol &&
         OrderMagicNumber()==1 ||
         OrderMagicNumber()==2 || 
         OrderMagicNumber()==3 || 
         OrderMagicNumber()==4 || 
         OrderMagicNumber()==5 || 
         OrderMagicNumber()==6)  {  TradesThisSymbol++;  }
   }//end for
return(TradesThisSymbol);
}//end TotalTradesThisSymbol

