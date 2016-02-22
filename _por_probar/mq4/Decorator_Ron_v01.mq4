//+--------------------------------+
//|                                |
//+--------------------------------+
#property copyright "Ron Thompson"
#property link      "http://www.lightpatch.com/forex/"

//+-------------------------------------------+
//|                                           |
//+-------------------------------------------+
int start()
  {   
   int cnt;
   
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if( OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY)
           {
            ObjectDelete("Objt"+DoubleToStr(cnt,0) );
            ObjectCreate("Objt"+DoubleToStr(cnt,0), OBJ_TEXT, 0, Time[OrderOpenTime()], OrderOpenPrice()+(10*Point()) );
            ObjectSetText("Objt"+DoubleToStr(cnt,0),"B",10,"Arial",White);
           }
         if(OrderType()==OP_SELL)
           {
            ObjectCreate("Objt"+DoubleToStr(cnt,0), OBJ_TEXT, 0, Time[OrderOpenTime()], OrderOpenPrice()+(10*Point()) );
            ObjectSetText("Objt"+DoubleToStr(cnt,0),"S",10,"Arial",White);
           }
        }//if
     
     }//for
  
  }//start

