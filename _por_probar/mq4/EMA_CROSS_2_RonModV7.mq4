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

extern double    StartingBalance=1751.72;
extern double    TakeProfit=    8;
extern double    StopLoss =    37;
extern double    TrailingStop=  6;
extern int       ShortEma =     2;
extern int       LongEma =     12;
extern  bool     logging=true;

double           Lots;
int              MagicNumber=200606251707;
string           TradeComment="EMACross_RonModV7.txt";


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
   

   // Ron's mod for lot increasement based on StartingBalance
   // this will trade 1.0, then 1.1, then 1.2 etc as balance grows
   // or 0.9 then 0.8 then 0.7 as balance shrinks 
   Lots=NormalizeDouble(AccountBalance()/StartingBalance,1);
   if(Lots>50.0) Lots=50.0;
     

   double SEma, LEma;
   static int isCrossed  = 0;
   SEma = iMA(Symbol(),0,ShortEma,0,MODE_EMA,PRICE_CLOSE,0);
   LEma = iMA(Symbol(),0,LongEma,0,MODE_EMA,PRICE_CLOSE,0);
   isCrossed = Crossed (LEma,SEma);


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
      if(isCrossed == 1)
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
         
         
      if(isCrossed == 2)
        {
         SL=Bid+StopLoss*Point;
         TP=Bid-TakeProfit*Point;
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,SL,TP,TradeComment,MagicNumber,0,Red);
         if(ticket>0)
           {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
              {
               Print("SELL order opened : ",OrderOpenPrice());
               if(logging) logwrite(TradeComment,"SELL Ticket="+ticket+" Bid="+Bid+" Lots="+Lots+" SL="+SL+" TP="+TP+" Time="+CurTime() );
              }
           }
         else 
           {
            Print("Error opening SELL order : ",GetLastError()); 
            if(logging) logwrite(TradeComment,"Error opening SELL order : "+GetLastError()); 
           }
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


int Crossed (double Lline1 , double Sline2)
   {
      static int last_direction = 0;
      static int current_direction = 0;
      
      if(Lline1>Sline2)current_direction = 1; //up
      if(Lline1<Sline2)current_direction = 2; //down

      if(current_direction != last_direction) //changed 
      {
            last_direction = current_direction;
            return (current_direction);
      }
   }


void logwrite (string filename, string mydata)
  {
   int myhandle;
   myhandle=FileOpen(Symbol()+"_"+filename, FILE_CSV|FILE_WRITE|FILE_READ, ";");
   if(myhandle>0)
     {
      FileSeek(myhandle,0,SEEK_END);
      FileWrite(myhandle, mydata);
      FileClose(myhandle);
     }
  } 