#property copyright "Copyright © 2006, Shahin Monsef & David Stanley"
#property link               "shahinonsef@hotmail.com xxdavidxsxx@yahoo.com"
//-----input parameters

extern double Lots=1;
extern double TrailingStop=35;
//+-------------------------------------+
int start()
{
int slip=3;
int TrailingStop=35;

double ao  =iAO (NULL,0,0);
double ao1 =iAO (NULL,0,1);

double cci =iCCI(NULL,0,55,PRICE_CLOSE,0);
double cci1=iCCI(NULL,0,55,PRICE_CLOSE,1);

double   PrevPrice=0, PrevHigh=0, PrevLow=0, Pivot=0, Price=0;
PrevPrice = iClose(NULL,PERIOD_D1,1);
PrevHigh  = iHigh(NULL,PERIOD_D1,1);
PrevLow   = iLow(NULL,PERIOD_D1,1);
Pivot = (PrevHigh + PrevLow + PrevPrice)/3;
Price = iClose(NULL,PERIOD_H1,1);

if(OrdersTotal()==0){
  if( ao>0 && cci>=0 && Ask>Pivot && (ao1<0 || cci1<=0 || Price<Pivot)) 
   OrderSend(Symbol(),OP_BUY ,.1,Ask,5,0,0,"",0,0,Green);
       
        
         
  if( ao<0 && cci<=0 && Ask<Pivot && (ao1>0 || cci1>=0 || Price>Pivot)) 
  OrderSend(Symbol(),OP_SELL,.1,Bid,5,0,0,"",0,0,Blue);
        
}else{
  for(int i=0;i<OrdersTotal();i++){
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
    if(OrderSymbol()!=Symbol()) continue;
    if(OrderType()==OP_BUY )
      if(ao<0 && cci<=0 && Ask<Pivot && (ao1>0 || cci1>=0 || Price>Pivot)) OrderClose(OrderTicket(),OrderLots(),Bid,4,Green);
    if(OrderType()==OP_SELL)
      if(ao>0 && cci>=0 && Ask>Pivot && (ao1<0 || cci1<=0 || Price<Pivot)) OrderClose(OrderTicket(),OrderLots(),Ask,4,Blue);
  }
}
}