//+------------------------------------------------------------------+
//|                                                        |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copywrong 2005, RonT "
#property  link      "http://www.lightpatch.com/forex"

extern int extRperiod = 48;
extern double extLots=0.1;

int init()   {return(0);}
int deinit() {return(0);}
int start()
  {   

   int redcount=0;
   int greencount=0;
   int yellowcount=0;
   
   int cnt=0;
   int err=0;
   
   double p=Point;
   
   bool     found=false;
   bool    bought=false;
   bool      sold=false;

   //----- variables
   int    c;
   int    i;
   int    length;
   double lengthvar;
   int    loopbegin;
   //int    pos;
   double sum;
   double tmp;
   int    width;

   double wtp; //previous value
   double wt;  //current value

   
   // Error checking
   if(Bars<100)                           {Print("Bars less than 100"); return(0);}
   if(AccountFreeMargin()<(1000*extLots)) {Print("We have no money");   return(0);}


   // Does the Symbol() have an open order
   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderSymbol()==Symbol())
        {found=true; break;}
         else
        {found=false;}        
     }
   
   // YOU HAVE TO OPEN AN ORDER MANUALLY 1ST
   // Leave if there is no open order 
   //if (found==false) {Print(Symbol()," Order not found"); return(0);}
   

   // Leave if order was less than 4 periods ago
   //if ((Time[0]-OrderOpenTime())<300) {Print(Symbol()," not old enough ", Time[0]-OrderOpenTime()); return(0);}
   //if ((Time[0]-OrderOpenTime())<300) {return(0);}

   if (OrderType()==0) {bought=true;  sold=false;}
   if (OrderType()==1) {bought=false; sold=true;}

   length = extRperiod;  //48
 
   sum = 0;
   for(i = length; i >= 1  ; i--)
     {
      lengthvar = length + 1;
      lengthvar /= 3;
      tmp = 0;
      tmp = ( i - lengthvar)*Close[length-i+1];
      sum+=tmp;
     }
         
   wtp=wt;
   wt = sum*6/(length*(length+1));
   if (wtp > wt) {redcount++;} else  {greencount++;}

   
   //reset counters if there is any switching
   if (greencount>0 && redcount>0)
     {
      // Close any open orders, buy or sell
      greencount=0; 
      redcount=0;
     }
      
   // Entry definitions
   if (greencount==5)
     {
      Print(Symbol()," CLOSE sell BUY buy");
      //ignore errors here as there may be no order in progress
      OrderClose(OrderTicket(),extLots,Ask,0,Red);

      Print("BUY  Order started  ",Ask);
      OrderSend(Symbol(),OP_BUY,extLots,Ask,3,Ask-(p*50),0,"BC Buy ",16123,0,White);
      if(GetLastError()==0)
        {
         Comment("BC_BUY  Order opened : ",Ask);
         Print("BC_BUY  Order opened : ",Ask);
        }
         else
        {
         Print(Symbol(),"BUY Error ",err);
        }
     }
     
   if (redcount==5)
     {
      Print(Symbol(),Time[0],OrderOpenTime(),"CLOSE buy BUY sell");
      //ignore errors here as there may be no order in progress
      OrderClose(OrderTicket(),extLots,Bid,0,White);

      Print("SELL Order started  ",Bid);
      OrderSend(Symbol(),OP_SELL,extLots,Bid,3,Bid+(p*50),0,"BC Sell",16321,0,Red);
      if(GetLastError()==0)
        {
         Comment("BC_SELL Order opened : ",Bid );
         Print("BC_SELL Order opened : ",Bid );
        }
         else
        {
         Print(Symbol(),"SELL Error ",err);
        }
     }

   return(0);
  }


//+------------------------------------------------------------------+

