//+------------------------------------------------------------------+
//|                                               100 pips a day.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern int     timeframe      = 5;
extern double  stopLoss       = 1000; 
extern double  lTakeProfit    = 20;
extern double  sTakeProfit    = 15;
extern double  lTrailingStop  = 10;
extern double  sTrailingStop  = 10;
extern color   clOpenBuy      = Blue;
extern color   clCloseBuy     = Aqua;
extern color   clOpenSell     = Red;
extern color   clCloseSell    = Violet;
extern color   clModiBuy      = Blue;
extern color   clModiSell     = Red;
extern string  Name_Expert    = "100 pips";
extern int     Slippage       = 2;
extern bool    UseSound       = true;
extern string  NameFileSound  = "shotgun.wav";
extern double  Lots           = 0.1;

int init(){return(0);}

int deinit(){return(0);}

int start(){
   
   if(Bars<100)   {Print("bars less than 100");return(0);}
   if(lTakeProfit<10){Print("TakeProfit less than 10");return(0);}
   if(sTakeProfit<10){Print("TakeProfit less than 10");return(0);}
   
   if(timeframe==0) {timeframe=Period();}
   double diClose0=iClose(Symbol(),timeframe,0);
   double diMA1=iMA(Symbol(),timeframe,7,0,MODE_SMA,PRICE_OPEN,0);
   double diClose2=iClose(Symbol(),timeframe,0);
   double diMA3=iMA(Symbol(),timeframe,6,0,MODE_SMA,PRICE_OPEN,0);

   if(AccountFreeMargin()<(1000*Lots)){
      Print("We have no money. Free Margin = ", AccountFreeMargin());
      return(0);  }
      
   if(!ExistPositions())  {
      if((diClose0<diMA1)) {
         OpenBuy();
         return(0);  }
      if ((diClose2>diMA3))   {
         OpenSell();
         return(0);  }  }
   
   TrailingPositionsBuy(lTrailingStop);
   TrailingPositionsSell(sTrailingStop);

return (0); }//end start

// - - - - - - FUNCTIONS - - - - - - -
 
bool ExistPositions()   {
   for(int i=0;i<OrdersTotal(); i++)  {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderComment()==Name_Expert) return(True);
         else return(false); }   }

void TrailingPositionsBuy(int trailingStop) { 
   for(int i=0;i<OrdersTotal();i++) { 
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderComment()==Name_Expert) { 
            if(OrderType()==OP_BUY) { 
               if(Bid-OrderOpenPrice()>trailingStop*Point) { 
                  if(OrderStopLoss()<Bid-trailingStop*Point || OrderStopLoss()==0)   {
                     ModifyStopLoss(Bid-trailingStop*Point); }}}}}} 

void TrailingPositionsSell(int trailingStop) { 
   for(int i=0;i<OrdersTotal();i++) { 
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderComment()==Name_Expert) { 
            if(OrderType()==OP_SELL) { 
               if(OrderOpenPrice()-Ask>trailingStop*Point) { 
                  if(OrderStopLoss()>Ask+trailingStop*Point || OrderStopLoss()==0)  {  
                     ModifyStopLoss(Ask+trailingStop*Point);}}}}}} 
 
void ModifyStopLoss(double ldStopLoss) { 
   bool fm;
   fm = OrderModify(OrderTicket(),OrderOpenPrice(),ldStopLoss,OrderTakeProfit(),0,0); 
   if (fm && UseSound) PlaySound(NameFileSound); 
} 

void OpenBuy() { 
   double ldLot, ldStop, ldTake; 
   string lsComm; 
   ldLot = GetSizeLot(); 
   ldStop = Ask-Point*stopLoss; 
   ldTake = NormalizeDouble(GetTakeProfitBuy(),Digits); 
   lsComm = GetCommentForOrder(); 
   OrderSend(Symbol(),OP_BUY,ldLot,NormalizeDouble(Ask,Digits),Slippage,ldStop,ldTake,lsComm,0,0,clOpenBuy); 
   if (UseSound) PlaySound(NameFileSound);   }
 
void OpenSell() { 
   double ldLot, ldStop, ldTake; 
   string lsComm; 
   ldLot = GetSizeLot(); 
   ldStop = Bid+Point*stopLoss; 
   ldTake = NormalizeDouble(GetTakeProfitSell(),Digits); 
   lsComm = GetCommentForOrder(); 
   OrderSend(Symbol(),OP_SELL,ldLot,NormalizeDouble(Bid,Digits),Slippage,ldStop,ldTake,lsComm,0,0,clOpenSell); 
   if (UseSound) PlaySound(NameFileSound);   }
 
string GetCommentForOrder() { return(Name_Expert); } 
double GetSizeLot() { return(Lots); } 
double GetTakeProfitBuy() { return(Ask+lTakeProfit*Point); } 
double GetTakeProfitSell() { return(Bid-sTakeProfit*Point); } 