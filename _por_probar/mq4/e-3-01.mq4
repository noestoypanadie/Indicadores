//+------------------------------------------------------------------+
//|                                                   Envelope.mq4 |
//|                                                         tageiger |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "tageiger"
#property link      "http://www.metaquotes.net"

//5 min time frame

//---- input parameters
extern int        EnvelopePeriod    =144;//ma length
extern int        EnvTimeFrame      =0; //envelope time frame: 0=chart,60=1hr,240=4hr, etc.
extern int        EnvMaMethod       =1; //0=sma,1=ema,2=smma,3=lwma.
extern double     EnvelopeDeviation =0.4;//envelope width
extern int        MaElineTSL        =0;//0=iMA trailing stoploss  1=Opposite Envelope TSL
extern int        TimeBegin         =0;//server time order placement begins
extern int        TimeEnd          =20;//server time order placement ends
extern int        TimeDelete        =23;//server time unexecuted orders deleted
extern double     FirstTP           =21.0;
extern double     SecondTP          =34.0;
extern double     ThirdTP           =55.0;
extern double     Lots              =0.1;
extern double     MaximumRisk       =0.02;
extern double     DecreaseFactor    =3;

int               b1,b2,b3,s1,s2,s3;
double            TSL               =0;
string            comment           ="Envelope 3.01 ";
string            TradeSymbol;      TradeSymbol=Symbol();

int init()  {  return(0);  }
int deinit(){  return(0);  }
int start()
   {
   int      p=0;p=EnvelopePeriod;
   int      etf=0;etf=EnvTimeFrame;
   int      mam=0;mam=EnvMaMethod;
   double   d=0;d=EnvelopeDeviation;
   double   btp1,btp2,btp3,stp1,stp2,stp3;
   double   bline=0,sline=0,ma=0;
   int      cnt, ticket,total=OrdersTotal();

   ma=iMA(NULL,etf,p,0,mam,PRICE_CLOSE,0);
   bline=iEnvelopes(NULL,etf,p,mam,0,PRICE_CLOSE,d,MODE_UPPER,0);
   sline=iEnvelopes(NULL,etf,p,mam,0,PRICE_CLOSE,d,MODE_LOWER,0);

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
   
   if(b1==0)
      {  
      if(Hour()>TimeBegin && Hour()<TimeEnd)
         {
         if(bline>Close[0] && sline<Close[0])
            {
            btp1=(NormalizeDouble(bline,Digits))+(FirstTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(bline,Digits)),
                              0,
                              (NormalizeDouble(sline,Digits)),
                              btp1,
                              Period()+comment+"btp1",
                              21,
                              0,
                              Aqua);
                              if(ticket>0)
                                 {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {
                                    b1=ticket;
                                    Print(ticket);
                                    }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }         

   if(b2==0)
      {
      if(Hour()>TimeBegin && Hour()<TimeEnd)
         {
         if(bline>Close[0] && sline<Close[0])
            {      
            btp2=(NormalizeDouble(bline,Digits))+(SecondTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(bline,Digits)),
                              0,
                              (NormalizeDouble(sline,Digits)),
                              btp2,
                              Period()+comment+"btp2",
                              41,
                              0,
                              Aqua);
                              if(ticket>0)
                                 {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {
                                    b2=ticket;
                                    Print(ticket);
                                    }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }                              

   if(b3==0)
      {
      if(Hour()>TimeBegin && Hour()<TimeEnd)
         {
         if(bline>Close[0] && sline<Close[0])
            {      
            btp3=(NormalizeDouble(bline,Digits))+(ThirdTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_BUYSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(bline,Digits)),
                              0,
                              (NormalizeDouble(sline,Digits)),
                              btp3,
                              Period()+comment+"btp3",
                              61,
                              0,
                              Aqua);
                              if(ticket>0)
                                 {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {
                                    b3=ticket;
                                    Print(ticket);
                                    }
                                 else Print("Error Opening BuyStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }                     
   
   if(s1==0)
      {
      if(Hour()>TimeBegin && Hour()<TimeEnd)
         {
         if(bline>Close[0] && sline<Close[0])
            {      
            stp1=NormalizeDouble(sline,Digits)-(FirstTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(sline,Digits)),
                              0,
                              (NormalizeDouble(bline,Digits)),
                              stp1,
                              Period()+comment+"stp1",
                              11,
                              0,
                              HotPink);
                              if(ticket>0)
                                 {
                                 if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                                    {
                                    s1=ticket;
                                    Print(ticket);
                                    }
                                 else Print("Error Opening SellStop Order: ",GetLastError());
                                 return(0);
                                 }
            }
         }
      }

   if(s2==0)
      {
      if(Hour()>TimeBegin && Hour()<TimeEnd)
         {
         if(bline>Close[0] && sline<Close[0])
            {      
            stp2=NormalizeDouble(sline,Digits)-(SecondTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(sline,Digits)),
                              0,
                              (NormalizeDouble(bline,Digits)),
                              stp2,
                              Period()+comment+"stp2",
                              31,
                              0,
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
      if(Hour()>TimeBegin && Hour()<TimeEnd)
         {
         if(bline>Close[0] && sline<Close[0])
            {      
            stp3=NormalizeDouble(sline,Digits)-(ThirdTP*Point);
            ticket=OrderSend(Symbol(),
                              OP_SELLSTOP,
                              LotsOptimized(),
                              (NormalizeDouble(sline,Digits)),
                              0,
                              (NormalizeDouble(bline,Digits)),
                              stp3,
                              Period()+comment+"stp3",
                              51,
                              0,
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
   
   for(cnt=0;cnt<total;cnt++)
      {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);            
      if(OrderType()==OP_BUY)
         {
         if(MaElineTSL==0) {TSL=NormalizeDouble(ma,Digits); }
         if(MaElineTSL==1) {TSL=NormalizeDouble(sline,Digits); }
         if(Close[0]>OrderOpenPrice())
            {
            if((/*Close[0]>bline) && (*/TSL>OrderStopLoss()))
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
         if(MaElineTSL==0) {TSL=NormalizeDouble(ma,Digits); }
         if(MaElineTSL==1) {TSL=NormalizeDouble(bline,Digits); }         
         if(Close[0]<OrderOpenPrice())
            {
            if((/*Close[0]<sline) && (*/TSL<OrderStopLoss()))
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
      if(Hour()==TimeDelete && OrderType()==OP_BUYSTOP)
         {
         OrderDelete(OrderTicket());
         if(OrderTicket()==b1) {b1=0; return;}
         if(OrderTicket()==b2) {b2=0; return;}
         if(OrderTicket()==b3) {b3=0; return;}                  
         }
     if(Hour()==TimeDelete && OrderType()==OP_SELLSTOP)
         {
         OrderDelete(OrderTicket());
         if(OrderTicket()==s1) {s1=0; return;}
         if(OrderTicket()==s2) {s2=0; return;}
         if(OrderTicket()==s3) {s3=0; return;}
         }
      OrderSelect(b1,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {b1=0;}
      OrderSelect(b2,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {b2=0;}
      OrderSelect(b3,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {b3=0;}
      OrderSelect(s1,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {s1=0;}
      OrderSelect(s2,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {s2=0;}     
      OrderSelect(s3,SELECT_BY_TICKET);
      if(OrderCloseTime()>0) {s3=0;}
      }
   }

//Functions

double LotsOptimized()  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//---- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//---- calcuulate number of losses orders without a break
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
//---- return lot size
   if(lot<0.1) lot=0.1;
return(lot);
}//end LotsOptimized

int TotalTradesThisSymbol(string TradeSymbol) {
   int i, TradesThisSymbol=0;
   
   for(i=0;i<OrdersTotal();i++)  {
      OrderSelect(i,SELECT_BY_POS);
      if(OrderSymbol()==TradeSymbol &&
         OrderMagicNumber()==11 ||
         OrderMagicNumber()==21 || 
         OrderMagicNumber()==31 || 
         OrderMagicNumber()==41 || 
         OrderMagicNumber()==51 || 
         OrderMagicNumber()==61)   {  TradesThisSymbol++;  }
   }//end for
return(TradesThisSymbol);
}//end TotalTradesThisSymbol