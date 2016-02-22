//+------------------------------------------------------------------+
//|                                                      HedgeEA.mq4 |
//|                                  Copyright © 2006, Forex-TSD.com |
//+------------------------------------------------------------------+

//first v  used code from (EA's by Igorad,waltini) by kokas,cturner
//v5.0 latest greatest version by kokas
//v5.1 10-23-06 added bollinger filter, micro account by cturner
//v5.2 10-24-06 added logic to catch and fix 1 of the 2 trades not being placed due to error
//v5.3 10-24-06 correlation logic built in by Nicholishen  
//v5.4 10-24-06 bug fixes on open orders by cturner
//v5.5 10-30-06 added short/long option that was missing by cturner
//v5.6 10-30-06 added Autotrade, to stop entering automatic after exit, by kokas


#property copyright "Copyright © 2006, Forex-TSD.com "
#property link      "http://www.forex-tsd.com/"

#include <stdlib.mqh>

//---- input parameters
extern string     Expert        = "HedgeEA[5.6]";                // Expert Name and first part of comment line
extern int        Magic            = 100;                           // Magic Number ( 0 - for All positions)
extern bool       Autotrade        = true;                          // Set to false to prevent an entry after an exit
extern string     Symbol1          = "GBPJPY";
extern bool       Symbol1isLong    = true;                          // Set to true to put long orders on the second pair
extern string     Symbol2          = "CHFJPY";
extern bool       Symbol2isLong    = false;                         // Set to true to put long orders on the second pair
extern string     Lotsizes         = "Set Ratio to 1 to use equal";
extern double     Lots             = 0.01;                          // Lots for first pair if MM is turned off
extern double     Ratio            = 1.8;                           // Ratio between the two pairs
extern string     Data             = " Input Data ";
extern bool       StopManageAcc    = false;                         // Stop of Manage Account switch(Close All Trades)
extern double     ProfitTarget     = 50;                            // Profit target in pips or USD       	
extern double     MaxLoss          = 0;                             // Maximum total loss in pips or USD 
extern string     Data2            = "Correlation Settings";
extern bool       UseCorrelation   = false;                         // Set to true if you want to use correlation as an entry signal
extern int        cPeriod          = 20;                            // If the correlation is used to check before put new Orders 
extern double     MinCorrelation   = 0.8; 
extern double     MaxCorrelation   = 1.0;
extern string     Data3            = "Bollinger Band Settings";
extern bool       UseBollinger     = false;                         // Set to true to use Bollinger bands as an entry signal
extern string     Bollinger_Symbol = "GBPCHF";
extern double     Bollinger_Period = 60;                            // Period must be in minutes
extern string     Data4            = "SWAP Settings";               
extern bool       UseSwap          = true;                          // Select true if you want to use swap on profit calculation
extern string     Data5            = "Money Management";
extern bool       AccountIsMicro   = true;                          // Set true if you use a micro account
extern bool       MoneyManagement  = true;
extern double     Risk             = 15;                            // 10%

string comment = "";
int totalPips=0;
double  totalProfits=0;
bool CloseSignal=false;
bool signal1=true;
bool signal2=true;
double valueswap = 0;
double Correlation;
double Bands;
int ticket1=0
   ,ticket2=0
   ,Symbol1SP
   ,Symbol2SP
   ,Order1=0
   ,Order2=0
   ,c1=0
   ,c2=0
   ,Symbol1OP
   ,Symbol2OP
   ,numords=0
   ;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 

   //____________________________________________________________________________________________         
   if(Symbol1isLong){Symbol1OP=OP_BUY;}
   else           {Symbol1OP=OP_SELL;}
   
   if(Symbol2isLong){Symbol2OP=OP_BUY;}
   else           {Symbol2OP=OP_SELL;}
   //____________________________________________________________________________________________ 
   //CloseSignal=false;
//----
   return(0);
  }

// ---- Scan Open Trades
int ScanOpenTrades()
{   
           
   Order1=0;Order2=0;  
   int total = OrdersTotal();
int numords = 0;
    
   for(int cnt=0; cnt<=total-1; cnt++)
   {
    OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    //if(OrderMagicNumber()==Magic)
    if(Magic > 0) if(OrderMagicNumber() == Magic) numords++;
    {
    if(OrderType()==Symbol1OP && OrderMagicNumber() == Magic && OrderSymbol()==Symbol1)Order1  += 1;
    if(OrderType()==Symbol2OP && OrderMagicNumber() == Magic && OrderSymbol()==Symbol2)Order2  += 1;
    }    
   }
//   int total = OrdersTotal();
//int numords = 0;
    
  // for(int cnt=0; cnt<=total-1; cnt++) 
   //{        
//   OrderSelect(cnt, SELECT_BY_POS);            
  //    if(OrderType()<=OP_SELL)
    //  {
      //if(Magic > 0) if(OrderMagicNumber() == Magic) numords++;
//      if(Magic == 0) numords++;
  //    }
//   }   
   return(numords);
}

// Generate Comment on OrderSend 
string GenerateComment(string Expert, int Magic, int time)
{
   return (StringConcatenate(Expert, "-", Magic, "-", time));
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
 
   if(UseCorrelation){sComment = sComment + "Correlation              = " + DoubleToStr(Correlation,3) + NL + NL;}
   if(UseBollinger){sComment = sComment + "Bollinger Middle           = " + DoubleToStr(Bands,4) + NL;} 
   if(UseBollinger){sComment = sComment + "Bollinger Pair Price       = " + DoubleToStr(MarketInfo(Bollinger_Symbol,MODE_ASK),4) + NL + NL;}
   sComment = sComment + "SWAP Value (USD)   = " + DoubleToStr(valueswap,2) + NL;
   if(UseSwap){
          sComment = sComment + "SWAP Enabled" + NL;
       } else {
          sComment = sComment + "SWAP Disabled" + NL;
       }
   sComment = NL + sComment + "Net Value (USD)      = " + DoubleToStr(totalProfits+valueswap,2) + NL;
   sComment = sComment + "Account Leverage 1:" + AccountLeverage() + NL;
   sComment = sComment + sp;

   Comment(sComment);
}	  


// added MM v3
double LotSize()
{
     double lotMM = MathCeil(AccountFreeMargin() *  Risk / 1000) / 100 / 2;
	  
//	  if(AccountIsMicro==false)           //normal account
//	  {
	     if(lotMM < 0.1)                  lotMM = 0.1; // Lots miss between 0.1 and 0.5 ?? 
	     if((lotMM > 0.5) && (lotMM < 1)) lotMM = 0.5;
	     if(lotMM > 1.0)                  lotMM = MathCeil(lotMM);
	     if(lotMM > 100)                  lotMM = 100;
//	  }
//	  else //micro account
//	  {
//	     if(lotMM < 0.01)                 lotMM = 0.01; // Lots;
//	     if(lotMM > 1.0)                  lotMM = MathCeil(lotMM);
//	     if(lotMM > 100)                  lotMM = 100;
//	  }
	  
	  
	  Print(lotMM);
	  
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
  
  Correlation= CorrelationIND(Symbol1,Symbol2,0);

//added Bollinger Filter

   Bands=iCustom(Bollinger_Symbol,Bollinger_Period,"Bands",20,0,2,0,0,0);  
  
 //  if(ScanOpenTrades()==0) CloseSignal=false; Order1=0; Order2=0;
 //  if(ScanOpenTrades()==2) Order1=1; Order2=1;
   
   TotalProfit();
   SwapProfit();
   ChartComment();

   if (UseSwap) {totalProfits = totalProfits + valueswap;}
    
   if (!StopManageAcc)
   {
      if(ScanOpenTrades() > 0 && !CloseSignal && (ProfitTarget>0 || MaxLoss>0))
      {
        if(ProfitTarget > 0 && totalProfits>=ProfitTarget) CloseSignal=true;
        if(MaxLoss > 0 && totalProfits <= -MaxLoss) CloseSignal=true;
 
      }   
   }
   else 
   { if (ScanOpenTrades() > 0) CloseSignal=true;}    
   
   if( CloseSignal ) OpenOrdClose();

// Prepare Comment line for the trades

     if(Symbol1isLong) {
     comment = Symbol1 + "_L/"; 
     } else {
     comment = Symbol1 + "_S/";
     }
     if(Symbol2isLong) {
     comment = comment + "L_" + Symbol2;
     } else {
     comment = comment +"S_" + Symbol2;
     }
     
     comment = comment + " " + GenerateComment(Expert, Magic, Period());
     
// Micro or Mini

double AccountSize;

     if(AccountIsMicro)  {
     
     AccountSize=2;
     
     } else {
     
     AccountSize=1;
     
     }        

// added MM statement

double OrderLots1,OrderLots2;


     if(MoneyManagement) {
     
     OrderLots1 = NormalizeDouble(LotSize(),AccountSize); //Adjust the lot size
     OrderLots2 = NormalizeDouble(LotSize() * Ratio,AccountSize); // change 2 to 1 for mini account
     
     } else {
     
     OrderLots1 = Lots;
     OrderLots2 = NormalizeDouble(Lots * Ratio,2); //change 2 to 1 for mini account
   
     }
      
     
// Added signal1 that will store correlation logic if used 
     
     if(UseCorrelation) {
        if(Correlation < MaxCorrelation && Correlation > MinCorrelation) {
            signal1 = true;
        } else {
            signal1 = false;
        }
     }
     
     Print(OrderLots1," + ",OrderLots2);     
     
// Added signal2 that will store bollinger logic if used 
     
     if(UseBollinger) {
        if(MarketInfo(Bollinger_Symbol,MODE_ASK) < Bands) {
            signal2 = true;
        } else {
            signal2 = false;
        }
     }     
     
     Print(OrderLots1," + ",OrderLots2);
     
// Long/Short   
     
     if((Order1==0 || Order2==0) && Symbol1isLong && !Symbol2isLong && !StopManageAcc && signal1 && signal2 && Autotrade){
    
      CloseSignal=false;
      
      if (Order1==0) {
      OrderSend(Symbol1,OP_BUY,OrderLots1,MarketInfo(Symbol1,MODE_ASK),3,0,0,comment,Magic,0,Blue);
      if (GetLastError()==0) {Order1=1;}
      }
      if (Order2==0) {
      OrderSend(Symbol2,OP_SELL,OrderLots2,MarketInfo(Symbol2,MODE_BID),3,0,0,comment,Magic,0,Red);
      if (GetLastError()==0) {Order2=1;}
      }
      }
      
// Short/Long   
     
     if((Order1==0 || Order2==0) && !Symbol1isLong && Symbol2isLong && !StopManageAcc && signal1 && signal2 && Autotrade){
    
      CloseSignal=false;
      
      if (Order1==0) {
      OrderSend(Symbol1,OP_SELL,OrderLots1,MarketInfo(Symbol1,MODE_BID),3,0,0,comment,Magic,0,Red);
      if (GetLastError()==0) {Order1=1;}
      }
      if (Order2==0) {
      OrderSend(Symbol2,OP_BUY,OrderLots2,MarketInfo(Symbol2,MODE_ASK),3,0,0,comment,Magic,0,Blue);
      if (GetLastError()==0) {Order2=1;}
      }
      }
  

// Short/Short


     if((Order1==0 || Order2==0) && !Symbol1isLong && !Symbol2isLong && !StopManageAcc && signal1 && signal2 && Autotrade){
    
      CloseSignal=false;
      
      if (Order1==0) {
      OrderSend(Symbol1,OP_SELL,OrderLots1,MarketInfo(Symbol1,MODE_BID),3,0,0,comment,Magic,0,Red);
      if (GetLastError()==0) {Order1=1;}
      }
      if (Order2==0) {
      OrderSend(Symbol2,OP_SELL,OrderLots2,MarketInfo(Symbol2,MODE_BID),3,0,0,comment,Magic,0,Red);
      if (GetLastError()==0) {Order2=1;}
      }
      }
      
      
      
// Long/Long

     if((Order1==0 || Order2==0) && Symbol1isLong && Symbol2isLong && !StopManageAcc && signal1  && signal2 && Autotrade){
    
      CloseSignal=false;
      
      if (Order1==0) {
      OrderSend(Symbol1,OP_BUY,OrderLots1,MarketInfo(Symbol1,MODE_ASK),3,0,0,comment,Magic,0,Blue);
      if (GetLastError()==0) {Order1=1;}
      }
      if (Order2==0) {
      OrderSend(Symbol2,OP_BUY,OrderLots2,MarketInfo(Symbol2,MODE_ASK),3,0,0,comment,Magic,0,Blue);
      if (GetLastError()==0) {Order2=1;}
      }
      }
              
 return(0);
}//int start
//+------------------------------------------------------------------+


double CorrelationIND(string Symbol1,string Symbol2,int CorrelationShift=0){
   double Correlation[],DiffBuffer1[],DiffBuffer2[],PowDiff1[],PowDiff2[];
   ArrayResize(Correlation,cPeriod*2);ArrayResize(DiffBuffer1,cPeriod*2);
   ArrayResize(DiffBuffer2,cPeriod*2);ArrayResize(PowDiff1,cPeriod*2);ArrayResize(PowDiff2,cPeriod*2);
   for( int shift=cPeriod+1; shift>=0; shift--){
      DiffBuffer1[shift]=iClose(Symbol1,0,shift)-iMA(Symbol1,0,cPeriod,0,MODE_SMA,PRICE_CLOSE,shift);
      DiffBuffer2[shift]=iClose(Symbol2,0,shift)-iMA(Symbol2,0,cPeriod,0,MODE_SMA,PRICE_CLOSE,shift);
      PowDiff1[shift]=MathPow(DiffBuffer1[shift],2);
      PowDiff2[shift]=MathPow(DiffBuffer2[shift],2);
      double u=0,l=0,s=0;
      for( int i = cPeriod-1 ;i >= 0 ;i--){
         u += DiffBuffer1[shift+i]*DiffBuffer2[shift+i];
         l += PowDiff1[shift+i];
         s += PowDiff2[shift+i];
      }
      if(l*s >0)Correlation[shift]=u/MathSqrt(l*s);
   }   
   return(Correlation[CorrelationShift]);
   return(-1); 
}