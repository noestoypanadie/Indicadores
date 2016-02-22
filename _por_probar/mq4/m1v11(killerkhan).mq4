//+------------------------------------------------------------------+
//|                                            m1v11(killerkhan).mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern int  slippage       =1;

int         BreakPeriod1   =27;
int         NumberOfBars1  =2700;
int         CountBars1,CurrentBar1,CurrentTrend1;
double      Value11,Value21,LowestBreak1,HighestBreak1;

int         BreakPeriod2   =9;
int         NumberOfBars2  =2700;
int         CountBars2,CurrentBar2,CurrentTrend2;
double      Value12,Value22,LowestBreak2,HighestBreak2;

datetime    vTime;
string      Period1Signal,Period2Signal;

int init(){return(0);}
int deinit(){return(0);}
int start(){


return(0);}//end start

/*

///////////////////////////////////////////////
// Main Script
///////////////////////////////////////////////
if CurTime - LastTradeTime < 5 then Exit;

if Period != 1 then
{
	Comment("This expert is for M1 Chart Only!!!");
	Exit;
};

If vTime != Time[0] then
{
///////////////////////////////////////////////
// Look for direction of Currency 1
///////////////////////////////////////////////
SetLoopCount(0);
If Bars > NumberOfBars1
then CountBars1 = NumberOfBars1
else CountBars1 = Bars;

For CurrentBar1 = CountBars1-1 Downto 1 Begin
	LowestBreak1 = Low[Lowest(MODE_LOW, CurrentBar1 + BreakPeriod1, BreakPeriod1)];
	HighestBreak1 = High[Highest(MODE_HIGH, CurrentBar1 + BreakPeriod1, BreakPeriod1)];
	
	If Close[CurrentBar1] < LowestBreak1 Then 
	{
		Value11 = Low[CurrentBar1];
		Value21 = High[CurrentBar1];
		CurrentTrend1 = -1;
	}
	Else If Close[CurrentBar1] > HighestBreak1 Then 
	{
		Value11 = High[CurrentBar1];
		Value21 = Low[CurrentBar1];
		CurrentTrend1 = 1;
	}
	Else 
	{
		If (CurrentTrend1 > 0) Then 
		{
			Value11 = High[CurrentBar1];
			Value21 = Low[CurrentBar1];
		}
		Else 
		{
			Value11 = Low[CurrentBar1];
			Value21 = High[CurrentBar1];
		}
	};
End;

///////////////////////////////////////////////
// Look for direction of Currency 2
///////////////////////////////////////////////
SetLoopCount(0);
If Bars > NumberOfBars2
then CountBars2 = NumberOfBars2
else CountBars2 = Bars;

For CurrentBar2 = CountBars2-1 Downto 1 Begin
	LowestBreak2 = Low[Lowest(MODE_LOW, CurrentBar2 + BreakPeriod2, BreakPeriod2)];
	HighestBreak2 = High[Highest(MODE_HIGH, CurrentBar2 + BreakPeriod2, BreakPeriod2)];
	
	If Close[CurrentBar2] < LowestBreak2 Then 
	{
		Value12 = Low[CurrentBar2];
		Value22 = High[CurrentBar2];
		CurrentTrend2 = -1;
	}
	Else If Close[CurrentBar2] > HighestBreak2 Then 
	{
		Value12 = High[CurrentBar2];
		Value22 = Low[CurrentBar2];
		CurrentTrend2 = 1;
	}
	Else 
	{
		If (CurrentTrend2 > 0) Then 
		{
			Value12 = High[CurrentBar2];
			Value22 = Low[CurrentBar2];
		}
		Else 
		{
			Value12 = Low[CurrentBar2];
			Value22 = High[CurrentBar2];
		}
	};
End;

};

///////////////////////////////////////////////
// Set Variables
///////////////////////////////////////////////
vSlippage = Slippage * Point;

///////////////////////////////////////////////
// Count Trades for current Symbol
///////////////////////////////////////////////
Opentrades = 0;
for i = 1 to TotalTrades 
{
	If OrderValue(i,Val_Symbol) == Symbol then
	{
		Opentrades++;
	};
};

///////////////////////////////////////////////
// Trailing Stop and Closing Trades
///////////////////////////////////////////////
if Opentrades != 0 then
{
	for i=1 to TotalTrades
 	{
   		If OrderValue(i,VAL_TYPE) == OP_BUY and OrderValue(i,VAL_SYMBOL) == Symbol then
     	{
     		if vTime != Time[0] and Value22 > Value12 then
     		{
       			CloseOrder(OrderValue(i,VAL_TICKET),Ord(i,VAL_LOTS),Ord(i,VAL_CLOSEPRICE),vSlippage,Teal);
       			Exit;
       		};
       		If vTime != Time[0] and Value12 > Value22 then
       		{
       			vTime = Time[0];
       		};
    	};
    	If OrderValue(i,VAL_TYPE) == OP_SELL and OrderValue(i,VAL_SYMBOL) == Symbol then
     	{
     		If vTime != Time[0] and Value12 > Value22 then
     		{
     			CloseOrder(OrderValue(i,VAL_TICKET),Ord(i,VAL_LOTS),Ord(i,VAL_CLOSEPRICE),vSlippage,Pink);
       			Exit;
       		};
       		if vTime != Time[0] and Value22 > Value12 then
     		{
       			vTime = Time[0];
       		};     		
    	};
    };
};

///////////////////////////////////////////////
// Open New Trades
///////////////////////////////////////////////
if Opentrades == 0 and vTime != Time[0] then 
{	
	if vTime == 0 then
	{
		vTime = Time[0];
		Exit;
	};
	If Value11 > Value21 and Value12 > Value22 then
	{
		If FreeMargin < 100 then Exit;
      	SetOrder(OP_BUY,Lots,Ask,vSlippage,ask-stoploss*point,ask+takeprofit*point,Blue);
      	vTime = Time[0];
		Exit;
	};
	If Value21 > Value11 and Value22 > Value12 then
	{
		If FreeMargin < 100 then Exit;
		SetOrder(OP_SELL,Lots,Bid,vSlippage,bid+stoploss*point,bid-takeprofit*point,Red);
		vTime = Time[0];
		Exit;
	};
};

///////////////////////////////////////////////
// Comments for testing purposes only
///////////////////////////////////////////////
If Value11 > Value21 then Period1Signal = "BUY"
else If Value21 > Value11 then Period1Signal = "SELL"
else Period1Signal = "NONE";

If Value12 > Value22 then Period2Signal = "BUY"
else If Value22 > Value12 then Period2Signal = "SELL"
else Period2Signal = "NONE";

Comment("Period1Signal: ",Period1Signal,"\nPeriod2Signal: ",Period1Signal);

