//+------------------------------------------------------------------+
//|                                                    EMA_CROSS.mq4 |
//|                                                      Coders Guru |
//|                                         http://www.forex-tsd.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| TODO: Add Money Management routine           
//|       Ron added extremly simple OpenBalance lot increasement
//+------------------------------------------------------------------+

#property copyright "Coders Guru"
#property link      "http://www.forex-tsd.com"

extern double    StartingBalance=1884.01;
extern double    TakeProfit=   55;
extern double    StopLoss =    12;
extern double    TrailingStop=  6;

bool logging=false;

double    Lots;
int       MagicNumber=200606251942;
string    TradeComment="EMACross_RonModV6.txt";


//+---------+
//| init    |
//+---------+
int init()
  {
   if(logging) logwrite( TradeComment,"Init happened at "+CurTime() );
  }
  
//+---------+
//| De-init |
//+---------+
int deinit()
  {
   if(logging) logwrite( TradeComment,"DE-Init happened at "+CurTime() );
  }

//+---------+
//| Start   |
//+---------+
int start()
  {

   int cnt, ticket, total;
   double SL,TP;
   

   // Lot increasement based on StartingBalance
   // this will trade 1.0, then 1.1, then 1.2 etc as balance grows
   // or 0.9 then 0.8 then 0.7 as balance shrinks 
   Lots=NormalizeDouble(AccountBalance()/StartingBalance,1);
  
   total = 0; 
   for(cnt=OrdersTotal()-1; cnt>=0; cnt--)
     {
      OrderSelect (cnt, SELECT_BY_POS, MODE_TRADES);
      if ( OrderSymbol()      != Symbol())     continue;
      if ( OrderMagicNumber() != MagicNumber)  continue;
      if(OrderType() == OP_BUY )  total++;
      if(OrderType() == OP_SELL ) total++;
     }

   if(total < 1) 
     {
      SL=Ask-StopLoss*Point;
      TP=Ask+TakeProfit*Point;
      ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,SL,TP,TradeComment,MagicNumber,0,White);
      if(ticket>0)
        {
         if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
           {
            Print("BUY order opened : ",OrderOpenPrice());
            if(logging) logwrite(TradeComment,"BUY Ticket="+ticket+" Ask="+Ask+" Lots="+Lots+" SL="+SL+" TP="+TP+" Time="+CurTime() );
           }
        }
      else 
        {
         Print("Error opening BUY order : ",GetLastError()); 
         if(logging) logwrite(TradeComment,"Error opening BUY order : "+GetLastError()); 
        }
     }
     
     
   for(cnt=total-1; cnt>=0; cnt--)
     {

      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
        {
        
         if(OrderType()==OP_BUY)   // long position is opened
           {
            // check for trailing stop
            if(TrailingStop>0)  
              {                 
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
                     SL=Bid-Point*TrailingStop;
                     TP=OrderTakeProfit();
                     OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP,0,Green);
                     if(logging) logwrite(TradeComment,"MODIFY BUY SL=" + SL + " TP=" + TP);
                    }
                 }
              }
           }

         if(OrderType()==OP_SELL)   // long position is opened
           {
            // check for trailing stop
            if(TrailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     SL=Ask+Point*TrailingStop;
                     TP=OrderTakeProfit();
                     OrderModify(OrderTicket(),OrderOpenPrice(),SL,TP,0,Red);
                     if(logging) logwrite(TradeComment,"MODIFY SELL SL=" + SL + " TP=" + TP);
                    }
                 }
              }
           }
        }
     }
  }


void logwrite (string filename, string mydata)
  {
   int myhandle;
   myhandle=FileOpen(filename, FILE_CSV|FILE_WRITE|FILE_READ, ";");
   if(myhandle>0)
     {
      FileSeek(myhandle,0,SEEK_END);
      FileWrite(myhandle, mydata);
      FileClose(myhandle);
     }
  } 