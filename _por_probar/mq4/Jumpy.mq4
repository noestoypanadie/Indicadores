//+------------------------------------------------------------------+
//|                                                        Jumpy.mq4 |
//|                                                      Version 1.0 |
//|              Copyright © 2005, Alan Gruskoff, Performant Systems |
//|                               http://performantsystems.com/jumpy |
//|                             Contact Email gruskoff@earthlink.net |
//|                                                                  |
//| No representation is being made that the Jumpy Expert Alert      |
//| plug-in (Jumpy) will guarantee profits or not result in losses   |
//| from trading or trade opportunities that may have been missed.   |
//| Nothing related to Jumpy should be construed as providing a trade|
//| recommendation or the giving of investment advice.  The purchase,|
//| sale or advice regarding a security can only be performed by a   |
//| licensed Broker/Dealer and/or Registered Investment Advisor.     |
//| Neither Performant Systems nor Alan Gruskoff are a registered    |
//| Broker/Dealer or Investment Advisor in any State in the USA.     |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Alan Gruskoff, Performant Systems"
#property link      "http://performantsystems.com/jumpy"
#property show_confirm

#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>

//---- initialize my global variables
double   BidVar;
datetime InitTime;
datetime LastTime;
double   LastPrice;
datetime CurrentTime;
int      ElapsedMins;
int      ElapsedSecs;
int      LastAlertMins;
int      AlertMins = 5;    // the number of minutes between alerts
int      Idx;
int      Diff;
string   Direction;
double   PriceMin[60];
int      PriceMinIdx;
string   AlertCaption = "Jumpy Expert Advisor";
int      Response;
int      Factor = 10000;
string   AlertMsg;
string   OutVal;
int      Places;
string   LastPriceStr;
string   BidVarStr;

//---- User Interface input parameters
extern int       Threshold_Pips=8;           // minimum movement to alert
extern int       Threshold_Mins=15;          // how far back to look 
extern string    Alert_By_Email="Yes";       // only sends Email if = Yes, instead of popup message box
extern int       Alert_Pause_Mins=10;        // the number of minutes between alerts
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() 
{
  ArrayInitialize(PriceMin,0);
  InitTime = CurTime(); LastTime = InitTime;
  Places = Digits;
  if (Places != 4) { Factor = 100; }
  if (Threshold_Mins > 60) {
    Threshold_Mins = 60;
    AlertMsg = "Threshold Minutes now set to Maximum 60 Minutes";  
    Response = MessageBox(AlertMsg, AlertCaption, MB_OK|MB_ICONEXCLAMATION);         
  }
  if (Threshold_Mins < 5) {
    Threshold_Mins = 5;
    AlertMsg = "Threshold Minutes now set to Minimum 5 Minutes";  
    Response = MessageBox(AlertMsg, AlertCaption, MB_OK|MB_ICONEXCLAMATION);         
  }
  if (Threshold_Pips < 3) {
    Threshold_Pips = 3;
    AlertMsg = "Threshold Pips now set to Minimum 3 Pips";  
    Response = MessageBox(AlertMsg, AlertCaption, MB_OK|MB_ICONEXCLAMATION);         
  }
 //
 //  loop to here as in real time
 //
    while(True) {
    ElapsedSecs = (CurTime() - LastTime);
    if (ElapsedSecs >= 60) {
      LastTime  = CurTime();
      ElapsedMins = ElapsedMins + 1;      
      PriceMinIdx = PriceMinIdx + 1;
      if (PriceMinIdx > 60) { PriceMinIdx = 1; }
      BidVar = MarketInfo(Symbol(),MODE_BID);
      PriceMin[PriceMinIdx] = BidVar;      
      if (ElapsedMins > Threshold_Mins) {
        Idx = PriceMinIdx - Threshold_Mins;
        if (Idx < 1) { Idx = 60 - Threshold_Mins + PriceMinIdx; }
        LastPrice = PriceMin[Idx];
        if (LastPrice != 0) {
          Direction = "Same";
          if (BidVar > LastPrice) { Direction = "Up"; }
          if (BidVar < LastPrice) { Direction = "Down"; }
          Diff = MathAbs((BidVar * Factor) - (LastPrice* Factor));
          LastPriceStr = DoubleToStr(LastPrice,Places);
          BidVarStr    = DoubleToStr(BidVar,Places);
          if (Diff >= Threshold_Pips) {
            Print(" Previous Price= ", LastPriceStr,"  Current Price= ",BidVarStr,"  Direction= ",Direction," ",Diff," Pips");          
            if (LastAlertMins <= 0) {
              AlertMsg = Symbol() + " " + Direction+" " + Diff + " Pips from " + LastPriceStr; 
              if (Alert_By_Email == "Yes") {
                SendMail("Jumpy Alert", AlertMsg);
              } else {
                MessageBox(AlertMsg, AlertCaption, MB_OK|MB_ICONEXCLAMATION);
              }
              LastAlertMins = Alert_Pause_Mins + 1;
            }
          }
        }
        LastAlertMins = LastAlertMins - 1;
      }
    }
   }
   return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
   return(0);
}
//+------------------------------------------------------------------+
//| expert start function, called on price tick                      |
//+------------------------------------------------------------------+
int start()
{
   return(0);
}

