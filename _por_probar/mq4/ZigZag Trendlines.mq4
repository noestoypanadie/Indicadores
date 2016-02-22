//+------------------------------------------------------------------+
//|                                            ZigZag Trendlines.mq4 |
//|                 Copyright © 2005, tageiger aka fxid10t@yahoo.com |
//|                MetaTrader_Experts_and_Indicators@yahoogroups.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, tageiger aka fxid10t@yahoo.com"
#property link      "MetaTrader_Experts_and_Indicators@yahoogroups.com"

extern int  ExtDepth    =13;

int init(){return(0);}
int deinit(){return(0);}
int start(){

   double low.1,high.1;
   low.1=Low[Lowest(Symbol(),0,MODE_LOW,ExtDepth,(Bars-ExtDepth))];
   Print(low.1);



return(0);
}//end start

