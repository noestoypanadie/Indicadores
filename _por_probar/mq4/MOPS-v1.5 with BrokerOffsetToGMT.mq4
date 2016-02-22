//+---------------------------------------------------------------------------+
//|                                                               MOPS-v1S.mq4|
//|   Copyright © 2006, RogerThait, Treberk,-=EvgeniX=- (with thanks to PipSeeker)|
//|http://www.strategybuilderfx.com/forums/showthread.php?t=15858&page=1&pp=8 |
//+---------------------------------------------------------------------------+

#property copyright "Copyright © 2006, RogerThait, Treberk"
#property link      "http://www.strategybuilderfx.com/forums/showthread.php?t=15858&page=1&pp=8"


extern double Lots=0.1;
extern int MagicNumber=69654;
extern int Slippage=5;

extern int BrokerOffsetToGMT=2;// This value would be a 0(zero) if your data feed is GMT. IBFX uses GMT. Alpari uses GMT+1. 
                               // TradexGroup and North Financial use GMT+2. Check your brokers feed and adjust accordingly.
		
extern int OpenHour=8;
extern int OpenMinute=0;
extern int OpenStartHour1=7;
extern int CloseHour1=21;
extern int CloseHour2=22;
extern int CloseHour3=7;
extern int CloseHour4=20;
extern int CloseMinute1=55;
extern int CloseMinuteF=53;
extern int CloseMinute2=5;
extern int CloseMinute3=55;
extern int CloseMinute4=59;

extern double MinProfitTake=0;

extern int Buys,Sells;
bool BuyThisSymbol=true;
bool SellThisSymbol=true;
double LargestMarginUsed,LargestFloatingLoss;
double LowestFreeMargin;
double StartBalance,StartEquity;
int i;

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
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+

int start()
{
   
if (BuyThisSymbol==false && Hour()==OpenStartHour1) 
{
BuyThisSymbol = true;
}

if (SellThisSymbol==false && Hour()==OpenStartHour1) 
{
SellThisSymbol = true;
}

   
   
   
   if(AccountMargin() > LargestMarginUsed)    LargestMarginUsed   = AccountMargin();  
   if(AccountProfit() < LargestFloatingLoss)  LargestFloatingLoss = AccountProfit(); 
   if(LowestFreeMargin == 0.0)                LowestFreeMargin    = AccountFreeMargin();
   if(AccountFreeMargin() < LowestFreeMargin) LowestFreeMargin    = AccountFreeMargin();



Buys = 0;
Sells = 0;

for(i =0; i < OrdersTotal(); i++)
	{
	OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
	if ( OrderSymbol() == Symbol() && OrderType() == OP_BUY && OrderMagicNumber()==MagicNumber)  Buys  += 1;
	if ( OrderSymbol() == Symbol() && OrderType() == OP_SELL && OrderMagicNumber()==MagicNumber) Sells += 1;
	}


Comment("Buy trades: ",Buys,","," Sell trades: ",Sells,
		   "\nLargest Margin Used: ",LargestMarginUsed,","," Largest Floating Loss: ",LargestFloatingLoss,","," Lowest Free Margin: ",LowestFreeMargin,
		   "\nStart Balance= ",StartBalance,",","Start Equity= ",StartEquity,
		   "\nBalance: ",AccountBalance(),","," Equity: ",AccountEquity(),","," TotalProfit: ",AccountProfit());
		   
if ( (OrdersTotal() == 0) )
{
StartBalance= AccountBalance();
StartEquity=AccountEquity();
}
if ( (StartEquity==0) && (AccountProfit()!= 0) && (OrdersTotal() >=1))  StartEquity=(AccountEquity()-AccountProfit()); 

for(i =0; i < OrdersTotal(); i++)
      {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL && IsTradeAllowed()==true && OrderMagicNumber()==MagicNumber)
         {
            if (Hour()==CloseHour3 + BrokerOffsetToGMT && Minute()>=CloseMinute3 && Minute()<=CloseMinute4 && OrderProfit()>MinProfitTake*Point && Hour()!=OpenHour + BrokerOffsetToGMT)
                OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, Yellow);
         }
         
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY && IsTradeAllowed()==true && OrderMagicNumber()==MagicNumber)
         {
            if (Hour()==CloseHour3 + BrokerOffsetToGMT && Minute()>=CloseMinute3 && Minute()<=CloseMinute4 && OrderProfit()>MinProfitTake*Point && Hour()!=OpenHour + BrokerOffsetToGMT)
                OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, White);
         }
         
// form  EvgeniX

if (DayOfWeek()!=5)
{    
   if (MarketInfo(Symbol(),MODE_SWAPSHORT)>0)
    {
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY && IsTradeAllowed()==true && OrderMagicNumber()==MagicNumber)
         {
            if (Hour()==CloseHour1 + BrokerOffsetToGMT && Minute()>=CloseMinute1 && OrderProfit()>MinProfitTake*Point)
                OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Yellow);
         }
         
            if(OrderSymbol()==Symbol() && OrderType()==OP_SELL && IsTradeAllowed()==true && OrderMagicNumber()==MagicNumber)
         {
            if (Hour()==CloseHour2 + BrokerOffsetToGMT && Minute()>=CloseMinute2 && OrderProfit()>MinProfitTake*Point)
                OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, White);
         }
     }
// form  EvgeniX

   if (MarketInfo(Symbol(),MODE_SWAPLONG)>0)
    {    
         if(OrderSymbol()==Symbol() && OrderType()==OP_SELL && IsTradeAllowed()==true && OrderMagicNumber()==MagicNumber)
         {
            if (Hour()==CloseHour1 + BrokerOffsetToGMT && Minute()>=CloseMinute1 && OrderProfit()>MinProfitTake*Point)
                OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, Yellow);
         }
         
            if(OrderSymbol()==Symbol() && OrderType()==OP_BUY && IsTradeAllowed()==true && OrderMagicNumber()==MagicNumber)
         {
            if (Hour()==CloseHour2 + BrokerOffsetToGMT && Minute()>=CloseMinute2 && OrderProfit()>MinProfitTake*Point)
                OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, White);
         }
     } 
}

else     
   {    
         if(OrderSymbol()==Symbol() && OrderType()==OP_BUY && IsTradeAllowed()==true && OrderMagicNumber()==MagicNumber)
         {
            if (Hour()==CloseHour4 + BrokerOffsetToGMT && Minute()>=CloseMinuteF && Minute()<=CloseMinute4 && OrderProfit()>MinProfitTake*Point)
                OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Yellow);
         }
         
            if(OrderSymbol()==Symbol() && OrderType()==OP_SELL && IsTradeAllowed()==true && OrderMagicNumber()==MagicNumber)
         {
            if (Hour()==CloseHour4 + BrokerOffsetToGMT && Minute()>=CloseMinuteF && Minute()<=CloseMinute4 && OrderProfit()>MinProfitTake*Point)
                OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, White);
         }
   }
        
       }

// form  EvgeniX

        if (Hour() == OpenHour + BrokerOffsetToGMT && Minute() >= OpenMinute && IsTradeAllowed()==true)
          {
          if  ( SellThisSymbol == true) 
              {
              OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,"MOPS-v1S",MagicNumber,0,Red);
              SellThisSymbol=false;
                    {
                    if(IsTradeAllowed()==false) Print("Trade not allowed");
                    }
                    return(0);
              }
              
          }
         if (Hour() == OpenHour + BrokerOffsetToGMT && Minute() >= OpenMinute && IsTradeAllowed()==true)
           {
             if (BuyThisSymbol == true )  
              {
              OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,"MOPS-v1S",MagicNumber,0,Blue);
              BuyThisSymbol=false;
                    {
                    if(IsTradeAllowed()==false) Print("Trade not allowed");
                    }
              return(0);
              }
              
            
        }
           
         


if (BuyThisSymbol==false && Hour()==OpenStartHour1 + BrokerOffsetToGMT) 
{
BuyThisSymbol = true;
}

if (SellThisSymbol==false && Hour()==OpenStartHour1 + BrokerOffsetToGMT) 
{
SellThisSymbol = true;
}


return(0);
}
//+------------------------------------------------------------------+




