// 
// 2 Bar Trend

extern int ProfitMade=65;
extern int LossLimit=20;
extern double OCSpread=8;

// Bar handling
datetime bartime=0;
bool     TradeAllowed=true;


int start()
{

   double SL,TP;
   double ocs=OCSpread*Point();
   
   // bar counting
   if(bartime!=Time[0]) 
     {
      bartime=Time[0];
      TradeAllowed=true;
     }
   
   //rising
   if ( Open[1]+ocs < Close[1] && Close[1] < Open[0] )
     {
      //buy
      SL=Ask-( LossLimit*Point() );
      TP=Ask+( ProfitMade*Point() );
      OrderSend(Symbol(),OP_BUY,0.1,Ask,3,SL,TP,"2Bar",55555,White);
      TradeAllowed=false;
     }
   //falling
   if ( Open[1] > Close[1]+ocs && Close[1] > Open[0] )
     {
      //sell
      SL=Ask+( LossLimit*Point() );
      TP=Ask-( ProfitMade*Point() );
      OrderSend(Symbol(),OP_SELL,0.1,Bid,3,SL,TP,"2Bar",55555,Red);
      TradeAllowed=false;
     }

  } //start


