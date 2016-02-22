//+------------------------------------------------------------------+
//|                                                         HedgeHog |
//|                                     Copyright © 2006, Milan Volf |
//|                                                 milan@mmtop.info |
//+------------------------------------------------------------------+

//---- input parameters
extern int       StartHr=0;
extern int       StartMin=30;
extern int       StopLoss=75;
extern int       TakeProfit=20;
extern double    Lots=1;
extern int       DaysOfClose=2;   // how many days before closing open orders
extern int       TS_Mode=1; // use trailing stop   0=NO 1=YES 2=TS Only
extern int       TS_Trigger=5;
extern int       TS_Sensitivity=5;
int              BuySell=0; // 0= Both BUY/SELL - 1=Buy ONLY - 2=Sell ONLY
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
   StartTime= StrToTime(StartHr+":"+StartMin);
   
   //Setup comment
   Text="HH"+Symbol();
   
   // Update Trailing Stop
      for (i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      
         if(OrderComment()==Text)
         {
            int ticket = OrderTicket();
            if (TS_Mode == 1)
            {
               ControlTrailingStop(ticket);
            }
            if (TS_Mode == 2 && (OrderOpenPrice() < Ask  || OrderOpenPrice() > Bid))
            {
               ControlTrailingStop(ticket);
            }            
         }
      }
   
   
   
   //Set orders
   if(CurTime()>= StartTime && CurTime()<StartTime+300){
      //Check Orders
      for (i=0;i<OrdersTotal();i++){
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderComment()==Text && OrderType()==OP_BUY && OrderOpenTime()>CurTime()-3600) Bought++;
         if(OrderComment()==Text && OrderType()==OP_SELL && OrderOpenTime()>CurTime()-3600) Sold++;
      }

      double iiSar = iSAR(NULL,PERIOD_M5,0.02,0.2,0);
      if(Bought==0 && (iiSar < Bid)){ //no buy order
         Vol=Lots;
         //Ticket=OrderSend(Symbol(),OP_BUY,Vol,Ask,3,Ask-StopLoss*Point,0,Text,0,0,Green);
         //Ticket=OrderSend(Symbol(),OP_BUYLIMIT,Vol,Ask-TakeProfit*Point,3,Ask-(StopLoss+TakeProfit)*Point,Ask+TakeProfit*Point,Text,0,0,Green);
         Ticket=OrderSend(Symbol(),OP_BUY,Vol,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,Text,0,0,Green);
         PlaySound("expert.wav");
         Sleep(10000);
      }
      
      if(Sold==0  && (iiSar > Bid)){ //no sell order
         Vol=Lots;
         //Ticket=OrderSend(Symbol(),OP_SELL,Vol,Bid,3,Bid+StopLoss*Point,0,Text,0,0,Green);
         //Ticket=OrderSend(Symbol(),OP_SELLLIMIT,Vol,Bid+TakeProfit*Point,3,Bid+(StopLoss+TakeProfit)*Point,Bid-TakeProfit*Point,Text,0,0,Green);
         Ticket=OrderSend(Symbol(),OP_SELL,Vol,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,Text,0,0,Green);
         PlaySound("expert.wav");
         Sleep(10000);
      }
      if(GlobalVariableCheck("Closed")) GlobalVariableDel("Closed");
   }
   
   //Manage opened orders
   for (i=0;i<OrdersTotal();i++){
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      //close open position after 2 days
      if(OrderComment()==Text && CurTime()>=OrderOpenTime()+DaysOfClose*24*3600-300){
         if(OrderType()==OP_BUY && OrderOpenPrice() > Bid){
            OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
            PlaySound("expert.wav");
            GlobalVariableSet("Closed",1);
            Sleep(10000);
         }
         if(OrderType()==OP_SELL  && OrderOpenPrice() < Ask){
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
//+------------------------------------------------------------------+
//| Control trailing stop                                            |
//+------------------------------------------------------------------+
void ControlTrailingStop(int ticket)
{
  if (ticket == 0) return;
  
  double ts;
  if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)==false) return;
  if (OrderType() == OP_BUY)
  {
    ts = Bid-(Point*TS_Sensitivity);
    if ((ts >= OrderStopLoss() + TS_Sensitivity*Point) && (Bid >= OrderOpenPrice() + TS_Trigger*Point )) 
    {
      OrderModify(ticket, OrderOpenPrice(), ts, OrderTakeProfit(), 0);
    }
    
  }else if(OrderType() == OP_SELL){
  
    ts = Ask+(Point*TS_Sensitivity);
    if ((ts <= OrderStopLoss() - TS_Sensitivity*Point) && (Ask <= OrderOpenPrice() - TS_Trigger*Point))
    {
      OrderModify(ticket, OrderOpenPrice(), ts, OrderTakeProfit(), 0);
    }
  }
  
}


