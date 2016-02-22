int start()
{
// double tenkan, kijun, tenkan2, kijun2; //you don't need these...
// double senkouspanA, senkouspanB;       //you don't need these...


double tenkan=iIchimoku(Symbol(),0,9,26,52,MODE_TENKANSEN,1);
double kijun=iIchimoku(Symbol(),0,9,26,52,MODE_KIJUNSEN,1);
double tenkan2=iIchimoku(Symbol(),0,9,26,52,MODE_TENKANSEN,2);
double kijun2=iIchimoku(Symbol(),0,9,26,52,MODE_KIJUNSEN,2);
double senkouspanA=iIchimoku(Symbol(),0,9,26,52,MODE_SENKOUSPANA,1);
double senkouspanB=iIchimoku(Symbol(),0,9,26,52,MODE_SENKOUSPANB,1);

// conditions for opening long position

if (OrdersTotal()==0)
{
if (tenkan2<kijun2)
{
if (tenkan>kijun)
{
if (senkouspanA>senkouspanB)
{
if (Ask>senkouspanA)
{
OrderSend(Symbol(),OP_BUY,6,Ask,0,(senkouspanB-10*Point),0,0,0,0,1);
return(0);
{
if (senkouspanA>Ask>senkouspanB)
{
OrderSend(Symbol(),OP_BUY,3,Ask,0,(senkouspanB-10*Point),0,0,0,0,1);
return(0);
{
if (senkouspanB>senkouspanA)
{
OrderSend(Symbol(),OP_BUY,6,Ask,0,(senkouspanA-10*Point),0,0,0,0,1);
return(0);
{
if (senkouspanB>Ask>senkouspanA)
{
OrderSend(Symbol(),OP_BUY,3,Ask,0,(senkouspanA-10*Point),0,0,0,0,1);
return(0);
{
if (Ask<senkouspanA)
{
if (Ask<senkouspanB)
{
OrderSend(Symbol(),OP_BUY,1,Ask,0,(Bid-100*Point),0,0,0,0,1);
return(0);
}}}}}}}}}}}}}}

// condition for closing long position

if (OrdersTotal()==1)
{
if (OrderType()==OP_BUY)
{
if (tenkan2>kijun2) 
{
if (tenkan<kijun)
{
OrderClose(OrderTicket(),OrderLots(),Bid,0,1);
return(0);
}}}}

// conditions for opening up short position

if (OrdersTotal()==0)
{
if (tenkan2>kijun2)
{
if (tenkan<kijun)
{
if (senkouspanA<senkouspanB)
{
if (Bid<senkouspanA)
{
OrderSend(Symbol(),OP_SELL,6,Bid,0,(senkouspanB+10*Point),0,0,0,0,1);
return(0);
{
if (senkouspanB>Bid>senkouspanA)
{
OrderSend(Symbol(),OP_SELL,3,Bid,0,(senkouspanB+10*Point),0,0,0,0,1);
return(0);
{
if (senkouspanB<senkouspanA)
{
if (Bid<senkouspanB)
{
OrderSend(Symbol(),OP_SELL,6,Bid,0,(senkouspanA+10*Point),0,0,0,0,1);
return(0);
{
if (senkouspanA>Bid>senkouspanB)
{
OrderSend(Symbol(),OP_SELL,3,Bid,0,(senkouspanA+10*Point),0,0,0,0,1);
return(0);
{
if (Bid>senkouspanA)
{
if (Bid>senkouspanB)
{
OrderSend(Symbol(),OP_SELL,1,Bid,0,(Ask+100*Point),0,0,0,0,1);
return(0);
}}}}}}}}}}}}}}}

// condition for closing short position

if (OrdersTotal()==1)
{
if (OrderType()==OP_SELL)
{
if (tenkan2<kijun2) 
{
if (tenkan>kijun)
{
OrderClose(OrderTicket(),OrderLots(),Bid,0,1);
return(0);
}}}}
}

