//---- input parameters
extern int RISK=2;
extern double TrailingStop = 0;
extern double StopLoss = 50;
extern double TakeProfit = 50;
extern double Lots = 1;


//+------------------------------------------------------------------+
//| ASCTrend1sig |
//+------------------------------------------------------------------+
int start()
{
int i,shift;
int Counter,i1,value10,value11;
double val1,val2;
double value1,x1,x2;
double value2,value3;
double TrueCount,Range,AvgRange,MRO1,MRO2;
int cnt, ticket, total;

value10=3+RISK*2;
x1=67+RISK;
x2=33-RISK;
value11=value10;

shift=0;
Counter=0;
Range=0.0;
AvgRange=0.0;

for (Counter=shift; Counter<=shift+9; Counter++)
AvgRange=AvgRange+MathAbs(High[Counter]-Low[Counter]);

Range=AvgRange/10;
Counter=shift;
TrueCount=0;

while (Counter<1)
{
if (MathAbs(Close[Counter+1])>=Range*2.0)
{
TrueCount=TrueCount+1;
Counter=Counter+1;
}
}

if (TrueCount>=1)
MRO1=Counter;
else
MRO1=-1;

Counter=shift;
TrueCount=0;

while (Counter<1)
{
if (MathAbs(Close[Counter+3])-Close[Counter]>=Range*4.6)
{
TrueCount=TrueCount+1;
Counter=Counter+1;
}
}

if (TrueCount>=1)
MRO2=Counter;
else
MRO2=-1;

if (MRO1>-1) {value11=3;} else {value11=value10;}
if (MRO2>-1) {value11=4;} else {value11=value10;}


value2=MathAbs(iWPR(NULL,0,value11,shift));
val1=0;
val2=0;
value3=0;

if (value2<x2)
{
i1=1;
while (MathAbs(iWPR(NULL,0,value11,shift+i1))
>=x2&&MathAbs(iWPR(NULL,0,value11,shift+i1))<=x1)
{
i1=i1+1;
}
if (MathAbs(iWPR(NULL,0,value11,shift+i1))>x1)
{
value3=Low[shift]-Range*0.5;
val1=value3;
}
}
if (value2>x1)
{
i1=1;
while (MathAbs(iWPR(NULL,0,value11,shift+i1))
>=x2&&MathAbs(iWPR(NULL,0,value11,shift+i1))<=x1)
{
i1=i1+1;
}
if (MathAbs(iWPR(NULL,0,value11,shift+i1))<x2)
{
value3=High[shift]-Range*0.5;
val2=value3;
}
}

if (val1!=0)
val1=-val1;
else
val1=val2;

total=OrdersTotal();
if(total<1)
{
if(AccountFreeMargin()<(1000*Lots))
{
Print("We have no money. Free Margin = ", AccountFreeMargin());
return(0);
}
}

if (val1<0)
{
if(total==0)
{
ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,
Ask+TakeProfit*Point,0,0,Green);
return(0);
}
else
{
OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet);
ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,
Ask+TakeProfit*Point,0,0,Green);
return(0);
}
}

if (val1>0)
{
if(total==0)
{
ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,
Ask+TakeProfit*Point,0,0,Green);
return(0);
}
else
{
OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet);
ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,
Ask+TakeProfit*Point,0,0,Green);
return(0);
}
}
return(0);
}