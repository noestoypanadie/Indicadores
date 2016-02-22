//+------------------------------------+
//| Back Test Tester                   |
//+------------------------------------+
//

// generic user input
extern double Lots=0.1;
extern int TP=100;
extern int SL=50;

datetime bartime=0;


int start()
  {

   double p=Point();
   int      cnt=0;
   int      OrdersPerSymbol=0;

   double  I1=0;
   double  I2=0;
   
   bool IPOS, INEG;

   // Error checking & bar movement
   if(AccountFreeMargin()<(1000*Lots))        {Print("-----NO MONEY"); return(0);}
   if(Bars<100)                               {Print("-----NO BARS "); return(0);}
   if(Time[0]!=bartime)                       {bartime=Time[0];}

   OrdersPerSymbol=0;
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol() )
        {
         OrdersPerSymbol++;
        }
     }

   // place new orders based on direction
   // only of no orders open
   if(OrdersPerSymbol==0)
     {
      OrderSend(Symbol(),OP_BUY, Lots,Ask,2,Ask-(SL*p),Bid+(TP*p),"BUY  "+CurTime(),0,0,White);
      OrderSend(Symbol(),OP_SELL,Lots,Bid,2,Bid+(SL*p),Ask-(TP*p),"SELL "+CurTime(),0,0,Red);
     } 

   return(0);
  } // start()




