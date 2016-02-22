//+------------------------------------------------------------------+
//|                                                         HedgeHog |
//|                                     Copyright © 2006, Milan Volf |
//|                                                 milan@mmtop.info |
//+------------------------------------------------------------------+

//---- input parameters
extern int       Start=0;
extern int       Pips=14;
extern int       StopLoss=25;
extern int       TakeProfit=14;
extern int       PO_Mode=0; //Mode Pending Orders / 0-close when opposite is actived / 1-close at 23:55
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
   
   //Setup comment
   Text="HH"+Symbol();

   //Check orders if any of them is actived
   if(PO_Mode==0){
      for (i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderComment()==Text && OrderType()==OP_BUY) Bought++;
         if(OrderComment()==Text && OrderType()==OP_SELL) Sold++;
      }
      if(Bought==1 || Sold==1){ //delete opposite pending order when one is actived
         for (j=0;j<OrdersTotal();j++){
            OrderSelect(j,SELECT_BY_POS,MODE_TRADES);
            if(OrderComment()==Text && (OrderType()==OP_SELLSTOP || OrderType()==OP_BUYSTOP)){
               OrderDelete(OrderTicket());
               PlaySound("expert.wav");
               Sleep(10000);
            }
         }
      }
   }
   //send pending orders if there isn't any
   if(CurTime()>= StrToTime(Start+":00") && CurTime()<StrToTime(Start+":00")+300){
      //Check Orders
      for (i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderComment()==Text && OrderType()==OP_BUYSTOP && OrderOpenTime()>CurTime()-3600) Bought++;
         if(OrderComment()==Text && OrderType()==OP_SELLSTOP && OrderOpenTime()>CurTime()-3600) Sold++;
      }
      if(Bought==0){ //no buy order
         if(GlobalVariableGet("Closed")==1) Vol=2*Lots; else Vol=Lots;
         Ticket=OrderSend(Symbol(),OP_BUYSTOP,Vol,Ask+Pips*Point,3,Ask+(Pips-StopLoss)*Point,Ask+(Pips+TakeProfit)*Point,Text,0,0,Green);
         PlaySound("expert.wav");
         Sleep(10000);
      }
      if(Sold==0){ //no sell order
         if(GlobalVariableGet("Closed")==2) Vol=2*Lots; else Vol=Lots;
         OrderSend(Symbol(),OP_SELLSTOP,Vol,Bid-Pips*Point,3,Bid+(StopLoss-Pips)*Point,Bid-(Pips+TakeProfit)*Point,Text,0,0,Green);
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
      if(PO_Mode==1){
         if(CurTime()>StrToTime("23:55")){
            if(OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP){
               OrderDelete(OrderTicket());
               PlaySound("expert.wav");
               GlobalVariableSet("Closed",1);
               Sleep(10000);
            }
         }
      }
   }
   
   return(0);
   }
//+------------------------------------------------------------------+