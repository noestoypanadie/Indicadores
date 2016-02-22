//+------------------------------------------------------------------+
//|                                                     EuroBull.mq4 |
//|                                                           Zonker |
//|                                        http://www.greenpeace.org |
//+------------------------------------------------------------------+
//
//The EuroBull, tends to favour markets that trend in favour of Euro:).
//Designed to run on EURUSD.

#property copyright "Zonker"
#property link      "http://www.greenpeace.org"

#define MAXLOTSIZE 5
#define MAXPOS 3
#define SLIP 1
#define SL 100
int myMagic = 88888888;//very lucky, yes?

//+------------------------------------------------------------------- 
int init() { return(0); }
int deinit() { return(0); }
//+------------------------------------------------------------------- 

int start()
{  double sma;
   bool BuyEuros = false;
   int LotsToBuy,Lots; 
   int i;

   if(!Happyness()) return(0);

   sma = iMA(NULL,PERIOD_D1,10,0,MODE_SMA,PRICE_CLOSE,0);//Must respect the sma.
   
   if(sma > Ask) //Euros going cheap! BUY!
      BuyEuros = true;
   
   if(sma < Ask) //Momentum in our favour! BUY!!
      BuyEuros = true;
      
   if(sma == Ask) //BuY EUROS NOW!!!, BUY MORE!!!
      BuyEuros = true;
   
   if(OrdersTotal()>0)
   {  //We have Euros! Do we need any more?
      Lots=0;
      for(i=0;i<OrdersTotal();i++)
      {  OrderSelect(i,SELECT_BY_POS,MODE_TRADES); 
         Lots += OrderLots();
      }
      if(AccountEquity() > (Lots*2000 + MathMin(5,(Lots+1)/2)*2000 + 100) && Lots < MAXLOTSIZE*MAXPOS && Lots >= 1.0)
         CloseOrders(OP_BUY); //Sell up and buy more Euros   
      else 
         return(0);
      
   }
    
   if(BuyEuros)
   {  //We don't have any Euros?!!? How many Euros should we buy?
      LotsToBuy = AccountBalance()/2000;
      
      if(LotsToBuy == 0 && AccountBalance() > 100)
      {  //Ok, getting desparate..
         double tinyLots = NormalizeDouble(AccountBalance()/2000.0-0.1,1);
         if(tinyLots>0)
            MyOrderSend(Symbol(),OP_BUY,tinyLots,Ask,SLIP,Ask-SL*Point,Ask+SL*Point,"",myMagic,0,Blue);    
         return(0);
      }
      
      for(i=0;i<MAXPOS;i++)
      {  if(LotsToBuy>MAXLOTSIZE) Lots = MAXLOTSIZE;
         else Lots = LotsToBuy;
         
         MyOrderSend(Symbol(),OP_BUY,Lots,Ask,SLIP,Ask-SL*Point,0,"",myMagic,0,Blue);
         
         LotsToBuy -= MAXLOTSIZE;
         if(LotsToBuy <= 0) break;
      } 
   }  


   return(0);
}
  
//+------------------------------------------------------------------- 
bool Happyness() //Are we in the right mood to trade?
{  
   if(!IsConnected()) 
   {  Print("Yo man, we are not connected!");
      return(false);
   }
   if(!IsExpertEnabled())
   {  Print("Hey, we are not enabled!");
      return(false);
   }
   
   if(AccountEquity() > 98800) //Stop at 888%, lets not be greedy.
   {  if(OrdersTotal() > 0) 
         CloseOrders(OP_BUY); 
      return(false);
   }
   
   if(AccountBalance() < 200) return(false); //Ok, we  lost.
   
   return(true);
}
  
//+-------------------------------------------------------------------  
int CloseOrders(int cmd)
{  int i;
   double price;
   if(cmd == OP_SELL) price = Ask;
   else price = Bid;

   for(i=OrdersTotal()-1;i>=0;i--)
   {  OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderType() == cmd)
         MyOrderClose(OrderTicket(),OrderLots(),price,SLIP,CLR_NONE);
   }
}
//+------------------------------------------------------------------- 
int MyOrderSend(string sym, int cmd, double vol, double price, int slip, double sl, double tp, string comment="", int magic=0, datetime exp=0, color cl=CLR_NONE)
{  int err;
   bool isAsk=false;
 
   if(price == Ask) isAsk = true;   

   for(int z=0;z<10;z++)
   {  if(OrderSend(sym,cmd,vol,price,slip,sl,tp,comment,magic,exp,cl)<0)
      {  err = GetLastError();
         Print("OrderSend failed, Error: ", err);
         if(err>4000) break;
         RefreshRates();
         if(isAsk) price = Ask;
         else price = Bid;
      }
      else
         break;
   }

}
//+------------------------------------------------------------------+
bool MyOrderClose(int ticket, double lots, double price, int slip, color cl=CLR_NONE)
{  int err;
   bool isAsk=false;
   
   if(price == Ask) isAsk = true; 

   for(int z=0;z<10;z++)
   {
      if(!OrderClose(ticket,lots,price,slip,cl))
      {  err = GetLastError();
         Print("OrderClose failed, Error: ", err);
         if(err>4000) break;
         RefreshRates();
         if(isAsk) price = Ask;
         else price = Bid;
      }
      else
         break;
   }

} 
//+------------------------------------------------------------------- 

