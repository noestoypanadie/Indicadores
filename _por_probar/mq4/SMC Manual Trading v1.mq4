//+------------------------------------------------------------------+
//|                                                           SMC.mq4 
//|              inspired by my own efforts
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

 extern double Lots = 0.1;
 extern double RiskPercent = 1;
 extern int SL= 0;
 extern int TP=0;
 
 datetime BarTime;
 int cnt,tmp;
//#####################################################################
int init()
{
//----
//----
   return(0);
  }
//#############################################################################

int start()
  {
   double SL;
   double Spread, ATR, MinDist;
   double MaxRisk;

   double OpenLongVal, OpenShortVal;  //Breakout Prices
   double CloseLongVal,CloseShortVal;
   double LongProfitVal,ShortProfitVal;

   bool   CloseLongs,CloseShorts;
   bool   Buy,Sell;
   bool   BuyZone, SellZone;

   int    total,ticket,err,tmp;
   int    NumberofPositions;
   
   string MaxRiskStr;
   datetime tmpstring;
   
//############################################################################
  if(Bars<100){Print("bars less than 100"); return(0); }
//exit if not new bar
// if(BarTime == Time[0]) {return(0);}
//new bar, update bartime
// BarTime = Time[0];
//#############################################################################
//~~~~~~~~~~~~~~~~Miscellaneous setup stuff~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 MinDist=(MarketInfo(Symbol(),MODE_STOPLEVEL)*Point);
 Spread=(Ask-Bid);
 MaxRisk=(AccountFreeMargin()*RiskPercent/100)*Point();
 MaxRiskStr=DoubleToStr(MaxRisk,4);

//#############################################################################
  double LineVal,LowLineValm1;
  
  LineVal = ObjectGetValueByShift("OpenLong",1);
  if(LineVal!= 0) ObjectMove("OpenLong",1,CurTime()+ 3*Period()*60,LineVal);
 
  LineVal = ObjectGetValueByShift("OpenShort",1);
  if(LineVal!= 0) ObjectMove("OpenShort",1,CurTime()+ 3*Period()*60,LineVal);
 
   LineVal = ObjectGetValueByShift("CloseShort",1);
  if(LineVal!= 0) ObjectMove("CloseShort",1,CurTime()+ 3*Period()*60,LineVal);

  LineVal = ObjectGetValueByShift("CloseLong",1);
  if(LineVal!= 0) ObjectMove("CloseLong",1,CurTime()+ 3*Period()*60,LineVal);

  LineVal = ObjectGetValueByShift("ShortProfit",1);
  if(LineVal!= 0) ObjectMove("ShortProfit",1,CurTime()+ 3*Period()*60,LineVal);

  LineVal = ObjectGetValueByShift("LongProfit",1);
  if(LineVal!= 0) ObjectMove("LongProfit",1,CurTime()+ 3*Period()*60,LineVal);
  
  
  
//PUT Prices as part of  description 


//####################OPENING RULES######################################
//BUY and SELL rules:
 OpenLongVal= 999999;
 OpenLongVal = ObjectGetValueByShift("OpenLong",1);
 err=GetLastError();
 if(err == 0)
 {
 Buy=false; 
  if(Close[1] > OpenLongVal)
   
   {ObjectDelete("OpenLong");
    OpenLongVal=99999;
    Buy=true;
    SL=0;
    TP=0;
     }
  }
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 OpenShortVal= 1;
 OpenShortVal = ObjectGetValueByShift("OpenShort",1);
 err=GetLastError();
 if(err == 0)
 {
 Sell =false;
  if(Close[1] < OpenShortVal)
  
   {ObjectDelete("OpenShort");
    OpenShortVal=0;  
    Sell=true;
    SL=0;
    TP=0;
     }
  }
//######################CLOSING RULES###################################
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//CLOSE CloseShorts = false;
//LONG & SHORT Rules:  PROBLEM IF LINES MOVE DURING TRADE
CloseLongs = false;
CloseShorts = false;

err=0;
CloseLongVal=ObjectGetValueByShift("CloseLong",1);
if(err!=0) CloseLongVal=1;

err=0;
CloseShortVal=ObjectGetValueByShift("CloseShort",1);
if(err!=0) CloseShortVal=999999;

err=0;
LongProfitVal=ObjectGetValueByShift("LongProfit",1);
if(err!=0) LongProfitVal=999999;

err=0;
ShortProfitVal=ObjectGetValueByShift("ShortProfit",1);
if(err!=0) ShortProfitVal=1;


if(Close[1]>LongProfitVal) CloseLongs = true;
if(Close[1]<ShortProfitVal) CloseShorts= true;

if(Close[1]<CloseLongVal) CloseLongs = true;
if(Close[1]>CloseShortVal) CloseShorts= true;

if(0==1) // CHECK THIS IS OFF OTHERWISE CLOSE ALL!!!!! Positions
{
CloseLongs = true;
CloseShorts = true;
}
Comment("\n","Trend= ","\n", "Max Risk ",MaxRiskStr,"\n","Open Long @ ",
        OpenLongVal,"\n","Open Short @ ",OpenShortVal,"\n","Close Long @ ",CloseLongVal,"\n",
        "Close Short @ ",CloseShortVal);  

//~~~~~~~~~~~~~~~~  ORDER CLOSURE  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//CLOSE LONG Entries
 if(CloseLongs == true)
 {                                 
  total=OrdersTotal();
  if(total>0)
   { 
   for(cnt=0;cnt<total;cnt++)
   {
    OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
    if(OrderType()==OP_BUY && OrderSymbol()==Symbol() && CloseLongs==true)
     {CloseLongs=false;
      OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // close LONG position
      SendMail(Symbol()+" BUY Order Closed @ "+Bid," ");
   }}}}
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//CLOSE SHORT ENTRIES: 
 if(CloseShorts == true)
 { 
  total=OrdersTotal();
  if(total>0)
   { 
   for(cnt=0;cnt<total;cnt++)
   {CloseShorts=false;   
    OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES); 
    if(OrderType()==OP_SELL && OrderSymbol()==Symbol() && CloseShorts==true) // check for symbol
     {
      OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // close SHORT position
      SendMail(Symbol()+" SELL Order Closed @ "+ Ask," ");
   }}}}
//##############################################################################################


//~~~~~~~~~~~ END OF ORDER Closure routines & Stoploss changes  ~~~~~~~~~~~~~~~~~~~~
//##################################################################################
//##################################################################################
//~~~~~~~~~~~~START of NEW ORDERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   if(AccountFreeMargin()<(1000*Lots))
   {Print("We have no money. Free Margin = ", AccountFreeMargin());
    return(0);}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (0==1) // switch to turn ON/OFF history check
{  
 total=HistoryTotal();
 if(total>0)
  { 
   for(cnt=0;cnt<total;cnt++)
    {
     OrderSelect(cnt, SELECT_BY_POS, MODE_HISTORY);            //Needs to be next day not as below
     if(OrderSymbol()==Symbol()&& CurTime()- OrderCloseTime() < (Period() * 60 )
        )
        {
        return(0);
 }}}}
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 NumberofPositions = 0;
 total=OrdersTotal();
  if(total>0)
   { 
    for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
       if(OrderSymbol()==Symbol()) NumberofPositions=NumberofPositions+1;
       }
//may require extra code to determine exposure on any one pair
       if (NumberofPositions >= 1) return(0);
   }

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//OPEN ORDER: LONG 
 if(Buy==true) 
  {
   ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,SL,TP,"Manual System Long",16384,0,Orange); //Bid-(Point*(MinDist+2))
   if(ticket>0)
    { 
     Print("BUY order opened : ",OrderOpenPrice());
     Alert(Symbol()," Buy");
     if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
      {Print("BUY order opened : ",OrderOpenPrice()," ",SL," ",TP);     
       //SendMail(Symbol()+" "+Period()+" BUY Order Opened @ "+Ask,"Comments: SL ="+SL+" Risk = "+DoubleToStr((Bid-SL),4)+" Max Risk "+MaxRiskStr);
       }
     }
     else Print("Error opening BUY order : ",GetLastError()); 
     return(0); 
   } 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//OPEN ORDER: SHORT                                   
 if(Sell==true) 
  {
   ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,SL,TP,"Manual System Short",16384,0,Red);
   if(ticket>0)
    {
      Print("SELL order opened : ",OrderOpenPrice());
      Alert(Symbol()," Sell");
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
       {Print("SELL order opened : ",OrderOpenPrice()," ",SL," ",TP);
        //SendMail(Symbol()+" "+Period()+" SELL Order Opened @ "+Bid,"Comments: SL ="+SL+" Risk = "+DoubleToStr((SL-Ask),4)+" Max Risk "+MaxRiskStr);
        }
      }
      else Print("Error opening SELL order : ",GetLastError()); 
      return(0); 
   }

//####################################################################################
//############               End of PROGRAM                  #########################   
   return(0);
}

