//+------------------------------------------------------------------+
//|                                                      Samuray.mq4 |
//|                                                            Kokas |
//|                                       http://www.forexforums.org |
//+------------------------------------------------------------------+
#property copyright "Kokas"
#property link      "http://www.forexforums.org"

//---- input parameters

extern string     ExpertName         = "Samuray GBPJPY";
//extern double     MarginTrade        = 1;
extern bool       AutoTrade          = true;
extern int        MaxTrades          = 50;
extern double     RecycleProfit      = 300;
extern bool       UseSwap            = false;
extern double     InitialStop        = 0;
extern double     BreakEven          = 10;        // Profit Lock in pips  
extern double     StepSize           = 10;
extern double     MinDistance        = 15;
extern bool       SecureOrders       = true;                        // If set to true only open orders when in profi
extern double     MinPip             = 10;                          // Min Profit Pips to open another order
extern bool       CloseAll           = false;                       // Set true to close all current Orders
extern int        Magic              = 5665;                        // Magic Number of the EA
extern double     Lots               = 0.01;                         // Lot size when not using MM
extern bool       MoneyManagement    = false;  
extern bool       AccountIsMicro     = false;
extern double     MaxLotSize         = 100;
extern double     Risk               = 10;
extern string     Param2             = "Bollinger Band Settings";
extern double     Bollinger_Period   = 20;                           
extern double     Bollinger_TF       = 60;
extern double     Bollinger_Dev      = 2;

int   k, digit=0;
bool BE = false;
double AccountSize,totalPips,totalProfits;
double pBid, pAsk, pp,valueswap;

bool signal1 = true, signal2 =true, signal3 = true , signal4 = true, SecureSignal = true;
string comment = "";
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   
//----
   return(0);
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
  
  
void ChartComment()
{
   string sComment   = "";
   string sp         = "****************************\n";
   string NL         = "\n";

   sComment = sp;
   sComment = sComment + "Open Positions      = " + ScanOpenTrades() + NL;
   sComment = sComment + "Current Profit(Pip)= " + totalPips + NL;
   sComment = sComment + "SWAP Value (Pip)   = " + DoubleToStr(valueswap,2) + NL;
   if(UseSwap){
          sComment = sComment + "SWAP Enabled" + NL;
       } else {
          sComment = sComment + "SWAP Disabled" + NL;
       }
   sComment = NL + sComment + "Net Value (Pip)      = " + DoubleToStr(totalPips+valueswap,2) + NL;
   sComment = sComment + NL + sp;
   
   Comment(sComment);
}	    
  
  
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
	
	if (UseSwap) {
	
	SwapProfit();
	totalProfits = totalProfits + valueswap;
	}
	
	}
}

// MoneyManagement with Account Leverage Protection

double LotSize()
{
     double lotMM = MathCeil(AccountFreeMargin() *  Risk / 1000) / AccountLeverage() / 2;
	  
	  if(AccountIsMicro==false)                          //normal account
	  {
	     if(lotMM < 0.1)                    lotMM = 0.1;
	     if((lotMM >= 0.1) && (lotMM < 0.2)) lotMM = 0.2;
	     if((lotMM >= 0.2) && (lotMM < 0.3)) lotMM = 0.3;
	     if((lotMM >= 0.3) && (lotMM < 0.4)) lotMM = 0.4;
	     if((lotMM >= 0.4) && (lotMM < 1))   lotMM = 0.5;  
	     if(lotMM >= 1.0)                    lotMM = MathCeil(lotMM);
	     if(lotMM >= MaxLotSize)             lotMM = MaxLotSize;
	  }
	  else                                               //micro account
	  {
	     if(lotMM < 0.01)                 lotMM = 0.01; 
	     if((lotMM >= 0.01) && (lotMM < 0.02)) lotMM = 0.02;
	     if((lotMM >= 0.02) && (lotMM < 0.03)) lotMM = 0.03;
	     if((lotMM >= 0.03) && (lotMM < 0.04)) lotMM = 0.04;
	     if((lotMM >= 0.05) && (lotMM < 0.06)) lotMM = 0.05; 
	     if((lotMM >= 0.06) && (lotMM < 0.07)) lotMM = 0.06; 
	     if((lotMM >= 0.07) && (lotMM < 0.08)) lotMM = 0.08; 
	     if((lotMM >= 0.08) && (lotMM < 0.09)) lotMM = 0.09;
	     if((lotMM >= 0.09) && (lotMM < 0.10)) lotMM = 0.1;  
	     if((lotMM >= 0.1) && (lotMM < 0.2)) lotMM = 0.2;
	     if((lotMM >= 0.2) && (lotMM < 0.3)) lotMM = 0.3;
	     if((lotMM >= 0.3) && (lotMM < 0.4)) lotMM = 0.4;
	     if((lotMM >= 0.4) && (lotMM < 1))   lotMM = 0.5; 	   
	     if(lotMM >= 1.0)                    lotMM = MathCeil(lotMM);
	     if(lotMM >= MaxLotSize)             lotMM = MaxLotSize;
	  }
  
     if(AccountIsMicro)  {
     
     AccountSize=2;
     
     } else {
     
     AccountSize=1;
     
     }
     
     lotMM = NormalizeDouble(lotMM,AccountSize);
   
	  return (lotMM);
}

void StepStops()
{        
    double BuyStop, SellStop;
    int total=OrdersTotal();
    for (int cnt=0;cnt<total;cnt++)
    { 
     OrderSelect(cnt, SELECT_BY_POS);   
     int mode=OrderType();    
        if ( OrderSymbol()==Symbol() && OrderMagicNumber()==Magic ) 
        {
            if ( mode==OP_BUY )
            {
               BuyStop = OrderStopLoss();
               if ( Bid-OrderOpenPrice()>0 || OrderStopLoss()==0) 
               {
               if ( Bid-OrderOpenPrice()>=Point*BreakEven && !BE) {BuyStop = OrderOpenPrice();BE = true;}
               
               if (OrderStopLoss()==0) {BuyStop = OrderOpenPrice() - InitialStop * Point; k=1; BE = false;}
               
               if ( Bid-OrderOpenPrice()>= k*StepSize*Point) 
               {
               BuyStop = OrderStopLoss()+ StepSize*Point; 
               if (Bid - BuyStop >= MinDistance*Point)
               { BuyStop = BuyStop; k=k+1;}
               else
               BuyStop = OrderStopLoss();
               }                              
               //Print( " k=",k ," del=", k*StepSize*Point, " BuyStop=", BuyStop," digit=", digit);
               OrderModify(OrderTicket(),OrderOpenPrice(),
                           NormalizeDouble(BuyStop, digit),
                           OrderTakeProfit(),0,LightGreen);
			      return(0);
			      }
			   }
            if ( mode==OP_SELL )
            {
               SellStop = OrderStopLoss();
               if ( OrderOpenPrice()-Ask>0 || OrderStopLoss()==0) 
               {
               if ( OrderOpenPrice()-Ask>=Point*BreakEven && !BE) {SellStop = OrderOpenPrice(); BE = true;}
               
               if ( OrderStopLoss()==0 ) { SellStop = OrderOpenPrice() + InitialStop * Point; k=1; BE = false;}
               
               if ( OrderOpenPrice()-Ask>=k*StepSize*Point) 
               {
               SellStop = OrderStopLoss() - StepSize*Point; 
               if (SellStop - Ask >= MinDistance*Point)
               { SellStop = SellStop; k=k+1;}
               else
               SellStop = OrderStopLoss();
               }
               //Print( " k=",k," del=", k*StepSize*Point, " SellStop=",SellStop," digit=", digit);
               OrderModify(OrderTicket(),OrderOpenPrice(),
   		                  NormalizeDouble(SellStop, digit),
   		                  OrderTakeProfit(),0,Yellow);	    
               return(0);
               }    
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
      if (condition && OrderSwap()!=0)
      {     
      valueswap = valueswap + OrderSwap()/PipCost(OrderSymbol());         // ERROOOOOOOOOOOOOOOOOOOOOOOOOOO
      }            
	}
}

//+--------- --------- --------- --------- --------- --------- ----+
//+ Calculate cost in USD of 1pip of given symbol
//+--------- --------- --------- --------- --------- --------- ----+
double PipCost (string TradeSymbol) {
double Base, Cost;
string TS_13, TS_46, TS_4L;

TS_13 = StringSubstr (TradeSymbol, 0, 3);
TS_46 = StringSubstr (TradeSymbol, 3, 3);
TS_4L = StringSubstr (TradeSymbol, 3, StringLen(TradeSymbol)-3);

Base = MarketInfo (TradeSymbol, MODE_LOTSIZE) * MarketInfo (TradeSymbol,MODE_POINT);
if ( TS_46 == "USD" )
Cost = Base;
else if ( TS_13 == "USD" )
Cost = Base / MarketInfo (TradeSymbol, MODE_BID);
else if ( PairExists ("USD"+TS_4L) )
Cost = Base / MarketInfo ("USD"+TS_4L, MODE_BID);
else
Cost = Base * MarketInfo (TS_46+"USD" , MODE_BID);

return(Cost) ;
}

//+--------- --------- --------- --------- --------- --------- ----+
//+ Returns true if given symbol exists
//+--------- --------- --------- --------- --------- --------- ----+
bool PairExists (string TradeSymbol) {
return ( MarketInfo (TradeSymbol, MODE_LOTSIZE) > 0 );
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+

int start()
  {
  
  digit  = MarketInfo(Symbol(),MODE_DIGITS);
  
  double BandsLower = iBands(Symbol(),Bollinger_TF,Bollinger_Period,Bollinger_Dev,0,0,2,0);          // Lower  Bollinger
  double BandsUpper = iBands(Symbol(),Bollinger_TF,Bollinger_Period,Bollinger_Dev,0,0,1,0);          // Upper  Bollinger
  double Bands = (BandsLower + BandsUpper) / 2;                                                      // Middle Bollinger

  signal1 = false;
  signal2 = false;
  signal3 = false;
  signal4 = true;

  if (CloseAll) {
      
      OpenOrdClose();
      signal4 = false;
      
  }
  
  TotalProfit();
  
  if (totalPips > RecycleProfit) {
  
      OpenOrdClose();
      signal4 = false;
  
  }
  
  
  if (ScanOpenTrades() < MaxTrades) signal1 = true;
  
  if (ScanOpenTrades() == 0){
  
          signal2 = true;
  
  } else {
  
          signal2 = true; // if (AccountFreeMargin() > (AccountBalance()+AccountBalance()*MarginTrade/100)) signal2 = true;  /// ERROOOOOOOOOOOOOOOOOOOOOOOOOOO
  
  } 
  
  if (MarketInfo(Symbol(),MODE_ASK) < Bands) signal3 = true;
 
  if (MoneyManagement) Lots = LotSize();

  if (SecureOrders){
     
     if (totalPips > MinPip || ScanOpenTrades() == 0){
     
        SecureSignal = true;
        
     } else {
     
        SecureSignal = false;
     }  
  
  } else {
  
  SecureSignal = true;
  
  }

  comment = "O:" + DoubleToStr(ScanOpenTrades(),0);
  

//+------------------------------------------------------------------+

   if (signal1 && signal2 && signal3 && signal4 && AutoTrade && SecureSignal){
   
   // signal1 - Control the number of open orders
   // signal2 - Check Margin (INACTIVE)
   // signal3 - Bollinger Bands Filter
   // signal4 - Control Recycle Profits
  
   OrderSend(Symbol(),OP_BUY,Lots,MarketInfo(Symbol(),MODE_ASK),3,0,0,comment,Magic,0,Blue);
   }
   
   if (BreakEven>0 || InitialStop>0 || StepSize>0) StepStops(); 
   
   ChartComment();
      
  return(0);
  }

//+------------------------------------------------------------------+