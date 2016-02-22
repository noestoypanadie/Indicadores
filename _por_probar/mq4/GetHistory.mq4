static int mPrev;
int m;

int init()
  {
   mPrev=Minute();
   return(0);
  }
//+------------------------------------------------------------------+
int start()
  {
   int i,handle,hstTotal=HistoryTotal();
   m=Minute();
   if(m!=mPrev)
      {
      mPrev=m;
      handle=FileOpen("OrdersReport.csv",FILE_WRITE|FILE_CSV,",");
      if(handle<0) return(0);
      FileWrite(handle,"#,Open Time,Type,Lots,Symbol,Price,Stop/Loss,Take Profit,Close Time,Close Price,Profit,Comment");
      for(i=0;i<hstTotal;i++)
         {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true)
            {
            FileWrite(handle,OrderTicket(),TimeToStr(OrderOpenTime(),TIME_DATE|TIME_MINUTES),OrderType(),OrderLots(),OrderSymbol(),OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit(),TimeToStr(OrderCloseTime(),TIME_DATE|TIME_MINUTES),OrderClosePrice(),OrderProfit(),OrderComment());
            }
         }
      FileClose(handle);
      }
   return(0);
  }
//+------------------------------------------------------------------+