//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
#property copyright ""
#property link      ""

//---- input parameters
extern double    Lots=1;
extern int       ChartHourStart=7;
extern int       ChartMinuteStart=30;
extern int       ChartHourEnd=12;
extern int       ChartMinuteEnd=30;
extern int       TakeProfit=10;
extern int       StopLoss=20;
extern int       Slip=5;
extern int       ExpertID=253646;

double Opentrades;
int cnt,cnt2,OpenPosition,notouchbar,PendingOrderTicket,OpenOrderTicket; 
int StartTime,Endtime;
string ExpertMode;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
if (iMA(Symbol(),0,10,0,MODE_LWMA,PRICE_CLOSE,0)<iMA(Symbol(),0,20,0,MODE_SMA,PRICE_CLOSE,0))
   ExpertMode="WaitingForCrossUp"; else ExpertMode="WaitingForCrossDown";

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {

if ( ! IsTesting() ) Comment(" Tick no. ", iVolume(NULL,0,0));


//Check if we're in trade hours. If not, exit and let SL/TP take care of any trades still open.
if (ChartMinuteStart<10) StartTime=StrToTime(ChartHourStart+":0"+ChartMinuteStart); else StartTime=StrToTime(ChartHourStart+":"+ChartMinuteStart);
if (ChartMinuteEnd<10) Endtime=StrToTime(ChartHourEnd+":0"+ChartMinuteEnd); else Endtime=StrToTime(ChartHourEnd+":"+ChartMinuteEnd);
if (CurTime()<StartTime || CurTime()>Endtime)
   {
   ExpertMode="Normal";
   return(0);
   }


Opentrades=0;
for (cnt=0;cnt<OrdersTotal();cnt++) 
   {
   if ( OrderSelect (cnt, SELECT_BY_POS) == false )  continue;
   if ( OrderSymbol()==Symbol() && OrderMagicNumber()==ExpertID) 
      {
      Opentrades=Opentrades+1;
      OpenOrderTicket=OrderTicket();
      }
   }

if (Opentrades>0) 
   {
      if ( OrderSelect (OpenOrderTicket, SELECT_BY_TICKET) == false )  return(0); //Should never be the case...
   }


if (ExpertMode=="ExpectingOpenedLong")
   {
   if (Opentrades>0 && OrderType()==OP_BUY)
      {
      ExpertMode="WaitingForCrossDown";
      return(0);
      }
      else ExpertMode="Normal"; //If we were expecting an opened postion, set to normal so opening position will be attempted again
   } 
 else if (ExpertMode=="ExpectingOpenedShort")
   {
   if (Opentrades>0 && OrderType()==OP_SELL)
      {
      ExpertMode="WaitingForCrossUp";
      return(0);
      }
      else ExpertMode="Normal"; //If we were expecting an opened postion, set to normal so opening position will be attempted again
   } 
 else if (ExpertMode=="WaitingForCrossUp")
   {
   if (iMA(Symbol(),0,10,0,MODE_LWMA,PRICE_CLOSE,1)>iMA(Symbol(),0,20,0,MODE_SMA,PRICE_CLOSE,1) && iMA(Symbol(),0,10,0,MODE_LWMA,PRICE_CLOSE,2)<=iMA(Symbol(),0,20,0,MODE_SMA,PRICE_CLOSE,2))
      {
      ExpertMode="Normal";
      }
   }
 else if (ExpertMode=="WaitingForCrossDown")
   {   
   if (iMA(Symbol(),0,10,0,MODE_LWMA,PRICE_CLOSE,1)<iMA(Symbol(),0,20,0,MODE_SMA,PRICE_CLOSE,1) && iMA(Symbol(),0,10,0,MODE_LWMA,PRICE_CLOSE,2)>=iMA(Symbol(),0,20,0,MODE_SMA,PRICE_CLOSE,2))
      {
      ExpertMode="Normal";
      }
   }
 else if (ExpertMode != "Normal") {Alert("Unrecognised expert mode: ",ExpertMode);}


   
//If flag hasn't been reset to normal by the above ifs, then exit.
if (ExpertMode != "Normal") return(0);


//And finally, check for entry/reverse conditions
if ( 1 == 2 //trade conditions here
   )
   {
   if (Opentrades==0)
      {
      OrderSend(Symbol(),OP_BUY,Lots,Ask,Slip,Ask-StopLoss*Point,Ask+TakeProfit*Point,"",ExpertID,0,Blue);
      ExpertMode="ExpectingOpenedLong"; //Use a flag method rather than MT4's broken trade error detection
      return(0);
      }
     else
      {
      OrderClose(OrderTicket(),OrderLots(),Ask,Slip,Yellow);
      return(0); //Wait with reverse till the next tick to be sure position is closed successfully
      }
   }
   
   
if ( 1 == 2 //trade conditions here
   )
   {
   
   if (Opentrades==0)
      {
      OrderSend(Symbol(),OP_SELL,Lots,Bid,Slip,Bid+StopLoss*Point,Bid-TakeProfit*Point,"",ExpertID,0,Red);
      ExpertMode="ExpectingOpenedShort"; //Use a flag method rather than MT4's broken trade error detection
      return(0);
      }
     else
      {
      OrderClose(OrderTicket(),OrderLots(),Bid,Slip,White); 
      return(0); //Wait with reverse till the next tick to be sure position is closed successfully
      }
   }
  

   return(0);
  }



