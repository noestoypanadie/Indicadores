//+------------------------------------------------------------------+
//|                                                FXAnalyser_v6.mq4 |
//|                           Copyright © 2006, Renato P. dos Santos |
//|                   inspired on 4xtraderCY's and SchaunRSA's ideas |
//|   http://www.strategybuilderfx.com/forums/showthread.php?t=16086 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Renato P. dos Santos"
#property link "http://www.strategybuilderfx.com/forums/showthread.php?t=16086"

extern double Lots = 0;
extern int StopLoss = 30; 
extern int TakeProfit = 200;
extern int TrailingStop = 30;
extern int PipsGoal = 200;
extern int PipsLoss = 40;
extern int TimeFrame = 5;
extern double RiskLevel = 0.004;
extern bool UseSound = True;

color clOpenBuy = DodgerBlue;
color clModiBuy = DodgerBlue;
color clCloseBuy = DodgerBlue;
color clOpenSell = Red;
color clModiSell = Red;
color clCloseSell = Red;
color clDelete = White;
string Name_Expert = "FXAnalyser_v6";
string NameFileSound = "expert.wav";

int MODE_DIV=0;
int MODE_SLOPE=1;

void deinit() {
   Comment("");
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start() {

   if (Period()!=TimeFrame) {
      Alert("This advisor works better on the M",TimeFrame," chart"); return(0); }
   if (!ExistPositions()) { if (DayOfWeek()==6 && Hour()>=20) {
       CloseAllTrades(); Comment("weekend"); return(0); }}
   if (!ExistPositions()) { if (Hour()<2 || Hour()>18) { 
       CloseAllTrades(); Comment("bad hours.");  return(0); }}
//   if (!(IsTesting() || IsDemo())) { if (GoalCheck()) { CloseAllTrades(); Comment("goal attained"); PlaySound("applause.wav"); return(0); }}
   if (!(IsTesting() || IsDemo())) { if (LossCheck()) { CloseAllTrades(); Comment("excessive loss!"); PlaySound("alert.wav"); return(0); }}

   if (Bars<100) { Comment("bars less than 100!"); PlaySound("alert.wav"); return(0); }
   if (StopLoss<5) { Alert("wrong StopLoss"); PlaySound("alert.wav"); return(0); }
   if (TakeProfit<2*StopLoss) { Alert("wrong TakeProfit!"); PlaySound("alert.wav"); return(0); }
   if (GetSizeLot()<0.1) { Alert("not enough margin!"); PlaySound("alert.wav"); return(0); }

   int EMADiv_OpenLevel,EMADiv_CloseLevel,EMASlope_OpenLevel,EMASlope_CloseLevel;
   if(StringSubstr(Symbol(),0,6)=="EURUSD") {
      EMADiv_OpenLevel=6;
      EMADiv_CloseLevel=1;
      EMASlope_OpenLevel=6;
      EMASlope_CloseLevel=2;
      }
   if(StringSubstr(Symbol(),0,6)=="USDJPY") {
      EMADiv_OpenLevel=6;
      EMADiv_CloseLevel=1;
      EMASlope_OpenLevel=6;
      EMASlope_CloseLevel=2;
      }
   if(StringSubstr(Symbol(),0,6)=="GBPUSD") {
      EMADiv_OpenLevel=7;
      EMADiv_CloseLevel=1;
      EMASlope_OpenLevel=7;
      EMASlope_CloseLevel=2;
      }
   if(StringSubstr(Symbol(),0,6)=="USDCHF") {
      EMADiv_OpenLevel=6;
      EMADiv_CloseLevel=1;
      EMASlope_OpenLevel=6;
      EMASlope_CloseLevel=2;
      }
   if(EMADiv_OpenLevel==0) { Comment("Incorrect pair!"); PlaySound("alert.wav"); return(0); }


//   Comment(EMADiv_OpenLevel,",",EMASlope_OpenLevel,",",EMASlope_CloseLevel);   
   Comment("Lots = ",GetSizeLot());

   if (!ExistPositions()) {
      if (BuyCondition(EMADiv_OpenLevel,EMASlope_OpenLevel)) {
         double BuyPrice=NormalizeDouble(0.8*High[0]+0.2*Low[0],MarketInfo(Symbol(),MODE_DIGITS)); 
         OpenBuy(Ask);
         return(0);
      }
      if (SellCondition(EMADiv_OpenLevel,EMASlope_OpenLevel)) {
         double SellPrice=NormalizeDouble(0.8*Low[0]+0.2*High[0],MarketInfo(Symbol(),MODE_DIGITS)); 
         OpenSell(Bid);
         return(0);
      }
   }

   TrailingPositionsBuy(TrailingStop,EMADiv_CloseLevel,EMASlope_CloseLevel);
   TrailingPositionsSell(TrailingStop,EMADiv_CloseLevel,EMASlope_CloseLevel);

   return (0);
}

bool ExistPositions() {
   for (int i=0; i<OrdersTotal(); i++) {
     if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
       if (OrderSymbol()==Symbol() && OrderComment()==GetCommentForOrder()) return(True);
   } 
   Comment("no open trades");
   return(false);
}

bool BuyCondition(int EMADiv_OpenLevel,int EMASlope_OpenLevel) {
   if (((iCustom(NULL,0,"iFXAnalyser_v6",MODE_DIV,0)>EMADiv_OpenLevel*Point
         && iCustom(NULL,0,"iFXAnalyser_v6",MODE_SLOPE,0)>0)
       || (iCustom(NULL,0,"iFXAnalyser_v6",MODE_SLOPE,0)>EMASlope_OpenLevel*Point 
         && iCustom(NULL,0,"iFXAnalyser_v6",MODE_DIV,0)>0))
       && iADX(NULL,0,4,PRICE_CLOSE,MODE_MAIN,0)>50)
      return(True);
   else
      return(False);
}   

bool SellCondition(int EMADiv_OpenLevel,int EMASlope_OpenLevel) {
   if (((iCustom(NULL,0,"iFXAnalyser_v6",MODE_DIV,0)<-EMADiv_OpenLevel*Point
         && iCustom(NULL,0,"iFXAnalyser_v6",MODE_SLOPE,0)<0)
       || (iCustom(NULL,0,"iFXAnalyser_v6",MODE_SLOPE,0)<-EMASlope_OpenLevel*Point 
         && iCustom(NULL,0,"iFXAnalyser_v6",MODE_DIV,0)<0))
       && iADX(NULL,0,4,PRICE_CLOSE,MODE_MAIN,0)>50)
      return(True);
   else
      return(False);
}   

void OpenBuy(double BuyPrice) { 
   double ldLot = GetSizeLot(); 
   double Slippage = GetSlippage();
   double ldStop = GetStopLossBuy(BuyPrice); 
   double ldTake = GetTakeProfitBuy(BuyPrice); 
   string lsComm = GetCommentForOrder(); 
   OrderSend(Symbol(),OP_BUY,ldLot,BuyPrice,Slippage,ldStop,ldTake,lsComm,0,0,clOpenBuy); 
   if (UseSound) PlaySound(NameFileSound);
} 

void OpenSell(double SellPrice) { 
   double ldLot = GetSizeLot(); 
   double Slippage = GetSlippage();
   double ldStop = GetStopLossSell(SellPrice); 
   double ldTake = GetTakeProfitSell(SellPrice); 
   string lsComm = GetCommentForOrder(); 
   OrderSend(Symbol(),OP_SELL,ldLot,SellPrice,Slippage,ldStop,ldTake,lsComm,0,0,clOpenSell); 
   if (UseSound) PlaySound(NameFileSound); 
} 

void TrailingPositionsBuy(int TrailingStop,int EMADiv_CloseLevel,int EMASlope_CloseLevel) { 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderComment()==GetCommentForOrder()) { 
            if (OrderType()==OP_BUY) { 
               if (CloseBuyCondition(EMADiv_CloseLevel,EMASlope_CloseLevel))
                  OrderClose(OrderTicket(),OrderLots(),Bid,GetSlippage(),clCloseBuy);
               if (Bid-OrderOpenPrice()>TrailingStop*Point && OrderOpenPrice()>OrderStopLoss()) 
                  ModifyStopLoss(OrderOpenPrice(),clModiBuy); 
               if (Bid-OrderOpenPrice()>TrailingStop*Point)  
                  if (OrderStopLoss()<Bid-TrailingStop*Point || OrderStopLoss()==0) 
                     ModifyStopLoss(Bid-TrailingStop*Point,clModiBuy); 
               if (OrderTakeProfit()-Bid<TrailingStop*Point/2) 
                  ModifyStopLoss(Bid-TrailingStop*Point/2,clModiBuy); 
            } 
         } 
      } 
   } 
} 

void TrailingPositionsSell(int trailingStop,int EMADiv_CloseLevel,int EMASlope_CloseLevel) { 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderComment()==GetCommentForOrder()) { 
            if (OrderType()==OP_SELL) { 
               if (CloseSellCondition(EMADiv_CloseLevel,EMASlope_CloseLevel))
                  OrderClose(OrderTicket(),OrderLots(),Ask,GetSlippage(),clCloseSell);
               if (OrderOpenPrice()-Ask>TrailingStop*Point && OrderOpenPrice()<OrderStopLoss()) 
                  ModifyStopLoss(OrderOpenPrice(),clModiBuy); 
               if (OrderOpenPrice()-Ask>TrailingStop*Point)  
                  if (OrderStopLoss()>Ask+TrailingStop*Point || OrderStopLoss()==0) 
                     ModifyStopLoss(Ask+TrailingStop*Point,clModiBuy); 
               if (Ask-OrderTakeProfit()<TrailingStop*Point/2) 
                  ModifyStopLoss(Ask+TrailingStop*Point/2,clModiSell); 
            } 
         } 
      } 
   } 
} 

void ModifyStopLoss(double ldStopLoss, double clModi) { 
   bool fm;
   fm = OrderModify(OrderTicket(),OrderOpenPrice(),
        ldStopLoss,OrderTakeProfit(),OrderExpiration(),clModi); 
   if (fm && UseSound) PlaySound(NameFileSound); 
} 

bool CloseBuyCondition(int EMADiv_CloseLevel,int EMASlope_CloseLevel) {
   if (iCustom(NULL,0,"iFXAnalyser_v6",MODE_DIV,0)<-EMADiv_CloseLevel*Point)
      return(True);
   else
      return(False);
}   

bool CloseSellCondition(int EMADiv_CloseLevel,int EMASlope_CloseLevel) {
   if (iCustom(NULL,0,"iFXAnalyser_v6",MODE_DIV,0)>EMADiv_CloseLevel*Point)
      return(True);
   else
      return(False);
}   

void CloseAllTrades() {
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if (OrderSymbol()==Symbol() && OrderComment()==GetCommentForOrder()) { 
            if (OrderType()==OP_BUY) 
               OrderClose(OrderTicket(),OrderLots(),Bid,GetSlippage(),clCloseBuy);
            if (OrderType()==OP_SELL) 
               OrderClose(OrderTicket(),OrderLots(),Ask,GetSlippage(),clCloseSell);
            if (OrderType()==OP_SELLSTOP || OrderType()==OP_SELLLIMIT || 
                OrderType()==OP_BUYSTOP || OrderType()==OP_BUYLIMIT) 
               OrderDelete(OrderTicket());
         }
      }
   }
}

bool GoalCheck() {
   int handle = FileOpen(LogFileName(),FILE_CSV|FILE_READ,";"); 
   if (handle>0) {
      int lsteqty = FileReadNumber(handle);
      FileClose(handle);
   }
   else lsteqty = 0;
   if (lsteqty==0) {  
     handle = FileOpen(LogFileName(),FILE_CSV|FILE_WRITE,";"); 
     FileWrite(handle,AccountEquity()); 
     FileClose(handle);
   }
   else if (AccountEquity()-lsteqty>=PipsGoal*GetSizeLot()) return(True);
        else return(False); 
}

bool LossCheck() {
   int handle = FileOpen(LogFileName(),FILE_CSV|FILE_READ,";"); 
   if (handle>0) {
      int lsteqty = FileReadNumber(handle);
      FileClose(handle);
   }
   else lsteqty = 0;
   if (lsteqty-AccountEquity()>=PipsLoss*GetSizeLot()) return(True);
   else return(False); 
}

string LogFileName() {
    string stryear = DoubleToStr(Year(),0);
    string strmonth = DoubleToStr(Month(),0);
    if (StringLen(strmonth)<2) strmonth = "0"+strmonth;
    string strday = DoubleToStr(Day(),0);
    if (StringLen(strday)<2) strday = "0"+strday;
    return(stryear+strmonth+strday+".log");
}

string GetCommentForOrder() { return(Name_Expert); } 
double GetSizeLot() { if (IsTesting() || IsDemo()) return(1); 
                      else if (Lots > 0) return(Lots); 
                           else return(NormalizeDouble(AccountFreeMargin()/StopLoss*RiskLevel,1)); } 
double GetSlippage() { return((Ask-Bid)/Point); }
double GetStopLossBuy(double BuyPrice) { if (StopLoss==0) return(0); else return(BuyPrice-StopLoss*Point); } 
double GetStopLossSell(double SellPrice) { if (StopLoss==0) return(0); else return(SellPrice+StopLoss*Point); } 
double GetTakeProfitBuy(double BuyPrice) { if (TakeProfit==0) return(0); else return(BuyPrice+TakeProfit*Point); } 
double GetTakeProfitSell(double SellPrice) { if (TakeProfit==0) return(0); else return(SellPrice-TakeProfit*Point); } 

¥”≠7”Ωvﬂ^9Û}z