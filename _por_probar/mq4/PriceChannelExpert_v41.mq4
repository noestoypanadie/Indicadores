//+------------------------------------------------------------------+
//|                                        PriceChannelExpert_v4.mq4 |
//|                                  Copyright © 2006, Forex-TSD.com |
//|                         Written by IgorAD,igorad2003@yahoo.co.uk |   
//|            http://finance.groups.yahoo.com/group/TrendLaboratory |                                      
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Forex-TSD.com "
#property link      "http://www.forex-tsd.com/"

#include <stdlib.mqh>
#include <Tracert.mqh>

//---- input parameters
extern string     Expert_Name    = "---- PriceChannelExpert_v4 ----";

extern int        Magic          = 10000;
extern int        Slippage       =     6;
extern bool       Trace          = false;    // Trace Switch

extern string     Main_data      = " Trade Volume & Trade Method";
extern double     Lots = 0.1;
extern double     TakeProfit     =   100;    // Take Profit Value 
extern double     InitialStop    =    50;    // Initial Stop Value
extern bool       TrailingStop   = false;    // Trailing Stop Switch   
extern bool       SwingTrade     = false;    // Swing Trade Switch
extern bool       PendingOrder   = false;    // PendingOrder/InstantExecution Switch
extern double     PendOrdGap     =    10;    // Gap from High/Low for Pending Orders
extern double     BreakEven      =    30;    // BreakEven Level in pips
extern double     BreakEvenGap   =     0;    // Pips when BreakEven will be reached

extern string     Calc_data      = " Price Channel Parameters ";
extern int        MainTimeFrame  =  1440;    // Large Time Frame in min
extern int        MainChanPeriod =     9;    // Price Channel Period for Large Time Frame
extern double     MainRisk       =   0.3;    // Overbought/Oversold Level 0...0.5 for Large Time Frame

extern int        ChanPeriod     =     9;    // Price Channel Period for current Time Frame 
extern double     Risk           =   0.3;    // Overbought/Oversold Level 0...0.5 for current Time Frame 

extern string     MM_data        = " MoneyManagement by L.Williams ";
extern bool       MM             = false;    // ÌÌ Switch
extern double     MMRisk         =  0.15;    // Risk Factor
extern double     MaxLoss        =  1000;    // Maximum Loss by 1 Lot

int    MainTrend=0, Trend=0, PrevTrend=0, digit, Signal=0, b=0, cnt=0, Kz=0, ticket=0;
double Mainsmin1,Mainsmax1,Mainbsmin1=0,Mainbsmax1=0,Mainbsmin2=0,Mainbsmax2=0,
       MainHigh=0, MainLow=0, MainClose1 = 0, 
       smin1=0,smax1=0,bsmin1=0,bsmax1=0,bsmin2=0,bsmax2=0,
       SellStop,BuyStop;

double MainTFdata[][6];
bool   BuyInTrade = false, SellInTrade = false;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
   
//----
   return(0);
  }

// ---- Scan Trades
int ScanTrades()
{   
   int total = OrdersTotal();
   int numords = 0;
      
   for(int cnt=0; cnt<total; cnt++) 
   {        
   OrderSelect(cnt, SELECT_BY_POS);            
   if(OrderSymbol() == Symbol() && OrderType()<=OP_SELLSTOP && OrderMagicNumber() == Magic) 
   numords++;
   }
   return(numords);
}  

void MainPriceChannel()
{   
  //double MainTFdata[][6];
   
  ArrayCopyRates(MainTFdata, Symbol(), MainTimeFrame);
  MainClose1 = MainTFdata[1][4];
  //Print(" MainClose = ",MainClose1," High=",MainTFdata[9][3]," Low=",MainTFdata[4][2]);
  Mainsmax1 = 0; Mainsmin1 = 100000;
  for ( int i=MainChanPeriod; i>=1; i--)
  {
  MainHigh  = MainTFdata[i][3];
  MainLow   = MainTFdata[i][2]; 
  Mainsmax1 = MathMax(Mainsmax1,MainHigh);
  Mainsmin1 = MathMin(Mainsmin1, MainLow);
  } 
  
  //Print(" Mainsmin = ",Mainsmin1, " Mainsmax = ",Mainsmax1);
  
  Mainbsmax2 = Mainbsmax1;
  Mainbsmin2 = Mainbsmin1; 
  
  Mainbsmax1 = Mainsmax1 - (Mainsmax1 - Mainsmin1 )* MainRisk;
  Mainbsmin1 = Mainsmin1 + (Mainsmax1 - Mainsmin1 )* MainRisk;
  
  
  if (MainRisk > 0)
  {
  if (MainClose1 > Mainbsmax1 && Mainbsmax1>0) MainTrend =  1;
  if (MainClose1 < Mainbsmin1 && Mainbsmin1>0) MainTrend = -1;
  }
  else
  {
  if (MainClose1 > Mainbsmax2 && Mainbsmax2>0) MainTrend =  1;
  if (MainClose1 < Mainbsmin2 && Mainbsmax2>0) MainTrend = -1;
  }
  
  if(MainTrend>0)
  {
  if(MainRisk>0 && MainClose1<Mainbsmin1) Mainbsmin1 = Mainbsmin2;
  if(Mainbsmin1<Mainbsmin2) Mainbsmin1 = Mainbsmin2;
  }
  else
  if(MainTrend<0)
  {
  if(MainRisk>0 && MainClose1>Mainbsmax2) Mainbsmax1 = Mainbsmax2;
  if(Mainbsmax1>Mainbsmax2) Mainbsmax1 = Mainbsmax2;
  } 
}

void PriceChannel()
{

  smin1=Low[Lowest(Symbol(),Period(),MODE_LOW,ChanPeriod,1)];   
  smax1=High[Highest(Symbol(),Period(),MODE_HIGH,ChanPeriod,1)];  
  PrevTrend = Trend;
  bsmax2 = bsmax1;
  bsmin2 = bsmin1; 
  
  bsmax1 = smax1 - (smax1 - smin1 )* Risk;
  bsmin1 = smin1 + (smax1 - smin1 )* Risk;
  
  
  if (Risk > 0)
  {
  if (Close[1] > bsmax1 && bsmax1 > 0) Trend =  1;
  if (Close[1] < bsmin1 && bsmin1 > 0) Trend = -1;
  }
  else
  {
  if (Close[1] > bsmax2 && bsmax2 > 0) Trend =  1;
  if (Close[1] < bsmin2 && bsmin2 > 0) Trend = -1;
  }
  
  if(Trend>0)
  {
  if(Risk>0 && Close[1]<bsmin1) bsmin1 = bsmin2;
  if(bsmin1<bsmin2) bsmin1 = bsmin2;
  }
  else
  if(Trend<0)
  {
  if(Risk>0 && Close[1]>bsmax2) bsmax1 = bsmax2;
  if(bsmax1>bsmax2) bsmax1 = bsmax2;
  } 
}
  
void TradeSignal()
{         
  if 
  (
  MainTrend >0 
  &&
  Trend>0
  && 
  PrevTrend<0
  ) Signal= 1;
  
  if 
  (
  MainTrend <0
  &&
  Trend<0
  && 
  PrevTrend>0
  ) Signal= -1;
}  

double MoneyManagement ( bool flag, double Lots, double risk, double maxloss)
{
   double Lotsi=Lots;
	    
   if ( flag ) Lotsi=NormalizeDouble(Lots*AccountFreeMargin()*MMRisk/MaxLoss,1);   
     
   if (Lotsi<0.1) Lotsi=0.1;  
   return(Lotsi);
}   

void CloseTrade()
{
   int ExitSignal = Signal;

   for (cnt=0;cnt<OrdersTotal();cnt++)
   { 
       OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);   
       int mode=OrderType();
       if ( OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
       { 
// - BUY Orders         
         if ( ExitSignal<0 )
         {
            if (mode==OP_BUY)
                  {
			         OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,Yellow);
			         }
         }
         else
// - SELL Orders          
         if ( ExitSignal>0 )
	      {
            if (mode==OP_SELL)
			         {
   			      OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,White);
                  }
         }
      }       
   } 
}

void BreakEvenStop()
{        
   
    for (cnt=0;cnt<OrdersTotal();cnt++)
    { 
     OrderSelect(cnt, SELECT_BY_POS);   
     int mode=OrderType();    
        if ( OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
        {
            if ( mode==OP_BUY )
            {
               BuyStop = OrderStopLoss();
			         if (Bid-OrderOpenPrice() > Kz*BreakEven*Point) 
			            {
			            BuyStop=OrderOpenPrice()+((Kz-1)*BreakEven+BreakEvenGap)*Point;
			            OrderModify(OrderTicket(),OrderOpenPrice(),
			                        NormalizeDouble(BuyStop, digit),
			                        OrderTakeProfit(),0,LightBlue);
			            Kz=Kz+1;
			            return(0);
			            }
			      
			   }
            if ( mode==OP_SELL )
            {
               SellStop = OrderStopLoss();
                  if (OrderOpenPrice()-Ask > Kz*BreakEven*Point) 
			            {
			            SellStop=OrderOpenPrice()-((Kz-1)*BreakEven+BreakEvenGap)*Point;
			            OrderModify(OrderTicket(),OrderOpenPrice(),
			                        NormalizeDouble(SellStop, digit),
			                        OrderTakeProfit(),0,Orange);
			            Kz=Kz+1;
			            return(0);
			            }
               
            }
        }   
    } 
}

void TrailStop()
{
    for (cnt=0;cnt<OrdersTotal();cnt++)
    { 
     OrderSelect(cnt, SELECT_BY_POS);   
     int mode=OrderType();    
        if ( OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
        {
              if (mode==OP_BUY) 
                 {
			        BuyStop = OrderStopLoss();
			        if (bsmin1>OrderStopLoss()) 
			        {
			        BuyStop = bsmin1;  
			        OrderModify(OrderTicket(),OrderOpenPrice(),
			                    NormalizeDouble(BuyStop, digit),
			                    OrderTakeProfit(),0,LightGreen);
			        }            
			        return(0);
                 }
           
// - SELL Orders          
              if (mode==OP_SELL)
                 {
                 SellStop = OrderStopLoss(); 
                 if( bsmax1<OrderStopLoss()) 
                 {
                 SellStop = bsmax1;
                 OrderModify(OrderTicket(),OrderOpenPrice(),
   			                 NormalizeDouble(SellStop, digit),
   			                 OrderTakeProfit(),0,Yellow);
   			     }	    
                 return(0);
                 }
           }
      }     
}

// ---- Open Sell Orders
void SellOrdOpen()
{		     
        double SellStop,SellProfit;
        double SellPrice=Bid;
        int    Mode = OP_SELL;
        if ( PendingOrder ) {SellPrice=smin1 - PendOrdGap*Point; Mode=OP_SELLSTOP;} 
		  
		  if (InitialStop > 0) SellStop  =SellPrice + InitialStop*Point; else SellStop  =bsmax1;
        if (TakeProfit  > 0) SellProfit=SellPrice -  TakeProfit*Point; else SellProfit=0;
	     //Print(" SellPrice=", SellPrice);  
		  ticket = OrderSend( Symbol(),Mode,MoneyManagement ( MM, Lots, MMRisk, MaxLoss),
		                      NormalizeDouble(SellPrice, digit),
		                      Slippage,
		                      NormalizeDouble(SellStop , digit),
		                      NormalizeDouble(SellProfit   , digit),
		                      "sell",Magic,0,Red);
            
            
            
            if(ticket<0)
            {
            Print("SELL: OrderSend failed with error #",GetLastError());
            //
            }
        if ( PendingOrder && GetLastError() == 130) 
        int ticket2=OrderSend(Symbol(),OP_SELL, MoneyManagement ( MM, Lots, MMRisk, MaxLoss),
                              Bid,
                              Slippage,
                              NormalizeDouble(SellStop , digit),
		                        NormalizeDouble(SellProfit   , digit),
		                        "sell",Magic,0,Red);    
   
       SellInTrade=true; BuyInTrade=false; Kz=1;  Signal=0;  
   return(0);
}
// ---- Open Buy Orders
void BuyOrdOpen()
{		     
   double BuyStop,BuyProfit;
   double BuyPrice = Ask;
   int    Mode     = OP_BUY;
   if (  PendingOrder ) {BuyPrice = smax1 + PendOrdGap*Point; Mode = OP_BUYSTOP;} 
		  
		  if (InitialStop > 0) BuyStop  = BuyPrice - InitialStop*Point; else BuyStop=bsmin1;
        if (TakeProfit  > 0) BuyProfit= BuyPrice + TakeProfit*Point;  else BuyProfit=0;  
		 
		  ticket = OrderSend(Symbol(),Mode, MoneyManagement ( MM, Lots, MMRisk, MaxLoss),
		                     NormalizeDouble(BuyPrice, digit),
		                     Slippage,
		                     NormalizeDouble(BuyStop , digit), 
		                     NormalizeDouble(BuyProfit  , digit),
		                     "buy",Magic,0,Blue);
                
                  
            
            if(ticket<0)
            {
            Print("BUY : OrderSend failed with error #",GetLastError());
            //return(0);
            }
        if (PendingOrder && GetLastError() == 130) 
        int ticket2=OrderSend(Symbol(),OP_BUY, MoneyManagement ( MM, Lots, MMRisk, MaxLoss),
                              Ask,
                              Slippage,
                              NormalizeDouble(BuyStop , digit), 
		                        NormalizeDouble(BuyProfit  , digit),
		                        "buy",Magic,0,Blue);
   BuyInTrade=true; SellInTrade = false; Kz=1; Signal = 0;
   return(0);
} 

void PendOrdsDel()
{
   
   if(Close[1]< 0.5*(bsmin1+bsmax1))int PendClose=1; 
   if(Close[1]> 0.5*(bsmin1+bsmax1))    PendClose=-1;  
   
   for (cnt=0;cnt<OrdersTotal();cnt++)
   { 
      OrderSelect(cnt, SELECT_BY_POS);   
      int mode=OrderType();    
      if ( OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
      {
         if (mode==OP_BUYSTOP && PendClose>0)
         {
	 	   OrderDelete(OrderTicket());
	      return(0);
	      }
         else	    
         if (mode==OP_SELLSTOP && PendClose<0) 
	 	   {
	 	   OrderDelete(OrderTicket());
	      return(0);
	      }
	   }
	}
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
   int total,ticket;
//---- 
   digit  = MarketInfo(Symbol(),MODE_DIGITS);
   if ( Trace ) SetTrace();
   
  if (Bars>b)
  { b=Bars;
     
  PriceChannel();
  if (MainTimeFrame > 0) MainPriceChannel(); else MainTrend = Trend;
  Print(" Trend = ",Trend, " PrevTrend = ",PrevTrend," MainTrend=",MainTrend, " Signal=",Signal);
  PendOrdsDel();
  
  TradeSignal();
  
  CloseTrade();
  
  if (BreakEven >0) BreakEvenStop();
  if (TrailingStop) TrailStop();
  //Print(" Signal = ",Signal);
  if (SwingTrade)
  {
  if (ScanTrades()<1 && Signal>0 && !BuyInTrade) BuyOrdOpen();
  if (ScanTrades()<1 && Signal<0 && !SellInTrade ) SellOrdOpen();
  }
  else
  {
  if (ScanTrades()<1 && Signal>0) BuyOrdOpen();
  if (ScanTrades()<1 && Signal<0) SellOrdOpen();
  }

  }//if (Bars>b)
//----
   return(0);
} //start()
//+------------------------------------------------------------------+