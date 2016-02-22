//+------------------------------------------------------------------+
//|                                                  iFxOverEasy.mq4 |
//|                                  Copyright © 2005, Shahin Monsef |
//|                                         shahinmonsef@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Shahin Monsef"
#property link      "shahinonsef@hotmail.com"
extern int StopLoss=15,TakeProfit=150,TrailingStop=10;
int   init(){return(0);}
int deinit(){return(0);}
int start(){
double UL,DL;
if(Bars<20) return(0);
if(OrdersTotal()==0){
  if(AccountFreeMargin()<1000) return;
  iCustom(NULL,0,"SHI_Channel",0,0);
  double MIDL2=ObjectGet("MIDL",OBJPROP_PRICE2);
  double MIDL1=ObjectGet("MIDL",OBJPROP_PRICE1);
  double TL1  =ObjectGet("TL1" ,OBJPROP_PRICE2);
  double TL2  =ObjectGet("TL2" ,OBJPROP_PRICE2);
  if( TL1>TL2){ UL=TL1; DL=TL2; }else{ UL=TL2; DL=TL1; }
  double i_Trend1 =iCustom(NULL,0,"i_Trend" ,0,0);
  double i_Trend2 =iCustom(NULL,0,"i_Trend" ,1,0);
  double Laguerre1=iCustom(NULL,0,"Laguerre",0,0);
  double Juice1   =iCustom(NULL,0,"Juice"   ,0,0);
  double PAsctrnd1=iCustom(NULL,0,"PerkyAsctrend1",0,0);
  double PAsctrnd2=iCustom(NULL,0,"PerkyAsctrend1",1,0);
  if(MIDL2>MIDL1 && Ask<UL && Ask>DL && UL-DL>40*Point && i_Trend1>i_Trend2 && Laguerre1>0.15 && Juice1>0.0 && PAsctrnd1>0.0){
//    if( iMA(NULL,0,25,0,MODE_LWMA,PRICE_TYPICAL,0)<iMA(NULL,0,25,0,MODE_LWMA,PRICE_TYPICAL,2)) Print("Bad long");
//    Print( "Laguerre1=",Laguerre1,",Juice=",Juice1,/*",Midl2=",MIDL2,",Midl1=",MIDL1,*/",TL1=",TL1,",TL2=",TL2);
    OrderSend(Symbol(),OP_BUY ,1,Ask,5,Ask-StopLoss*Point,Ask+TakeProfit*Point,"",0,0,YellowGreen);
  }
  if(MIDL2<MIDL1 && Bid<UL && Bid>DL && UL-DL>40*Point && i_Trend1<i_Trend2 && Laguerre1<0.75 && Juice1>0.0 && PAsctrnd2>0.0){
//    if( iMA(NULL,0,25,0,MODE_LWMA,PRICE_TYPICAL,0)>iMA(NULL,0,25,0,MODE_LWMA,PRICE_TYPICAL,2)) Print("Bad short");
//    Print( "Laguerre1=",Laguerre1,",Juice=",Juice1,/*",Midl2=",MIDL2,",Midl1=",MIDL1,*/",TL1=",TL1,",TL2=",TL2);
    OrderSend(Symbol(),OP_SELL,1,Bid,5,Bid+StopLoss*Point,Bid-TakeProfit*Point,"",0,0,LightBlue);
  }
}else{
for( int i=0; i<OrdersTotal();i++){	
  if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
  if (OrderSymbol()!=Symbol()) continue;
  switch (OrderType()){
    case OP_BUY:
      if (TrailingStop && Bid-OrderOpenPrice()>TrailingStop*Point && OrderStopLoss()<Bid-TrailingStop*Point)
        OrderModify(OrderTicket(),0,Bid-TrailingStop*Point,OrderTakeProfit(),0,YellowGreen);
    break;
    case OP_SELL:
      if (TrailingStop && OrderOpenPrice()-Ask>Point*TrailingStop && (!OrderStopLoss() || OrderStopLoss()>Ask+Point*TrailingStop))
        OrderModify(OrderTicket(),0,Ask+TrailingStop*Point,OrderTakeProfit(),0,LightBlue);
    break;
  }
}
}
}