//+------------------------------------------------------------------+
//|                                                   RahnAbbott.mq4 |
//|                           Copyright © 2006, Renato P. dos Santos |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Renato P. dos Santos"
#property link "mailto:renato@reniza.com"

extern double Lots=0.01;
extern int StopLoss=20; 
extern int TakeProfit=20;
extern int TrailingStop=20;
extern int MaxTrades=5;
extern bool UseSound=False;

color clOpenBuy=DodgerBlue;
color clModiBuy=Cyan;
color clCloseBuy=Cyan;
color clOpenSell=Red;
color clModiSell=Yellow;
color clCloseSell=Yellow;
color clDelete=White;
string Name_Expert="SureShot_v01";
string NameFileSound="expert.wav";


extern int FastMAPeriod=9;
extern int MediumMAPeriod=14;
extern int SlowMAPeriod=29;
extern int FastMAMode = PRICE_OPEN;
extern int MediumMAMode = PRICE_OPEN;
extern int SlowMAMode = PRICE_OPEN;
extern int EMA_OpenLevel=2;

double FastMA=0;
double MediumMA=0;
double SlowMA=0;


void deinit() {
   Comment("");
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start() {

   FastMA=iMA(NULL,0,FastMAPeriod,0,MODE_SMA,FastMAMode,0);
   MediumMA=iMA(NULL,0,FastMAPeriod,0,MODE_SMA,MediumMAMode,0);
   SlowMA=iMA(NULL,0,SlowMAPeriod,0,MODE_SMA,SlowMAMode,0);

   int dir1 = Crossed1(FastMA,MediumMA,EMA_OpenLevel*Point);
   int dir2 = Crossed2(MediumMA,SlowMA,EMA_OpenLevel*Point);

   if ( MyOrdersTotal()<MaxTrades ) {
      if ( BuyCondition(dir1+dir2) ) {
         OpenBuy(Ask);
         return(0);
      }
      if ( SellCondition(dir1+dir2) ) {
         OpenSell(Bid);
         return(0);
      }
   }

   TrailingPositionsBuy(dir1); 
   TrailingPositionsSell(dir1);

   return (0);
}

int Crossed1(double line1,double line2,double tolerance) {
   static int last_dir1 = 0;
   static int current_dir1 = 0;
   if ( line1-line2>tolerance ) current_dir1 = 1; //up
   if ( line2-line1>tolerance ) current_dir1 = -1; //down
   if ( current_dir1 != last_dir1 ) { //changed
       last_dir1 = current_dir1;
       return (last_dir1);
      }
   else {
         return(0);
      }
  }

int Crossed2(double line1,double line2,double tolerance) {
   static int last_dir2 = 0;
   static int current_dir2 = 0;
   if ( line1-line2>tolerance ) current_dir2 = 1; //up
   if ( line2-line1>tolerance ) current_dir2 = -1; //down
   if ( current_dir2 != last_dir2 ) { //changed
       last_dir2 = current_dir2;
       return (last_dir2);
      }
   else {
         return(0);
      }
  }

bool BuyCondition(int direction) {
   if ( direction>0 ) 
      return(True);
   else
      return(False);
}   

bool SellCondition(int direction) {
   if ( direction<0 ) 
      return(True);
   else
      return(False);
}   

void OpenBuy(double lPrice) { 
   if ( MathAbs(lPrice-Ask)>100*Point ) { Alert("invalid price in OpenBuy!"); return(NULL); }
   double ldLot=GetSizeLot();
   double lSlip=GetSpread();
   double ldStop=GetStopLossBuy(lPrice); 
   double ldTake=GetTakeProfitBuy(lPrice); 
   string lsComm=GetCommentForOrder(); 
   OrderSend(Symbol(),OP_BUY,ldLot,lPrice,lSlip,ldStop,ldTake,lsComm,0,0,clOpenBuy); 
   if (UseSound) PlaySound(NameFileSound);
} 

void OpenSell(double lPrice) { 
   double ldLot=GetSizeLot();
   double lSlip=GetSpread();
   double ldStop=GetStopLossSell(lPrice); 
   double ldTake=GetTakeProfitSell(lPrice); 
   string lsComm=GetCommentForOrder(); 
   if ( MathAbs(lPrice-Bid)>100*Point ) { Alert("invalid price in OpenSell!"); return(NULL); }
   OrderSend(Symbol(),OP_SELL,ldLot,lPrice,lSlip,ldStop,ldTake,lsComm,0,0,clOpenSell); 
   if (UseSound) PlaySound(NameFileSound); 
} 

void TrailingPositionsBuy(int direction) { 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if ( (OrderSymbol()==Symbol()) && (OrderComment()==GetCommentForOrder()) ) { 
            if (OrderType()==OP_BUY) { 
               if ( TrailingStop==0 ) { Alert("invalid TrailingStop in TrailingPositionsBuy!"); return(NULL); }
               if ( CloseBuyCondition(direction) ) {
                  OrderClose(OrderTicket(),OrderLots(),Bid,GetSpread(),clCloseBuy); continue; }
               if ( OrderOpenPrice()<Bid-(TrailingStop+GetSpread())*Point && OrderOpenPrice()>OrderStopLoss() ) 
                  ModifyStopLoss(OrderOpenPrice(),clModiBuy); 
               if ( OrderStopLoss()<Bid-(TrailingStop+GetSpread())*Point && OrderStopLoss()>=OrderOpenPrice() ) 
                  ModifyStopLoss(Bid-(TrailingStop+GetSpread())*Point,clModiBuy); 
//               if ( OrderTakeProfit()-Bid<TrailingStop*Point/2 ) 
//                  ModifyStopLoss(Bid-TrailingStop*Point/2,clModiBuy); 
            } 
         } 
      } 
   } 
} 

void TrailingPositionsSell(int direction) { 
   for (int i=0; i<OrdersTotal(); i++) { 
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { 
         if ( (OrderSymbol()==Symbol()) && (OrderComment()==GetCommentForOrder()) ) { 
            if (OrderType()==OP_SELL) { 
               if ( TrailingStop==0 ) { Alert("invalid TrailingStop in TrailingPositionsSell!"); return(NULL); }
               if ( CloseSellCondition(direction) ) {
                  OrderClose(OrderTicket(),OrderLots(),Ask,GetSpread(),clCloseSell); continue; }
               if ( OrderOpenPrice()>Ask+(TrailingStop+GetSpread())*Point && OrderOpenPrice()<OrderStopLoss() ) 
                  ModifyStopLoss(OrderOpenPrice(),clModiBuy); 
               if ( OrderStopLoss()>Ask+(TrailingStop+GetSpread())*Point && OrderStopLoss()<=OrderOpenPrice() ) 
                  ModifyStopLoss(Ask+(TrailingStop+GetSpread())*Point,clModiBuy); 
//               if ( Ask-OrderTakeProfit()<TrailingStop*Point/2 ) 
//                  ModifyStopLoss(Ask+TrailingStop*Point/2,clModiSell); 
            } 
         } 
      } 
   } 
} 

void ModifyStopLoss(double ldStopLoss, double clModi) { 
   bool fm;
   fm=OrderModify(OrderTicket(),OrderOpenPrice(),
        ldStopLoss,OrderTakeProfit(),OrderExpiration(),clModi); 
   if (fm && UseSound) PlaySound(NameFileSound); 
} 

bool CloseBuyCondition(int direction) {
   if ( direction<0 )
      return(True);
   else
      return(False);
}   

bool CloseSellCondition(int direction) {
   if ( direction>0 )
      return(True);
   else
      return(False);
}   

int MyOrdersTotal() { 
   int Mytotal=0; 
   for (int i=0; i<OrdersTotal(); i++) { 
     if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
       if ( (OrderSymbol()==Symbol()) && (OrderComment()==GetCommentForOrder()) ) 
          Mytotal++; 
   }  
   return(Mytotal); 
} 

string GetCommentForOrder() { return(Name_Expert); } 
double GetSizeLot() { return (Lots); } 
double GetSpread() { return((Ask-Bid)/Point); }
double GetStopLossBuy(double BuyPrice) { if (StopLoss==0) return(0); else return(BuyPrice-StopLoss*Point); } 
double GetStopLossSell(double SellPrice) { if (StopLoss==0) return(0); else return(SellPrice+StopLoss*Point); } 
double GetTakeProfitBuy(double BuyPrice) { if (TakeProfit==0) return(0); else return(BuyPrice+TakeProfit*Point); } 
double GetTakeProfitSell(double SellPrice) { if (TakeProfit==0) return(0); else return(SellPrice-TakeProfit*Point); } 

