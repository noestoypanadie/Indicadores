//+------------------------------------------------------------------+
//|                             |
//|                                           |
//+------------------------------------------------------------------+

#property copyright "Copyright 2006,"
#property link      ""

#define MAGIC 771986

extern double StopLoss = 14;
extern double MaxLoss = 200;
extern double TakeProfit = 50;
extern double SecureProfit = 15;
extern double TrailingStop = 15;
extern double sTrailingStop = 15;
double Points;
double OpenBuy , OpenSell ;
bool openbuy=false;
bool opensell=false;

extern color clOpenBuy = Blue;
extern color clCloseBuy = Aqua;
extern color clOpenSell = Red;
extern color clCloseSell = Violet;
extern color clModiBuy = Blue;
extern color clModiSell = Red;
extern string Name_Expert = "  ";
extern int Slippage = 0;
extern bool UseHourTrade = True;
extern int FromHourTrade = 7;
extern int ToHourTrade = 23;
extern bool UseSound = True;
extern string NameFileSound = "alert.wav";
extern double Lots = 0.10;


void deinit() {
   Comment("");
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start(){
   if (UseHourTrade){
      if (!(Hour()>=FromHourTrade && Hour()<=ToHourTrade)) {
         Comment("Time for trade has not come else!");
         return(0);
      } else Comment("");
   }else Comment("");
   if(Bars<100){
      Print("bars less than 100");
      return(0);
   }
   if(StopLoss<10){
      Print("StopLoss less than 10");
      return(0);
   }
   if(TakeProfit<10){
      Print("TakeProfit less than 10");
      return(0);
   }
   if(MaxLoss<10){
      Print("StopLoss less than 10");
      return(0);
   }
   if(SecureProfit<10){
      Print("TakeProfit less than 10");
      return(0);
   }

   double diMA0=iMA(NULL,1440,13,0,MODE_EMA,PRICE_CLOSE,0);
   double diMA1=iMA(NULL,1440,13,0,MODE_EMA,PRICE_CLOSE,0);
   double diMA2=iMA(NULL,1440,13,0,MODE_EMA,PRICE_CLOSE,0);
   double diMA3=iMA(NULL,1440,13,0,MODE_EMA,PRICE_CLOSE,0);

   if(AccountFreeMargin()<(1000*Lots)){
      Print("We have no money. Free Margin = ", AccountFreeMargin());
      return(0);
   }
   if (!ExistPositions()){

      if ((diMA0>diMA1)){
      
        if (OpenBuy==true) {
         OpenBuy();
         OpenBuy=OrderSend(Symbol(),OP_BUY,Lots,Ask-StopLoss,3,0,Ask+TakeProfit*Points,"",16384,0,Blue);
         return(0);
        }
      }

      if ((diMA2<diMA3)){
      
        if (OpenSell==true) {
         OpenSell();
         OpenSell=OrderSend(Symbol(),OP_SELL,Lots,Bid+StopLoss,3,0,Bid-TakeProfit*Points,"",16384,0,Red);
         return(0);
        }
      }
   }
   TrailingPositionsBuy(TrailingStop);
   TrailingPositionsSell(TrailingStop);
   return (0);
}

bool ExistPositions() {
	for (int i=0; i<OrdersTotal(); i++) {
		if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
			if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC) {
				return(True);
			}
		} 
	} 
	return(false);
}
void TrailingPositionsBuy(int trailingStop) { 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC) { 
            if (OrderType()==OP_BUY) { 
               if (Bid-OrderOpenPrice()>trailingStop*Point) { 
                  if (OrderStopLoss()<Bid-trailingStop*Point) 
                     ModifyStopLoss(Bid-trailingStop*Point); 
               } 
            } 
         } 
      } 
   } 
} 
void TrailingPositionsSell(int trailingStop) { 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC) { 
            if (OrderType()==OP_SELL) { 
               if (OrderOpenPrice()-Ask>trailingStop*Point) { 
                  if (OrderStopLoss()>Ask+trailingStop*Point || OrderStopLoss()==0)  
                     ModifyStopLoss(Ask+trailingStop*Point); 
               } 
            } 
         } 
      } 
   } 
} 
void ModifyStopLoss(double ldStopLoss) { 
   bool fm;
   fm = OrderModify(OrderTicket(),OrderOpenPrice(),ldStopLoss,OrderTakeProfit(),0,CLR_NONE); 
   if (fm && UseSound) PlaySound(NameFileSound); 
} 

void OpenBuy() { 
   double ldLot, ldStop, ldTake; 
   string lsComm; 
   ldLot = GetSizeLot(); 
   ldStop = GetStopLossBuy(); 
   ldTake = GetTakeProfitBuy(); 
   lsComm = GetCommentForOrder(); 
   OrderSend(Symbol(),OP_BUY,ldLot,Ask,Slippage,ldStop,ldTake,lsComm,MAGIC,0,clOpenBuy); 
   if (UseSound) PlaySound(NameFileSound); 
} 
void OpenSell() { 
   double ldLot, ldStop, ldTake; 
   string lsComm; 

   ldLot = GetSizeLot(); 
   ldStop = GetStopLossSell(); 
   ldTake = GetTakeProfitSell(); 
   lsComm = GetCommentForOrder(); 
   OrderSend(Symbol(),OP_SELL,ldLot,Bid,Slippage,ldStop,ldTake,lsComm,MAGIC,0,clOpenSell); 
   if (UseSound) PlaySound(NameFileSound); 
}
 
string GetCommentForOrder() { 	return(Name_Expert); } 
double GetSizeLot() { 	return(Lots); } 
double GetStopLossBuy() { 	return (Bid-StopLoss*Point);} 
double GetStopLossSell() { 	return(Ask+MaxLoss*Point); } 
double GetTakeProfitBuy() { 	return(Ask+TakeProfit*Point); } 
double GetTakeProfitSell() { 	return(Bid-SecureProfit*Point); }