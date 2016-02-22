//+------------------------------------------------------------------+
//|                                                    MaxMinWPR.mq4 |
//|                                                           MojoFX |
//| Run on GBPUSD/USDJPY M15                http://fx.studiomojo.com |
//+------------------------------------------------------------------+
#property copyright "MojoFX"
#property link      "http://fx.studiomojo.com"
#define MAGICMA 111666888

extern int depth=12,
           deviation=5,
           backstep=3,
           per=14,
           mweek=5,
           mhour=23,
           slip=6,
           lots=1,
           SL=150,
           TP=50,
           TS=30;
extern double MM = -2;
extern double Leverage = 10;
int LotsMax = 100,  MarginChoke = 200;

#include <TrailStop.mqh>

int i,m,cnt;
int b,s,bloks,blokb;
double wpr,wpr1,swpr,porog,canal,MaxH,MinL,MaxHOld,MinLOld,ZZ,ZZ1,Htrend,Ltrend,bsig,ssig,LotMM;

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
   {
//---- 
   MoneyManagement();
   StartRoutine();   
   TrailStop();   
   PosCounter();   
   Block4();   
   WprBlock();
   OpenPosition();
//----
 return;
  }  
 
   
//+------------------------------------------------------------------+
//+                         Money Management                         +
//+------------------------------------------------------------------+
void MoneyManagement() {  //-2=Micro//-1=Mini//0=Lots//1=Lots compounded
   
	if ( MM ==-2  ) {		
		LotMM = NormalizeDouble(MathCeil(AccountBalance()*Leverage/1000)/100,2);
		
   }	
	if ( MM ==-1  ) {		
		LotMM = NormalizeDouble(MathCeil(AccountBalance()*Leverage/10000)/10,1);
		
   }
	if ( MM == 0 ) {
		if ( AccountFreeMargin() < MarginChoke ) return(-1); 
		LotMM = lots;
	}
	if ( MM > 0 ) {
      
		LotMM = MathCeil(AccountBalance()*Leverage/10000/10);
 		if ( LotMM < 1 )  LotMM = 1;
 		
	}
	if ( LotMM > LotsMax )  LotMM = LotsMax;
	return;
   }
//+------------------------------------------------------------------+

void StartRoutine()
   {   
   if (MaxHOld!=MaxH) MaxHOld=MaxH;
   if (MinLOld!=MinL) MinLOld=MinL;
   
   ZZ=iCustom(Symbol(),0,"ZigZag",depth,deviation,backstep,0,0);
   ZZ1=iCustom(Symbol(),0,"ZigZag",depth,deviation,backstep,0,1);
   }

void PosCounter()
   {
   b=0;s=0;
   for (int cnt=0; cnt<=OrdersTotal(); cnt++)
      {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA) 
         {
         if (OrderType() == OP_SELL) s++;
         if (OrderType() == OP_BUY ) b++;
         }
      }
   }
   
void Block4()
   {
   MaxH=High[per];MinL=Low[per];
   for (int m=per; m>=0; m--)
      {
      if (High[m]>MaxH) MaxH=High[m];
      if (Low [m]<MinL) MinL=Low [m];
      }
      
   if (b+s==0)
      {
      porog=MathRound((0.40*(MaxH-MinL))/Point)*10;
      canal=(MaxH-MinL)/Point;
      }
   
   Htrend=MaxHOld-MaxH;
   Ltrend=MinLOld-MinL;
   
   if (b+s>0)
      {
      for (int x=0; x<OrdersTotal(); x++)
         {      
         OrderSelect(x, SELECT_BY_POS, MODE_TRADES);
         if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA) {
         
         if (OrderType() == OP_SELL) 
            {         
			   if (OrderProfit()>porog ||
			      (wpr<-85 && wpr > wpr1 && OrderProfit()>0) || 
			      (DayOfWeek()==mweek && mhour==Hour()))
			      {
			      OrderClose(OrderTicket(),OrderLots(),Ask,slip,White);
			      s--; 
			      ssig=0;
			      }
			   }
			
			if (OrderType() == OP_BUY) 
			   {
			   if (OrderProfit()>porog ||
			      (wpr>-15 && wpr < wpr1 && OrderProfit()>0) || 
			      (DayOfWeek()==mweek && mhour==Hour())) 
			      {
			      OrderClose(OrderTicket(),OrderLots(),Bid,slip,White);
			      b--; 
			      bsig=0;
			      }
			   }
			
			} //   
			} // for
		} // if
     
   } // void function

void WprBlock()
   {
   wpr   = iWPR(Symbol(),0,per,0);
   wpr1  = iWPR(Symbol(),0,per,1);
   swpr  = iWPR(Symbol(),0,per,2);
   
   if (wpr<-5 && wpr>=-25 && swpr>=-5 && ssig==0) 
      {
      ssig=0.5;
      SetArrow(Time[0],High[0],159,Gold,1);
      bloks=0;
      }
   
   if (wpr>-95 && wpr<=-75 && swpr<=-95 && bsig==0) 
      {
      bsig=0.5;
      SetArrow(Time[0],Low[0],159,Aqua,2);
      blokb=0;
      }
      
   if (ssig==0.5 && wpr<-15 && wpr>=-25 && swpr>=-15) 
      {
      ssig=1;
      SetArrow(Time[0],High[0],242,GreenYellow,3);
      bloks=0;
      }
      
   if (bsig==0.5 && wpr>-85 && wpr<=-75 && swpr<=-85) 
      {
      bsig=1;
      SetArrow(Time[0],Low[0],242,Violet,4);
      blokb=0;
      }
   if(!IsTesting()) { 
   Comment ("Data: ",Year(),".",Month(),".",Day(),
            "  Time ",Hour(),":",Minute(),
            "  Porog=",porog,
            "  Profit=",MathRound(AccountProfit()),"\n",
            "  SBlok=",bloks,"  BBlok=",blokb,
            "  WPR=",MathRound(wpr),"  SWPR=",MathRound(swpr), "\n",
            "  SSig=",ssig,  "\n",
            "  BSig=",bsig,  "\n",
            "  ZZ=",ZZ,  "\n",
            "  ZZ1=",ZZ1,  "\n",
            "  Lots  :  ", LotMM);}     
   }
   
void OpenPosition()
   {
   if (b+s==0) 
      {
      if (s==0 && bloks==0 && 
          (ssig==1 || (ssig==0.5 && ZZ!=0)) && 
          MaxHOld>=MaxH)
         {
         SetArrow(Time[0],High[0]+5*Point,242,GreenYellow,5);
         s++;
         bloks=1;
         blokb=0;
         //SpeechText("Opening order, Sell."+Symbol());
         OrderSend(Symbol(),OP_SELL,LotMM,Bid,slip,Bid+SL*Point,Bid-TP*Point,Period()+" MMWPR",MAGICMA,0,GreenYellow);
         ssig=0;
         } 
  
      if (b==0 && blokb==0 &&
          (bsig==1 || (bsig==0.5 && ZZ!=0)) && 
          MinLOld<=MinL)
         {
         SetArrow(Time[0],Low[0]-5*Point,241,Violet,6);
         b++;
         bloks=0;
         blokb=1;
         //SpeechText("Opening order, Buy."+Symbol());
         OrderSend(Symbol(),OP_BUY,LotMM,Ask,slip,Ask-SL*Point,Ask+TP*Point,Period()+" MMWPR",MAGICMA,0,Violet);          
         bsig=0;
         }
      
      }      
   }
   
void SetArrow(int time1, double price1, int aCode, int aColor, int type)
   {
   ObjectCreate("MMWPR_"+type+Time[0],OBJ_ARROW,0,time1,price1);
   ObjectSet("MMWPR_"+type+Time[0],OBJPROP_ARROWCODE,aCode);
   ObjectSet("MMWPR_"+type+Time[0],OBJPROP_COLOR,aColor);
   }      