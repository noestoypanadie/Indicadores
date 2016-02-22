//+------------------------------------------------------------------+
//|                                                        |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copywrong 2005, RonT "
#property  link      "http://www.lightpatch.com/forex"

// how many periods in the moving average
extern int extRperiod = 48;
// how many periods to qualify red(sell) or green(buy)
// so we can stay out of the non-trending chop
extern int extQualforHowLong = 5;
// how many lots do you want to risk
extern double extLots=0.1;

//used to track the real bar changes
//must be here, or will be set in 
//start() on every tick and won't work
int prevTime;  

double wtp;   //previous value
double wt;    //current value

int init()   {prevTime=Time[1]; return(0);}
int deinit() {                  return(0);}


int start()
  {   
   int cnt=0;
   int err=0;

   bool     found=false;
   bool    bought=false;
   bool      sold=false;

   double p=Point;
   
   //----- variables
   int    c;
   int    i;
   int    length;
   double lengthvar;
   int    loopbegin;
   int    pos;
   double sum;
   double tmp;
   int    width;
   
   int    rc=0;  //red count
   int    gc=0;  //green count

   
   // Error checking
   if(Bars<100)                           {Print("Bars less than 100"); return(0);}
   if(AccountFreeMargin()<(1000*extLots)) {Print("We have no money");   return(0);}
   if (Time[1] == prevTime)               {                             return(0);}
   
   
   // This makes us trade right on the timeframe
   // boundry, and also keeps us from multiple
   // trades by evaluating every tick
   prevTime=Time[1];
  
   // Does our current Symbol() have an open order?
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {found=true;  break;}
         else
        {found=false;}        
     }

   if (found && OrderType()==0) {bought=true;  sold=false;}
   if (found && OrderType()==1) {bought=false; sold=true;}

   //re-assign this, since it gets modified each loop
   length    = extRperiod;
 
   // -1 not needed since we're NOT evaluating Bar 0
   // +1 needed to prime the wtp variable otherwise
   // you always get red 1 green 6  or red 6 and green 1
   for(pos = extQualforHowLong+1; pos >= 1; pos--)
     { 
      sum = 0;
      for(i = length; i >= 1  ; i--)
        {
         lengthvar = length + 1;
         lengthvar /= 3;
         tmp = 0;
         tmp = ( i - lengthvar)*Close[length-i+pos];
         sum+=tmp;
        }
      
      //Print("wt=",wt," at ",Time[1]);
         
      wtp=wt;
      wt = sum*6/(length*(length+1));
      if (wtp > wt) {rc++;} else {gc++;}

      //and finally get rid of the extra +1 from above
      if (rc>0 && gc>0) {rc=0; gc=0;}
      
     }


   Print("Red=",rc," Green=",gc);


   return(0);
  }









/*
   
   //reset counters and close orders
   if (greencount>0 && redcount>0)
     {
      greencount=0; 
      redcount=0;

      if (found && bought)
        {
         Print(Symbol(),Time[0],OrderOpenTime(),"CLOSE buy");
         OrderClose(OrderTicket(),extLots,Bid,0,White);
         if(GetLastError()==0)
           {
            Print(Symbol()," CLOSE Buy: ",Bid);
           }
            else
           {
            Print(Symbol()," CLOSE Buy Error ",err);
           }
        }

      if (found && sold)
        {
         Print(Symbol(),Time[0],OrderOpenTime(),"CLOSE sell");
         OrderClose(OrderTicket(),extLots,Ask,0,Red);
         if(GetLastError()==0)
           {
            Print(Symbol()," CLOSE Sell : ",Ask);
           }
            else
           {
            Print(Symbol(),"CLOSE Sell Error ",err);
           }
        }
     }
      

   // Entry definitions
   if (!found && greencount==5)
     {
      Print("LSMA BUY Order started  ",Ask);
      OrderSend(Symbol(),OP_BUY,extLots,Ask,3,Ask-(p*50),0,"LSMA Buy ",16125,0,White);
      if(GetLastError()==0)
        {
         Print(Symbol()," LSMA order success : ",Ask);
        }
         else
        {
         Print(Symbol()," LSMA order Error ",err);
        }
     }
     
   if (!found && redcount==5)
     {
      Print("LSMA SELL Order started  ",Bid);
      OrderSend(Symbol(),OP_SELL,extLots,Bid,3,Bid+(p*50),0,"LSMA Sell",16521,0,Red);
      if(GetLastError()==0)
        {
         Print(Symbol()," LSMA order success : ",Bid );
        }
         else
        {
         Print(Symbol()," LSMA order Error ",err);
        }
     }
*/


//+------------------------------------------------------------------+

