//+------------------------------------------------------------------+
//|                           TYP1                                   |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+


#property copyright "NONE"
#property link      "NONE"

#define MIN_STOPLOSS_POINT 10
#define MIN_TAKEPROFIT_POINT 10 
#define MAGIC 0

extern string sNameExpert = "TYP1";
extern int nAccount =0;
extern double dBuyStopLossPoint = 40;
extern double dSellStopLossPoint = 40;
extern double dBuyTakeProfitPoint = 0;
extern double dSellTakeProfitPoint = 0;
extern double dBuyTrailingStopPoint = 55;
extern double dSellTrailingStopPoint = 55;
extern double dLots = 0.10; 
extern int nSlippage = 1;
extern bool lFlagUseHourTrade = False;
extern int nFromHourTrade = 0;
extern int nToHourTrade = 23;
extern bool lFlagUseSound = False;
extern string sSoundFileName = "alert.wav";
extern color colorOpenBuy = Blue;
extern color colorCloseBuy = Aqua;
extern color colorOpenSell = Red;
extern color colorCloseSell = Aqua;


void deinit() {
   Comment("");
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start(){
   if (lFlagUseHourTrade){
      if (!(Hour()>=nFromHourTrade && Hour()<=nToHourTrade)) {
         Comment("Time for trade has not come else!");
         return(0);
      }
   }
   
   if(Bars < 100){
      Print("bars less than 100");
      return(0);
   }
   
   if (nAccount > 0 && nAccount != AccountNumber()){
      Comment("Trade on account :"+AccountNumber()+" FORBIDDEN!");
      return(0);
   }
   
   if((dBuyStopLossPoint > 0 && dBuyStopLossPoint < MIN_STOPLOSS_POINT) ||
      (dSellStopLossPoint > 0 && dSellStopLossPoint < MIN_STOPLOSS_POINT)){
      Print("StopLoss less than " + MIN_STOPLOSS_POINT);
      return(0);
   }
   if((dBuyTakeProfitPoint > 0 && dBuyTakeProfitPoint < MIN_TAKEPROFIT_POINT) ||
      (dSellTakeProfitPoint > 0 && dSellTakeProfitPoint < MIN_TAKEPROFIT_POINT)){
      Print("TakeProfit less than " + MIN_TAKEPROFIT_POINT);
      return(0);
   }

double diMA0=iMA(NULL,5,10,0,MODE_EMA,PRICE_MEDIAN,0);
double diMA1=iMA(NULL,5,288,0,MODE_EMA,PRICE_MEDIAN,0);
double diMA2=iMA(NULL,5,20,0,MODE_EMA,PRICE_MEDIAN,0);
double diMA3=iMA(NULL,5,288,0,MODE_EMA,PRICE_MEDIAN,0);
//double diEnvelopes4=iEnvelopes(NULL,5,288,MODE_EMA,0,PRICE_CLOSE,0.05,MODE_UPPER,0);
//double diEnvelopes5=iEnvelopes(NULL,5,288,MODE_EMA,0,PRICE_CLOSE,0.05,MODE_LOWER,0);
//double diMA4=iMA(NULL,5,10,0,MODE_EMA,PRICE_MEDIAN,0);
//double diMA5=iMA(NULL,5,70,0,MODE_EMA,PRICE_MEDIAN,0);
//double diMA6=iMA(NULL,5,20,0,MODE_EMA,PRICE_MEDIAN,0);
//double diMA7=iMA(NULL,5,70,0,MODE_EMA,PRICE_MEDIAN,0);


   if(AccountFreeMargin() < (1000*dLots)){
      Print("We have no money. Free Margin = " + AccountFreeMargin());
      return(0);
   }
   
   bool lFlagBuyOpen = false, lFlagSellOpen = false, lFlagBuyClose = false, lFlagSellClose = false;
   
   lFlagBuyOpen = (diMA0>diMA1 && diMA2<diMA3);
   lFlagSellOpen = (diMA0<diMA1 && diMA2>diMA3);
   lFlagBuyClose = False;
   lFlagSellClose = False;
   
   if (!ExistPositions()){

      if (lFlagBuyOpen){
         OpenBuy();
         return(0);
      }

      if (lFlagSellOpen){
         OpenSell();
         return(0);
      }
   }
   if (ExistPositions()){
      if(OrderType()==OP_BUY){
         if (lFlagBuyClose){
            bool flagCloseBuy = OrderClose(OrderTicket(), OrderLots(), Bid, nSlippage, colorCloseBuy); 
            if (flagCloseBuy && lFlagUseSound) 
               PlaySound(sSoundFileName); 
           return(0);
         }
      }
      if(OrderType()==OP_SELL){
        if (lFlagSellClose){
            bool flagCloseSell = OrderClose(OrderTicket(), OrderLots(), Ask, nSlippage, colorCloseSell); 
            if (flagCloseSell && lFlagUseSound) 
               PlaySound(sSoundFileName); 
            return(0);
         }
      }
   }
   
   if (dBuyTrailingStopPoint > 0 || dSellTrailingStopPoint > 0){
      
      for (int i=0; i<OrdersTotal(); i++) { 
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
            bool lMagic = true;
            if (MAGIC > 0 && OrderMagicNumber() != MAGIC)
               lMagic = false;
            
            if (OrderSymbol()==Symbol() && lMagic) { 
               if (OrderType()==OP_BUY && dBuyTrailingStopPoint > 0) { 
                  if (Bid-OrderOpenPrice() > dBuyTrailingStopPoint*Point) { 
                     if (OrderStopLoss()<Bid-dBuyTrailingStopPoint*Point) 
                        ModifyStopLoss(Bid-dBuyTrailingStopPoint*Point); 
                  } 
               } 
               if (OrderType()==OP_SELL) { 
                  if (OrderOpenPrice()-Ask>dSellTrailingStopPoint*Point) { 
                     if (OrderStopLoss()>Ask+dSellTrailingStopPoint*Point || OrderStopLoss()==0)  
                        ModifyStopLoss(Ask+dSellTrailingStopPoint*Point); 
                  } 
               } 
            } 
         } 
      } 
   }
   return (0);
}

bool ExistPositions() {
	for (int i=0; i<OrdersTotal(); i++) {
		if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         bool lMagic = true;
         
         if (MAGIC > 0 && OrderMagicNumber() != MAGIC)
            lMagic = false;

			if (OrderSymbol()==Symbol() && lMagic) {
				return(True);
			}
		} 
	} 
	return(false);
}

void ModifyStopLoss(double ldStopLoss) { 
   bool lFlagModify = OrderModify(OrderTicket(), OrderOpenPrice(), ldStopLoss, OrderTakeProfit(), 0, CLR_NONE); 
   if (lFlagModify && lFlagUseSound) 
      PlaySound(sSoundFileName); 
} 

void OpenBuy() { 
   double dStopLoss = 0, dTakeProfit = 0;

   if (dBuyStopLossPoint > 0)
      dStopLoss = Bid-dBuyStopLossPoint*Point;
   
   if (dBuyTakeProfitPoint > 0)
     dTakeProfit = Ask + dBuyTakeProfitPoint * Point; 
 
   
   int numorder = OrderSend(Symbol(), OP_BUY, dLots, Ask, nSlippage, dStopLoss, dTakeProfit, sNameExpert, MAGIC, 0, colorOpenBuy); 
   
   if (numorder > -1 && lFlagUseSound) 
      PlaySound(sSoundFileName);
} 

void OpenSell() { 
   double dStopLoss = 0, dTakeProfit = 0;
   
   if (dSellStopLossPoint > 0)
      dStopLoss = Ask+dSellStopLossPoint*Point;
   
   if (dSellTakeProfitPoint > 0)
      dTakeProfit = Bid-dSellTakeProfitPoint*Point;
   
   int numorder = OrderSend(Symbol(),OP_SELL, dLots, Bid, nSlippage, dStopLoss, dTakeProfit, sNameExpert, MAGIC, 0, colorOpenSell); 
   
   if (numorder > -1 && lFlagUseSound) 
      PlaySound(sSoundFileName); 
} 

