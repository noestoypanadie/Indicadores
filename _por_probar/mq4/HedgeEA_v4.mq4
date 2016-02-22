//+------------------------------------------------------------------+
//|                                                      HedgeEA.mq4 |
//|                                  Copyright © 2006, Forex-TSD.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Forex-TSD.com "
#property link      "http://www.forex-tsd.com/"


#include <stdlib.mqh>

//---- input parameters
extern string     ExpertName       = "HedgeEA V.4";
extern int        Magic            = 1001;                   // Magic Number ( 0 - for All positions)
extern string     Symbol1          = "GBPJPY";
extern bool       Symbol1isLong    = true;
extern string     Symbol2          = "CHFJPY";
extern bool       Symbol2isLong    = false;
extern string     Lotsizes         = "Set Ratio to 1 to use equal";
extern double     Lots             = 0.1;                    //Lots
extern double     Ratio            = 1.8;
extern string     Data             = " Input Data ";
extern bool       StopManageAcc    = false;                  // Stop of Manage Account switch(Close All Trades)
extern bool       UsePips          = false;    
extern double     ProfitTarget     = 50;                     // Profit target in pips or USD       	
extern double     MaxLoss          = 0;                      // Maximum total loss in pips or USD 
extern string     Data2            = "Correlation Settings";
extern bool       UseCorrelation   = false;                   // If the correlation is used to check before put new Orders 
extern double     MinCorrelation   = 0.8; 
extern double     MaxCorrelation   = 1.0;
extern string     Data3            = "SWAP Settings";
extern bool       UseSwap          = true;
extern string     Data4            = "Money Management";
extern bool       AccountIsMicro   = false;
extern bool       MoneyManagement  = true;
extern double     Risk             = 15;                     // 10%

// extern string     Data3            = " Double Hedge ";
// extern bool       UseDoubleHedge   = true;                 // Set to false to exit one hedge as soon as possible
// extern int        Magic2           = 9009;                   

string comment = "";
int totalPips=0;
double  totalProfits=0;
bool CloseSignal=false;
bool signal1=true;
double valueswap = 0;
// int Lots=0;
// double Lots;

// added this

double Correlation;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
   //CloseSignal=false;
//----
   return(0);
  }

// ---- Scan Open Trades
int ScanOpenTrades()
{   
   int total = OrdersTotal();
   int numords = 0;
    
   for(int cnt=0; cnt<=total-1; cnt++) 
   {        
   OrderSelect(cnt, SELECT_BY_POS);            
      if(OrderType()<=OP_SELL)
      {
      if(Magic > 0) if(OrderMagicNumber() == Magic) numords++;
      if(Magic == 0) numords++;
      }
   }   
   return(numords);
}

// Generate Comment on OrderSend 
string GenerateComment(string ExpertName, int Magic, int timeFrame)
{
   return (StringConcatenate(ExpertName, "-", Magic, "-", timeFrame));
}


// Closing of Open Orders      
void OpenOrdClose()
{
    int total=OrdersTotal();
    for (int cnt=0;cnt<total;cnt++)
    { 
    OrderSelect(cnt, SELECT_BY_POS);   
    int mode=OrderType();
    bool res = false; 
    bool condition = false;
    if ( Magic>0 && OrderMagicNumber()==Magic ) condition = true;
    else if ( Magic==0 ) condition = true;
      if (condition && ( mode==OP_BUY || mode==OP_SELL ))
      { 
// - BUY Orders         
         if(mode==OP_BUY)
         {  
         res = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),3,Yellow);
               
            if( !res )
            {
            Print(" BUY: OrderClose failed with error #",GetLastError());
            Print(" Ticket=",OrderTicket());
            Sleep(3000);
            }
         break;
         }
         else     
// - SELL Orders          
         if( mode == OP_SELL)
         {
         res = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),3,White);
                 
            if( !res )
            {
            Print(" SELL: OrderClose failed with error #",GetLastError());
            Print(" Ticket=",OrderTicket());
            Sleep(3000);
            }
         break;    
         }  
      }                  
   }
}

void TotalProfit()
{
   int total=OrdersTotal();
   totalPips = 0;
   totalProfits = 0;
   valueswap = 0;
   for (int cnt=0;cnt<total;cnt++)
   { 
   OrderSelect(cnt, SELECT_BY_POS);   
   int mode=OrderType();
   bool condition = false;
   if ( Magic>0 && OrderMagicNumber()==Magic ) condition = true;
   else if ( Magic==0 ) condition = true;   
      if (condition)
      {      
         
         switch (mode)
         {
         case OP_BUY:
            totalPips += MathRound((MarketInfo(OrderSymbol(),MODE_BID)-OrderOpenPrice())/MarketInfo(OrderSymbol(),MODE_POINT));
            //totalPips += MathRound((Bid-OrderOpenPrice())/Point);
            totalProfits += OrderProfit();
            break;
            
         case OP_SELL:
            totalPips += MathRound((OrderOpenPrice()-MarketInfo(OrderSymbol(),MODE_ASK))/MarketInfo(OrderSymbol(),MODE_POINT));
            //totalPips += MathRound((OrderOpenPrice()-Ask)/Point);
            totalProfits += OrderProfit();
            break;
          
                 
                       
         }
      }            
	}
}

void SwapProfit()
{
   int total=OrdersTotal();
   valueswap = 0;
   for (int cnt=0;cnt<total;cnt++)
   { 
   OrderSelect(cnt, SELECT_BY_POS);   
   int mode=OrderType();
   bool condition = false;
   if ( Magic>0 && OrderMagicNumber()==Magic ) condition = true;
   else if ( Magic==0 ) condition = true;   
      if (condition)
      {      
      
      valueswap = valueswap + OrderSwap();
         
      }            
	}
}

void ChartComment()
{
   string sComment   = "";
   string sp         = "----------------------------------------\n";
   string NL         = "\n";

   sComment = sp;
   sComment = sComment + "Open Positions      = " + ScanOpenTrades() + NL;
   sComment = sComment + "Current Profit(pips)= " + totalPips + NL;
   sComment = sComment + "Current Profit(USD) = " + DoubleToStr(totalProfits,2) + NL + NL; 
 
   if(UseCorrelation){sComment = sComment + "Correlation              = " + DoubleToStr(Correlation,2) + NL + NL;}
   sComment = sComment + "SWAP Value (USD)   = " + DoubleToStr(valueswap,2) + NL;
   if(UseSwap){
          sComment = sComment + "SWAP Enabled" + NL;
       } else {
          sComment = sComment + "SWAP Disabled" + NL;
       }
   sComment = NL + sComment + "Net Value (USD)      = " + DoubleToStr(totalProfits+valueswap,2) + NL;
 //  sComment = sComment + "Account Leverage 1:" + AccountLeverage() + NL;
   sComment = sComment + sp;
  
   Comment(sComment);
}	  


// added MM v3
double LotSize()
{
     double lotMM = MathCeil(AccountFreeMargin() *  Risk / 1000) / 100 / 2;
	  
	  if(AccountIsMicro==false)           //normal account
	  {
	     if(lotMM < 0.1)                  lotMM = Lots;
	     if((lotMM > 0.5) && (lotMM < 1)) lotMM = 0.5;
	     if(lotMM > 1.0)                  lotMM = MathCeil(lotMM);
	     if(lotMM > 100)                  lotMM = 100;
	  }
	  else //micro account
	  {
	     if(lotMM < 0.01)                 lotMM = Lots;
	     if(lotMM > 1.0)                  lotMM = MathCeil(lotMM);
	     if(lotMM > 100)                  lotMM = 100;
	  }
	  
	  return (lotMM);
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
  
  Correlation= iCustom(NULL,0,"Correlation",Symbol1,Symbol2,20,0,0);  
  
   if(ScanOpenTrades()==0) CloseSignal=false;
   
   TotalProfit();
   SwapProfit();
   ChartComment();

   if (UseSwap) {totalProfits = totalProfits + valueswap;}
    
   if (!StopManageAcc)
   {
      if(ScanOpenTrades() > 0 && !CloseSignal && (ProfitTarget>0 || MaxLoss>0))
      {
         if(UsePips)
         {
         if(ProfitTarget > 0 && totalPips>=ProfitTarget) CloseSignal=true;    
         if(MaxLoss > 0 && totalPips <= -MaxLoss) CloseSignal=true; 
         //Print("pips: totalPips =",totalPips," signal=",CloseSignal); 
         }
         else
         {
         if(ProfitTarget > 0 && totalProfits>=ProfitTarget) CloseSignal=true;
         if(MaxLoss > 0 && totalProfits <= -MaxLoss) CloseSignal=true;
         //Print("usd: tatalprofit=",totalProfits," signal=",CloseSignal);
         }        
      }   
   }
   else 
   { if (ScanOpenTrades() > 0) CloseSignal=true;}    
   
   //Print("Signal=",CloseSignal);
   if( CloseSignal ) OpenOrdClose();

// Prepare Comment line for the trades

     if(Symbol1isLong) {
     comment = "L/"; 
     } else {
     comment = "S/";
     }
     if(Symbol2isLong) {
     comment = comment + "L";
     } else {
     comment = comment + "S";
     }
     
     comment = comment + " " + GenerateComment(ExpertName, Magic, Period());

// added MM statement

     double OrderLots1,OrderLots2;


     if(MoneyManagement) {
     
     OrderLots1 = NormalizeDouble(LotSize(),2);                   //Adjust the lot size
     OrderLots2 = NormalizeDouble(OrderLots1 * Ratio,2);
     
     } else {
     
     OrderLots1 = NormalizeDouble(Lots,2);
     OrderLots2 = NormalizeDouble(Lots * Ratio,2);
   
     }
     
     
// Added signal1 that will store correlation logic if used 
     
     if(UseCorrelation) {
        if(Correlation < MaxCorrelation && Correlation > MinCorrelation) {
            signal1 = true;
        } else {
            signal1 = false;
        }
     }
     
     
// Long/Short   
     
     if(ScanOpenTrades()==0 && Symbol1isLong && !Symbol2isLong && !StopManageAcc && signal1){
    
      CloseSignal=false;
      
      OrderSend(Symbol1,OP_BUY,OrderLots1,MarketInfo(Symbol1,MODE_ASK),3,0,0,comment,Magic,0,Blue);
      OrderSend(Symbol2,OP_SELL,OrderLots2,MarketInfo(Symbol2,MODE_BID),3,0,0,comment,Magic,0,Red);
      }
      

// Short/Short


     if(ScanOpenTrades()==0 && !Symbol1isLong && !Symbol2isLong && !StopManageAcc && signal1){
    
      CloseSignal=false;
      
      OrderSend(Symbol1,OP_SELL,OrderLots1,MarketInfo(Symbol1,MODE_BID),3,0,0,comment,Magic,0,Red);
      OrderSend(Symbol2,OP_SELL,OrderLots2,MarketInfo(Symbol2,MODE_BID),3,0,0,comment,Magic,0,Red);
      }
      
      
      
// Long/Long

     if(ScanOpenTrades()==0 && Symbol1isLong && Symbol2isLong && !StopManageAcc && signal1){
    
      CloseSignal=false;
      
      OrderSend(Symbol1,OP_BUY,OrderLots1,MarketInfo(Symbol1,MODE_ASK),3,0,0,comment,Magic,0,Blue);
      OrderSend(Symbol2,OP_BUY,OrderLots2,MarketInfo(Symbol2,MODE_ASK),3,0,0,comment,Magic,0,Blue);
      }
              
 return(0);
}//int start
//+------------------------------------------------------------------+