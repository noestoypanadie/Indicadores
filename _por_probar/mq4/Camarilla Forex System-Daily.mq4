#include <stdlib.mqh>
//+------------------------------------------------------------------+
//|                                 Camarilla Forex System-Daily.mq4 |
//|                                                                  |
//|                                                                  |
//|                                        Converted by Mql2Mq4 v1.1 |
//|                                            http://yousky.free.fr |
//|                                    Copyright © 2006, Yousky Soft |
//+------------------------------------------------------------------+

#property copyright " Copyright © 2005 FAB4x, Alejandro Galindo & KillerKhan"
#property link      ""


//+------------------------------------------------------------------+
//| Common External variables                                        |
//+------------------------------------------------------------------+
extern double Lots = 1.00;
extern double StopLoss = 0.00;
extern double TakeProfit = 0.00;
extern double TrailingStop = 0.00;

//+------------------------------------------------------------------+
//| External variables                                               |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Special Convertion Functions                                     |
//+------------------------------------------------------------------+

int LastTradeTime;

//+------------------------------------------------------------------+
//| End                                                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+

int init()
{
   return(0);
}
int start()
{
//+------------------------------------------------------------------+
//| Local variables                                                  |
//+------------------------------------------------------------------+
double Q = 0;
double H4 = 0;
double H3 = 0;
double L4 = 0;
double L3 = 0;
double L1 = 0;
double H1 = 0;
string vQ = "";
string vH4 = "";
string vH3 = "";
string vL4 = "";
string vL3 = "";
string vL1 = "";
string vH1 = "";

//+-------------------------------------------------------------------+
//|                                Made/Modified by Alejandro Galindo |
//|                                                                   |
//|       				  If this work/modification is helpful to you |
//|                      send me a PayPal donation to ag@elcactus.com |
//|                                         any help is apreciated :) |
//|                                                           Thanks. |
//+-------------------------------------------------------------------+
/*[[
	Name := CAMARILLA SYSTEM DAILY
	Author := Copyright © 2005 FAB4x, Alejandro Galindo & KillerKhan
	Lots := 1.00
	Stop Loss := 0
	Take Profit := 0
	Trailing Stop := 0
]]*/


















if( Period() != 1440 ) 
{
	Comment("This expert is for Daily Charts Only!!!");
	return(0);
}

if( TimeYear(Time)<2006 ) return(0);  
if( CurTime() - LastTradeTime < 5 ) return(0);

Q=(High[1]-Low[1]);
H4 =(Q*0.55)+Close[1];
H3 =(Q*0.27)+Close[1];
L3 =Close[1]-(Q*0.27);	
L4 =Close[1]-(Q*0.55);
L1 =Close[1]-(Q*0.09);
H1 =(Q*0.09)+Close[1];

vQ = "[" + Symbol() + "] Q";
vH4 = "[" + Symbol() + "] H4";
vH3 = "[" + Symbol() + "] H3";
vL3 = "[" + Symbol() + "] L3";
vL4 = "[" + Symbol() + "] L4";
vL1 = "[" + Symbol() + "] L1";
vH1 = "[" + Symbol() + "] H1";

GlobalVariableSet(vQ,Q);
GlobalVariableSet(vH4,H4);
GlobalVariableSet(vH3,H3);
GlobalVariableSet(vL4,L4);
GlobalVariableSet(vL3,L3);
GlobalVariableSet(vL1,L1);
GlobalVariableSet(vH1,H1);

return(0);  return(0);
}