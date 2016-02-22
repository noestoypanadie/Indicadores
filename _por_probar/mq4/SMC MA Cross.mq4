//+------------------------------------------------------------------+
//|                                                           SMC.mq4 
//|                                                                  +
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

 extern double Lots = 0.1; 
 extern int    LotsMultiplier=2;

 extern int    BreakEvenStart=25; 
 extern int    ProtectProfit = 5;
 extern int    TrailingStop = 25;
 extern int    TakeProfit = 100;
 extern double RiskPercent = 1;
 extern bool   PositionManagement=false;
 extern bool   OrderClosure=false;
 extern int    AllowedPositions=5;
 
 
 string  LastOrder;
 string  Trend;
 datetime BarTime;
//#####################################################################
int init()
{
//----
Trend = "NONE";

LastOrder= " ";


//----
   return(0);
  }
//#############################################################################

int start()
  {
   double SL,TP,Spread,MinDist,MaxRisk;

   string MaxRiskStr;

   bool   CloseLongs,CloseShorts;
   bool   Buy,Sell;

   int    total,ticket,err,tmp,cnt;
   int    NumberofPositions;
   int    BuyLots;

  if(Bars<100){Print("bars less than 100"); return(0); }
   
//################################################################################
//~~~~~~~~~~~~~~~~Miscellaneous setup stuff~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 MinDist=(MarketInfo(Symbol(),MODE_STOPLEVEL)*Point);
 Spread=(Ask-Bid);
 MaxRisk=(AccountFreeMargin()*RiskPercent/100)*Point;
 MaxRiskStr=DoubleToStr(MaxRisk,4);

//#############################################################################
//~~~~~~~~~~~~~~~~~~INDICATOR CALCULATIONS~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
double SMAP1,MMAP1,LMAP1,SMAP2,MMAP2,LMAP2;
 SMAP1=iMA(NULL,0,9,0,MODE_EMA,PRICE_CLOSE,1);
 SMAP2=iMA(NULL,0,9,0,MODE_EMA,PRICE_CLOSE,2);

 MMAP1=iMA(NULL,0,30,0,MODE_EMA,PRICE_CLOSE,1);
 MMAP2=iMA(NULL,0,30,0,MODE_EMA,PRICE_CLOSE,2);

double MomP1;
MomP1=iMomentum(NULL,0,21,PRICE_CLOSE,1);
  
//#############################################################################

tmp=0;
err=0;
tmp = ObjectGet("X"+Time[0],6);
err = GetLastError();
 if(err!=0) 
  {ObjectCreate("X"+Time[0],22,0,Time[0],High[1]);
   ObjectSet("X"+Time[0],14,2);
   ObjectSetText("X"+Time[0],TimeToStr(Time[0]));
   ObjectSet("X"+Time[0],6,Gray);
   }

   ObjectDelete("X"+Time[3]);

//#############################################################################

Comment("SMC BB RR & Breakout        Trend = ", Trend,"    ", Hour()," ",Minute()," ",Seconds(),
       "\n",
        "TRADING VALUES",
        "\n",
        "Spread ", Spread," MinDist ",MinDist," Max Risk ",MaxRiskStr,
        "\n",
        "Ask/Bid ",Ask," ",Bid,
        "\n",
        "SYSTEM PARAMETERS",
        "\n"
        );


//##############################################################################
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~         
//BUY and SELL rules:
 Buy = false;
 Sell =false;
 tmp=0;
 tmp=ObjectGet("X"+Time[0],6);  //add in tmp=gray check
if(tmp!=Pink)
{
//################################################################################
//~~~~~~~~~~~~BUY~~~~~~~~~~~~~~~~~~~~~~~~

  if(SMAP2<MMAP2 && SMAP1>MMAP1&& MomP1>100)
   {
    Buy=true;
    LastOrder = " Buy Breakout";
    ObjectSet("X"+Time[0],6,Pink);
    SL=LMAP1;
    TP=0;
   }
//################################################################################

//~~~~~~~~~~~SELL~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if(SMAP2>LMAP2 && SMAP1<LMAP1&&MomP1<100)
    {
    Sell=true;
    LastOrder = " Sell Breakout";
    ObjectSet("X"+Time[0],6,Pink);
    SL=LMAP1;
    TP=0;
   }
}//if bar indicator is Pink no new trade this bar
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//##################################################################################
//~~~~~~~~~~~~~~~~  POSITION MANAGEMENT  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//##################################################################################
//~~~ CLOSURE RULES  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CloseLongs=false;
CloseShorts=false;
if(SMAP1 < MMAP1) CloseLongs=true; OrderClosure=true;
if(SMAP1 > MMAP1) CloseShorts=true; OrderClosure=true;


//turn off MM
//PositionManagement = false;
//OrderClosure=false;
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if(PositionManagement == true)
{
tmp=0;
tmp = ObjectGet("X"+Time[0],6);
if(tmp==Gray)
{
ObjectSet("X"+Time[0],6,Blue);
total=OrdersTotal();
  if(total>0)
   { 
   for(cnt=0;cnt<total;cnt++)
    { 
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
     if(OrderType()==OP_BUY && OrderSymbol()==Symbol())    
     { 
//######################################################################
//  Long Stop Loss rules
//  note if TS is < BreakEvenStart then BES non functional
      SL = LMAP1;
//      if(Bid > OrderOpenPrice() + (BreakEvenStart*Point)) SL= OrderOpenPrice();             
//      if(Bid > OrderStopLoss() + (TrailingStop*Point)) SL= Bid-(TrailingStop*Point); 
//#######################################################################
      if(SL > OrderStopLoss())
      {OrderModify(OrderTicket(),OrderOpenPrice(),SL,OrderTakeProfit(),0,Orange);}
       }}}
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  total=OrdersTotal();
  if(total>0)
   { 
   for(cnt=0;cnt<total;cnt++)
    {
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
     if(OrderType()==OP_SELL && OrderSymbol()==Symbol())   
     {
//#################################################################################      
//  Short Stop Loss rules

      SL = LMAP1;
//      if(Ask < OrderOpenPrice() - (BreakEvenStart*Point)) SL= OrderOpenPrice();             
//      if(Ask < OrderStopLoss() - (TrailingStop*Point)) SL= Ask+(TrailingStop*Point); 
//####################################################################################
      if(SL != 0)
       {
       if(SL < OrderStopLoss() || OrderStopLoss()==0 )
        {OrderModify(OrderTicket(),OrderOpenPrice(),SL,OrderTakeProfit(),0,Orange);}
       }}}}
}
}
//##################################################################################
//~~~~~~~~~~~~~~~~  ORDER CLOSURE  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if(OrderClosure == true)
{

 tmp=0;
 tmp=ObjectGet("X"+Time[0],6);  
if(tmp==Gray)
{

//CLOSE LONG Entries
                                
   total=OrdersTotal();
   if(total>0)
    { 
    for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()==OP_BUY && OrderSymbol()==Symbol() && CloseLongs==true)
       
       {
        OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); 
   }}}
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//CLOSE SHORT ENTRIES: 
 
   total=OrdersTotal();
   if(total>0)
    { 
    for(cnt=0;cnt<total;cnt++)
     {  
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES); 
      if(OrderType()==OP_SELL && OrderSymbol()==Symbol() && CloseShorts==true)
      
       {
        OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); 
   }}}
}
}
//##########################################################################################
//~~~~~~~~~~~ END OF ORDER Closure routines & Stoploss changes  ~~~~~~~~~~~~~~~~~~~~
//##################################################################################
//~~~~~~~~~~~~START of NEW ORDERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   if(AccountFreeMargin()<(1000*Lots))
   {Print("Insufficient funds available. Free Margin = ", AccountFreeMargin());
    return(0);}
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
       if (NumberofPositions >=AllowedPositions) return(0);
   }
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//OPEN ORDER: LONG 
 if(Buy==true) 
  {Buy=false;

   ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,SL,TP,LastOrder,070177,0,Orange); //Bid-(Point*(MinDist+2))
   if(ticket>0)
    { 
     if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
      {Print("BUY order opened : ",OrderOpenPrice());
       Alert("Buy Order for ",Symbol());
       SendMail("Buy Order "+Symbol()+" "+Ask,SL);     
       }
     }
     else Print("Error opening BUY order : ",GetLastError()); 
     return(0); 
   } 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//OPEN ORDER: SHORT                                   
 if(Sell==true) 
  {Sell=false;

   ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,SL,TP,LastOrder,070177,0,Red);
   if(ticket>0)
    {
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
       {Print("SELL order opened : ",OrderOpenPrice());
        Alert("Sell Order for ",Symbol());
        SendMail("Sell Order "+Symbol()+" "+Bid,Bid); 
        }
      }
      else Print("Error opening SELL order : ",GetLastError()); 
      return(0); 
   }
//############               End of PROGRAM                  #########################   
   return(0);
}
//####################################################################################

