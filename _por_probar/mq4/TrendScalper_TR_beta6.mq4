//+------------------------------------------------------------------+
//|                                              TrendScalper_TR.mq4 |
//|                      Copyright � 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Smoky's Trendscalper modified by TR_n00btrader@frisurf.no"
#property link      "http://www.metaquotes.net/"

//---- input parameters
extern double    LotsIfNoMM=0.1;
extern int       Stoploss=40;
extern int       Slip=5;
extern int       InitialTarget=999;
extern int       BB2period=100;
extern double    BB2multiplier=1;
extern int       TTFperiod=15;
extern double    TSmultiplier=4;
extern int       MM_Mode=0;
extern int       MM_Risk=40;
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


double Opentrades,orders,first,mode,cnt,Ilo,sym,b;
double b4signal,Signal,Triggerline,b4Triggerline,Nowsignal,NowTriggerline,sl,LastOpByExpert,LastBarChecked;


//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {

   Comment(" Trailingstop    ",  b, "\n","      Tick no. ", iVolume(Symbol(),0,0),
     "\n"," Lots    ",Ilo);


   /**********************************Money and Risk Management***************************************
   Changing the value of mm will give you several money management options
   mm = 0 : Single 1 lot orders.
   mm = -1 : Fractional lots/ balance X the risk factor.(use for Mini accts)
   mm = 1 : Full lots/ balance X the risk factor up to 100 lot orders.(use for Regular accounts)
   ***************************************************************************************************
   RISK FACTOR:
   risk can be anything from 1 up. 
   Factor of 5 adds a lot for every $20,000.00 added to the balance. 
   Factor of 10 adds a lot with every $10.000.00 added to the balance.
   The higher the risk,  the easier it is to blow your margin..
   **************************************************************************************************/

   if (MM_Mode < 0)  {
   Ilo = MathCeil(AccountBalance()*MM_Risk/10000)/10;
     if (Ilo > 100) {  
     Ilo = 100;  
     }
   } else {
   Ilo = LotsIfNoMM;
   }
   if (MM_Mode > 0)  
    {
   Ilo = MathCeil(AccountBalance()*MM_Risk/10000)/10;
    if (Ilo > 1)  
    {
    Ilo = MathCeil(Ilo);
    }
    if (Ilo < 1)  
    {
    Ilo = 1;
    }
    if (Ilo > 100)  
    {  
     Ilo = 100;  
     }
   }




   //------------------------------------------------------------------------------------------------ 
   Opentrades=0;
   for (cnt=0;cnt<OrdersTotal();cnt++) 
   {
      if ( OrderSelect (cnt, SELECT_BY_POS) == false )  continue;
      if ( OrderSymbol()==Symbol()) Opentrades=Opentrades+1;
   }


   if (Opentrades==0)  //and iATR(5,2)<StopLoss*Point 
   
     {
  
     if (LastBarChecked == Time[0]) 
         return(0); 
      else 
  	      {
  	      LastBarChecked = Time[0]; 
  	      //if (! High[1]>iBands(Symbol(),0,BB2period,2,0,PRICE_CLOSE,MODE_UPPER,1) && ! Low[1]<iBands(Symbol(),0,BB2period,2,0,PRICE_CLOSE,MODE_LOWER,1)) 
  	      if (! High[1]>(iMA(Symbol(),0,BB2period,0,MODE_SMA,PRICE_CLOSE,1) + ((iBands(Symbol(),0,BB2period,2,0,PRICE_CLOSE,MODE_UPPER,1) - iMA(Symbol(),0,BB2period,0,MODE_SMA,PRICE_CLOSE,1)) * BB2multiplier)) && ! Low[1]<(iMA(Symbol(),0,BB2period,0,MODE_SMA,PRICE_CLOSE,1) - ((iMA(Symbol(),0,BB2period,0,MODE_SMA,PRICE_CLOSE,1) - iBands(Symbol(),0,BB2period,2,0,PRICE_CLOSE,MODE_LOWER,1)) * BB2multiplier)))
  	         return(0);
  	      }
   	
	   //Signal =iCustom("TrendScalpIndic",15,0,5,0.7,0,1000,0,MODE_FIRST,1);
	   //b4signal=iCustom("TrendScalpIndic",15,0,5,0.7,0,1000,0,MODE_FIRST,2);
	   //NowSignal=iCustom("TrendScalpIndic",15,0,5,0.7,0,1000,0,MODE_FIRST,0);
	   //Triggerline =iCustom("TrendScalpIndic",15,0,5,0.7,0,1000,0,MODE_SECOND,0);
	   //b4Triggerline =iCustom("TrendScalpIndic",15,0,5,0.7,0,1000,0,MODE_SECOND,1);

      double HHR,HHO,LLR,LLO;
      double BP,SP;

	  HHR=High[Highest(Symbol(), 0, MODE_HIGH,1,0+1)];
	  HHO =High[Highest(Symbol(), 0, MODE_HIGH,TTFperiod,0+1+1)];
	  LLR =Low [Lowest (Symbol(), 0, MODE_LOW,1,0+1)];
	  LLO =Low [Lowest (Symbol(), 0, MODE_LOW,TTFperiod,0+1+1)];
	  BP =HHR-LLO;
	  SP=HHO -LLR;
	  Triggerline=(BP-SP)/(0.5*(BP+SP))*100;
	  if (Triggerline>=0) Triggerline= 100; else Triggerline=-100;

	  HHR=High[Highest(Symbol(), 0, MODE_HIGH,1,1+1)];
	  HHO =High[Highest(Symbol(), 0, MODE_HIGH,TTFperiod,1+1+1)];
	  LLR =Low [Lowest (Symbol(), 0, MODE_LOW ,1,1+1)];
	  LLO =Low [Lowest (Symbol(), 0, MODE_LOW ,TTFperiod,1+1+1)];
	  BP =HHR-LLO;
	  SP=HHO -LLR;
	  b4Triggerline=(BP-SP)/(0.5*(BP+SP))*100;
	  if (b4Triggerline>=0) b4Triggerline=100; else b4Triggerline=-100;

     //Print (Triggerline, "   ", b4Triggerline);



     if (b4Triggerline>=100
     && High[1]>(iMA(Symbol(),0,BB2period,0,MODE_SMA,PRICE_CLOSE,1) + ((iBands(Symbol(),0,BB2period,2,0,PRICE_CLOSE,MODE_UPPER,1) - iMA(Symbol(),0,BB2period,0,MODE_SMA,PRICE_CLOSE,1)) * BB2multiplier))
     && Triggerline<100) 
  
        {
        OrderSend(Symbol(),OP_SELL,Ilo,Bid,Slip,Bid+Stoploss*Point,0,"Tscalp",0,0,Red);
        LastOpByExpert=CurTime();
        //	Print (TimeToStr(Time[1]),"   ", Triggerline);
        return(0);            
        }

     if 
     (b4Triggerline<=(-100) 
     && Low[1]<(iMA(Symbol(),0,BB2period,0,MODE_SMA,PRICE_CLOSE,1) - ((iMA(Symbol(),0,BB2period,0,MODE_SMA,PRICE_CLOSE,1) - iBands(Symbol(),0,BB2period,2,0,PRICE_CLOSE,MODE_LOWER,1)) * BB2multiplier))
     && Triggerline>(-100)) //and iATR(10,1)>6*Point

        {
        OrderSend(Symbol(),OP_BUY,Ilo,Ask,Slip,Ask-Stoploss*Point,0,"Tscalp",0,0,White);
        LastOpByExpert=CurTime();
        return(0);
        }

     }

   //----------------------------------------Order Control-------------------------------------------
 
   if (Opentrades != 0)  
   
     {
      orders=0;
      sym=0;
      for (cnt=0;cnt<OrdersTotal();cnt++) 
         { 
         if ( OrderSelect (cnt, SELECT_BY_POS) == false )  continue;

         if ( OrderSymbol()==Symbol())
            {
            sym=cnt;
            orders=1;
	         HHR=High[Highest(Symbol(), 0, MODE_HIGH,1,0+1)];
	         HHO =High[Highest(Symbol(), 0, MODE_HIGH,TTFperiod,0+1+1)];
	         LLR =Low [Lowest (Symbol(), 0, MODE_LOW,1,0+1)];
	         LLO =Low [Lowest (Symbol(), 0, MODE_LOW,TTFperiod,0+1+1)];
	         BP =HHR-LLO;
	         SP=HHO -LLR;
	         NowTriggerline=(BP-SP)/(0.5*(BP+SP))*100;
	         if (NowTriggerline>=0) NowTriggerline= 100; else NowTriggerline=-100;

            b=5*Point+iATR(Symbol(),0,3,1)*TSmultiplier;
            }
         } 

      mode=OrderType();

      if (mode==OP_BUY)   
       {
       if (
       OrderOpenPrice()>OrderStopLoss()
       && Bid-OrderOpenPrice()>InitialTarget*Point  
       && NowTriggerline<100 || High[1]>iBands(Symbol(),0,BB2period,1,0,PRICE_CLOSE,MODE_UPPER,1) && NowTriggerline<100)
           {
           OrderClose(OrderTicket(),OrderLots(),Bid,Slip,Red);
           LastOpByExpert=CurTime();
           return(0);
           } 
       if (Close[1]-OrderOpenPrice()>b)
        {
        if (OrderStopLoss()<Close[1]-b) 
         {
         OrderModify(OrderTicket(),OrderOpenPrice(),Close[1]-b,OrderTakeProfit(),0,LimeGreen);
         LastOpByExpert=CurTime();
         return(0);
         } 
        }
       }  

       if (mode==OP_SELL) 
           {
           if (OrderOpenPrice()<OrderStopLoss()
           && OrderOpenPrice()-Ask>InitialTarget*Point 
           && NowTriggerline>-100 || Low[1]<iBands(Symbol(),0,BB2period,1,0,PRICE_CLOSE,MODE_LOWER,1) && NowTriggerline>-100)
             
               {
               OrderClose(OrderTicket(),OrderLots(),Ask,Slip,Red);
               LastOpByExpert=CurTime();
               return(0);
               }
         if (OrderOpenPrice()-Close[1]>(b)+MarketInfo(Symbol(),MODE_SPREAD)*Point) 
            {
            if (OrderStopLoss()>(Close[1]+b+MarketInfo(Symbol(),MODE_SPREAD)*Point)) 
              {
              OrderModify(OrderTicket(),OrderOpenPrice(),Close[1]+b+MarketInfo(Symbol(),MODE_SPREAD)*Point,OrderTakeProfit(),0,HotPink);
              LastOpByExpert=CurTime();
              return(0);
              }
            }
         }
   }




   return(0);
  }
//+------------------------------------------------------------------+