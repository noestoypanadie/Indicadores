//+------------------------------------------------------------------+
//|                                                HedgExpert_v1.mq4 |
//|                                  Copyright © 2006, Forex-TSD.com |
//|                         Written by IgorAD,igorad2003@yahoo.co.uk |   
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |                                      
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Forex-TSD.com "
#property link      "http://www.forex-tsd.com/"

#include <stdlib.mqh>
#include <Tracert.mqh>

//---- input parameters
extern string     Expert_Name = "---- HedgExpert_v1 ----";

extern int        Magic            = 10000;
extern int        Slippage         = 6;

extern bool       Trace = false;            // Trace Switch

extern string     Main_Parameters = " Trade Volume & Trade Method";
extern double     Lots             = 0.1;   // Lot size
extern int        OrdersMode       =   1;   // 1- Limit Orders; 2 - Stop Orders 

extern string     Data = " Input Data ";
extern string     TimeFrame        = "D1";  // Working period (M1,M5...H1...D1...W1) 
extern double     NetProfit        = 50;    // Net Profit         	
extern double     NetLoss          = 50;    // Net Loss       
extern double     InitialStop      = 10;    // Initial Stop in pips 
extern double     TakeProfit       = 20;    // Take Profit in pips    
extern double     FirstOrdGap      = 20;    // Gap for Pending Orders from High/Low in pips
extern int        NumberOrds       =  2;    // Number of orders to place 
extern double     StepSize         = 10;    // Pips between orders


extern string     MM_Parameters = " MoneyManagement by L.Williams ";
extern bool       MM=false;                 // ÌÌ Switch
extern double     MMRisk=0.15;              // Risk Factor
extern double     LossMax=1000;             // Maximum Loss by 1 Lot


int      i=0, cnt=0, ticket, mode=0, digit=0, numords, PeriodName ;
double   open=0, low=0, spread=0, SellProfit=0,BuyProfit=0;
double   smin=0, smax=0, BuyStop=0, SellStop=0, Lotsi=0;
bool     BuyInTrade=false, SellInTrade=false;
datetime Previous_bar;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
  
  if (TimeFrame=="M1" || TimeFrame=="1"  ) PeriodName=PERIOD_M1; 
   else
      if (TimeFrame=="M5" || TimeFrame=="5" ) PeriodName=PERIOD_M5;
      else
         if (TimeFrame=="M15" || TimeFrame=="15" )PeriodName=PERIOD_M15;
         else
            if (TimeFrame=="M30" || TimeFrame=="30" )PeriodName=PERIOD_M30;
            else
               if (TimeFrame=="H1" || TimeFrame=="60" ) PeriodName=PERIOD_H1;
               else
                  if (TimeFrame=="H4" || TimeFrame=="240" ) PeriodName=PERIOD_H4; 
                  else 
                     if (TimeFrame=="D1" || TimeFrame=="1440" ) PeriodName=PERIOD_D1;
                     else
                        if (TimeFrame=="W1" || TimeFrame=="10080" ) PeriodName=PERIOD_W1; 
                        else
                           if (TimeFrame=="MN" || TimeFrame=="43200" ) PeriodName=PERIOD_MN1;
                           else
                              {
                              PeriodName=Period(); 
                              return(0);
                              }
   Previous_bar=iTime(Symbol(),PeriodName,0); 
//----
   return(0);
  }
  
// ---- Money Management
double MoneyManagement ( bool flag, double Lots, double risk, double maxloss)
{
   Lotsi=Lots;
	    
   if ( flag ) Lotsi=NormalizeDouble(Lots*AccountFreeMargin()*risk/maxloss,1);   
     
   if (Lotsi<0.1) Lotsi=0.1;  
   return(Lotsi);
}   

// ---- Trailing Stops
//void TrailStops()
//{        
//    int total=OrdersTotal();
//    for (cnt=0;cnt<total;cnt++)
//    { 
//     OrderSelect(cnt, SELECT_BY_POS);   
//     mode=OrderType();    
//        if ( OrderSymbol()==Symbol() && OrderMagicNumber()==Magic ) 
//        {
//            if ( mode==OP_BUY )
//            {
//            smin = Bid - TrailingStop*Point;
//            if ( ProfitLock > 0 && Bid-OrderOpenPrice()>Point*ProfitLock ) smin = OrderOpenPrice();
//            BuyProfit=OrderTakeProfit();
//              if( smin > OrderStopLoss())
//              { 
//              OrderModify(OrderTicket(),OrderOpenPrice(),
//                          NormalizeDouble(smin, digit),
//                          BuyProfit,0,LightGreen);
//			     return(0);
//			     }
//            }
//            if ( mode==OP_SELL )
//            {
//            smax = Ask + TrailingStop*Point;
//            if ( ProfitLock > 0 && OrderOpenPrice()-Ask>Point*ProfitLock ) smax = OrderOpenPrice();
//            SellProfit=OrderTakeProfit();
//              if( smax < OrderStopLoss())
//              {  
//   		     OrderModify(OrderTicket(),OrderOpenPrice(),
//   		                 NormalizeDouble(smax, digit),
//   		                 SellProfit,0,Yellow);	    
//              return(0);
//              }
//            }    
//        }
//    }   
//} 

// ---- Open Sell Orders
void SellOrdOpen()
{		     
		  
		  if (OrdersMode == 1)
		  {
		  double SellPrice=open + FirstOrdGap*Point+(i-1)*StepSize*Point;
		  int Type = OP_SELLLIMIT; 
	     }
	     else
	     if (OrdersMode == 2)
		  {
		  SellPrice=open - FirstOrdGap*Point-(i-1)*StepSize*Point;
	     Type = OP_SELLSTOP; 
	     }
	     
	     if (InitialStop > 0) SellStop=SellPrice + InitialStop*Point; else SellStop=0;
        if (TakeProfit  > 0) SellProfit=SellPrice - TakeProfit*Point; else SellProfit=0;
		  
		  ticket = OrderSend( Symbol(),Type,Lotsi,
		                      NormalizeDouble(SellPrice, digit),
		                      Slippage,
		                      NormalizeDouble(SellStop , digit),
		                      NormalizeDouble(SellProfit   , digit),
		                      "sell",Magic,0,Red);
            
        SellInTrade=false;            
            
            if(ticket<0)
            {
            Print("SELL Order: OrderSend failed with error #",GetLastError());
            //
            }

}
// ---- Open Buy Orders
void BuyOrdOpen()
{		     
        if (OrdersMode == 1)
		  { 
		  double BuyPrice =open - FirstOrdGap*Point - (i-1)*StepSize*Point;
		  int Type = OP_BUYLIMIT;
		  }
		  else
		  if (OrdersMode == 2)
		  {
		  BuyPrice =open + FirstOrdGap*Point + (i-1)*StepSize*Point;
		  Type = OP_BUYSTOP;
		  }
		  
		  if (InitialStop >0) BuyStop = BuyPrice - InitialStop*Point; else BuyStop=0;
        if (TakeProfit  >0) BuyProfit=BuyPrice + TakeProfit*Point; else BuyProfit=0;  
		  
		  ticket = OrderSend(Symbol(),Type, Lotsi,
		                     NormalizeDouble(BuyPrice, digit),
		                     Slippage,
		                     NormalizeDouble(BuyStop , digit), 
		                     NormalizeDouble(BuyProfit  , digit),
		                     "buy",Magic,0,Blue);
                
        BuyInTrade=false;            
            
            if(ticket<0)
            {
            Print("BUY Order: OrderSend failed with error #",GetLastError());
            //return(0);
            }
}      
// ---- Delete Extra Orders
void AllOrdClose()
{
    int total = OrdersTotal();
    for (cnt=0;cnt<total;cnt++)
    { 
      OrderSelect(cnt, SELECT_BY_POS);   
      mode=OrderType();
      bool result = false, result2 = false;
        if ( OrderSymbol()==Symbol() && mode<=OP_SELL && OrderMagicNumber()==Magic )     
        {
         switch(mode)
         {
           //Close opened long positions
           case OP_BUY       : 
           result  = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), Slippage, Aqua);
           //break;
           //Close opened short positions
           case OP_SELL      : 
           result2 = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), Slippage, Magenta);
           //break;
           
         }
                        
	     }
	 }        
return;
}
// ---- Scan Trades
int ScanTrades()
{   
   int total = OrdersTotal();
   numords = 0;
      
   for(cnt=0; cnt<total; cnt++) 
   {        
   OrderSelect(cnt, SELECT_BY_POS);            
   if(OrderSymbol() == Symbol() && OrderType()>=OP_BUY && OrderMagicNumber() == Magic) 
   numords++;
   }
   return(numords);
}

double  ScanProfit()
{   
   int total = OrdersTotal();
   double profit = 0;
      
   for(cnt=0; cnt<total; cnt++) 
   {        
   OrderSelect(cnt, SELECT_BY_POS);            
   if(OrderSymbol() == Symbol() && OrderType()<=OP_SELL && OrderMagicNumber() == Magic) 
   profit = profit + OrderProfit();
   //Print(" Profit=",profit);
   }
   return (profit);
}

// Closing of Pending Orders      
void PendOrdDel()
{
    int total=OrdersTotal();
    for (int cnt=total-1;cnt>=0;cnt--)
    { 
      OrderSelect(cnt, SELECT_BY_POS);   
      
        if ( OrderSymbol()==Symbol() && OrderMagicNumber()==Magic  )     
        {
          int mode=OrderType();
          bool result = false;
          switch(mode)
          {
            case OP_BUYSTOP    : result = OrderDelete( OrderTicket() ); 
            case OP_SELLSTOP   : result = OrderDelete( OrderTicket() ); 
            case OP_BUYLIMIT   : result = OrderDelete( OrderTicket() ); 
            case OP_SELLLIMIT  : result = OrderDelete( OrderTicket() ); 
          
          //Print(" cnt=",cnt, " total=",total," MODE = ",mode," Ticket=",OrderTicket()  );                       
          }
         }
      } 
  return;
  }    
         	                    
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
   if(Bars < 1) {Print("Not enough bars for this strategy");return(0);}
   if(InitialStop < 10){Print("StopLoss less than 10")  ;return(0);}
   if(TakeProfit  < 10){Print("TakeProfit less than 10");return(0);}
   if(AccountFreeMargin()<(1000*Lots)){
   Print("We have no money. Free Margin = ", AccountFreeMargin());
   return(0);}
//---- 
   if ( Trace ) SetTrace();
   
   open  = iOpen(NULL,PeriodName,0);
      
   digit  = MarketInfo(Symbol(),MODE_DIGITS);
          
 if (Previous_bar!=iTime(Symbol(),PeriodName,0)) 
   {  
   //PendOrdDel(); 
   //AllOrdClose();
   
   
   Lotsi = MoneyManagement ( MM, Lots, MMRisk, LossMax);
    
   if(ScanTrades()<1)
   {
   for( i=1; i<= NumberOrds; i++) BuyOrdOpen();
   for( i=1; i<= NumberOrds; i++) SellOrdOpen();
   }
      
   Previous_bar=iTime(Symbol(),PeriodName,0);  
   }
   else 
   {
   Previous_bar=iTime(Symbol(),PeriodName,0); 
   }
   
   if (ScanProfit() >= NetProfit) { AllOrdClose();PendOrdDel();} 
   else
   if (ScanProfit() <= -NetLoss) { AllOrdClose();PendOrdDel();}
   //if (TrailingStop>0 || ProfitLock>0) TrailStops(); 
   
 return(0);
}//int start
//+------------------------------------------------------------------+





