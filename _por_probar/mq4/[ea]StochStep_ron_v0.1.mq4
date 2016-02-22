//+---------------------+
//| StochStep Expert    |
//+---------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 1.0;
extern int    TakeProfit=92;
extern int    StopLoss=0;


// Global scope
datetime newbar = 0;

//---- input parameters
extern int extPeriodWATR=10;
extern double extKwatr=1.0000;
extern int extHighLow=0;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//|------------------------------------------------------------------|

int init()
  {
   return(0);
  }


//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int start()
  {

   bool      found=false;
   bool     rising=false;
   bool    falling=false;
   bool      cross=false;

   double slA=0, slB=0, tpA=0, tpB=0;
   double p=Point();
   
   int myStoch;
   
   int      cnt=0;

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   if(newbar != Time[0])                      {                        return(0);}
   newbar=Time[0];
   
   // Bars have moved, see if there is a cross
   myStoch=GetStoch();   
   if (myStoch==0)                            {                        return(0);}

   // since the bar just moved
   // calculate TP and SL for (B)id and (A)sk
   tpA=Ask+(p*TakeProfit);
   slA=Ask-(p*StopLoss);
   tpB=Bid-(p*TakeProfit);
   slB=Bid+(p*StopLoss);
   if (TakeProfit==0) {tpA=0; tpB=0;}           
   if (StopLoss==0)   {slA=0; slB=0;}           
   
   // close then open orders based on cross
   if (myStoch==2 || myStoch==1)
     {
      Print("myStoch=",myStoch);
      
      // Close ALL the open orders 
      for(cnt=0;cnt<OrdersTotal();cnt++)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            if (OrderType()==0) {OrderClose(OrderTicket(),Lots,Bid,3,White);}
            if (OrderType()==1) {OrderClose(OrderTicket(),Lots,Ask,3,Red);}
           }
        }
      // Open new order based on direction of cross
      if (myStoch==2) OrderSend(Symbol(),OP_BUY,Lots,Ask,3,slA,tpA,"ZZZ100",11123,0,White);
      if (myStoch==1) OrderSend(Symbol(),OP_SELL,Lots,Bid,3,slB,tpB,"ZZZ100",11321,0,Red);
     }
   
   return(0);
  }



int GetStoch()
  {
   int      i,shift,TrendMin,TrendMax,TrendMid;
   double   SminMin0,SmaxMin0,SminMin1,SmaxMin1,SumRange,dK,WATR0,WATRmax,WATRmin,WATRmid;
   double   SminMax0,SmaxMax0,SminMax1,SmaxMax1,SminMid0,SmaxMid0,SminMid1,SmaxMid1;
   double   linemin,linemax,linemid,bsmin,bsmax;
   double   Stoch1,Stoch2,pStoch1,pStoch2;
   int      rv;
      	
   for(shift=20; shift>=0; shift--)
     {	
      SumRange=0;
      for (i=extPeriodWATR-1; i>=0; i--)
	     { 
         dK = 1+1.0*(extPeriodWATR-i)/extPeriodWATR;
         SumRange+= dK*MathAbs(High[i+shift]-Low[i+shift]);
        }

      WATR0 = SumRange/extPeriodWATR;

      WATRmax=MathMax(WATR0,WATRmax);

      if (shift==Bars-1-extPeriodWATR) WATRmin=WATR0;

      WATRmin=MathMin(WATR0,WATRmin);
	
      int StepSizeMin=MathRound(extKwatr*WATRmin/Point);
      int StepSizeMax=MathRound(extKwatr*WATRmax/Point);
      int StepSizeMid=MathRound(extKwatr*0.5*(WATRmax+WATRmin)/Point);

		
      if (extHighLow!=0)
        {
         SmaxMin0=Low[shift]+2*StepSizeMin*Point;
         SminMin0=High[shift]-2*StepSizeMin*Point;
	  
         SmaxMax0=Low[shift]+2*StepSizeMax*Point;
         SminMax0=High[shift]-2*StepSizeMax*Point;
	  
         SmaxMid0=Low[shift]+2*StepSizeMid*Point;
         SminMid0=High[shift]-2*StepSizeMid*Point;
  
         if(Close[shift]>SmaxMin1) TrendMin=1; 
         if(Close[shift]<SminMin1) TrendMin=-1;
	  
         if(Close[shift]>SmaxMax1) TrendMax=1; 
         if(Close[shift]<SminMax1) TrendMax=-1;
	  
         if(Close[shift]>SmaxMid1) TrendMid=1; 
         if(Close[shift]<SminMid1) TrendMid=-1;
        }
      else
        {
         SmaxMin0=Close[shift]+2*StepSizeMin*Point;
         SminMin0=Close[shift]-2*StepSizeMin*Point;
	  
         SmaxMax0=Close[shift]+2*StepSizeMax*Point;
         SminMax0=Close[shift]-2*StepSizeMax*Point;
	  
         SmaxMid0=Close[shift]+2*StepSizeMid*Point;
         SminMid0=Close[shift]-2*StepSizeMid*Point;
	  
         if(Close[shift]>SmaxMin1) TrendMin=1; 
         if(Close[shift]<SminMin1) TrendMin=-1;
	  
         if(Close[shift]>SmaxMax1) TrendMax=1; 
         if(Close[shift]<SminMax1) TrendMax=-1;
	  
         if(Close[shift]>SmaxMid1) TrendMid=1; 
         if(Close[shift]<SminMid1) TrendMid=-1;
        }


      if (TrendMin>0 && SminMin0<SminMin1) SminMin0=SminMin1;
      if (TrendMin<0 && SmaxMin0>SmaxMin1) SmaxMin0=SmaxMin1;
		
      if (TrendMax>0 && SminMax0<SminMax1) SminMax0=SminMax1;
      if (TrendMax<0 && SmaxMax0>SmaxMax1) SmaxMax0=SmaxMax1;
	  
      if (TrendMid>0 && SminMid0<SminMid1) SminMid0=SminMid1;
      if (TrendMid<0 && SmaxMid0>SmaxMid1) SmaxMid0=SmaxMid1;
	  
      if (TrendMin>0) linemin=SminMin0+StepSizeMin*Point;
      if (TrendMin<0) linemin=SmaxMin0-StepSizeMin*Point;
	  
      if (TrendMax>0) linemax=SminMax0+StepSizeMax*Point;
      if (TrendMax<0) linemax=SmaxMax0-StepSizeMax*Point;
	  
      if (TrendMid>0) linemid=SminMid0+StepSizeMid*Point;
      if (TrendMid<0) linemid=SmaxMid0-StepSizeMid*Point;
	  
      bsmin=linemax-StepSizeMax*Point;
      bsmax=linemax+StepSizeMax*Point;

      pStoch1=Stoch1;
      Stoch1=(linemin-bsmin)/(bsmax-bsmin);
      pStoch2=Stoch2;
      Stoch2=(linemid-bsmin)/(bsmax-bsmin);
      
      rv=0;
      if (pStoch1<pStoch2 && Stoch1>=Stoch2) {rv=2;} //rising
      if (pStoch1>pStoch2 && Stoch1<=Stoch2) {rv=1;} //falling

      SminMin1=SminMin0;
      SmaxMin1=SmaxMin0;

      SminMax1=SminMax0;
      SmaxMax1=SmaxMax0;

      SminMid1=SminMid0;
      SmaxMid1=SmaxMid0;
     }
   return(rv);
  }
  

