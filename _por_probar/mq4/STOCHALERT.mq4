//+------------------------------------------------------------------+
//|                                                    STOCHALERT.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

//---- input parameters
extern int       kperiodstoch=5;
extern int       dperiodstoch=3;
extern int       slowingstoch=3;
double Stoch;
double Stochsig;


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+

 static datetime lasttime = 0; 
 
if (lasttime == Time[0])
   return(0);
lasttime = Time[0];

int  start()
  {
Stoch=iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,0);
Stochsig=iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
     
   if(Stoch>85)         
      {
      SendMail("STOCH>85 GET READY TO SELL",Symbol());
      Alert ("STOCH>85 GET READY TO SELL",Symbol());         
      }   
   if(Stoch<15)
         
      {
      SendMail("STOCH<15 GET READY TO BUY",Symbol());
      Alert ("STOCH<15 <GET READY TO BUY",Symbol());    
      }   
 }
  {
SendMail("TEST FX Alert", "OPEN " +Open[0] + " LOW " +Low[0] + " HIGH " + High[0] + " BID " +Bid);

Print(" Daily Email Alert Sent "); 
}

   return(0);
 