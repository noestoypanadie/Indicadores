//+------------------------------------------------------------------+
//|                                      Hans123 testing version.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+

//---- input parameters
extern int       Start=0;
extern int       TakeProfit=14;
extern double    Lots=1;

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   //---- 
   int i,j,Ticket,StartTime,Bought=0,Sold=0,Closed;
   double Vol;
   string Text;
   
   //Count time
   StartTime= StrToTime(Start+":00");
   
   //Setup comment
   Text="HH"+Symbol();
   
   //Set orders
   if(CurTime()>= StartTime && CurTime()<StartTime+300){
      //Check Orders
      for (i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderComment()==Text && OrderType()==OP_BUY && OrderOpenTime()>CurTime()-3600) Bought++;
         if(OrderComment()==Text && OrderType()==OP_SELL && OrderOpenTime()>CurTime()-3600) Sold++;
      }
      if(Bought==0){ //no buy order
         if(GlobalVariableGet("Closed")==1) Vol=2*Lots; else Vol=Lots;
         Ticket=OrderSend(Symbol(),OP_BUY,Vol,Ask,3,0,Ask+TakeProfit*Point,Text,0,0,Green);
         PlaySound("expert.wav");
         Sleep(10000);
      }
      if(Sold==0){ //no sell order
         if(GlobalVariableGet("Closed")==2) Vol=2*Lots; else Vol=Lots;
         Ticket=OrderSend(Symbol(),OP_SELL,Vol,Bid,3,0,Bid-TakeProfit*Point,Text,0,0,Green);
         PlaySound("expert.wav");
         Sleep(10000);
      }
      if(GlobalVariableCheck("Closed")) GlobalVariableDel("Closed");
   }
   
   //Manage opened orders
   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      //close open position after 2 days
      if(OrderComment()==Text && CurTime()>=OrderOpenTime()+2*24*3600-300){
         if(OrderType()==OP_BUY){
            OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
            PlaySound("expert.wav");
            GlobalVariableSet("Closed",1);
            Sleep(10000);
         }
         if(OrderType()==OP_SELL){
            OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
            PlaySound("expert.wav");
            GlobalVariableSet("Closed",2);
            Sleep(10000);
         }
      }
   }
   
   return(0);
   }
//+------------------------------------------------------------------+