//+------------------------------------------------------------------+
//|                                                        eFXSI.mq4 |
//|                                  Copyright © 2005, Forex-Experts |
//|                                     http://www.forex-experts.com |
//+------------------------------------------------------------------+

#define expiryDate "2006.12.31" //expiration date yyyy.mm.dd
#define accountNum  0  //if 0 works on all accounts, if >0 then works only on this account number

#property copyright "Copyright © 2005, Forex-Experts"
#property link      "http://www.forex-experts.com"
#include <stdlib.mqh>

#define MAGICNUM  1777

extern double TakeProfit = 150;     //pips value for take profit level
extern double MaxStopLoss = 30;     //pips value for maximum stop loss level 
extern double BreakEven = 15;       //pips for BreakEven
extern double TrailingProfit = 30;  //pips of profit when turning trailing stop on 
extern double TrailingStop = 15;    //pips value for trailing stop level

extern double  Lots = 0.1; //number of lots to trade
extern bool    FixedLot = true; //trade either fixed lots or calculate lots as % of balance function
extern double  MaximumRisk = 8; //%% of balance to calculate lots


//For alert system
extern int     Repeat=3,Periods=5;
extern int     UseAlert=1;
extern int     SendEmail=0;
int       	   Crepeat=0;

                                //indicator parameters
extern bool useITrend=false;
extern bool useZeroLag=true;
extern bool useADX=false;
extern bool ConfirmOnCurrent=false;


extern int       A_period=50;
extern int       ADX_Period=14;
extern int Bands_Mode_0_2=0;  // =0-2 MODE_MAIN, MODE_LOW, MODE_HIGH
extern int Power_Price_0_6=0; // =0-6 PRICE_CLOSE,PRICE_OPEN,PRICE_HIGH,PRICE_LOW,PRICE_MEDIAN,PRICE_TYPICAL,PRICE_WEIGHTED
extern int Price_Type_0_3=0;  // =0-3 PRICE_CLOSE,PRICE_OPEN,PRICE_HIGH,PRICE_LOW
extern int Bands_Period=20;
extern int Bands_Deviation=2;
extern int Power_Period=13;



extern int    slippage=3;   	//slippage for market order processing
extern int    shift=0;			//shift to current bar, 



bool buysig,sellsig,closebuy,closesell; int lastsig,ttime;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
Crepeat=Repeat;   
//----
   return(0);
  }


//Alert function
void CheckAlert()
  {
string AlertStr="";
AlertStr="";
int AlertTime=0;
//Alert system
if (UseAlert==1)
{

if (sellsig) 
{ 
   if (Crepeat==Repeat)
   { 
   AlertTime=0;
   }

if (Crepeat>0 && (CurTime()-AlertTime)>Periods)
{
   if (sellsig) AlertStr=AlertStr+"FXSI SELL; ";

   Alert(Symbol()," ",Period(), ": ", AlertStr); 
   if (SendEmail==1) 
   {
      SendMail(Symbol()+" "+Period()+ ": ",Symbol()+" "+Period()+": "+AlertStr);
   }
   Crepeat=Crepeat-1;
   AlertTime=CurTime();
}

} 


if (buysig) 
{ 
   if (Crepeat==Repeat)
   { 
      AlertTime=0;
   }
   if (Crepeat>0 && (CurTime()-AlertTime)>Periods)
   {
   if (buysig) AlertStr=AlertStr+"FXSI BUY; ";

   Alert(Symbol()," ",Period(), ": ",AlertStr); 
   if (SendEmail==1) 
   {
      SendMail(Symbol()+" "+Period()+ ": ",Symbol()+" "+Period()+": "+AlertStr);
   }

      Crepeat=Crepeat-1;
      AlertTime=CurTime();
   } 
}

if (!buysig && !sellsig)  
{
   Crepeat=Repeat;
   AlertTime=0;
}

}


  }
   

//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//----
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICNUM)
        {
         if(OrderType()==OP_BUY || OrderType()==OP_BUYSTOP)  buys++;
         if(OrderType()==OP_SELL || OrderType()==OP_SELLSTOP) sells++;
        }
     }
//---- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }

//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
//---- select lot size
   if (!FixedLot)
      lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/10000.0,1);
   else
      lot=Lots;
//---- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
  }


//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForSignals() {
      double buyval,sellval,cci_cur,cci_prev;
      
      buyval=0;
      sellval=0;
      cci_cur=0;
      cci_prev=0;


      //buyval=iCustom(NULL,0,"iFXSI",useITrend,useZeroLag,useADX,ConfirmOnCurrent,false,false,false,A_period,ADX_Period,Bands_Mode_0_2,Power_Price_0_6,Price_Type_0_3,Bands_Period,Bands_Deviation,Power_Period,0,0,shift);
      //sellval=iCustom(NULL,0,"iFXSI",useITrend,useZeroLag,useADX,ConfirmOnCurrent,false,false,false,A_period,ADX_Period,Bands_Mode_0_2,Power_Price_0_6,Price_Type_0_3,Bands_Period,Bands_Deviation,Power_Period,0,1,shift);

      buyval=iFXSI(0,shift);
      sellval=iFXSI(1,shift);
//Comment("buyval=",buyval," sellval=",sellval);

      cci_cur=iCCI(NULL,0,A_period,PRICE_TYPICAL,shift);
      cci_prev=iCCI(NULL,0,A_period,PRICE_TYPICAL,shift+1);

      if (cci_cur>0 && cci_prev<0)   closesell=true; else closesell=false;
      if (cci_cur<0 && cci_prev>0)   closebuy=true; else closebuy=false;            
      buysig=false;
      if ( buyval>0.01 )

         buysig=true;

      sellsig=false;
      if ( sellval>0.01 )

      sellsig=true;
      return;      
}

void CheckForOpen() {
   int    res;
   double entryPrice,stopPrice;
   
   if (CalculateCurrentOrders(Symbol())>0) {
      CheckForClose();
   }
   
   if (CalculateCurrentOrders(Symbol())==0) {
      //---- sell conditions
      if(sellsig)  {
         entryPrice=Bid;
         stopPrice=entryPrice+MaxStopLoss*Point;      
         res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),entryPrice,slippage,stopPrice,entryPrice-TakeProfit*Point,"FXSI",MAGICNUM,0,Red);
         sellsig=false;
         return;
      }
      //---- buy conditions
      if(buysig)  {
         entryPrice=Ask;   
         stopPrice=entryPrice-MaxStopLoss*Point;      
         res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),entryPrice,slippage,stopPrice,entryPrice+TakeProfit*Point,"FXSI",MAGICNUM,0,Blue);
         buysig=false;
         return;
      }
   }
   return;
}
  
  
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()  {
   int i;
   //close on the opposite signal
   for(i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)  break;
      if(OrderMagicNumber()!=MAGICNUM || OrderSymbol()!=Symbol()) continue;
      //---- check order type 
      if(OrderType()==OP_BUY)
        {
         if (closebuy) OrderClose(OrderTicket(),OrderLots(),Bid,slippage,White);
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if (closesell) OrderClose(OrderTicket(),OrderLots(),Ask,slippage,White);
         break;
        }
      if(OrderType()==OP_BUYSTOP)
        {
         if (closebuy) OrderDelete(OrderTicket());
         break;
        }
      if(OrderType()==OP_SELLSTOP)
        {
         if (closesell) OrderDelete(OrderTicket());
         break;
        }
   }

   return;
}


//+------------------------------------------------------------------+
//| Start function                                                   |
//+------------------------------------------------------------------+
void start()  {

   if (CurTime() > StrToTime(expiryDate)) {
      Alert("Version expired!");
      return;
   }

   if (accountNum!=0 && accountNum!=AccountNumber()) {
      Alert("This expert is not licensed to your account number!");
      return;
   }
   //---- check for history and trading
   //if(Bars<100 || IsTradeAllowed()==false) return;

   buysig=false;
   sellsig=false;
   closesell=buysig;
   closebuy=sellsig;
   
   CheckForSignals();
   CheckAlert();
   CheckForOpen();
   TrailStop(Symbol(), MAGICNUM, TrailingStop);

}
//+------------------------------------------------------------------+


void TrailStop(string mySymbol, int myMagic, int TrailingStop) {
   double StopLoss;
   if ( TrailingStop > 8 ) {
      for (int i = 0; i < OrdersTotal(); i++) {
         if ( OrderSelect (i, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != mySymbol || OrderMagicNumber() != myMagic )  continue;
         if ( OrderType() == OP_BUY ) {
            
            if (BreakEven!=0)
            {
               if ((Bid-OrderOpenPrice())>BreakEven*Point)
               {
                  if ((OrderStopLoss()-OrderOpenPrice())<0)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+Point,OrderTakeProfit(),Aqua);
                     return(0);
                  }
               }
            }
            if ((Bid-OrderOpenPrice())>BreakEven*Point) {
               if ( Bid < OrderOpenPrice () )  return;
               StopLoss = Bid-BreakEven*Point;
               if ( StopLoss > OrderStopLoss() ) {
                  OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, White);
               }
            }
         }
   
         if ( OrderType() == OP_SELL ) {
                 //Modify stoploss to zero profit
            if (BreakEven!=0)
            {
               if ((OrderOpenPrice()-Ask)>BreakEven*Point)
                  {
                     if ((OrderOpenPrice()-OrderStopLoss())<0)
                        {  
                           OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-Point,OrderTakeProfit(),Aqua);
                           return(0);
                        }
                  }
            }                                                                        
            
            
            if ((OrderOpenPrice()-Ask)>TrailingProfit*Point) {                              
               
               if ( Ask > OrderOpenPrice () )  return;
               StopLoss = Ask+TrailingStop*Point;
               if ( StopLoss < OrderStopLoss() ) {
                  OrderModify (OrderTicket(), OrderOpenPrice(), StopLoss, OrderTakeProfit(), 0, Gold);
               }
            }
         }
      }
   }
   return;
}


double ZeroLag(int mode, int index) { 

int k, numbars=100;
double stok1=0,stok2=0,stok3=0,stok4=0,stok5=0,mov=0,stoksmoothed=0,smoothing=15;
double TrendBuffer[101];
double LoBuffer[101];
   
   for (k=101;k>=0;k--) {
      TrendBuffer[k]=0;
      LoBuffer[k]=0;
   }

for (k = numbars; k>= 0 ;k--) {
stok1 = (iStochastic(NULL,0,8,3,3,MODE_SMA,NULL,MODE_MAIN,k))*0.05;
stok2 = (iStochastic(NULL,0,89,21,3,MODE_SMA,NULL,MODE_MAIN,k))*0.43;
stok3 = (iStochastic(NULL,0,55,13,3,MODE_SMA,NULL,MODE_MAIN,k))*0.26;
stok4 = (iStochastic(NULL,0,34,8,3,MODE_SMA,NULL,MODE_MAIN,k))*0.16;
stok5 = (iStochastic(NULL,0,21,5,3,MODE_SMA,NULL,MODE_MAIN,k))*0.10;
mov   = stok1+stok2+stok3+stok4+stok5;
stoksmoothed = mov/smoothing + LoBuffer[k+1]*(smoothing-1)/smoothing;
TrendBuffer[k]=mov;
LoBuffer[k]=stoksmoothed;

}
if (mode==0) return (TrendBuffer[index]);
if (mode==1) return (LoBuffer[index]);

}

  double iTrend (int mode, int index)
   {
      int Bands_Mode;
      double Power_Price,CurrentPrice;
      if (Bands_Mode_0_2==1) Bands_Mode=MODE_LOW;
      if (Bands_Mode_0_2==2) Bands_Mode=MODE_HIGH;
      if (Bands_Mode_0_2==0) Bands_Mode=MODE_MAIN;
      if (Power_Price_0_6==1) Power_Price=PRICE_OPEN;
      if (Power_Price_0_6==2) Power_Price=PRICE_HIGH;
      if (Power_Price_0_6==3) Power_Price=PRICE_LOW;
      if (Power_Price_0_6==4) Power_Price=PRICE_MEDIAN;
      if (Power_Price_0_6==5) Power_Price=PRICE_TYPICAL;
      if (Power_Price_0_6==6) Power_Price=PRICE_WEIGHTED;
      if (Power_Price_0_6==0) Power_Price=PRICE_CLOSE;
   
      if (Price_Type_0_3==1) CurrentPrice=Open[index];
      if (Price_Type_0_3==2) CurrentPrice=High[index];
      if (Price_Type_0_3==3) CurrentPrice=Low[index];
      if (Price_Type_0_3==0) CurrentPrice=Close[index];   
      if (mode==0) return (CurrentPrice-iBands(NULL,0,Bands_Period,Bands_Deviation,0,Bands_Mode,Power_Price,index));
      if (mode==1) return(-(iBearsPower(NULL,0,Power_Period,Power_Price,index)+iBullsPower(NULL,0,Power_Period,Power_Price,index)));    

     }



double iFXSI(int mode, int i) {
   int DotLoc=7;
   double   BuySig[30];
   double   SellSig[30];
   double cci_cur[2],cci_prev[2];
   double BuyCCI[2],SellCCI[2];
   for (int cnt=0; cnt<=1; cnt++) {   
   //check cci crossing
   cci_cur[cnt]=iCCI(NULL,0,A_period,PRICE_TYPICAL,i+cnt);
   cci_prev[cnt]=iCCI(NULL,0,A_period,PRICE_TYPICAL,i+1+cnt);

   if (cci_cur[cnt]>0 && cci_prev[cnt]<0)   BuyCCI[cnt]=Low[i]-DotLoc*Point; else BuyCCI[cnt]=0;
   if (cci_cur[cnt]<0 && cci_prev[cnt]>0)   SellCCI[cnt]=High[i]+DotLoc*Point; else SellCCI[cnt]=0;
   }


   //check iTrend crossing
   double itrendg_cur[2],itrendg_prev[2],itrendr_cur[2],itrendr_prev[2],BuyiTrendCross[2],SelliTrendCross[2];
   bool BuyITrend=false, SellITrend=false;
   
   for (cnt=0; cnt<=1; cnt++) {
   itrendg_cur[cnt]=iTrend(0,i+cnt);
   itrendg_prev[cnt]=iTrend(0,i+1+cnt);
   itrendr_cur[cnt]=iTrend(1,i+cnt);
   itrendr_prev[cnt]=iTrend(1,i+1+cnt);
   if (itrendr_prev[cnt]>itrendg_prev[cnt] && itrendr_cur[cnt]<itrendg_cur[cnt]) BuyiTrendCross[cnt]=1; else BuyiTrendCross[cnt]=0;
   if (itrendr_prev[cnt]<itrendg_prev[cnt] && itrendr_cur[cnt]>itrendg_cur[cnt]) SelliTrendCross[cnt]=1; else SelliTrendCross[cnt]=0;
   }

   if ((!ConfirmOnCurrent && ((BuyiTrendCross[0] && (BuyCCI[0]>0 || BuyCCI[1]>0)) || (BuyiTrendCross[1] && BuyCCI[0]>0))) ||
      (ConfirmOnCurrent && BuyiTrendCross[0] && BuyCCI[0]>0)) BuyITrend=true; else BuyITrend=false;   
   if ((!ConfirmOnCurrent && ((SelliTrendCross[0] && (SellCCI[0]>0 || SellCCI[1]>0)) || (SelliTrendCross[1] && SellCCI[0]>0))) ||
      (!ConfirmOnCurrent && SelliTrendCross[0] && SellCCI[0]>0)) SellITrend=true; else SellITrend=false;



   //ZeroLag Crossing
   double zlsw_cur[2],zlsw_prev[2],zlsr_cur[2],zlsr_prev[2],BuyZeroLagCross[2],SellZeroLagCross[2];
   bool BuyZeroLag=false, SellZeroLag=false;
   
   for (cnt=0; cnt<=1; cnt++) {   
   //zlsw_cur[cnt]=iCustom(NULL,0,"Zerolagstochs",0,i+cnt);
   //zlsw_prev[cnt]=iCustom(NULL,0,"Zerolagstochs",0,i+1+cnt);   
   //zlsr_cur[cnt]=iCustom(NULL,0,"Zerolagstochs",1,i+cnt);
   //zlsr_prev[cnt]=iCustom(NULL,0,"Zerolagstochs",1,i+1+cnt);

   zlsw_cur[cnt]=ZeroLag(0,i+cnt);
   zlsw_prev[cnt]=ZeroLag(0,i+1+cnt);   
   zlsr_cur[cnt]=ZeroLag(1,i+cnt);
   zlsr_prev[cnt]=ZeroLag(1,i+1+cnt);


   if (zlsr_prev[cnt]>zlsw_prev[cnt] && zlsr_cur[cnt]<zlsw_cur[cnt]) BuyZeroLagCross[cnt]=1; else BuyZeroLagCross[cnt]=0; 
   if (zlsr_prev[cnt]<zlsw_prev[cnt] && zlsr_cur[cnt]>zlsw_cur[cnt]) SellZeroLagCross[cnt]=1; else SellZeroLagCross[cnt]=0;
   } 

   if ((!ConfirmOnCurrent && ((BuyZeroLagCross[0] && (BuyCCI[0]>0 || BuyCCI[1]>0)) || (BuyZeroLagCross[1] && BuyCCI[0]>0))) ||
       (ConfirmOnCurrent && BuyZeroLagCross[0] && BuyCCI[0]>0)) BuyZeroLag=true; else BuyZeroLag=false;
   if ((!ConfirmOnCurrent && ((SellZeroLagCross[0] && (SellCCI[0]>0 || SellCCI[1]>0)) || (SellZeroLagCross[1] && SellCCI[0]>0))) ||
       (ConfirmOnCurrent && SellZeroLagCross[0] && SellCCI[0]>0)) SellZeroLag=true; else SellZeroLag=false;

   //Adx crossing
    double b4plusdi[2],b4minusdi[2],nowplusdi[2],nowminusdi[2],BuyADXCross[2],SellADXCross[2];
      
    bool BuyADX=false, SellADX=false;
    for (cnt=0; cnt<=1; cnt++) {
    b4plusdi[cnt]=iADX(NULL,0,ADX_Period,PRICE_CLOSE,MODE_PLUSDI,i+1+cnt);
    nowplusdi[cnt]=iADX(NULL,0,ADX_Period,PRICE_CLOSE,MODE_PLUSDI,i+cnt);
   
    b4minusdi[cnt]=iADX(NULL,0,ADX_Period,PRICE_CLOSE,MODE_MINUSDI,i+1+cnt);
    nowminusdi[cnt]=iADX(NULL,0,ADX_Period,PRICE_CLOSE,MODE_MINUSDI,i+cnt);
    if (b4plusdi[cnt]>b4minusdi[cnt] && nowplusdi[cnt]<nowminusdi[cnt]) SellADXCross[cnt]=1; else SellADXCross[cnt]=0;
    if (b4plusdi[cnt]<b4minusdi[cnt] && nowplusdi[cnt]>nowminusdi[cnt]) BuyADXCross[cnt]=1; else BuyADXCross[cnt]=0;
    }

    if ((!ConfirmOnCurrent && ((BuyADXCross[0] && (BuyCCI[0]>0 || BuyCCI[1]>0)) || (BuyADXCross[1] && BuyCCI[0]>0))) ||
       (ConfirmOnCurrent && BuyADXCross[0] && BuyCCI[0]>0)) BuyADX=true; else BuyADX=false;
    if ((!ConfirmOnCurrent && ((SellADXCross[0] && (SellCCI[0]>0 || SellCCI[1]>0)) || (SellADXCross[1] && SellCCI[0]>0))) ||
       (ConfirmOnCurrent && SellADXCross[0] && SellCCI[0]>0)) SellADX=true; else SellADX=false;



   if ((BuyITrend || !useITrend) && (BuyZeroLag || !useZeroLag) && (BuyADX ||!useADX))   BuySig[i]=Low[i]-DotLoc*Point; else BuySig[i]=0.0;
   if ((SellITrend || !useITrend) && (SellZeroLag || !useZeroLag)&& (SellADX||!useADX))   SellSig[i]=High[i]+DotLoc*Point; else SellSig[i]=0.0;
   if (!useITrend && !useZeroLag && !useADX) {     
      BuySig[i]=0.0;
      SellSig[i]=0.0;
   }

if (mode==0) return (BuySig[i]);
if (mode==1) return (SellSig[i]);




} 

