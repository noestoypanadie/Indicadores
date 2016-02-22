//+------------------------------------+
//| TRUE_SCALPER                       |
//+------------------------------------+

// Designed for 5 but I attached it to 15 and it worked fine.
//	long if EMA3>EMA7:::EMA3<EMA7<0 
// Code Adapted from  Scalper EAs to use EMA and RSI and multiple currencies


// variables declared here are GLOBAL in scope

#property copyright "Jacob Yego"
#property link      "http://www.PointForex.com/"

// generic user input
extern double Lots=1.0;
extern int MyPeriod=14;
extern int TakeProfit=100;
extern int StopLoss=0;
extern int TrailingStop=5;
extern int Slippage=2;
extern int BuyLevel=0;
extern int SellLevel=0;

//Bar movement, must be 0 to cause 1st movement
datetime newbar=0;


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
   double   slA, tpA, slB, tpB;

   bool      found=false;
   bool     rising=false;
   bool    falling=false;
   bool      cross=false;

   double  bull=0;
   double  bear=0;
   double  RSIPOS=0;
   double  RSINEG=0;
   double  lobar=0;
   double  highbar=0; 

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   if (TakeProfit<10)                         {Print("TakeProfit<10"); return(0);}

   if (newbar == Time[0])                     {                        return(0);}
   newbar=Time[0];
   
   
   // One trade per Symbol
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() )
        {
         return(0);
        }
     }

   // calculate TakeProfit and StopLoss for 
   //(B)id (sell, short) and (A)sk(buy, long)
   slA=Ask-(p*StopLoss);
   tpA=Ask+(p*TakeProfit);
   slB=Bid+(p*StopLoss);
   tpB=Bid-(p*TakeProfit);
   if (TakeProfit<=0) {tpA=0; tpB=0;}           
   if (StopLoss<=0)   {slA=0; slB=0;}           

   bull=iMA(3,MODE_EMA,1);
   bear=iMA(7,MODE_EMA,1);
   RSIPOS=iRSI(2,2)>50;
   RSINEG=iRSI(2,2)<50;

vars:	sl(0),tp(0);
vars:	cnt(0);
vars:   OpenTrades(0);
vars:   i(0);
Define: ProfitMade(2);

 
    OpenTrades = 0;
    lobar=LOW[Lowest(MODE_LOW,19,19)];
    highbar=HIGH[Highest(MODE_HIGH,19,19)];
  For i = 1 to TotalTrades
  {
        if OrderValue(i,VAL_SYMBOL) = Symbol then
             OpenTrades++;
  };

If OpenTrades<1 then
	{
	If bull>bear and RSINEG then
		{
		sl= lobar-1*Point;    //(ask-(StopLoss*point));
		tp=(bid+(TakeProfit*point));
		SetOrder(OP_BUY,Lots,ask,slippage,sl,tp,blue);
		exit;
		};
	If bull<bear and RSIPOS then
		{
		sl=highbar+1*point;//(bid+(StopLoss*point));
		tp=(ask-(TakeProfit*point));
		SetOrder(OP_SELL,Lots,bid,slippage,sl,tp,red);
		exit;
		};
	};
	
	If OpenTrades<1 then
	{
	
	if bull >bear and RSINEG then 
		{
		sl=lobar-1*point;                  //(ask-(StopLoss*point));
		tp=(bid+(TakeProfit*point));
		SetOrder(OP_BUY,Lots,ask,slippage,sl,tp,blue);
		exit;
		};
	if bull < bear and RSIPOS then
		{
		sl= highbar+1*point;//(bid+(StopLoss*point));
		tp=(ask-(TakeProfit*point));
		SetOrder(OP_SELL,Lots,bid,slippage,sl,tp,red);
		exit;
		};
	};
	
for cnt=1 to TotalTrades
 {
   If Ord(cnt,VAL_TYPE)=OP_BUY and Ord(cnt,VAL_SYMBOL)=Symbol then
     {
      If (Bid-Ord(cnt,VAL_OPENPRICE))>(ProfitMade*Point) then 
       {
         CloseOrder(OrderValue(cnt,VAL_TICKET),Ord(cnt,VAL_LOTS),Ord(cnt,VAL_CLOSEPRICE),0,BlueViolet);
          Exit;
        };
     };
   If Ord(cnt,VAL_TYPE)=OP_SELL and Ord(cnt,VAL_SYMBOL)=Symbol then    
     {
      If (Ord(cnt,VAL_OPENPRICE)-Ask)>(ProfitMade*Point) then
      {
        CloseOrder(OrderValue(cnt,VAL_TICKET),Ord(cnt,VAL_LOTS),Ord(cnt,VAL_CLOSEPRICE),0,Purple);
         Exit;
      };
    };
 };

/////Direction Change

for cnt=1 to TotalTrades
 {
   If Ord(cnt,VAL_TYPE)=OP_BUY and Ord(cnt,VAL_SYMBOL)=Symbol then
     {
      If  bull < bear  then 
       {
         CloseOrder(OrderValue(cnt,VAL_TICKET),Ord(cnt,VAL_LOTS),Ord(cnt,VAL_CLOSEPRICE),0,BlueViolet);
          Exit;
        };
     };
   If Ord(cnt,VAL_TYPE)=OP_SELL and Ord(cnt,VAL_SYMBOL)=Symbol then    
     {
      If  bull < bear   then
      {
        CloseOrder(OrderValue(cnt,VAL_TICKET),Ord(cnt,VAL_LOTS),Ord(cnt,VAL_CLOSEPRICE),0,Purple);
         Exit;
      };
    };
 };



      
   // ---> HERE is where you determine when to BUY
   //if (i1>BuyLevel)
   //  {
   //   OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,slA,tpA,"ZMRLQVYX",11123,0,White);
   //  }
        
   // ---> HERE is where you determine when to SELL
   //if (i2<SellLevel)
   //  {
   //   OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,slB,tpB,"ZMRLQVYX",11321,0,Red);
   //  }
     
   return(0);
  }




