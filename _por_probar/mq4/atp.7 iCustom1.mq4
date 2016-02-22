//+------------------------------------------------------------------+
//|                                 automated trading program 7.mq4  |
//|                              Copyright © 2006, fxid10t@yahoo.com |
//|                               http://www.forexprogramtrading.com |
//| USES iCustom() TO OBTAIN GLS-STARTREND INDICATOR VALUES          | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, fxid10t@yahoo.com"
#property link      "http://www.forexprogramtrading.com"

extern int     Trigger.Period=15;
extern int     Filter.Period.1=60;
extern int     Filter.Period.2=240;
extern bool    Exit.On.Yellow=false;
extern int     Exit.On.Yellow.Period=15;

extern double  tsl.divisor=0.40;
extern int     stoploss.pips=50;
extern bool    Use.ADR.for.SL.pips?=true;

extern bool    Use.Money.Management?=false;//if false, lot=Minimum.Lot
extern double  Minimum.Lot=1;
extern double  MaximumRisk=0.03;
extern int     Lot.Margin=100;
extern int     Magic=1775;
extern string  comment="m ATP.7";
extern string  sep1="----------------";
extern bool    Use.Only.First2.Indicators=false;
extern bool    Use.Trading.Hours.Restriction = false;
extern int     Start.Trading.Hour.Begin = 0;
extern int     Start.Trading.Hour.End   = 24;
extern bool    Use.ADR.Tightening =false;
extern string  sep2="----------------";
extern bool    Use.Juice=true;
extern int     Juice.TimeFrame= 5;
extern int     Juice.Period= 7;
extern int     Juice.Level = 4;
extern string  sep3="----------------";
extern bool    Use.Adx   = false;
extern int     Adx.TimeFrame   = 15;
extern int     Adx.Period   = 14;
extern int     Adx.Threshold   = 20;
extern bool    Use.Plus.Minus.DI   = false;
extern string  sep4="----------------";
extern int     Move.To.BreakEven.at.pips=20;
extern int     Move.To.BreakEven.Lock.pips=1;

int b.ticket, s.ticket, slip;
string DR, DR1;
double avg.rng, rng, sum.rng, x, Year.ADR, ADR.AddOn=1.40;
int Trig_1_Green, Trig_1_MediumSeaGreen, Trig_1_Red, Trig_1_LightCoral, Trig_1_Yellow;
int Trig_2_Green, Trig_2_MediumSeaGreen, Trig_2_Red, Trig_2_LightCoral, Trig_2_Yellow;
int Per1_1_Green, Per1_1_MediumSeaGreen, Per1_1_Red, Per1_1_LightCoral, Per1_1_Yellow;
int Per1_2_Green, Per1_2_MediumSeaGreen, Per1_2_Red, Per1_2_LightCoral, Per1_2_Yellow;
int Per2_1_Green, Per2_1_MediumSeaGreen, Per2_1_Red, Per2_1_LightCoral, Per2_1_Yellow;
int Per2_2_Green, Per2_2_MediumSeaGreen, Per2_2_Red, Per2_2_LightCoral, Per2_2_Yellow;

bool TradingEnabled, LongTradeEnabled, ShortTradeEnabled;
double ADXMain1, PlusDI1, MinusDI1, ADXMain2, PlusDI2, MinusDI2, CurrentJuice;


int init(){HideTestIndicators(true); slip=(Ask-Bid)/Point; return(0);}
int deinit(){return(0);}
int start(){

Mail();
Filter.Values();
Indicator.Values();
PosCounter();
Year.Avg.ADR();

if (Use.ADR.for.SL.pips?) {stoploss.pips=NormalizeDouble(Daily.Range()/Point,Digits);}
x=NormalizeDouble(Daily.Range()*tsl.divisor,Digits);


CheckForOrderClosing();                       // Check if conditions for closing any open order based on exit rules
TradingEnabled=CheckIfConditionsAllowEntry(); // Check if conditions for opening a new trade
                                              // returns 0 if no trading conditions according to filters and indicators
                                              // returns 1 if conditions for Long are met 
                                              // returns 2 if conditions for Short are met
if (TradingEnabled==1)
{  b.ticket=OrderSend(Symbol(),
      OP_BUY,
      LotCalc(),
      NormalizeDouble(Ask,Digits),
      slip,
      NormalizeDouble(Ask-Point*stoploss.pips,Digits),
      0,
      Period()+comment,
      Magic,0,Blue);
      if(b.ticket>0)   
      {  if(OrderSelect(b.ticket,SELECT_BY_TICKET,MODE_TRADES))
         {  Print(b.ticket);   
         }
         else Print("Error Opening Buy Order: ",GetLastError());
         return(0);
      }
}
else if (TradingEnabled==2)
{  s.ticket=OrderSend(Symbol(),
      OP_SELL,
      LotCalc(),
      NormalizeDouble(Bid,Digits),
      slip,
      NormalizeDouble(Bid+Point*stoploss.pips,Digits),
      0,
      Period()+comment,
      Magic,0,Magenta);
      if(s.ticket>0)   
      {  if(OrderSelect(s.ticket,SELECT_BY_TICKET,MODE_TRADES))
         {  Print(s.ticket);
         }
         else Print("Error Opening Sell Order: ",GetLastError());
         return(0);
      }
}
if (Move.To.BreakEven.at.pips!=0) {{MoveToBreakEven();}  // Check if condition are met to move to breakeven
Trail.Stop();                                            // Check if we can trail our stops  
comments();
Mail();
return(0);}
}


//+------------------------------------------------------------------+
void Indicator.Values() {
Trig_1_Green            =iCustom(NULL,Trigger.Period, "GLS-StarTrend", 0, 1); //Green.
Trig_1_MediumSeaGreen   =iCustom(NULL,Trigger.Period, "GLS-StarTrend", 1, 1); //MediumSeaGreen.
Trig_1_Red              =iCustom(NULL,Trigger.Period, "GLS-StarTrend", 2, 1); //Red.
Trig_1_LightCoral       =iCustom(NULL,Trigger.Period, "GLS-StarTrend", 3, 1); //LightCoral.
Trig_1_Yellow           =iCustom(NULL,Trigger.Period, "GLS-StarTrend", 4, 1); //Neutral Yellow.

Trig_2_Green            =iCustom(NULL,Trigger.Period, "GLS-StarTrend", 0, 2); //Green.
Trig_2_MediumSeaGreen   =iCustom(NULL,Trigger.Period, "GLS-StarTrend", 1, 2); //MediumSeaGreen.
Trig_2_Red              =iCustom(NULL,Trigger.Period, "GLS-StarTrend", 2, 2); //Red.
Trig_2_LightCoral       =iCustom(NULL,Trigger.Period, "GLS-StarTrend", 3, 2); //LightCoral.
Trig_2_Yellow           =iCustom(NULL,Trigger.Period, "GLS-StarTrend", 4, 2); //Neutral Yellow.

Per1_1_Green            =iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 0, 1); //Green.
Per1_1_MediumSeaGreen   =iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 1, 1); //MediumSeaGreen.
Per1_1_Red              =iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 2, 1); //Red.
Per1_1_LightCoral       =iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 3, 1); //LightCoral.
Per1_1_Yellow           =iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 4, 1); //Neutral Yellow.

Per1_2_Green            =iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 0, 2); //Green.
Per1_2_MediumSeaGreen   =iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 1, 2); //MediumSeaGreen.
Per1_2_Red              =iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 2, 2); //Red.
Per1_2_LightCoral       =iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 3, 2); //LightCoral.
Per1_2_Yellow           =iCustom(NULL,Filter.Period.1, "GLS-StarTrend", 4, 2); //Neutral Yellow.

Per2_1_Green            =iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 0, 1); //Green.
Per2_1_MediumSeaGreen   =iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 1, 1); //MediumSeaGreen.
Per2_1_Red              =iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 2, 1); //Red.
Per2_1_LightCoral       =iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 3, 1); //LightCoral.
Per2_1_Yellow           =iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 4, 1); //Neutral Yellow.

Per2_2_Green            =iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 0, 2); //Green.
Per2_2_MediumSeaGreen   =iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 1, 2); //MediumSeaGreen.
Per2_2_Red              =iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 2, 2); //Red.
Per2_2_LightCoral       =iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 3, 2); //LightCoral.
Per2_2_Yellow           =iCustom(NULL,Filter.Period.2, "GLS-StarTrend", 4, 2); /*Neutral Yellow.*/ }

void Filter.Values()
{  ADXMain1=iADX(NULL,Adx.TimeFrame,Adx.Period,PRICE_CLOSE,MODE_MAIN,1);
   MinusDI1=iADX(NULL,Adx.TimeFrame,Adx.Period,PRICE_CLOSE,MODE_MINUSDI,1);
   PlusDI1 =iADX(NULL,Adx.TimeFrame,Adx.Period,PRICE_CLOSE,MODE_PLUSDI,1);
   ADXMain2=iADX(NULL,Adx.TimeFrame,Adx.Period,PRICE_CLOSE,MODE_MAIN,2);
   MinusDI2=iADX(NULL,Adx.TimeFrame,Adx.Period,PRICE_CLOSE,MODE_MINUSDI,2);
   PlusDI2 =iADX(NULL,Adx.TimeFrame,Adx.Period,PRICE_CLOSE,MODE_PLUSDI,2);
   CurrentJuice = Juice(1, Juice.Period, Juice.Level,Juice.TimeFrame);
}

double Daily.Range() 
{  if (DR==TimeToStr(CurTime(),TIME_DATE)) 
   {  return(NormalizeDouble(avg.rng,Digits));
   }
   rng=0;sum.rng=0;avg.rng=0;
   for (int i=0;i<iBars(Symbol(),1440);i++) 
   {  rng=(iHigh(Symbol(),PERIOD_D1,i)-iLow(Symbol(),PERIOD_D1,i));
      sum.rng+=rng;
   }
   double db=iBars(Symbol(),1440);
   avg.rng=sum.rng/db;
   DR=TimeToStr(CurTime(),TIME_DATE);
   return (NormalizeDouble(avg.rng,Digits));
}

double Year.Avg.ADR() 
{  if (DR1==TimeToStr(CurTime(),TIME_DATE)) 
   {  return(NormalizeDouble(Year.ADR,Digits));
   }
   Year.ADR=0;
   // Last 6 months ADR: 26 weeks = 26 x 5 trading days = 130 days + 'sunday' bars (they mess things up) ==> approx  150 daily bars
   for (int i=1;i<151;i++) 
   {  Year.ADR=+(iHigh(Symbol(),PERIOD_D1,i)-iLow(Symbol(),PERIOD_D1,i));
   }
   Year.ADR=(Year.ADR*ADR.AddOn)/150;
   DR1=TimeToStr(CurTime(),TIME_DATE);
   return (NormalizeDouble(Year.ADR,Digits));
}

void PosCounter() 
{  b.ticket=0;s.ticket=0;
   for (int cnt=0;cnt<=OrdersTotal();cnt++)   
   {  OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
      {  if (OrderType()==OP_SELL) {s.ticket=OrderTicket();}
         if (OrderType()==OP_BUY)  {b.ticket=OrderTicket();} 
      }
   }
}

double LotCalc() 
{  double lot;
   if (Use.Money.Management?)   
   {  //lot=AccountFreeMargin()*(MaximumRisk/Lot.Margin);
      lot=NormalizeDouble((AccountFreeMargin()*MaximumRisk)/(MarketInfo(Symbol(),MODE_TICKVALUE)*stoploss.pips),2);
   }
   if (!Use.Money.Management?) {lot=Minimum.Lot;}
   return(lot);
}

void comments()   {
if(MarketInfo(Symbol(),MODE_SWAPLONG)>0) string swap="longs.";
else swap="shorts.";
if(MarketInfo(Symbol(),MODE_SWAPLONG)<0 && MarketInfo(Symbol(),MODE_SWAPSHORT)<0) swap="your broker. :(";
Comment("Last Tick: ",TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS),"\n",
           //"Swap favors ",swap,"\n",
           "Average Daily Range: ",Daily.Range(),"\n",
           "Trailing Stop: ",x,"\n",
           "Open Long/Short Ticket #","\'","s: ",b.ticket," ",s.ticket,"  Profit: ",OrderProfit());  }

void Trail.Stop() 
{  PosCounter();
   //--Long TSL calc...
   //x=minimum wave range
   if(b.ticket>0) 
   {  double bsl=NormalizeDouble(x,Digits);double b.tsl=0;
      OrderSelect(b.ticket,SELECT_BY_TICKET);
      //if stoploss is less than minimum wave range, set bsl to current SL
      if(OrderStopLoss()<OrderOpenPrice() && OrderOpenPrice()-OrderStopLoss()<x) 
      {  bsl=OrderOpenPrice()-OrderStopLoss();
      }
      //if stoploss is equal to, or greater than minimum wave range, set bsl to minimum wave range
      if(OrderStopLoss()<OrderOpenPrice() && OrderOpenPrice()-OrderStopLoss()>=x) 
      {  bsl=NormalizeDouble(x,Digits);
      }
      //determine if stoploss should be modified
      if(Bid>(OrderOpenPrice()+bsl) && OrderStopLoss()<(OrderOpenPrice()+(Bid-(OrderOpenPrice()+bsl))))   
      {  b.tsl=NormalizeDouble(OrderOpenPrice()+(Bid-(OrderOpenPrice()+bsl)),Digits);
         Print("b.tsl ",b.tsl);
         if(OrderStopLoss()<b.tsl)  
         {  OrderModify(b.ticket,OrderOpenPrice(),b.tsl,OrderTakeProfit(),OrderExpiration(),MediumSpringGreen);
         }
      }
   }
   //--Short TSL calc...
   if(s.ticket>0) 
   {  double ssl=NormalizeDouble(x,Digits);double s.tsl=0;
      OrderSelect(s.ticket,SELECT_BY_TICKET);
      //if stoploss is less than minimum wave range, set ssl to current SL
      if(OrderStopLoss()>OrderOpenPrice() && OrderStopLoss()-OrderOpenPrice()<x) 
      {  ssl=OrderStopLoss()-OrderOpenPrice();
      }
      //if stoploss is equal to, or greater than minimum wave range, set bsl to minimum wave range
      if(OrderStopLoss()>OrderOpenPrice() && OrderStopLoss()-OrderOpenPrice()>=x)   
      {  ssl=NormalizeDouble(x,Digits);
      }
      //determine if stoploss should be modified
      if(Ask<(OrderOpenPrice()-ssl) && OrderStopLoss()>(OrderOpenPrice()-(OrderOpenPrice()-ssl)-Ask))   
      {  s.tsl=NormalizeDouble(OrderOpenPrice()-((OrderOpenPrice()-ssl)-Ask),Digits);
         Print("s.tsl ",s.tsl);
         if(OrderStopLoss()>s.tsl)  
         {  OrderModify(s.ticket,OrderOpenPrice(),s.tsl,OrderTakeProfit(),OrderExpiration(),MediumVioletRed);
         }
      }
    }   
}//end Trail.Stop

void Mail() 
{  OrderSelect(b.ticket,SELECT_BY_TICKET);
   if(OrderCloseTime()>0)  
   {  SendMail(Symbol()+" "+OrderComment(),"Buy Order Closed, $"+DoubleToStr(OrderProfit(),2)+" "+DoubleToStr(Bid,Digits)+"/"+DoubleToStr(Ask,Digits));
   }
   OrderSelect(s.ticket,SELECT_BY_TICKET);
   if(OrderCloseTime()>0)  
   {  SendMail(Symbol()+" "+OrderComment(),"Sell Order Closed, $"+DoubleToStr(OrderProfit(),2)+" "+DoubleToStr(Bid,Digits)+"/"+DoubleToStr(Ask,Digits));
   }
}

void MoveToBreakEven()
{  PosCounter();
   if (b.ticket > 0)
   {  OrderSelect(b.ticket,SELECT_BY_TICKET);
      if (OrderStopLoss()<OrderOpenPrice())
      {  if (Bid >((Move.To.BreakEven.at.pips*Point) +OrderOpenPrice()))
         {  OrderModify(b.ticket, OrderOpenPrice(), (OrderOpenPrice()+(Move.To.BreakEven.Lock.pips*Point)),OrderTakeProfit(),OrderExpiration(),MediumSpringGreen);
            if (OrderSelect(b.ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("Long StopLoss Moved to BE at : ",OrderStopLoss());
            else Print("Error moving Long StopLoss to BE: ",GetLastError());
         }
      }
   }
   if (s.ticket > 0)
   {  OrderSelect(s.ticket,SELECT_BY_TICKET);
      if (OrderStopLoss()>OrderOpenPrice())
      {  if ( Ask < (OrderOpenPrice()-(Move.To.BreakEven.at.pips*Point)))
         {  OrderModify(OrderTicket(), OrderOpenPrice(), (OrderOpenPrice()-(Move.To.BreakEven.Lock.pips*Point)),OrderTakeProfit(),OrderExpiration(),MediumVioletRed);
            if(OrderSelect(s.ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("Short StopLoss Moved to BE at : ",OrderStopLoss());
            else Print("Error moving Short StopLoss to BE: ",GetLastError());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Juice (std deviation limit) indicator                            |
//| by Shimodax, based on  "Juice.mq4 by Perky"                      |
//| original link "http://fxovereasy.atspace.com/index"              |
//| Modified by MrPip to only calculate current value                |
//+------------------------------------------------------------------+
double Juice(int shift, int period, int level, int jtimeframe)
{  double osma= 0;
   osma= iStdDev(NULL,jtimeframe, period, MODE_EMA, 0, PRICE_CLOSE,shift) - level*Point;
   return (osma);
}

int CheckIfConditionsAllowEntry() // 0=no entry 1=ok for long 2=ok for short
{  bool StarTrendIsOK;
   bool AdxIsOK;
   PosCounter(); // Check if current orders running.
   //General Conditions / Filtering
        if (!(b.ticket==0 && s.ticket==0))                                                                        return (0); // if a position is open, skip checking
   else if (Use.Trading.Hours.Restriction && (Hour()<Start.Trading.Hour.Begin || Hour()>Start.Trading.Hour.End))  return (0); // Check Time Filter
   else if (Use.Juice && CurrentJuice<=0)                                                                         return (0); // check Juice
   else if (Use.Adx && (!(ADXMain1>=ADXMain2 && ADXMain1>=Adx.Threshold)))                                        return (0); // Check Adx rising and above threshold
   
   // Conditions for Long
   StarTrendIsOK=false;
   AdxIsOK=false;  
   // Check Star Trend
   if (!Use.Only.First2.Indicators && 
         (  (  // If 5 turns from (red or light coral or yellow) to (green or mediumseagreen) 
               // and 15 and 60 are (green or mediumseagreen)
             (Trig_1_Green==1 || Trig_1_MediumSeaGreen==1) && (Trig_2_Red==1   || Trig_2_LightCoral==1 || Trig_2_Yellow==1) && 
             (Per1_1_Green==1 || Per1_1_MediumSeaGreen==1) && (Per2_1_Green==1 || Per2_1_MediumSeaGreen==1)
            )     
            || // OR
            (  // If 15 turns from (red or light coral or yellow) to (green or mediumseagreen) 
               // and 5 and 60 are (green or mediumseagreen)          
             (Per1_1_Green==1 || Per1_1_MediumSeaGreen==1) && (Per1_2_Red==1   || Per1_2_LightCoral==1 || Per1_2_Yellow==1) && 
             (Trig_1_Green==1 || Trig_1_MediumSeaGreen==1) && (Per2_1_Green==1 || Per2_1_MediumSeaGreen==1)
            ) 
            || // OR 
            (  // If 60 turns from (red or light coral or yellow) to (green or mediumseagreen) 
               // and 5 and 15 are (green or mediumseagreen)          
             (Per2_1_Green==1 || Per2_1_MediumSeaGreen==1) && (Per2_2_Red==1   || Per2_2_LightCoral==1 || Per2_2_Yellow==1) && 
             (Trig_1_Green==1 || Trig_1_MediumSeaGreen==1) && (Per1_1_Green==1 || Per1_1_MediumSeaGreen==1)
            )
         )
       ) {StarTrendIsOK=True;}
   else 
   if (Use.Only.First2.Indicators && 
         (  (  // If 5 turns from (red or light coral or yellow) to (green or mediumseagreen) 
               // and 15 is (green or mediumseagreen)
             (Trig_1_Green==1 || Trig_1_MediumSeaGreen==1) && (Trig_2_Red==1   || Trig_2_LightCoral==1 || Trig_2_Yellow==1) && 
             (Per1_1_Green==1 || Per1_1_MediumSeaGreen==1) 
            )     
            || // OR
            (  // If 15 turns from (red or light coral or yellow) to (green or mediumseagreen) 
               // and 5 is (green or mediumseagreen)          
             (Per1_1_Green==1 || Per1_1_MediumSeaGreen==1) && (Per1_2_Red==1   || Per1_2_LightCoral==1 || Per1_2_Yellow==1) && 
             (Trig_1_Green==1 || Trig_1_MediumSeaGreen==1)
            ) 
         )
      ) {StarTrendIsOK=True;}   

   // Check ADX
   if (!Use.Plus.Minus.DI || (Use.Plus.Minus.DI && PlusDI1>=MinusDI1 && PlusDI1>=PlusDI2)) {AdxIsOK=true;}
   // Check All Filters   
   if (StarTrendIsOK && AdxIsOK) return(1);   
         
   
   // Conditions for Short
   StarTrendIsOK=false;
   AdxIsOK=false;  
   // Check Star Trend
   if (!Use.Only.First2.Indicators && 
         (  (  // If 5 turns from (green or mediumseagreen or yellow) to (red or lightcoral) 
               // and 15 and 60 are (red or lightcoral)
             (Trig_1_Red==1 || Trig_1_LightCoral==1) && (Trig_2_Green==1 || Trig_2_MediumSeaGreen==1 || Trig_2_Yellow==1) && 
             (Per1_1_Red==1 || Per1_1_LightCoral==1) && (Per2_1_Red  ==1 || Per2_1_LightCoral==1)
            )     
            || // OR
            (  // If 15 turns from (green or mediumseagreen or yellow) to (red or lightcoral) 
               // and 5 and 60 are (red or lightcoral)          
             (Per1_1_Red==1 || Per1_1_LightCoral==1) && (Per1_2_Green==1 || Per1_2_MediumSeaGreen==1 || Per1_2_Yellow==1) && 
             (Trig_1_Red==1 || Trig_1_LightCoral==1) && (Per2_1_Red  ==1 || Per2_1_LightCoral==1)
            ) 
            || // OR 
            (  // If 60 turns from (green or mediumseagreen or yellow) to (red or lightcoral) 
               // and 5 and 15 are (red or lightcoral)          
             (Per2_1_Red==1 || Per2_1_LightCoral==1) && (Per2_2_Green==1 || Per2_2_MediumSeaGreen==1 || Per2_2_Yellow==1) && 
             (Trig_1_Red==1 || Trig_1_LightCoral==1) && (Per1_1_Red  ==1 || Per1_1_LightCoral==1)
            )
         )
       ) {StarTrendIsOK=True;}
   else 
   if (Use.Only.First2.Indicators && 
         (  (  // If 5 turns from (green or mediumseagreen or yellow) to (red or lightcoral) 
               // and 15 is (red or lightcoral)
             (Trig_1_Red==1 || Trig_1_LightCoral==1) && (Trig_2_Green==1 || Trig_2_MediumSeaGreen==1 || Trig_2_Yellow==1) && 
             (Per1_1_Red==1 || Per1_1_LightCoral==1) 
            )     
            || // OR
            (  // If 15 turns from (green or mediumseagreen or yellow) to (red or lightcoral) 
               // and 5 is (red or lightcoral)          
             (Per1_1_Red==1 || Per1_1_LightCoral==1) && (Per1_2_Green==1 || Per1_2_MediumSeaGreen==1 || Per1_2_Yellow==1) && 
             (Trig_1_Red==1 || Trig_1_LightCoral==1) 
            ) 
         )
      ) {StarTrendIsOK=True;}   
   
   // Check ADX
   if ((!Use.Plus.Minus.DI) || (Use.Plus.Minus.DI && MinusDI1>=PlusDI1 && MinusDI1>=MinusDI2)) {AdxIsOK=true;}
   // Check All Filters   
   if (StarTrendIsOK && AdxIsOK) return(2);   
   return(0);
}

void CheckForOrderClosing()
{  bool iShouldExit=false;
   PosCounter(); // Check if current orders running.
   iShouldExit=false;
   // Conditions for closing Longs
   if (b.ticket>0)
   {  if (!Exit.On.Yellow) // Yellow is ignored
      {  // if we have a change of colour in any time frame from (green or mediumseagreen) to (red or lightcoral) exit longs
         if (Trig_1_Red==1 || Trig_1_LightCoral==1 || Per1_1_Red==1 || Per1_1_LightCoral==1 || Per2_1_Red==1 || Per2_1_LightCoral==1) 
         {iShouldExit=true;}
      }
      else
      {  if (Exit.On.Yellow.Period==Trigger.Period && 
               (Trig_1_Red==1 || Trig_1_LightCoral==1 || Trig_1_Yellow==1 ||
                Per1_1_Red==1 || Per1_1_LightCoral==1 || Per1_1_Yellow==1 ||
                Per2_1_Red==1 || Per2_1_LightCoral==1 || Per2_1_Yellow==1
               )
            ) {iShouldExit=true;} 
         if (Exit.On.Yellow.Period==Filter.Period.1 && 
               (Trig_1_Red==1 || Trig_1_LightCoral==1                     ||
                Per1_1_Red==1 || Per1_1_LightCoral==1 || Per1_1_Yellow==1 ||
                Per2_1_Red==1 || Per2_1_LightCoral==1 || Per2_1_Yellow==1
               )
            ) {iShouldExit=true;} 
         if (Exit.On.Yellow.Period==Filter.Period.2 && 
               (Trig_1_Red==1 || Trig_1_LightCoral==1                     ||
                Per1_1_Red==1 || Per1_1_LightCoral==1                     ||
                Per2_1_Red==1 || Per2_1_LightCoral==1 || Per2_1_Yellow==1
               )
            ) {iShouldExit=true;} 
      }      
      if (iShouldExit) 
      {  OrderSelect(b.ticket,SELECT_BY_TICKET);
         OrderClose(OrderTicket(),OrderLots(),Bid,slip,Aqua);
      }
   }

   if (s.ticket>0)
   {  if (!Exit.On.Yellow) // Yellow is ignored
      {  // if we have a change of colour in any time frame from (red or lightcoral) to (green or mediumseagreen) exit shorts
         if (Trig_1_Green==1 || Trig_1_MediumSeaGreen==1 || Per1_1_Green==1 || Per1_1_MediumSeaGreen==1 || Per2_1_Green==1 || Per2_1_MediumSeaGreen==1)
            {iShouldExit=true;}
      }
      else
      {  if (Exit.On.Yellow.Period==Trigger.Period && 
               (Trig_1_Green==1 || Trig_1_MediumSeaGreen==1 || Trig_1_Yellow==1 ||
                Per1_1_Green==1 || Per1_1_MediumSeaGreen==1 || Per1_1_Yellow==1 ||
                Per2_1_Green==1 || Per2_1_MediumSeaGreen==1 || Per2_1_Yellow==1
               )
            ) {iShouldExit=true;} 
         if (Exit.On.Yellow.Period==Filter.Period.1 && 
               (Trig_1_Green==1 || Trig_1_MediumSeaGreen==1                     ||
                Per1_1_Green==1 || Per1_1_MediumSeaGreen==1 || Per1_1_Yellow==1 ||
                Per2_1_Green==1 || Per2_1_MediumSeaGreen==1 || Per2_1_Yellow==1
               )
            ) {iShouldExit=true;} 
         if (Exit.On.Yellow.Period==Filter.Period.2 && 
               (Trig_1_Green==1 || Trig_1_MediumSeaGreen==1                     ||
                Per1_1_Green==1 || Per1_1_MediumSeaGreen==1                     ||
                Per2_1_Green==1 || Per2_1_MediumSeaGreen==1 || Per2_1_Yellow==1
               )
            ) {iShouldExit=true;} 
      }      
      if (iShouldExit) 
      {  OrderSelect(s.ticket,SELECT_BY_TICKET);
         OrderClose(OrderTicket(),OrderLots(),Ask,slip,Magenta);
      }
   }
}
         