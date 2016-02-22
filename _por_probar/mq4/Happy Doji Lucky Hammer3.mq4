//+------------------------------------------------------------------+
//|                                      Happy Doji Lucky Hammer.mq4 |
//|                 Copyright © 2005, tageiger aka fxid10t@yahoo.com |
//|                MetaTrader_Experts_and_Indicators@yahoogroups.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, tageiger aka fxid10t@yahoo.com"
#property link      "MetaTrader_Experts_and_Indicators@yahoogroups.com"
//global user variables

extern int        TakeProfit        =50;
extern int        StopLoss          =25;
extern int        BarsTP            =34;
extern int        BarsSL            =13;
extern int        BarsTSL           =6;
extern int        TrailingPeriod    =PERIOD_M15;
extern int        BarShift          =0;
extern int        DeleteMinutes     =60;
extern int        slippage          =0;
extern double     Lots              =0.1;
extern double     MaximumRisk       =0.02;
extern double     DecreaseFactor    =3;

//global internal variables

double            SPoint;           SPoint      =MarketInfo(Symbol(), MODE_POINT);
double            Spread;           Spread      =Ask-Bid;
double            SDigits;          SDigits     =MarketInfo(Symbol(), MODE_DIGITS);
string            comment;          comment     ="HDLH v.016";
string            TradeSymbol;      TradeSymbol =Symbol();
int               cnt,total,ticket;
int               djb,djs,tst,dft,ttt,tbt,sst,hbt,dcc,ppt;

int init()  {  return(0);  }
int deinit(){  return(0);  }
int start() {
   
   total=OrdersTotal();
   if(TotalTradesThisSymbol(TradeSymbol)==0) {  djb=0;djs=0;tst=0;dft=0;ttt=0;tbt=0;sst=0;hbt=0;dcc=0;ppt=0;   }
   if(TotalTradesThisSymbol(TradeSymbol)>0)  {
      for(cnt=0;cnt<total;cnt++) {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==TradeSymbol) {
         if(OrderMagicNumber()==111)  {  djb=OrderTicket(); }
         if(OrderMagicNumber()==222)  {  djs=OrderTicket(); }
         if(OrderMagicNumber()==333)  {  tst=OrderTicket(); }
         if(OrderMagicNumber()==444)  {  dft=OrderTicket(); }
         if(OrderMagicNumber()==555)  {  ttt=OrderTicket(); }
         if(OrderMagicNumber()==666)  {  tbt=OrderTicket(); }
         if(OrderMagicNumber()==777)  {  sst=OrderTicket(); }
         if(OrderMagicNumber()==888)  {  hbt=OrderTicket(); }
         if(OrderMagicNumber()==999)  {  dcc=OrderTicket(); }
         if(OrderMagicNumber()==1111) {  ppt=OrderTicket(); }
         }/*end if(OrderSymbol*/ }/*end for*/   }//end if(TotalTradesThisSymbol

   if(DayOfWeek()==0 || (DayOfWeek()==5 && Hour()>=20)) return(0);
   else  {
   if(doji())              {  DojiTrade();            }
   if(tombstone())         {  TombstoneTrade();       } 
   if(dragonfly())         {  DragonflyTrade();       }   
   if(tweezertop())        {  TweezertopTrade();      }                        
   if(tweezerbottom())     {  TweezerbottomTrade();   }                     
   if(shootingstar())      {  ShootingStarTrade();    }
   if(hammerbottom())      {  HammerbottomTrade();    }
   if(darkcloudcover())    {  DarkCloudCoverTrade();  }
   if(piercingpattern())   {  PiercingPatternTrade(); }
   }//end else

   if(TotalTradesThisSymbol(TradeSymbol)>0)  {
      for(cnt=0;cnt<total;cnt++) {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==TradeSymbol)   {
            if(OrderType()==OP_BUY &&
            Bid>OrderOpenPrice() &&
            btsl()>OrderOpenPrice() &&
            btsl()>OrderStopLoss())   {
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           btsl(),
                           OrderTakeProfit(),
                           0,
                           Lime);
            }//end if(OrderType 
            if(OrderType()==OP_SELL &&
            Ask<OrderOpenPrice() &&
            stsl()<OrderOpenPrice() &&
            stsl()<OrderStopLoss())   {
               OrderModify(OrderTicket(),
                           OrderOpenPrice(),
                           stsl(),
                           OrderTakeProfit(),
                           0,
                           HotPink);
            }//end if(OrderType  
            if(OrderType()==OP_BUYSTOP &&
            CurTime()-OrderOpenTime()>=(Period()*DeleteMinutes)) {
               OrderDelete(OrderTicket());   }//end if(OrderType
            if(OrderType()==OP_SELLSTOP &&
            CurTime()-OrderOpenTime()>=(Period()*DeleteMinutes)) {
               OrderDelete(OrderTicket());   }//end if(OrderType

            OrderSelect(djb,SELECT_BY_TICKET);
            if(OrderCloseTime()>0) {djb=0;}
            OrderSelect(djs,SELECT_BY_TICKET);
            if(OrderCloseTime()>0) {djs=0;}
            OrderSelect(tst,SELECT_BY_TICKET);
            if(OrderCloseTime()>0) {tst=0;}
            OrderSelect(dft,SELECT_BY_TICKET);
            if(OrderCloseTime()>0) {dft=0;}
            OrderSelect(ttt,SELECT_BY_TICKET);
            if(OrderCloseTime()>0) {ttt=0;}
            OrderSelect(tbt,SELECT_BY_TICKET);
            if(OrderCloseTime()>0) {tbt=0;}     
            OrderSelect(sst,SELECT_BY_TICKET);
            if(OrderCloseTime()>0) {sst=0;}
            OrderSelect(hbt,SELECT_BY_TICKET);
            if(OrderCloseTime()>0) {hbt=0;}
         }//end if(OrderSymbol
      }//end for
   }//end if(TotalTradesThisSymbol

PrintComments();
return(0);
}//end start

//functions

bool doji() {
 
   int dojiorders = 0;
   int d = 0;
   //check if we have a current order, if we do select it
   for(d = 0; d < OrdersTotal(); d++ ) {
      OrderSelect(d,SELECT_BY_POS);
      if(OrderMagicNumber()==111 ||
         OrderMagicNumber()==222 &&
         OrderSymbol()==Symbol())  {
         dojiorders ++;
         break;
      }
   }
   //check that we don't already have an order going
   if(dojiorders < 1) {
   
      for(int i = 1; i < Bars; i++ ) { 
         // if we got a doji then save the high and low
         if(Open[i] == Close[i]) {
            double dHigh = High[i];
            double dLow = Low[i];
            double dBar = i;
            break;
         }    
      }
   }
if(dBar>0) return(true);   
else       return(false);   }//end doji

bool tombstone()  {  if(High[1]>=(High[Highest(NULL,0,MODE_HIGH,BarsSL,0)]) &&
                     Open[1]==Low[1]==Close[1]) return   (true);
                     else                       return   (false); }//end tombstone

bool dragonfly()  {  if(Low[1]<=(Low[Lowest(NULL,0,MODE_LOW,BarsSL,0)]) &&
                     Open[1]==High[1]==Close[1])   return   (true);
                     else                          return   (false); }//end dragonfly

bool tweezertop() {  if((MathAbs(High[2]-High[1])<=(1*SPoint)) ||
                     High[1]==High[2]  &&
                     High[1]==(High[Highest(NULL,0,MODE_HIGH,BarsSL,0)]) ||
                     High[2]==(High[Highest(NULL,0,MODE_HIGH,BarsSL,0)]))   return   (true);
                     else                                                   return   (false); }//end tweezertop

bool tweezerbottom() {  if((MathAbs(Low[2]-Low[1])<=(1*SPoint)) ||
                        Low[1]==High[2] &&
                        Low[2]==(Low[Lowest(NULL,0,MODE_LOW,BarsSL,0)]) ||
                        Low[1]==(Low[Lowest(NULL,0,MODE_LOW,BarsSL,0)]))    return   (true);
                        else                                                return   (false); }//end tweezerbottom

bool shootingstar()  {  if(High[1]>=(High[Highest(NULL,0,MODE_HIGH,BarsSL,0)]) &&
                     (MathAbs(Open[1]-Close[1]))<=(0.33*(High[1]-Low[1]))  &&
                     Open[1]<=(High[1]-(0.55*(High[1]-Low[1]))) &&
                     Close[1]<=(High[1]-(0.55*(High[1]-Low[1]))) &&
                     MathAbs(Open[1]-Low[1])<=(3*SPoint) ||
                     MathAbs(Close[1]-Low[1])<=(3*SPoint))   return   (true);
                     else                                    return   (false);}//end shootingstar

bool hammerbottom()  {  if(Low[1]<=(Low[Lowest(NULL,0,MODE_LOW,BarsSL,0)]) &&
                        (MathAbs(Open[1]-Close[1]))<=(0.33*(High[1]-Low[1]))  &&
                        Open[1]>=(Low[1]+(0.55*(High[1]-Low[1]))) &&
                        Close[1]>=(Low[1]+(0.55*(High[1]-Low[1]))) &&
                        MathAbs(High[1]-Open[1])<=(3*SPoint) ||
                        MathAbs(High[1]-Close[1])<=(3*SPoint))    return   (true);
                        else                                      return   (false);}//end hammerbottom

bool darkcloudcover()   {  if(Open[2]<Close[2] &&
                              Open[1]>Close[1] &&
                              High[2]-Close[2]<Close[2]-Open[2] &&
                              Close[2]-Open[2]>Open[2]-Low[2] &&
                              High[1]-Open[1]<Open[1]-Close[1] &&
                              Open[1]-Close[1]>Close[1]-Low[1] &&
                              Open[1]>Close[2] &&
                              Close[1]<((Close[2]-Open[2])*0.5)+Open[2])   return   (true);
                           else                                            return   (false);}//end darkcloudcover

bool piercingpattern()  {  if(Open[2]>Close[2] &&
                              Open[1]<Close[1] &&
                              High[2]-Open[2]<Open[2]-Close[2] && 
                              Open[2]-Close[2]>Close[2]-Low[2] &&
                              High[1]-Close[1]<Close[1]-Open[1] &&
                              Close[1]-Open[1]>Open[1]-Low[1] &&
                              Open[1]<Close[2] &&
                              Close[1]>((Open[2]-Close[2])*0.5)+Close[2])  return   (true);
                           else                                            return   (false);}//end piercingpattern


void PrintComments() {  string OC; OC="No Orders"; int T;
      
      if(TotalTradesThisSymbol(TradeSymbol)>0)  {
      for(cnt=0;cnt<total;cnt++) {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==TradeSymbol)   {  OC=OrderComment();
            T=(Period()*DeleteMinutes)-(CurTime()-OrderOpenTime());   }  }  }
      Comment("Current Time: ",Hour(),":",Minute(),"\n",OC,"\n","Delete Minutes ",(T/DeleteMinutes));  }

double CalcSlBuy()   { return (MathMax(MathMax(Low[Lowest(NULL,0,MODE_LOW,BarsSL,BarShift)]-Spread , Bid-(StopLoss*Point)) , NRTRStopLoss())); }
double CalcSlSell()  { return (MathMin(MathMin(High[Highest(NULL,0,MODE_HIGH,BarsSL,BarShift)]+Spread , Ask+(StopLoss*Point)) , NRTRStopLoss())); }
double CalcTpBuy()   { return (MathMax(High[Highest(NULL,0,MODE_HIGH,BarsTP,BarShift)]-Spread , Ask+(TakeProfit*Point))); }
double CalcTpSell()  { return (MathMin(Low[Lowest(NULL,0,MODE_LOW,BarsTP,BarShift)]+Spread , Bid-(TakeProfit*Point))); }

double btsl()        { return (Low[Lowest(NULL,TrailingPeriod,MODE_LOW,BarsTSL,BarShift)]-Spread); }
double stsl()        { return (High[Highest(NULL,TrailingPeriod,MODE_HIGH,BarsTSL,BarShift)]+Spread); }

double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
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
         OrderMagicNumber()==111 ||
         OrderMagicNumber()==222 || 
         OrderMagicNumber()==333 || 
         OrderMagicNumber()==444 || 
         OrderMagicNumber()==555 || 
         OrderMagicNumber()==666 || 
         OrderMagicNumber()==777 || 
         OrderMagicNumber()==888)   {  TradesThisSymbol++;  }
   }//end for
return(TradesThisSymbol);
}//end TotalTradesThisSymbol

int DojiTrade()   {

   int dojiorders = 0;
   int d = 0;
   double dLow,dHigh;
   int   dBar;
   //check if we have a current order, if we do select it
   for(d = 0; d < OrdersTotal(); d++ ) {
      OrderSelect(d,SELECT_BY_POS);
      if(OrderMagicNumber()==111 ||
         OrderMagicNumber()==222 && 
         OrderSymbol()==Symbol())  {
         dojiorders ++;
         break;
      }
   }
   
   //check for open order
   if(dojiorders > 0) {
      if(int eDirection; eDirection==1)  {
         //if last candle closed below the doji low
         if(Close[1]<dLow)  {
            OrderClose(OrderTicket(),OrderLots(),Bid,5,White);
         }
      }
      if(eDirection == -1){
         //if last candle closed higher then doji high
         if(Close[1]>dHigh){
            OrderClose(OrderTicket(),OrderLots(),Ask,5,White);
         }
      }
   }
   
   //trade EU and US sessions only
   if(Hour() < 0 || Hour() >= 23) return(0);

   //check that we don't already have an order going
   if(dojiorders < 1) {
   
      for(int i = 1; i < Bars; i++ ) { 
         // if we got a doji then save the high and low
         if(Open[i] == Close[i]) {
            dHigh = High[i];
            dLow = Low[i];
            dBar = i;
            break;
         }    
      }
   
      //if we had a doji within the last 3 Bars
      if(dBar < 4 && dBar > 1)   {      

         //did we already determine the direction/entry price?
         if(eDirection == 0)  {      
            //if last candle closed higher than the doji high, long is our direction
            if(Close[1] > dHigh) {
               eDirection = 1;
               double ePrice = Close[1];  
            }
            if(Close[1] < dLow)  {
               eDirection = -1;
               ePrice = Close[1];  
            }
         }   
      }
      else  {
         eDirection = 0;
      }
   
      if(djb==0 && eDirection==1 && Ask>ePrice)    {
         //buy
         OrderSend(Symbol(),
                     OP_BUY,
                     LotsOptimized(),
                     Ask,
                     slippage,
                     CalcSlBuy()+Spread,
                     CalcTpBuy(),
                     "Doji buy "+comment,
                     111,0,LimeGreen);
                     if(ticket>0)   {
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {  djb=ticket;  Print(ticket); }
                        else Print("Error Opening BuyStop Order: ",GetLastError());
                        return(0);
                        }//end if(ticket
      }//end if(djb
      if(djs==0 && eDirection==-1 && Bid<ePrice)   {
         //sell
         OrderSend(Symbol(),
                     OP_SELL,
                     LotsOptimized(),
                     Bid,
                     slippage,
                     CalcSlSell()-Spread,
                     CalcTpSell(),
                     "Doji sell "+comment,
                     222,0,Tomato);
                     if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                        {  djs=ticket;  Print(ticket); }
                     else Print("Error Opening SellStop Order: ",GetLastError());
                     return(0);
                     }//end if(ticket
      }//end if(djs
return   (djb);
return   (djs);
}//end DojiTrade

int TombstoneTrade() {

   if(tst==0)    {
   ticket=OrderSend(Symbol(),
                     OP_SELLSTOP,
                     LotsOptimized(),
                     NormalizeDouble((Low[1]),SDigits),
                     slippage,
                     NormalizeDouble((High[1]+Spread),SDigits),
                     CalcTpSell(),
                     ("Tombstone "+comment),
                     333,
                     0,
                     Tomato);
                     if(ticket>0)   {
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {  tst=ticket;  Print(ticket); }
                        else Print("Error Opening SellStop Order: ",GetLastError());
                        return(0);
                        }//end if(ticket
   }//end if(tst    
return   (tst);
}//end TombstoneTrade

int DragonflyTrade() {

   if(dft==0)   {
   ticket=OrderSend(Symbol(),
                     OP_BUYSTOP,
                     LotsOptimized(),
                     NormalizeDouble(High[1],SDigits),
                     slippage,
                     NormalizeDouble((Low[1]-Spread),SDigits),
                     CalcTpBuy(),
                     ("Dragonfly "+comment),
                     444,
                     0,
                     LimeGreen);
                     if(ticket>0)   {
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {  dft=ticket;  Print(ticket); }
                        else Print("Error Opening BuyStop Order: ",GetLastError());
                        return(0);
                        }//end if(ticket
   }//end if(dft
return (dft);
}//end DragonflyTrade

int TweezertopTrade()   {

   if(ttt==0)    {
   ticket=OrderSend(Symbol(),
                     OP_SELLSTOP,
                     LotsOptimized(),
                     NormalizeDouble((Low[1]),SDigits),
                     slippage,
                     NormalizeDouble((High[1]+Spread),SDigits),
                     CalcTpSell(),
                     ("Tweezertop "+comment),
                     555,
                     0,
                     Tomato);
                     if(ticket>0)   {
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {  ttt=ticket;  Print(ticket); }
                        else Print("Error Opening SellStop Order: ",GetLastError());
                        return(0);
                        }//end if(ticket
   }//end if(ttt    
return   (ttt);
}//end TweezertopTrade

int TweezerbottomTrade()   {

   if(tbt==0)   {
   ticket=OrderSend(Symbol(),
                     OP_BUYSTOP,
                     LotsOptimized(),
                     NormalizeDouble(High[1],SDigits),
                     slippage,
                     NormalizeDouble((Low[1]-Spread),SDigits),
                     CalcTpBuy(),
                     ("Tweezerbottom "+comment),
                     666,
                     0,
                     LimeGreen);
                     if(ticket>0)   {
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {  tbt=ticket;  Print(ticket); }
                        else Print("Error Opening BuyStop Order: ",GetLastError());
                        return(0);
                        }//end if(ticket
   }//end if(tbt
return (tbt);
}//end TweezerbottomTrade

int ShootingStarTrade() {

   if(sst==0)    {
   ticket=OrderSend(Symbol(),
                     OP_SELLSTOP,
                     LotsOptimized(),
                     NormalizeDouble((Low[1]),SDigits),
                     slippage,
                     NormalizeDouble((High[1]+Spread),SDigits),
                     CalcTpSell(),
                     ("ShootingStar "+comment),
                     777,
                     0,
                     Tomato);
                     if(ticket>0)   {
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {  sst=ticket;  Print(ticket); }
                        else Print("Error Opening SellStop Order: ",GetLastError());
                        return(0);
                        }//end if(ticket
   }//end if(htt    
return   (sst);
}//end ShootingStar

int HammerbottomTrade()   {

   if(hbt==0)   {
   ticket=OrderSend(Symbol(),
                     OP_BUYSTOP,
                     LotsOptimized(),
                     NormalizeDouble(High[1],SDigits),
                     slippage,
                     NormalizeDouble((Low[1]-Spread),SDigits),
                     CalcTpBuy(),
                     ("Hammerbottom "+comment),
                     888,
                     0,
                     LimeGreen);
                     if(ticket>0)   {
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {  hbt=ticket;  Print(ticket); }
                        else Print("Error Opening BuyStop Order: ",GetLastError());
                        return(0);
                        }//end if(ticket
   }//end if(hbt
return (hbt);
}//end HammerbottomTrade

int DarkCloudCoverTrade()   {

   if(dcc==0)  {
   ticket=OrderSend(Symbol(),
                     OP_SELLSTOP,
                     LotsOptimized(),
                     NormalizeDouble(Low[1],SDigits),
                     slippage,
                     NormalizeDouble((High[1]+Spread),SDigits),
                     CalcTpSell(),
                     ("DarkCloudCover "+comment),
                     999,
                     0,
                     Tomato);
                     if(ticket>0)   {
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {  dcc=ticket; Print(ticket); }
                        else Print("Error Opening SellStop Order: ",GetLastError());
                        return(0);
                        }//end if(ticket
   }//end if(dcc
return (dcc);
}//end DarkCloudCoverTrade

int PiercingPatternTrade()  {

   if(ppt==0)  {
   ticket=OrderSend(Symbol(),
                     OP_BUYSTOP,
                     LotsOptimized(),
                     NormalizeDouble(High[1],SDigits),
                     slippage,
                     NormalizeDouble((Low[1]-Spread),SDigits),
                     CalcTpBuy(),
                     ("PiercingPattern "+comment),
                     1111,
                     0,
                     LimeGreen);
                     if(ticket>0)   {
                        if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                           {  ppt=ticket; Print(ticket); }
                        else Print("Error Opening BuyStop Order: ",GetLastError());
                        return(0);
                        }//end if(ticket
   }//end if(ppt
return (ppt);
}



double NRTRStopLoss()   {
   /*extern*/ int AveragePeriod=10;
   /*extern*/ int CountBars=300;
   double value1[],value2[];
  {
   if (CountBars>iBars(Symbol(),PERIOD_H1)) CountBars=iBars(Symbol(),PERIOD_H1);
   int i,counted_bars=IndicatorCounted();
   double value;
   double trend=0,dK,AvgRange,price;
//----
   if(iBars(Symbol(),PERIOD_H1)<=AveragePeriod) return(0);
//---- initial zero
   if(counted_bars<1)
   {
      for(i=1;i<=AveragePeriod;i++) value1[iBars(Symbol(),PERIOD_H1)-i]=0.0;
      for(i=1;i<=AveragePeriod;i++) value2[iBars(Symbol(),PERIOD_H1)-i]=0.0;
   }


AvgRange=0;
for (i=1 ; i<=AveragePeriod ; i++) AvgRange+= MathAbs(iHigh(Symbol(),PERIOD_H1,i)-iLow(Symbol(),PERIOD_H1,i));
if (Symbol() == "USDJPY" || Symbol() == "GBPJPY" || Symbol() == "EURJPY")
{dK = (AvgRange/AveragePeriod)/100;}
else {dK = AvgRange/AveragePeriod;}

if (iClose(Symbol(),PERIOD_H1,CountBars-1) > iOpen(Symbol(),PERIOD_H1,CountBars-1))
   {
   value1[CountBars - 1] = iClose(Symbol(),PERIOD_H1,CountBars-1) * (1 - dK);
   trend = 1; value2[CountBars - 1] = 0.0;
   }
if (iClose(Symbol(),PERIOD_H1,CountBars-1) < iOpen(Symbol(),PERIOD_H1,CountBars-1))  {
   value2[CountBars - 1] = iClose(Symbol(),PERIOD_H1,CountBars-1) * (1 + dK);
   trend = -1; value1[CountBars - 1] = 0.0;
   }
//----
   i=CountBars-1;
   while(i>=0)
     {
value1[i]=0; value2[i]=0;
if (trend >= 0)
       {
       if (iClose(Symbol(),PERIOD_H1,i) > price) price = iClose(Symbol(),PERIOD_H1,i);
       value = price * (1 - dK);
       if (iClose(Symbol(),PERIOD_H1,i) < value)
          {
          price = iClose(Symbol(),PERIOD_H1,i);
          value = price * (1 + dK);
          trend = -1;
          }
       } 
    else
       { 
    if (trend <= 0)
       {
       if (iClose(Symbol(),PERIOD_H1,i) < price) price = iClose(Symbol(),PERIOD_H1,i);
       value = price * (1 + dK);
       if (iClose(Symbol(),PERIOD_H1,i) > value) 
          {
          price = iClose(Symbol(),PERIOD_H1,i);
          value = price * (1 - dK);
          trend = 1;
          }
       }
       }
if (trend ==  1)  {value1[i]=value; value2[i]=0.0;}
if (trend == -1)  {value2[i]=value; value1[i]=0.0;}

      i--;
     }
   return(value);
  }
  }//end NRTRStopLoss() 