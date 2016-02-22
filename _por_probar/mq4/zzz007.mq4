//+----------------------+
//| CCI SAR/Cross Expert |
//+----------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;


// Global scope
// Profit factors
int    TakeProfit=0;
int    Pym=0;
int    myCCI=0;

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
 
   if(Symbol()=="AUDUSD"){TakeProfit=163; Pym=1; myCCI=163; cmt="tp163 itv=1 cci=163";}
   if(Symbol()=="EURAUD"){TakeProfit=350; Pym=1; myCCI=89 ; cmt="tp350 itv=1 cci=89 ";}
   if(Symbol()=="EURCHF"){TakeProfit=65 ; Pym=2; myCCI=120; cmt="tp65  itv=2 cci=120";}
   if(Symbol()=="EURGBP"){TakeProfit=106; Pym=2; myCCI=172; cmt="tp106 itv=2 cci=172";}
   if(Symbol()=="EURJPY"){TakeProfit=121; Pym=2; myCCI=165; cmt="tp121 itv=2 cci=165";}
   if(Symbol()=="EURUSD"){TakeProfit=194; Pym=1; myCCI=180; cmt="tp194 itv=1 cci=180";}
   if(Symbol()=="GBPCHF"){TakeProfit=200; Pym=2; myCCI=83 ; cmt="tp200 itv=2 cci=83 ";}
   if(Symbol()=="GBPJPY"){TakeProfit=132; Pym=2; myCCI=20 ; cmt="tp132 itv=2 cci=20 ";}
   if(Symbol()=="GBPUSD"){TakeProfit=145; Pym=4; myCCI=161; cmt="tp145 itv=4 cci=161";}
   if(Symbol()=="USDCAD"){TakeProfit=130; Pym=1; myCCI=112; cmt="tp130 itv=1 cci=112";}
   if(Symbol()=="USDCHF"){TakeProfit=140; Pym=1; myCCI=205; cmt="tp140 itv=1 cci=205";}
   if(Symbol()=="USDJPY"){TakeProfit=220; Pym=1; myCCI=205; cmt="tp220 itv=1 cci=205";}
 
   itv=Pym;
    
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

   double tpA=0, tpB=0;
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

   // interval (bar) counter
   // used to pyramid orders during trend
   itv++;
   
   // since the bar just moved
   // calculate TP and SL for (B)id and (A)sk
   tpA=Ask+(p*TakeProfit);
   tpB=Bid-(p*TakeProfit);
   if (TakeProfit==0) {tpA=0; tpB=0;}           
   
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
      for(cnt=0;cnt<OrdersTotal();cnt++)
        {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(OrderSymbol()==Symbol())
           {
            if (OrderType()==0) {OrderClose(OrderTicket(),Lots,Bid,3,White);}
            if (OrderType()==1) {OrderClose(OrderTicket(),Lots,Ask,3,Red);}
            itv=0;
           }
        }
      // Open new order based on direction of cross
      if (rising)  OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,tpA,"ZZZ100",11123,0,White);
      if (falling) OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,tpB,"ZZZ100",11321,0,Red);
      
      // clear the interval counter
      itv=0;
      return(0);
     }
   
   // Only pyramid if order already open
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {
         if (OrderType()==0)  //BUY
           {
            if (itv >= Pym)
              {
               OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,tpA,"ZZZ100",11123,0,White);
               itv=0;
              }
           }
         if (OrderType()==1)  //SELL
           {
            if (itv >= Pym)
              {
               OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,tpB,"ZZZ100",11321,0,Red);
               itv=0;
              }
           }
        }
     }

   return(0);
  }

