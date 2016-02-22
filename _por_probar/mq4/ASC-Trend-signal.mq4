//+------------------------------------------------------------------+
//|                                                  ASC_signal.mq4 |
//|                                                           tom112 |
//|                                            tom112@mail.wplus.net |
//+------------------------------------------------------------------+
#property copyright "tom112"
#property link      "tom112@mail.wplus.net"

//---- input parameters
extern double TakeProfit = 0;
extern double Lots = 0.1;
extern double TrailingStop = 0;
extern int       RISK=3;
extern int       period=9;
double Points;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   Points = MarketInfo (Symbol(), MODE_POINT);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   
   int cnt=0, total;
   
   int i;
   int Counter,i1,value11;
   double value1,x1,x2;
   double value2;
   double TCount,Range,AvgRange,M1,M2;
   
   

   
   if(Bars<100)
     {
      Print("bars less than 100");
      return(0); 
     }
   if(TakeProfit<10)
     {
      Print("TakeProfit less than 10");
      return(0);  
            }
     
     
        x1=67+RISK;
        x2=33-RISK;
   value11=period;
   
   //******************************************************************************
 	Range=0.0;
	AvgRange=0.0;
	for (Counter=0; Counter<=period; Counter++) 
	AvgRange=AvgRange+MathAbs(High[Counter]-Low[Counter]);
		
	Range=AvgRange/(period+1);
	TCount=0;
	Counter=0;
	while (Counter<period && TCount<1)
		{if (MathAbs(Open[Counter]-Close[Counter+1])>=Range*2.0) TCount++;
		Counter++;
		}
	if (TCount>=1) {M1=Counter;} else {M1=-1;}
	Counter=0;
	TCount=0;
	while (Counter<(period-3) && TCount<1)
		{if (MathAbs(Close[Counter+3]-Close[Counter])>=Range*4.6) TCount++;
		Counter++;
		}
	if (TCount>=1) {M2=Counter;} else {M2=-1;}
	if (M1>-1) {value11=MathFloor(period/3);} else {value11=period;}
	if (M2>-1) {value11=MathFloor(period/2);} else {value11=period;}
	
	
	//****************************************************************************************
	
	
	value1=100-MathAbs(iWPR(NULL,0,value11,0)); 
	value2=100-MathAbs(iWPR(NULL,0,value11,1));
   
   

   if(OrdersTotal()<1) 
     {
      if(AccountFreeMargin()<(1000*Lots))
        {
         Print("We have no money");
         return(0); 
        }

      if( value1>x1 && value2<x1 )
        {
         OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,Ask+TakeProfit*Points,"macd signal",16384,0,Red); // исполняем
         if(GetLastError()==0)Print("Order opened : ",OrderOpenPrice());
         return(0); 
        }
  
      if( value1<x2 && value2 > x2 )
        {
         OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,Bid-TakeProfit*Points,"macd sample",16384,0,Red); // исполняем
         if(GetLastError()==0)Print("Order opened : ",OrderOpenPrice());
         return(0);
        }
 
      return(0);
     }
 
   total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL && 
         OrderSymbol()==Symbol())   
        {
         if(OrderType()==OP_BUY)   
           {
          
            if(value1<x2)
                {
                 OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); 
                 return(0); 
                }
            
            if(TrailingStop>0)  
              {                
               if(Bid-OrderOpenPrice()>Points*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Points*TrailingStop)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Points*TrailingStop,OrderTakeProfit(),0,Red);
                     return(0);
                    }
                 }
              }
           }
         else 
           {
          
            if(value1>x1)
              {
               OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); 
               return(0); 
              }
           
            if(TrailingStop>0)  
              {    
               if((OrderOpenPrice()-Ask)>(Points*TrailingStop))
                 {
                  if(OrderStopLoss()==0.0 || 
                     OrderStopLoss()>(Ask+Points*TrailingStop))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Points*TrailingStop,OrderTakeProfit(),0,Red);
                     return(0);
                    }
                 }
              }
           }
        }
     }
   return(0);
  }

//+------------------------------------------------------------------+