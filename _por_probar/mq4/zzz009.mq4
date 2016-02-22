//+----------------------+
//| CCI SAR/Cross Expert |
//+----------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;


// Global scope
// Profit factors
extern int    myCCI=0;

// Display factors
string    cmt;

// Event factors
double barmove0 = 0;
double barmove1 = 0;
int         itv = 0;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//|------------------------------------------------------------------|

int init()
  {
 
   /*
   // 12 Month
   if(Symbol()=="AUDUSD"){myCCI=168; cmt="cci="+myCCI;}
   if(Symbol()=="EURAUD"){myCCI=19 ; cmt="cci="+myCCI;}
   if(Symbol()=="EURCHF"){myCCI=59 ; cmt="cci="+myCCI;}
   if(Symbol()=="EURGBP"){myCCI=16 ; cmt="cci="+myCCI;}
   if(Symbol()=="EURJPY"){myCCI=26 ; cmt="cci="+myCCI;}
   if(Symbol()=="EURUSD"){myCCI=179; cmt="cci="+myCCI;}
   if(Symbol()=="GBPCHF"){myCCI=34 ; cmt="cci="+myCCI;}
   if(Symbol()=="GBPJPY"){myCCI=33 ; cmt="cci="+myCCI;}
   if(Symbol()=="GBPUSD"){myCCI=141; cmt="cci="+myCCI;}
   if(Symbol()=="USDCAD"){myCCI=54 ; cmt="cci="+myCCI;}
   if(Symbol()=="USDCHF"){myCCI=78 ; cmt="cci="+myCCI;}
   if(Symbol()=="USDJPY"){myCCI=167; cmt="cci="+myCCI;}
   */

   /*
   // 6 Month
   if(Symbol()=="AUDUSD"){myCCI=245; cmt="cci="+myCCI;}
   if(Symbol()=="EURAUD"){myCCI=83 ; cmt="cci="+myCCI;}
   if(Symbol()=="EURCHF"){myCCI=159; cmt="cci="+myCCI;}
   if(Symbol()=="EURGBP"){myCCI=130; cmt="cci="+myCCI;}
   if(Symbol()=="EURJPY"){myCCI=108; cmt="cci="+myCCI;}
   if(Symbol()=="EURUSD"){myCCI=76 ; cmt="cci="+myCCI;}
   if(Symbol()=="GBPCHF"){myCCI=41 ; cmt="cci="+myCCI;}
   if(Symbol()=="GBPJPY"){myCCI=114; cmt="cci="+myCCI;}
   if(Symbol()=="GBPUSD"){myCCI=60 ; cmt="cci="+myCCI;}
   if(Symbol()=="USDCAD"){myCCI=152; cmt="cci="+myCCI;}
   if(Symbol()=="USDCHF"){myCCI=24 ; cmt="cci="+myCCI;}
   if(Symbol()=="USDJPY"){myCCI=75 ; cmt="cci="+myCCI;}
   */

   /*
   // 3 Month
   if(Symbol()=="AUDUSD"){myCCI=192; cmt="cci="+myCCI;}
   if(Symbol()=="EURAUD"){myCCI=67 ; cmt="cci="+myCCI;}
   if(Symbol()=="EURCHF"){myCCI=246; cmt="cci="+myCCI;}
   if(Symbol()=="EURGBP"){myCCI=16 ; cmt="cci="+myCCI;}
   if(Symbol()=="EURJPY"){myCCI=34 ; cmt="cci="+myCCI;}
   if(Symbol()=="EURUSD"){myCCI=66 ; cmt="cci="+myCCI;}
   if(Symbol()=="GBPCHF"){myCCI=34 ; cmt="cci="+myCCI;}
   if(Symbol()=="GBPJPY"){myCCI=24 ; cmt="cci="+myCCI;}
   if(Symbol()=="GBPUSD"){myCCI=240; cmt="cci="+myCCI;}
   if(Symbol()=="USDCAD"){myCCI=106; cmt="cci="+myCCI;}
   if(Symbol()=="USDCHF"){myCCI=87 ; cmt="cci="+myCCI;}
   if(Symbol()=="USDJPY"){myCCI=75 ; cmt="cci="+myCCI;}
   */
 
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

   //bool      found=false;
   bool     rising=false;
   bool    falling=false;
   bool      cross=false;

   double p=Point();
   
   double cCI0;
   double cCI1;
   
   int      cnt=0;

   // Error checking
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   if(myCCI==0)                               {Print("-----NO CCI  "); return(0);}
   if(barmove0==Open[0] && barmove1==Open[1]) {                        return(0);}

   // bars moved, update current position
   barmove0=Open[0];
   barmove1=Open[1];

   // get CCI based on OPEN
   cCI0=iCCI(Symbol(),0,myCCI,PRICE_OPEN,0);
   cCI1=iCCI(Symbol(),0,myCCI,PRICE_OPEN,1);

   // is it crossing zero up or down
   if (cCI1<=0 && cCI0>=0) { rising=true; cross=true; Print("Rising  Cross");}
   if (cCI1>=0 && cCI0<=0) {falling=true; cross=true; Print("Falling Cross");}
   
   Comment(cmt," iCCI=",cCI0," rise=",rising," fall=",falling);
   
   // close then open orders based on cross
   // pyramid below based on itv
   if (cross)
     {
      // Close ALL the open orders 
      for(cnt=OrdersTotal();cnt>0;cnt--)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            if (OrderType()==0) {OrderClose(OrderTicket(),Lots,Bid,3,White);}
            if (OrderType()==1) {OrderClose(OrderTicket(),Lots,Ask,3,Red);}
            itv=0;
            Sleep(5000);
           }
         Sleep(5000);
        }
      // Open new order based on direction of cross
      if (rising)  OrderSend(Symbol(),OP_BUY, Lots,Ask,3,0,0,"ZZZ100",11123,0,White);
      if (falling) OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"ZZZ100",11321,0,Red);
      
      // clear the interval counter
      return(0);
     }
   
   // Only pyramid if order already open
   for(cnt=OrdersTotal();cnt>0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         if (OrderType()==0)  //BUY
           {
            OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"ZZZ100",11123,0,White);
            break;
           }
         if (OrderType()==1)  //SELL
           {
            OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,0,"ZZZ100",11321,0,Red);
            break;
           }
        }
     }

   return(0);
  }

