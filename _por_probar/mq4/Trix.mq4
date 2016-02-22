//+------------------------------------------------------------------+
//|                                                         Trix.mq4 |
//+------------------------------------------------------------------+

extern bool OCO=false;      // One Cancel The Other , will cancel the other pending order if one of them is hit
extern int MATrendPeriod=3;
extern int CCITrendPeriod=100;
extern int BEPips=0;       // Pips In profit which EA will Move SL to BE+1 after that
extern int TrailingStop=0; // Trailing Stop
extern int TakeProfit=0;
extern int StopLoss=0;
extern bool mm=false;       //Money Management?
extern int RiskPercent=3;  
extern double Lots=0.1;
extern double MinimumLot=0.1;
extern double DollarsPerLot = 10000;
extern string TradeLog = " MI_Log";
extern int ticklength=60;

//extern int Straddle=30;
int Total, Magic=091220060859;    //magic variable fails on compile as reminder to set as unique.
double Spread, Entry, TP, SL, high, low, highopen, lowopen, highstopopen, lowstopopen, hightakeprofit, lowtakeprofit, lot;
string filename;
double macdHistCurrent, macdHistPrevious, macdSignalCurrent, macdSignalPrevious;
double MACurrent, MAPrevious;
double CCICurrent, CCIPrevious;
double stochHistCurrent, stochHistPrevious, stochSignalCurrent, stochSignalPrevious;
double sarCurrent, sarPrevious, momCurrent, momPrevious;
double AOCurrent, AOPrevious;
double TrixBuy, TrixSell;
// Bar handling
datetime bartime=0;    // used to determine when a bar has moved
int      bartick=0;    // number of times bars have moved

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
    ObjectsDeleteAll();
    MinimumLot = MarketInfo(Symbol(),MODE_MINLOT);
    return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
    Comment("Done Testing");
    ObjectsDeleteAll();
//----
   return(0);
  }

/*double LotsOptimized()
  {
   double lot=Lots;
  //---- select lot size
   if (mm) lot=NormalizeDouble(MathFloor(AccountFreeMargin()*RiskPercent/100)/100,1);
   
  // lot at this point is number of standard lots
   return(lot);
  }*/
double LotsOptimized(double InputLots)
   { 
      lot=Lots;
      if (mm) 
      {
         lot = MathRound(InputLots/MinimumLot)*MinimumLot;
         if(lot<MinimumLot) lot = MinimumLot;
      }
      return(lot);
}   

  
int CheckOrdersCondition()
  {
    int result=0;
    for (int i=0;i<OrdersTotal();i++) 
    {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if ((OrderType()==OP_BUY) && (OrderSymbol() == Symbol()) && (OrderMagicNumber() == Magic)) 
      {
        result=result+1000; 
      }
      if ((OrderType()==OP_SELL) && (OrderSymbol() == Symbol()) && (OrderMagicNumber() == Magic)) 
      {
        result=result+100; 
      }
      if ((OrderType()==OP_BUYSTOP) && (OrderSymbol() == Symbol()) && (OrderMagicNumber() == Magic)) 
      {
        result=result+10;
      }
      if ((OrderType()==OP_SELLSTOP) && (OrderSymbol() == Symbol()) && (OrderMagicNumber() == Magic)) 
      {
        result=result+1; 
      }

    }
    return(result); // 0 means we have no trades
  }  
// OrdersCondition Result Pattern
//    1    1    1    1
//    b    s    bs   ss
//  
  
void OpenBuy()
 {
    int ticket,err,tries;
        tries = 0;
          while (tries < 3)
          {
               ticket = OrderSend(Symbol(),OP_BUY,LotsOptimized(AccountBalance()/DollarsPerLot),Ask,3,SL,TP,"EA Order",Magic,0,Red);
               if(ticket>0)
                 {
                  if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
                  tries=3;
                 }
               else 
               {
                  Print("Error opening BUY order : ",GetLastError()+" Buy @ "+Ask+" SL @ "+SL+" TP @"+TP); 
                  Print("Lots:",Lots,", TP:",TP,", SL:",SL);
                  tries++;
               }  
          }
 }

void OpenSell()
 {
    int ticket,err,tries;
        tries = 0;
          while (tries < 3)
          {
               ticket = OrderSend(Symbol(),OP_SELL,LotsOptimized(AccountBalance()/DollarsPerLot),Bid,3,SL,TP,"EA Order",Magic,0,Red);
               if(ticket>0)
                 {
                  if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
                  tries=3;
                 }
               else 
               {
                  Print("Error opening SELL order : ",GetLastError()+" Sell @ "+Bid+" SL @ "+SL+" TP @"+TP); 
                  Print("Lots:",Lots,", TP:",TP,", SL:",SL);
                  tries++;
               }  
          }
 }
  
void OpenBuyStop()
 {
    int ticket,err,tries;
        tries = 0;
          while (tries < 3)
          {
               ticket = OrderSend(Symbol(),OP_BUYSTOP,LotsOptimized(AccountBalance()/DollarsPerLot),Entry,3,SL,TP,"EA Order",Magic,0,Red);
               if(ticket>0)
                 {
                  if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUYSTOP order opened : ",OrderOpenPrice());
                  tries=3;
                 }
               else 
               {
                  Print("Error opening BUYSTOP order : ",GetLastError()+" BuyStop @ "+Entry+" SL @ "+SL+" TP @"+TP); 
                  Print("Lots:",Lots,", TP:",TP,", SL:",SL);
                  tries++;
               }  
          }
 }
  
void OpenSellStop()
 {
    int ticket,err,tries;
        tries = 0;
          while (tries < 3)
          {
               ticket = OrderSend(Symbol(),OP_SELLSTOP,LotsOptimized(AccountBalance()/DollarsPerLot),Entry,3,SL,TP,"EA Order",Magic,0,Red);
               if(ticket>0)
                 {
                  if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELLSTOP order opened : ",OrderOpenPrice());
                  tries=3;
                 }
               else 
               {
                  Print("Error opening SELLSTOP order : ",GetLastError()+" SellStop @ "+Entry+" SL @ "+SL+" TP @"+TP); 
                  Print("Lots:",Lots,", TP:",TP,", SL:",SL);
                  tries++;
               }  
          }
 }
 
void DoBE(int byPips)
  {
    for (int i = 0; i < OrdersTotal(); i++) {
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
     if ( OrderSymbol()==Symbol() && (OrderMagicNumber() == Magic))  // only look if mygrid and symbol...
        {
            if (OrderType() == OP_BUY) if (Bid - OrderOpenPrice() > byPips * Point) if (OrderStopLoss() < OrderOpenPrice()) {
              Write("Moving StopLoss of Buy Order to BE+1");
              OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() +  Point, OrderTakeProfit(), Red);
            }
            if (OrderType() == OP_SELL) if (OrderOpenPrice() - Ask > byPips * Point) if (OrderStopLoss() > OrderOpenPrice()) { 
               Write("Moving StopLoss of Buy Order to BE+1");
               OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() -  Point, OrderTakeProfit(), Red);
            }
        }
    }
  }

void DoTrail()
  {
    for (int i = 0; i < OrdersTotal(); i++) {
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
     if ( OrderSymbol()==Symbol() && (OrderMagicNumber() == Magic))  // only look if mygrid and symbol...
        {
          
          if (OrderType() == OP_BUY) {
             if(Bid-OrderOpenPrice()>Point*TrailingStop)
             {
                if(OrderStopLoss()<Bid-Point*TrailingStop)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                     return(0);
                  }
             }
          }

          if (OrderType() == OP_SELL) 
          {
             if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
             {
                if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                {
                   OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
                   return(0);
                }
             }
          }
       }
    }
 }
 
void CloseBuy()
{
   for (int i = 0; i < OrdersTotal(); i++) 
   {
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
     if (OrderSymbol()==Symbol() && (OrderMagicNumber() == Magic) && (OrderType()==OP_BUY)) 
     {
       OrderClose(OrderTicket(),OrderLots(),Bid,3,Red);
       Write("in function CloseBuyOrder Executed");
     }
       
   }
}

void CloseSell()
{
   for (int i = 0; i < OrdersTotal(); i++) 
   {
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
     if (OrderSymbol()==Symbol() && (OrderMagicNumber() == Magic) && (OrderType()==OP_SELL)) 
     {
       OrderClose(OrderTicket(),OrderLots(),Ask,3,Red);
       Write("in function CloseSellOrder Executed");
     }
       
   }
}

void DeleteBuyStop()
{
   for (int i = 0; i < OrdersTotal(); i++) {
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
     if (OrderSymbol()==Symbol() && (OrderMagicNumber() == Magic) && (OrderType()==OP_BUYSTOP)) {
       OrderDelete(OrderTicket());
       Write("in function DeleteBuyStopOrderDelete Executed");
     }
       
   }
}
   
void DeleteSellStop()
{
   for (int i = 0; i < OrdersTotal(); i++) {
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
     if (OrderSymbol()==Symbol() && (OrderMagicNumber() == Magic) && (OrderType()==OP_SELLSTOP)) {
       OrderDelete(OrderTicket());
       Write("in function DeleteSellStopOrderDelete Executed");
     }
       
   }
}

void DoModify()
{
   for (int i = 0; i < OrdersTotal(); i++) {
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
     if (OrderSymbol()==Symbol() && (OrderMagicNumber() == Magic) && (OrderType()==OP_SELLSTOP)) {
       if ((OrderOpenPrice()>Ask) || (OrderOpenPrice()<Ask)) {
         Write("in function DoModify , SellStop OrderModify Executed, Sell Stop was @ "+DoubleToStr(OrderOpenPrice(),4)+" it changed to "+DoubleToStr(Ask,4));
         OrderModify(OrderTicket(),Ask,SL,TP,0,Red);
       }
     }

     if (OrderSymbol()==Symbol() && (OrderMagicNumber() == Magic) && (OrderType()==OP_BUYSTOP)) {
       if ((OrderOpenPrice()>Bid) || (OrderOpenPrice()<Bid)) {
         Write("in function DoModify , BuyStop OrderModify Executed, Buy Stop was @ "+DoubleToStr(OrderOpenPrice(),4)+" it changed to "+DoubleToStr(Bid,4));
         OrderModify(OrderTicket(),Bid,SL,TP,0,Red);
       }
     }
   }
}

void ModifyStop()
{
   for (int i = 0; i < OrdersTotal(); i++) {
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
     if (OrderSymbol()==Symbol() && (OrderMagicNumber() == Magic) && (OrderType()==OP_SELL)) {
         Print("in function ModifyStop, Sell OrderModify Executed, Sell stoploss changed to ",SL);
         OrderModify(OrderTicket(),Ask,SL,TP,0,Red);
     }

     if (OrderSymbol()==Symbol() && (OrderMagicNumber() == Magic) && (OrderType()==OP_BUY)) {
         Print("in function ModifyStop, Buy OrderModify Executed, Buy stoploss was changed to ",SL);
         OrderModify(OrderTicket(),Bid,SL,TP,0,Red);
     }
   }
}

int Write(string str)
{
   int handle;
  
   handle = FileOpen(filename,FILE_READ|FILE_WRITE|FILE_CSV,"/t");
   FileSeek(handle, 0, SEEK_END);      
   FileWrite(handle,str + " Time " + TimeToStr(CurTime(),TIME_DATE|TIME_SECONDS));
    FileClose(handle);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
  
   int i, EODTime;
   int OrdersCondition;
   double ShortEntry, LongEntry, ShortSL, LongSL, ShortTP, LongTP;
   
      // bar counting
   if(bartime!=Time[0])
     {
      bartime=Time[0];
      bartick++;
     }
     
   //Settings for each currency pair.  Copy "else if" to create more.
   if (!IsTesting()){
      if (Symbol()=="EURUSD"){
         BEPips=40;
         StopLoss=15;
         TakeProfit=70;
      }   
      else if (Symbol()=="GBPUSD"){
         BEPips=56;
         StopLoss=21;
         TakeProfit=98;
         }
      else if (Symbol()=="USDJPY"){
         BEPips=40;
         StopLoss=15;
         TakeProfit=70;
         }
      else if (Symbol()=="USDCHF"){
         BEPips=40;
         StopLoss=15;
         TakeProfit=70;
      }
      else {   //default
         BEPips=40;
         StopLoss=15;
         TakeProfit=70;
      }
   }
      
   filename=Symbol() + TradeLog + "-" + Month() + "-" + Day() + ".txt";

   if (BEPips>0) DoBE(BEPips);
   
   if (TrailingStop>0) DoTrail();
   
//   if(Hour()==23 && Minute()==59)
//   {   
      
   /*
      MACurrent           = iMA(NULL,0,MATrendPeriod,0,MODE_EMA,PRICE_CLOSE,0);
      MAPrevious          = iMA(NULL,0,MATrendPeriod,0,MODE_EMA,PRICE_CLOSE,1);
      macdHistCurrent     = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_MAIN,0);   
      macdHistPrevious    = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_MAIN,1);   
      macdSignalCurrent   = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_SIGNAL,0); 
      macdSignalPrevious  = iMACD(NULL,0,12,26,9,PRICE_OPEN,MODE_SIGNAL,1); 
      stochHistCurrent    = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,0);
      stochHistPrevious   = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,1);
      stochSignalCurrent  = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
      stochSignalPrevious = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);
      momCurrent          = iMomentum(NULL,0,14,PRICE_OPEN,0); // Momentum Current
      momPrevious         = iMomentum(NULL,0,14,PRICE_OPEN,1); // Momentum Previous
      AOPrevious          = iAO(NULL,0,1);
      AOCurrent           = iAO(NULL,0,0);
      sarCurrent          = iSAR(NULL,0,0.02,0.2,0);           // Parabolic Sar Current
      sarPrevious         = iSAR(NULL,0,0.02,0.2,1);           // Parabolic Sar Previuos
      CCICurrent          = iCCI(NULL,0,CCITrendPeriod,PRICE_CLOSE,0);
      CCIPrevious         = iCCI(NULL,0,CCITrendPeriod,PRICE_CLOSE,1);
      MACurrent           = iMA(NULL,0,MATrendPeriod,0,MODE_SMA,PRICE_CLOSE,0);
      MAPrevious          = iMA(NULL,0,MATrendPeriod,0,MODE_SMA,PRICE_CLOSE,1);
*/
   TrixBuy = iCustom(NULL,0,"T3_TRIX_signals",18,350,0,10,0,0.7,3500,TRUE,0,0);
   TrixSell = iCustom(NULL,0,"T3_TRIX_signals",18,350,0,10,0,0.7,3500,TRUE,1,0);
//   JMACurrent = iCustom(NULL,0,"JMA",14,0,300,0,0);
//   JMAPrevious = iCustom(NULL,0,"JMA",14,0,300,0,1);
//   TriggerHigh = iCustom(NULL,0,"Triggerlines",50,50,0,0);
//   TriggerLow = iCustom(NULL,0,"Triggerlines",50,50,1,0);
   

//   Print(TrixMain,",",TrixSignal,",",JMACurrent,",",JMAPrevious);
   ShortEntry = Bid;
//   ShortEntry = Bid-(Straddle*Point);
   ShortSL = Bid+(StopLoss*Point);
   ShortTP = Bid-(TakeProfit*Point);
   
   LongEntry = Ask;
//   LongEntry = Ask+(Straddle*Point);
   LongSL = Ask-(StopLoss*Point);
   LongTP = Ask+(TakeProfit*Point);

      OrdersCondition=CheckOrdersCondition();
      // OrdersCondition Result Pattern
      //    1    1    1    1
      //    b    s    bs   ss
      if(OrdersCondition>0)
      {
         //Put Exit Conditions here
         if(TrixBuy>0 && Minute()==0) 
         {
            CloseSell();
            bartick=0;
         }
         if(TrixSell>0 && Minute()==0) 
         {
            CloseBuy();
            bartick=0;
         }
         
      }

      if(OrdersCondition==0)
      {
      //Go Long
         if (TrixBuy>0 && Minute()==0)
//         if(JMACurrent>JMAPrevious)
         {
            if(StopLoss>0) SL=LongSL;
            if(TakeProfit>0) TP=LongTP;
            OpenBuy();
            bartick=0;
         }

      //Go SHORT
         if (TrixSell>0 && Minute()==0)
//         if(JMACurrent<JMAPrevious)
         {
            if(StopLoss>0) SL=ShortSL;
            if(TakeProfit>0) TP=ShortTP;
            OpenSell();
            bartick=0;
         }
//      }
   }   
//----
   return(0);
  }
  
//+------------------------------------------------------------------+
//| return error description                                         |
//+------------------------------------------------------------------+
string ErrorDescription(int error_code)
  {
   string error_string;
//----
   switch(error_code)
     {
      //---- codes returned from trade server
      case 0:
      case 1:   error_string="no error";                                                  break;
      case 2:   error_string="common error";                                              break;
      case 3:   error_string="invalid trade parameters";                                  break;
      case 4:   error_string="trade server is busy";                                      break;
      case 5:   error_string="old version of the client terminal";                        break;
      case 6:   error_string="no connection with trade server";                           break;
      case 7:   error_string="not enough rights";                                         break;
      case 8:   error_string="too frequent requests";                                     break;
      case 9:   error_string="malfunctional trade operation";                             break;
      case 64:  error_string="account disabled";                                          break;
      case 65:  error_string="invalid account";                                           break;
      case 128: error_string="trade timeout";                                             break;
      case 129: error_string="invalid price";                                             break;
      case 130: error_string="invalid stops";                                             break;
      case 131: error_string="invalid trade volume";                                      break;
      case 132: error_string="market is closed";                                          break;
      case 133: error_string="trade is disabled";                                         break;
      case 134: error_string="not enough money";                                          break;
      case 135: error_string="price changed";                                             break;
      case 136: error_string="off quotes";                                                break;
      case 137: error_string="broker is busy";                                            break;
      case 138: error_string="requote";                                                   break;
      case 139: error_string="order is locked";                                           break;
      case 140: error_string="long positions only allowed";                               break;
      case 141: error_string="too many requests";                                         break;
      case 145: error_string="modification denied because order too close to market";     break;
      case 146: error_string="trade context is busy";                                     break;
      //---- mql4 errors
      case 4000: error_string="no error";                                                 break;
      case 4001: error_string="wrong function pointer";                                   break;
      case 4002: error_string="array index is out of range";                              break;
      case 4003: error_string="no memory for function call stack";                        break;
      case 4004: error_string="recursive stack overflow";                                 break;
      case 4005: error_string="not enough stack for parameter";                           break;
      case 4006: error_string="no memory for parameter string";                           break;
      case 4007: error_string="no memory for temp string";                                break;
      case 4008: error_string="not initialized string";                                   break;
      case 4009: error_string="not initialized string in array";                          break;
      case 4010: error_string="no memory for array\' string";                             break;
      case 4011: error_string="too long string";                                          break;
      case 4012: error_string="remainder from zero divide";                               break;
      case 4013: error_string="zero divide";                                              break;
      case 4014: error_string="unknown command";                                          break;
      case 4015: error_string="wrong jump (never generated error)";                       break;
      case 4016: error_string="not initialized array";                                    break;
      case 4017: error_string="dll calls are not allowed";                                break;
      case 4018: error_string="cannot load library";                                      break;
      case 4019: error_string="cannot call function";                                     break;
      case 4020: error_string="expert function calls are not allowed";                    break;
      case 4021: error_string="not enough memory for temp string returned from function"; break;
      case 4022: error_string="system is busy (never generated error)";                   break;
      case 4050: error_string="invalid function parameters count";                        break;
      case 4051: error_string="invalid function parameter value";                         break;
      case 4052: error_string="string function internal error";                           break;
      case 4053: error_string="some array error";                                         break;
      case 4054: error_string="incorrect series array using";                             break;
      case 4055: error_string="custom indicator error";                                   break;
      case 4056: error_string="arrays are incompatible";                                  break;
      case 4057: error_string="global variables processing error";                        break;
      case 4058: error_string="global variable not found";                                break;
      case 4059: error_string="function is not allowed in testing mode";                  break;
      case 4060: error_string="function is not confirmed";                                break;
      case 4061: error_string="send mail error";                                          break;
      case 4062: error_string="string parameter expected";                                break;
      case 4063: error_string="integer parameter expected";                               break;
      case 4064: error_string="double parameter expected";                                break;
      case 4065: error_string="array as parameter expected";                              break;
      case 4066: error_string="requested history data in update state";                   break;
      case 4099: error_string="end of file";                                              break;
      case 4100: error_string="some file error";                                          break;
      case 4101: error_string="wrong file name";                                          break;
      case 4102: error_string="too many opened files";                                    break;
      case 4103: error_string="cannot open file";                                         break;
      case 4104: error_string="incompatible access to a file";                            break;
      case 4105: error_string="no order selected";                                        break;
      case 4106: error_string="unknown symbol";                                           break;
      case 4107: error_string="invalid price parameter for trade function";               break;
      case 4108: error_string="invalid ticket";                                           break;
      case 4109: error_string="trade is not allowed";                                     break;
      case 4110: error_string="longs are not allowed";                                    break;
      case 4111: error_string="shorts are not allowed";                                   break;
      case 4200: error_string="object is already exist";                                  break;
      case 4201: error_string="unknown object property";                                  break;
      case 4202: error_string="object is not exist";                                      break;
      case 4203: error_string="unknown object type";                                      break;
      case 4204: error_string="no object name";                                           break;
      case 4205: error_string="object coordinates error";                                 break;
      case 4206: error_string="no specified subwindow";                                   break;
      default:   error_string="unknown error";
     }
//----
   return(error_string);
  }  
//+------------------------------------------------------------------+