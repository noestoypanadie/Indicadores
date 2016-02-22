//+------------------------------------------------------------------+
//|                                                    SweatSpot.mq4 |
//|                                Copyright © 2005, Safari Traders. |
//|                                          cmuriuki@bigpond.net.au |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Safari Traders"
#property link      "cmuriuki@bigpond.net.au"
#define MAGICMA  20050610
#define MAGIC_NUMBER 890070023

extern int MaxTradesPerSymbol = 3;
extern int Slippage = 2;
extern double Lots = 1;
extern double MaximumRisk = 0.05;
extern double DecreaseFactor = 6;
extern double Stop = 20;
extern double MAPeriod = 200;
extern double MinLot = 0.1;

int chartsUsed = 0;


int init(){
   return(0);
}

int start(){
 //double Laguerre;
 //double Laguerre1;
  
 double Alpha = iCCI(NULL, 30, 14, PRICE_CLOSE, 0);  // links to 30 minutes chart
 double MA = iMA(NULL,15,MAPeriod,0,MODE_EMA,PRICE_MEDIAN,1); // Links to 15 minutes chart for shorttearm accuracy
 double MAClose0 = iMA(NULL,15,28,0,MODE_EMA,PRICE_MEDIAN,0); // Links to 15 minutes chart for shorttearm accuracy
 double MAClose1 = iMA(NULL,15,28,0,MODE_EMA,PRICE_MEDIAN,1); // Links to 15 minutes chart for shorttearm accuracy
 double MAStop12 = iMA(NULL,15,12,0,MODE_EMA,PRICE_MEDIAN,0); // Links to 15 minutes chart for shorttearm accuracy
 double MAStop20 = iMA(NULL,15,20,0,MODE_EMA,PRICE_MEDIAN,0); // Links to 15 minutes chart for shorttearm accuracy
 double MAprevious = iMA(NULL,15,MAPeriod,0,MODE_EMA,PRICE_MEDIAN,2); // Links to 15 minutes chart for shorttearm accuracy


  int trades = 0;
  for(int cnt1 = 0; cnt1 < OrdersTotal(); cnt1++){
   if(!OrderSelect(cnt1, SELECT_BY_POS, MODE_TRADES)) continue;
   if(OrderMagicNumber() != MAGIC_NUMBER) continue;

   if(StringFind(OrderSymbol(), Symbol(), 0) != -1) {
   //debugging
    Print("symbol "+Symbol());
    trades++;
    if(cnt1 == OrdersTotal()-1) Print("Trades: "+trades);
   }
  }
  
  if(trades < MaxTradesPerSymbol){  
  
   // no opened orders identified
   if(AccountFreeMargin()<(1000*Lots)){
    Print("We have no money. Free Margin = ", AccountFreeMargin());
    return(0);  
   }
  
   int ticket = -10;
   
   // Bull trending
   if((MA>MAprevious) && (MAClose0 > MAClose1)&&(Alpha<-5))
    ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask, Slippage,0,0,NULL, MAGIC_NUMBER,0,Green);
  
  // Bear trending
   if((MA<MAprevious) && (MAClose0 < MAClose1) && (Alpha>5) )
    ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid, Slippage, 0,0, NULL, MAGIC_NUMBER,0,Red);         
    
  }
     
     
     
 // EXIT POSITIONS
 for(int cnt=0; cnt<OrdersTotal(); cnt++){
  if(!OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)) continue;
  if(OrderMagicNumber() != MAGIC_NUMBER) continue;
  if(StringFind(OrderSymbol(), Symbol(), 0) == -1) continue;
     
  if(OrderType() <= OP_SELL){   // opened position_Sell??
    
   if(OrderType() == OP_BUY){   // position is opened_buy??   
    // early take profit giving this strategy a scalping capability?
    if(MA <= MAprevious){
      OrderClose(OrderTicket(),OrderLots(),Bid, Slippage,Violet); // close position
      return(0);
    }   
    // check for stop
    if(Stop > 0){                
     if(Bid-OrderOpenPrice()>Point*Stop){
      OrderClose(OrderTicket(),OrderLots(),Bid, Slippage,Violet); // close position
      return(0);
     }
    }
   }else{ // OrderType() == OP_SELL
   
    // should it be closed?
    if(MA >= MAprevious){
     OrderClose(OrderTicket(),OrderLots(),Ask, Slippage, Violet); // close position
     return(0); // exit
    }
     
    // check for stop
    if(Stop > 0){                 
     if(OrderOpenPrice()-Ask>Point*Stop){
      OrderClose(OrderTicket(),OrderLots(),Ask, Slippage, Violet); // close position
      return(0);
     }
    }
   } 
  } //close -->  if(OrderType() <= OP_SELL){ 
 } //close -->  if(OrderType() == OP_BUY){
    
 return(0);
}


//////////////////////////////////////////////////////////////////////
// Calculate optimal lot size                                       
//////////////////////////////////////////////////////////////////////
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
   
//---- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/500, 1);
//---- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false) { Print("Error in history!"); break; }
         if(StringFind(OrderSymbol(), Symbol(), 0) == -1 || OrderType()>OP_SELL) continue;
         if(OrderMagicNumber() != MAGIC_NUMBER) continue;
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//---- return lot size
   if(lot>1000) lot=1000;
   if(lot < MinLot) lot = MinLot;
   return(lot);
}