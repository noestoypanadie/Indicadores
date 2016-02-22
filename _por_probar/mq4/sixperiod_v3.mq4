//+------------------------------------------------------------------+
//+ Trade on 6-period HLCC/4 trend NO T/P, keep adjusting S/L        |
//+------------------------------------------------------------------+


// need OrderSelect so more than one order can be open at a time


#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex"

// User Input
extern double Lots = 0.1;


//+------------------------------------------------------------------+
//| What to do 1st                                                   |
//+------------------------------------------------------------------+

int init ()
  {
   return(0);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int deinit()
  {
   return(0);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
   double oTYP0=0, oTYP1=0, oTYP2=0, oTYP3=0, oTYP4=0, oTYP5=0;
   double total;
   int cnt;
   bool foundorder=False;
   
   //
   // Error checking
   //
   
   if(Bars<100)
     {
      Print("bars less than 100");
      return(0);
     }
   
   //if(TakeProfit<10)
   //  {
   //   Print("TakeProfit less than 10");
   //   return(0);
   //  }
   
   if(AccountFreeMargin()<(1000*Lots))
     {
      Print("We have no money");
      return(0);
     }

   //
   // only one order at a time/ per symbol 
   //
  total=OrdersTotal();
  for(cnt=0;cnt<OrdersTotal();cnt++)
  {
   OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
   if(OrderSymbol()==Symbol())
     {
      foundorder=True;
      Comment("Order in progress ",Symbol()," ",Point() );
      break;
     }
  }

   if ( foundorder == False )
     {

      // three-period
      oTYP0=(High[0]+Low[0]+Close[0]+Close[0])/4;
      oTYP1=(High[1]+Low[1]+Close[1]+Close[1])/4;
      oTYP2=(High[2]+Low[2]+Close[2]+Close[2])/4;
      oTYP3=(High[3]+Low[3]+Close[3]+Close[3])/4;
      oTYP4=(High[4]+Low[4]+Close[4]+Close[4])/4;
      oTYP5=(High[5]+Low[5]+Close[5]+Close[5])/4;

      // down trend
      if(oTYP4>oTYP3 && oTYP3>oTYP2 && oTYP2>oTYP1 && oTYP1>oTYP0)
        {
         Print("SELL Order started");
         // no take profit. I wanna do it for now so I can scalp if I want
         OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+0.0010,0,"6P Sell",16789,0,Red);
         if(GetLastError()==0)Print("SELL Order opened : ",OrderOpenPrice());

        }
      
      // up trend
      if(oTYP4<oTYP3 && oTYP3<oTYP2 && oTYP2<oTYP1 && oTYP1<oTYP0)
        {
         Print("BUY  Order started");
         // no take profit. I wanna do it for now so I can scalp if I want
         OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-0.0010,0,"6P Buy",16543,0,White);
         if(GetLastError()==0)Print("BUY Order opened : ",OrderOpenPrice());
        }
     }           
      
   return(0);
  }


      //OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,Ask+TakeProfit*Points,"macd sample",16384,0,Red);
      //if(GetLastError()==0)Print("Order opened : ",OrderOpenPrice());
      //return(0);

      //OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,Bid-TakeProfit*Points,"macd sample",16384,0,Red);
      //if(GetLastError()==0)Print("Order opened : ",OrderOpenPrice());
      //return(0);

      //if(TrailingStop>0)
      //  {
      //   if(Bid-OrderOpenPrice()>Points*TrailingStop)
      //     {
      //      if(OrderStopLoss()<Bid-Points*TrailingStop)
      //        {
      //         OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Points*TrailingStop,OrderTakeProfit(),0,Red);
      //         return(0);
      //        }
      //     }
      //  }







