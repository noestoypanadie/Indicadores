//+------------------------------------------------------------------+
//|                                                   STI_v2_0_2.mq4 |
//|                                                                  |
//|                     developed by Joke modified by Nicholishen    |
//+------------------------------------------------------------------+
#property copyright ""
#property link      "www.forex-tsd.com"
#define MAGICMA  20060224

#include <stdlib.mqh>
#include <WinUser32.mqh>



/*
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Additions:

TotalEquitySL= This feature sets a total stoploss on entire account.  If account equity grows to a certain point and then drops
below the alowable draw down percentage AND there are no open trades then trading is suspended until human intervention.

ScalpIt = Brokers typically won't allow tight TP.  This feature will allow you to set any TP.

StepTrail= This feature will set the new stop loss after the Trail1Step level is hit.  The new stop is at the profit level
minus the flex.  It will step in increments of the (Trail1Step).
 
TradTrail= This is the Traditional Trailing Stop.

UseCCI= Only trades when CCI signal <100 && >-100

UseMailAlerts= Will email the details of the trade as it hits the history window regardless of whether or not EA closes or 
trade is closed by SL/TP

UseTimeFilter= If there are no pending trades AND Time is < Begin OR > End  then Trading is suspended

Reverse Trade Signal= reverses opening and closing criteria

You are now able to trade:
a)Multiple Pairs
b)Multiple TF on Same pair same platform
c)Multiple settings on (a) and/or (b) at the same time

System will automatically log trade settings and all trades associated with those settings. 
Logs can be found in the experts/files folder. File can be opened with Excel
for further analysis

TEST AWAY!       =) Nicholishen
*/
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
   //extern bool UseSendit=false;
   extern bool UseEmailAlerts=false;
   extern bool UseTotalEquitySL=false;
   extern double EquityRisk=50;
   extern double lots=0.5; 
   extern bool UseCloseCriteria=true;            
   extern int TakeProfit=30;             
   extern int StopLoss=50;             
              
   extern bool UseScalpIt=false;
   extern int ScalpPips=3;
   extern bool UseStepTrail=false;
   extern int Trail1Step=6;
   extern int Flex=2;
  
   extern bool UseTrail    = true; 
   extern bool ProfitTrailing = true;   
   extern double  TrailingAct   = 6;    
   extern double  TrailingStep   = 3;  

   extern int N1=3;            
   extern int N2=2;
   extern int MaxPeriodsBack=20;
               
   extern bool UseStochasticFilter=false;
   extern int  StoPeriod=1440;
   extern bool UseCCI=false;
   extern bool UseTimeFilter=false;
   extern int BeginHour=8;
   extern int EndHour=18;
   extern bool ReverseTradeSignal=false;
   extern string FileSavePrefix="STI";
   
   int TestStart;
   int k;
   int mm,dd,yy,hh,min,ss,tf;
   string comment;
   string syym;
   string qwerty;
   int OrderID;
   double TrailPrice;
   
int deinit()
  {
 // ObjectsDeleteAll(0,OBJ_ARROW);
 // ObjectsDeleteAll(0,OBJ_HLINE);
 
 //if(GlobalVariableCheck("STI")==false) GlobalVariableSet("STI",0);
 
 int TestStop=CurTime();
// int num=GlobalVariableGet("STI")+1;
 
 //string filename="STI_"+num+".csv";
 string filename=comment+"_"+yy+"_"+mm+"_"+dd+"_"+hh+"_"+min+"_"+syym+"_"+tf+".csv";
 
 //if(GlobalVariableCheck("STI")==false) GlobalVariableSet("STI",0);
 
 int h1=FileOpen(filename,FILE_CSV|FILE_WRITE,',');
 FileWrite(h1,"Period","UseStochasticFilter",
"UseEmailAlerts","UseTotalEquitySL","EquityRisk","lots","TakeProfit","StopLoss","UseScalpIt","ScalpPips",
"UseStepTrail","Trail1Step","Flex","UseTradTrail","ProfitTrailing","TrailingStop","TrailingStep", "N1","N2","UseCCI","UseTimeFilter","BeginHour", "EndHour","ReverseTradeSignal",
"TestStart","TestStop","TotalProfit");
 
 
 FileWrite(h1,Period(),UseStochasticFilter,
UseEmailAlerts,UseTotalEquitySL,EquityRisk,lots,TakeProfit,StopLoss,UseScalpIt,ScalpPips,
UseStepTrail,Trail1Step,Flex,UseTrail,ProfitTrailing,TrailingAct,TrailingStep, N1,N2,UseCCI,UseTimeFilter,BeginHour, EndHour,ReverseTradeSignal,
TimeToStr(TestStart,TIME_DATE|TIME_SECONDS),TimeToStr(TestStop,TIME_DATE|TIME_SECONDS),TotalProfit(TestStart,TestStop));

 FileWrite(h1,"");  
 FileWrite(h1,"TRADES");
 FileWrite(h1,"Order","OpenTime", "Type","Lots","Symbol","Price","SL","TP","Time","ClosePrice","Swap","Profit");
 /////////////
   double pr=0;
   for(int i=0;i<10000;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)){
         if(OrderMagicNumber()==OrderID){
            //if(OrderOpenTime() >= TestStart){
            if(OrderType()==OP_BUY){string typ="BUY";}else{typ="SELL";}
            FileWrite(h1,OrderTicket(),TimeToStr(OrderOpenTime(),TIME_DATE|TIME_SECONDS),typ,OrderLots(),OrderSymbol(),OrderOpenPrice(),OrderStopLoss(),
            OrderTakeProfit(),TimeToStr(OrderCloseTime(),TIME_DATE|TIME_SECONDS),OrderClosePrice(),OrderSwap(),OrderProfit() );
            //}
         }
      }else{
         break;
      }  
   }
//////////////
 
// GlobalVariableSet("STI",GlobalVariableGet("STI")+1);          
//---- 
  return;
  }
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
   if(!GlobalVariableCheck("STI")) GlobalVariableSet("STI",1);
   int ggg=GlobalVariableGet("STI");
   
   string gv=DoubleToStr(ggg,0);
   string sy=Symbol();
   
   OrderID = GetTagNumber();
   comment=FileSavePrefix+gv;
   GlobalVariableSet("STI",ggg+1);
   
   mm=Month();dd=Day();yy=Year();min=Minute();hh=Hour();ss=Seconds();syym=Symbol();tf=Period();
   TestStart=CurTime();
   qwerty=TimeToStr(TestStart,TIME_DATE|TIME_SECONDS);
   for(int i=0;i<1000;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)){
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==OrderID ){
            k++;
         }
      }else{
         break;
      }  
   }

return(0);
}  
//+------------------------------------------------------------------+
// Converts Periods to String to track Mult Orders on Same Pair diff TF
//+------------------------------------------------------------------+

int GetTagNumber() { 
   int PullNumber = 0;
   if( GlobalVariableCheck( "PullTag ( Do Not Delete )" ) ) {
	  PullNumber = GlobalVariableGet( "PullTag ( Do Not Delete )" );
   } else {
	  PullNumber = 100;
   } 
   GlobalVariableSet( "PullTag ( Do Not Delete )", PullNumber + 1 );
   if( GlobalVariableGet( "PullTag ( Do Not Delete )" ) > 999 ) {
	  GlobalVariableSet( "PullTag ( Do Not Delete )", 100 );
	} 
return( PullNumber );
}

string Cmt(int x){
return(DoubleToStr(x,0));
}

double TotalProfit(int start,int end){
   double pr=0;
   for(int i=0;i<10000;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)){
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==OrderID ){
            if(OrderOpenTime() >= TestStart)pr=pr+OrderProfit();
         }
      }else{
         break;
      }  
   }
   return(pr);
}
//+------------------------------------------------------------------+
// Time Filter
//+------------------------------------------------------------------+
int TimeFilter(){
   if(Hour()>EndHour || Hour()<BeginHour){
      return(1);
   }
   return(0);
}
//+------------------------------------------------------------------+
// Calculates Current Orders on TF,Pair,EA
//+------------------------------------------------------------------+

int CalculateCurrentOrders(){
   int orders=0;
   
   for(int i=0;i<OrdersTotal();i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==OrderID ){
            orders++;
         }
      }
   }
   
   return(orders);
}
 //+------------------------------------------------------------------+
// Trading Signal
//+------------------------------------------------------------------+
int TradeSignal(int functyp){
double Cbarhi[21], Cbarlo[21], minmin, maxmax, stMAINPrev, stSIGPrev, sl, tp;
   int    res, error, skUp, skDn , UD;
   bool   DownBar[21], UpBar[21];
     
   
   //Comment("sto1 ",sto1,"  sto2 ",sto2);
   for (int k=0; k<=MaxPeriodsBack; k++){
   
      UpBar[k]=True;
      DownBar[k]=True;
      Cbarhi[k]=High[N1+k];
      Cbarlo[k]=Low[N1+k];
  
      for (int d=1; d<=N1; d++){
         if (Cbarhi[k]>High[N1+k+d] && Cbarlo[k]<Low[N1+k-d]&&UpBar[k]==True) {
            UpBar[k]=True;
         }else{
            UpBar[k]=False;
         }
         if (Cbarhi[k]>High[N1+k-d]&& Cbarlo[k]<Low[N1+k+d]&& DownBar[k]==True){
            DownBar[k]=True;
         }else{
            DownBar[k]=False;
         }  
         if (UpBar[k]==True && skUp<N2){
            skUp++;
            if (minmin==0 || minmin>Low[N1+k] ) minmin=Low[N1+k];
         }   
     
         if (DownBar[k]==True && skDn<N2){
            skDn++;
            if (maxmax==0 || maxmax<High[N1+k] ) maxmax=High[N1+k];
         }   
         if (UD==0 && DownBar[k])UD=1;  
         if (UD==0 && UpBar[k])UD=2;             
      }
   }
   int tCCI=0;
   int stohit=0;
   
   
   
   if(UseStochasticFilter){
      double sto1=iStochastic(NULL,StoPeriod,5,3,3,MODE_SMA,0,MODE_MAIN,0);
      double sto2=iStochastic(NULL,StoPeriod,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);  
      if(sto1>sto2){
         stohit=1;
      }else{
         stohit=2;
      }
   }else{
      stohit=0;
   }
   
   
   if(UseCCI){
      double cci=iCCI(NULL,0,14,5,0);
      if(cci<100 && cci>-100){
         tCCI=1;
      }
   }else{
      tCCI=1;
   }
   
   if(functyp==1){
      if ( UD==1  && maxmax<=Bid && tCCI==1 && (stohit==2 || stohit==0) ){
         if(ReverseTradeSignal){
            return(1);
         }else{
            return(2);
         }
      }
      if ( UD==2 && minmin >= Ask && tCCI==1 && (stohit==1 || stohit==0)){
         if(ReverseTradeSignal){
            return(2);
         }else{
            return(1); 
         }
      }
   }
   if(functyp==2){
      if ( UD==1  && maxmax<=Bid){
         if(ReverseTradeSignal){
            return(1);
         }else{
            return(2);
         }
      }
      if ( UD==2 && minmin >= Ask){
         if(ReverseTradeSignal){
            return(2);
         }else{
            return(1); 
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Open Conditions                       |
//+------------------------------------------------------------------+
void Sendit(){
double sl,tp; int res,error;

  
     
      res = OrderSend(Symbol(),OP_SELL,lots,Bid,3,sl,tp,comment,OrderID,0,Blue); // def
      if(res<0){
         error=GetLastError();
         Print("Error = ",ErrorDescription(error));
      }
  
  }
void CheckForOpen(){
double sl,tp; int res,error;

  if(TradeSignal(1)==2){
      if (StopLoss==0) {sl=0;} else sl=Bid+Point*StopLoss;
      if (TakeProfit==0) {tp=0;} else tp=Bid-Point*TakeProfit;
     
      res = OrderSend(Symbol(),OP_SELL,lots,Bid,3,sl,tp,comment,OrderID,0,Blue); // def
      if(res<0){
         error=GetLastError();
         Print("Error = ",ErrorDescription(error));
      }
  }
  if(TradeSignal(1)==1){
      if (StopLoss==0) {sl=0;} else sl=Ask-Point*StopLoss;
      if (TakeProfit==0) {tp=0;} else tp=Ask+Point*TakeProfit;
   
      res = OrderSend(Symbol(),OP_BUY,lots,Ask,3,sl,tp,comment,OrderID,0,Red); // def
      if(res<0){
         error=GetLastError();
         Print("Error = ",ErrorDescription(error));
      }
  }
}   
  
//+------------------------------------------------------------------+
//| Close conditions                      |
//+------------------------------------------------------------------+
void CheckForClose(){

   for(int i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);    
      if (OrderType()==OP_BUY && OrderMagicNumber()==OrderID && Symbol()==OrderSymbol()){
         if (TradeSignal(2)==2) {                          // MA SELL signals
            int res = OrderClose(OrderTicket(),OrderLots(),Bid,3,White); // close 
            TrailPrice=0;
            if(res<0){
               int error=GetLastError();
               Print("Error = ",ErrorDescription(error));
            }
         }     
      } 
      if (OrderType()==OP_SELL && OrderMagicNumber()==OrderID && Symbol()==OrderSymbol() ){
         if (TradeSignal(2)==1) {                          // MA BUY signals
            res = OrderClose(OrderTicket(),OrderLots(),Ask,3,White); // close 
            TrailPrice=0;
            if(res<0){
               error=GetLastError();
               Print("Error = ",ErrorDescription(error));
            }
         }     
      }  
   }    
}
   

//+------------------------------------------------------------------+
// Set Tight TP
//+------------------------------------------------------------------+
void Scalp(){
double res;int error;
   for(int i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==OrderID ){
         if(OrderType()==OP_BUY){
            if(Bid - OrderOpenPrice() >= ScalpPips*Point){
               res = OrderClose(OrderTicket(),OrderLots(),Bid,3,White); // close 
               if(res<0){
                  error=GetLastError();
                  Print("Error = ",ErrorDescription(error));
               }
            }
         }
         if(OrderType()==OP_SELL){
            if(OrderOpenPrice() - Ask >= ScalpPips*Point){
               res = OrderClose(OrderTicket(),OrderLots(),Ask,3,White); // close 
               if(res<0){
                  error=GetLastError();
                  Print("Error = ",ErrorDescription(error));
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
// Step Trailing Stop
//+------------------------------------------------------------------+

void StepTrail(){
bool res;int error;
   for(int i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==OrderID  ){
         if(OrderType()==OP_BUY){
            for(int v=10;v>0;v--){
               if(Bid - OrderOpenPrice() >= Trail1Step*Point*v){
                  double bnm=OrderOpenPrice()+Trail1Step*v-Flex;
                  ModifyStopLoss(bnm);  
                  break;
               }
            }
         }
         if(OrderType()==OP_SELL){
            for(v=10;v>0;v--){
               if(OrderOpenPrice()-Ask >= Trail1Step*Point*v){
                  double sdf=OrderOpenPrice()-Trail1Step*v+Flex;
                  ModifyStopLoss(sdf);
                  break;
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
// Traditional Trailing Stop
//+------------------------------------------------------------------+
void TrailingPositions() {
  for (int i=0; i<OrdersTotal(); i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderMagicNumber()==OrderID ) {
         if (OrderType()==OP_BUY) {
            if (Bid-OrderOpenPrice()>TrailingAct*Point && TrailPrice ==0) {
               TrailPrice=Bid-TrailingStep*Point;
               Print("TRAIL PRICE MODIFIED: ",TrailPrice);
            }
            if (TrailPrice>0 && TrailPrice < Bid-TrailingStep*Point){
               TrailPrice=Bid-TrailingStep*Point;
               Print("TRAIL PRICE MODIFIED: ",TrailPrice);
            }
            if (TrailPrice >0 && TrailPrice >= Bid-TrailingStep*Point){
               CloseOrder(1);
            }
         }
         if (OrderType()==OP_SELL) {
            if (OrderOpenPrice()-Ask > TrailingAct*Point && TrailPrice ==0) {
               TrailPrice=Ask+TrailingStep*Point;
               Print("TRAIL PRICE MODIFIED: ",TrailPrice);
            }
            if (TrailPrice>0 && TrailPrice > Ask+TrailingStep*Point){
               TrailPrice=Ask+TrailingStep*Point;
               Print("TRAIL PRICE MODIFIED: ",TrailPrice);
            }
            if (TrailPrice >0 && TrailPrice <= Ask+TrailingStep*Point){
               CloseOrder(2);
            }   
         }
      }
   }
}}
void CloseOrder(int ord){
    for(int i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);    
      if (OrderType()==OP_BUY && OrderMagicNumber()==OrderID){
         if (ord==1){
         int res = OrderClose(OrderTicket(),OrderLots(),Bid,3,White); // close 
         TrailPrice=0;
         if(res<0){
            int error=GetLastError();
            Print("Error = ",ErrorDescription(error));
         }
      }}     
      
      if (OrderType()==OP_SELL && OrderMagicNumber()==OrderID ){
         if (ord==2) {                          // MA BUY signals
            res = OrderClose(OrderTicket(),OrderLots(),Ask,3,White); // close 
            TrailPrice=0;
            if(res<0){
               error=GetLastError();
               Print("Error = ",ErrorDescription(error));
            }
         }     
      }  
   }    
 }  

//+------------------------------------------------------------------+
// Order Modify function
//+------------------------------------------------------------------+
void ModifyStopLoss(double ldStop) {
  bool   fm;
  double ldOpen=OrderOpenPrice();
  double ldTake=OrderTakeProfit();

  fm=OrderModify(OrderTicket(), ldOpen, ldStop, ldTake, 0, Pink);
  
}
//+------------------------------------------------------------------+
// Emails the Closed order as soon as it hits the history.
//+------------------------------------------------------------------+
void MailAlert(){
int f =0;
   for(int i=0;i<10000;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)){
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==OrderID ){
            f++;
         }
      }else{
         break;
      }  
   }
   //Comment(" Trades in History ",f," Init cnt ",k  );
   if(k < f){
      string ordertyp;
      
      OrderSelect(f,SELECT_BY_POS,MODE_HISTORY);
      if(OrderType()==0)ordertyp="BUY";
      if(OrderType()==1)ordertyp="SELL";
     // SendMail("HI","HI");
      SendMail("CLOSED TRADE - STI - "+DoubleToStr(OrderProfit(),2),"  "+Symbol()+"    OpenTime: "+TimeToStr(OrderOpenTime())+"   Close Time: "+TimeToStr(OrderCloseTime())+"                     "+
      "Order Type "+ordertyp+"   Open "+DoubleToStr(OrderOpenPrice(),4)+"   Close "+DoubleToStr(OrderClosePrice(),4)+"  Profit ("+DoubleToStr(OrderProfit(),4)+")" );
      k++;
   }
 return;
} 
      
//+------------------------------------------------------------------+
// Safety net for trading.  Creates a total equity Stoploss
//+------------------------------------------------------------------+      
      
int EquitySL(){
static double eqhi;
   if(AccountEquity()>eqhi)eqhi=AccountEquity();
   if(AccountEquity() < eqhi * (( 100 - EquityRisk)/100))return(1);
return(0);
}

   
//+------------------------------------------------------------------+
// Expert Function
//+------------------------------------------------------------------+ 
int start(){
   Comment("\n","   ",comment," Started @ ",qwerty,"  OrderID: ",OrderID);
   if ((UseScalpIt && UseStepTrail)||(UseStepTrail && UseTrail) || (UseTrail && UseScalpIt)){
      Comment(" ERROR:  CANNOT USE MULTIPLE EXITING CRITERIA PLEASE CHANGE CRITERIA IN PROPERTIES ");
      return;
   }

   if(Bars<100 || IsTradeAllowed()==false) return;

   if(CalculateCurrentOrders()==0) {
      TrailPrice=0;
      if (UseTotalEquitySL && EquitySL()==1){
      Comment("Total Equity StopLoss Hit --------HUMAN INTERVENTION IS REQUIRED--------------");
      Alert("HUMAN INTERVENTION IS REQUIRED");
      return;
      }
      if(UseTimeFilter && TimeFilter()==1)return;
      CheckForOpen();
   }else{
      if (UseCloseCriteria){
         CheckForClose();
      }
   }
   //if(UseSendit){Sendit();}
   if(UseScalpIt) {Scalp();}
   if(UseStepTrail){StepTrail();}
   if(UseTrail){TrailingPositions();}
   if(UseEmailAlerts){MailAlert();}
   
   return(0);
}
//+------------------------------------------------------------------+
// developed by Joke modified by Nicholishen
//+------------------------------------------------------------------+


