//+------------------------------------------------------------------+
//|                           Copyright 2005, Gordago Software Corp. |
//|                                          http://www.gordago.com/ |
//+------------------------------------------------------------------+

#property copyright "Copyright 2005, Gordago Software Corp."
#property link      "http://www.gordago.com"

extern double lStopLoss = 20;
extern double sStopLoss = 20;
extern double Lots = 0.1;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start(){
   int cnt, ticket;
   if(Bars<100){
      Print("bars less than 100");
      return(0);
   }
   if(lStopLoss<10){
      Print("StopLoss less than 10");
      return(0);
   }
   if(sStopLoss<10){
      Print("StopLoss less than 10");
      return(0);
   }

   double diDeMarker0=iDeMarker(NULL,15,13,0);
   double diDeMarker1=iDeMarker(NULL,15,13,1);
   double diDeMarker2=iDeMarker(NULL,15,13,0);
   double diDeMarker3=iDeMarker(NULL,15,13,1);
   double diDeMarker4=iDeMarker(NULL,15,13,0);
   double diDeMarker5=iDeMarker(NULL,15,13,0);

   int total=OrdersTotal();
   if(total<1){
      if(AccountFreeMargin()<(1000*Lots)){
         Print("We have no money. Free Margin = ", AccountFreeMargin());
         return(0);
      }

      if ((diDeMarker0>0.3 && diDeMarker1<==0.3)){
         ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-lStopLoss*Point,0, "gordago simple",16384,0,Green);
         if(ticket>0){
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
         }
         else Print("Error opening BUY order : ",GetLastError());
         return(0);
      }

      if ((diDeMarker2<0.7 && diDeMarker3>==0.7)){
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+sStopLoss*Point,0,"gordago sample",16384,0,Red);
         if(ticket>0) {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
         }
         else Print("Error opening SELL order : ",GetLastError());
         return(0);
      }
   }
   for(cnt=0;cnt<total;cnt++) {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol()) {
         if(OrderType()==OP_BUY){

         if ((diDeMarker4>0.7)){
            OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet);
            return(0);
         }
         }else{

         if ((diDeMarker5<0.3)){
            OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet);
            return(0);
         }
         }
      }
   }
}
