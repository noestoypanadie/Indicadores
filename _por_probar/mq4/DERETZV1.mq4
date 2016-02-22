//+------------------------------------+
//| DERETZ EA  V1                    |
//+------------------------------------+
//©Copyright 2005 threzzz@yahoo.com
//For personal use only.
//  
//
// 
//	 
// 


// variables declared here are GLOBAL in scope

#property copyright "DERetz"
#property link      "Deretz.cos"


// generic user input
extern double Lots=1;
extern int    TakeProfit=100;
extern int    StopLoss=50;
extern int    TrailingStop=20;

extern int    Slippage=2;
// extern int    ProfitMade=30;


//+------------------------------------+
//| Custom init (usually empty on EAs) |
//|------------------------------------|
// Called ONCE when EA is added to chart
int init()
  {
   return(0);
  }


//+------------------------------------+
//| Custom deinit(usually empty on EAs)|
//+------------------------------------+
// Called ONCE when EA is removed from chart
int deinit()
  {
   return(0);
  }


//+------------------------------------+
//| EA main code                       |
//+------------------------------------+
// Called EACH TICK and possibly every Minute
// in the case that there have been no ticks

int start()
  {

   double p=Point();
   int      cnt=0;
   int      OrdersPerSymbol=0;
   double  bull=0,b=0,s=0,total=0;
   double  bear=0;
//   double  TrendBuffer[];
   int  MagicNumber=8749222;
//   double  LoBuffer[];
   double Ma534=0, Ma534_1=0,Ma534_2=0,Ma534_3=0,Ma534_4=0,Ma534_5=0 ;
   double pMa534=0, pMa534_1=0,pMa534_2=0,pMa534_3=0,pMa534_4=0,pMa534_5=0; 
   int CB=0, M15=240 ;
   double  slBUY=0,tpBUY=0;
   double  slSEL=0,tpSEL=0;
   //extern string nameEA       = "DeretzLWMA"

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   

////+++++++++++++++++++++++++++


CB=1000;
  for (CB=1000 ; CB>=0; CB--)
  {
 // iMA(NULL,0,55,0,MODE_EMA,PRICE_CLOSE,0)
Ma534=iMA(NULL,0,5,0,MODE_SMA, PRICE_MEDIAN,CB)-iMA(NULL,0,34,0,MODE_SMA,PRICE_MEDIAN,CB);
//if CB>=1 then 
Ma534_1=iMA(NULL,0,5,0,MODE_SMA,PRICE_MEDIAN,CB)-iMA(NULL,0,34,0,MODE_SMA,PRICE_MEDIAN,CB);
//if CB>=2 then 
Ma534_2=iMA(NULL,0,5,0,MODE_SMA,PRICE_MEDIAN,CB-1)-iMA(NULL,0,34,0,MODE_SMA,PRICE_MEDIAN,CB-1);
//if CB>=3 then 
Ma534_3=iMA(NULL,0,5,0,MODE_SMA,PRICE_MEDIAN,CB-2)-iMA(NULL,0,34,0,MODE_SMA,PRICE_MEDIAN,CB-2);
//if CB>=4 then 
Ma534_4=iMA(NULL,0,5,0,MODE_SMA,PRICE_MEDIAN,CB-3)-iMA(NULL,0,34,0,MODE_SMA,PRICE_MEDIAN,CB-3);
//if CB>=5 then 
Ma534_5=iMA(NULL,0,5,0,MODE_SMA,PRICE_MEDIAN,CB-4)-iMA(NULL,0,34,0,MODE_SMA,PRICE_MEDIAN,CB-4);
}
CB=1000;
  for (CB=1000 ; CB>=0; CB--)
  {
//For M15 direction check to stop order too late
pMa534=iMA(NULL,M15,5,0,MODE_SMA, PRICE_MEDIAN,CB)-iMA(NULL,M15,34,0,MODE_SMA,PRICE_MEDIAN,CB);
//if CB>=1 then 
pMa534_1=iMA(NULL,M15,5,0,MODE_SMA,PRICE_MEDIAN,CB)-iMA(NULL,M15,34,0,MODE_SMA,PRICE_MEDIAN,CB);
//if CB>=2 then 
pMa534_2=iMA(NULL,M15,5,0,MODE_SMA,PRICE_MEDIAN,CB-1)-iMA(NULL,M15,34,0,MODE_SMA,PRICE_MEDIAN,CB-1);
//if CB>=3 then 
pMa534_3=iMA(NULL,M15,5,0,MODE_SMA,PRICE_MEDIAN,CB-2)-iMA(NULL,M15,34,0,MODE_SMA,PRICE_MEDIAN,CB-2);
//if CB>=4 then 
pMa534_4=iMA(NULL,M15,5,0,MODE_SMA,PRICE_MEDIAN,CB-3)-iMA(NULL,M15,34,0,MODE_SMA,PRICE_MEDIAN,CB-3);
//if CB>=5 then 
pMa534_5=iMA(NULL,M15,5,0,MODE_SMA,PRICE_MEDIAN,CB-4)-iMA(NULL,M15,34,0,MODE_SMA,PRICE_MEDIAN,CB-4);
//SetIndexValue2(CB,Ma5345);
     
   
//   TrendBuffer[CB]=Ma534;
  
//    LoBuffer[CB]=((Ma534_1+Ma534_3+Ma534_2+Ma534_4+Ma534_5)/5);
    //loopbegin = loopbegin-1; // prevent to previous bars recounting
   
}
//+++++++++++++++++++++++

double   beli=(Ma534);
double   jual=((Ma534_1+Ma534_3+Ma534_2+Ma534_4+Ma534_5)/5);
double   bbeli= pMa534;
double   bjual=((pMa534_1+pMa534_3+pMa534_2+pMa534_4+pMa534_5)/5);


   OrdersPerSymbol=0;
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && (OrderMagicNumber() == MagicNumber) )
        {
         OrdersPerSymbol++;
        }
     }
  // History check
  if (0==1) // switch to turn ON/OFF history check
   {total=HistoryTotal();
  if(total>0)
      {for(cnt=0;cnt<total;cnt++)
        { OrderSelect(cnt, SELECT_BY_POS, MODE_HISTORY);            //Needs to be next day not as below
        if(OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber 
        && CurTime()- OrderCloseTime() < (Period() * 30 ))
          {
         OrdersPerSymbol++;
        }
        }
       }
    }   
     
 Comment ("Buy "+(Ma534)+"  Sell "+((Ma534_1+Ma534_3+Ma534_2+Ma534_4+Ma534_5)/5) +" "+ bbeli+ " "+ bjual); 

   // calculate TakeProfit and StopLoss for 
   //Ask(buy, long)
   slBUY=Ask-(StopLoss*Point);
   tpBUY=Ask+(TakeProfit*Point);
   //Bid (sell, short)
   slSEL=Bid+(StopLoss*Point);
   tpSEL=Bid-(TakeProfit*Point);

   // so we can eventually do trailing stop
   //if (TakeProfit<=0) {tpBUY=0; tpSEL=0;}           
   //if (StopLoss<=0)   {slBUY=0; slSEL=0;}           

   // place new orders based on direction
   // only of no orders open
   if(OrdersPerSymbol<1)
     {
      if (beli<jual && bbeli<bjual)
		  {
         OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,slBUY,tpBUY,"Deretz5Buy",MagicNumber,0,White);
         return(0);
        }
        
      // Sell Price
      if (beli>jual && bbeli>bjual)
        {
         OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,slSEL,tpSEL,"Deretz5Sell",MagicNumber,0,Red);
         return(0);
        }
     } //if
	
b = 1 * Point + iATR(NULL,0,5,1) * 1.5;
s = 1 * Point + iATR(NULL,0,5,1) * 1.5;

//++++++++++++++++++++++++++++++
total=OrdersTotal();
for(cnt=0;cnt<total;cnt++)
{

OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
    if ((OrderType()== OP_BUY) && (OrderSymbol()== Symbol()&& (OrderMagicNumber() == MagicNumber))) 
     {
         if ((OrderOpenPrice() > OrderStopLoss()) && (Bid-OrderOpenPrice() > StopLoss*Point))   
            { 
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,SlateBlue);
            return(0);
            }
         if ((Bid - OrderOpenPrice()) > b )
            { 
            if ((OrderStopLoss()) < (Bid -b))  
               {
               OrderModify(OrderTicket(),OrderOpenPrice(),Bid - b,Ask+(Point*10),0,SlateBlue);
               return(0);
               }
            }
        }
OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if ((OrderType()== OP_SELL) && (OrderSymbol()== Symbol()&& (OrderMagicNumber() == MagicNumber)))          
         {
         if ((OrderOpenPrice() < OrderStopLoss()) && (OrderOpenPrice()-Ask > StopLoss*Point)) 
            {
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Red);
            return(0);
            }
         if ((OrderOpenPrice()-Ask ) > s )
            { 
            if ((OrderStopLoss()) > (Ask + s))
            {
            OrderModify(OrderTicket(),OrderOpenPrice(),Ask + s,Bid - (Point * 10),0,Red);
            return(0);
            }  
            }
         } 
  
    
   }
//+++++++++++++++++++++++++++++++++++++++++

	
   // CLOSE order if profit target made
 
{   for( cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() && (OrderMagicNumber() == MagicNumber))
        {
         if(OrderType()==OP_BUY)
           {
            // did we make our desired BUY profit?
            if(beli == jual || beli > jual)
              {
               OrderClose(OrderTicket(),Lots,Bid,0,White);
               return(0);
              }
           } // if BUY

         if(OrderType()==OP_SELL)
           {
            // did we make our desired SELL profit?
            if(beli == jual || beli < jual)
              {
               OrderClose(OrderTicket(),Lots,Ask,0,Red);
               return(0);
              }
           } //if SELL
           
        } // if(OrderSymbol)
        
     } // for

   return(0);
  } // start()
}