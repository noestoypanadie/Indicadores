//+------------------------------------------------------------------+
//|                                             Straddle_JB_News.mq4 |
//|                                   Copyright © 2006, Joao Barbosa |
//|                                        obarbosa2001@yahoo.com.br |
//+------------------------------------------------------------------+
#property copyright "Joao Barbosa"
#property link      "obarbosa2001@yahoo.com.br"

int MagicNumber=0;
extern datetime StartTime=D'2006.10.19 08:30';
extern datetime EndTime=D'2006.10.19 08:35';
bool Start=false;

void Straddle(string Pair="",double Lots=0,int Pips=0,int TP=0,int SL=0)
{
    int Digits_,try,BuyTicket,SellTicket;
    double Points,Buy,Sell,BuyProfit,SellProfit,BuyLoss,SellLoss;

    Print("Straddle(Pair=",Pair," Lots=",Lots," Pips=",Pips," TP=",TP," SL=",SL,")");

    //se não definir explicitamente o par, seleciona o par corrente
    //if not explicit the pair select the current pair
    if (Pair=="") {Pair=Symbol();}

    // determina o SL e TP mínimos dependendo da corretora
    // detect the minimal SL and TP acording to the broaker
    int STOPLEVEL=MarketInfo(Pair,MODE_STOPLEVEL);

    //Calcula o valor em pips do nível do straddle entre o mínimo da corretora e o solicitado
    //calculates the distance of the price for the straddle, Digits and Points
    Pips=MathMax(Pips,STOPLEVEL);
    Digits_=MarketInfo(Pair,MODE_DIGITS);
    Points=MarketInfo(Pair,MODE_POINT);

    //Calcula a quantidade correta de lotes
    //calculates the lots quantity
    Lots=MathMin(MarketInfo(Pair,MODE_MAXLOT),Lots);
    Lots=MathMax(MarketInfo(Pair,MODE_MINLOT),Lots);

    // Tenta lançar as ordens 10 vezes
    // Try 100 times to lunch the orders.
    try=100;BuyTicket=0;SellTicket=0;
    while ((try>0) && ((SellTicket<1) || (BuyTicket<1)))  //&& ((SellTicket<1) || (BuyTicket<1))
      {try--;

       // Aguarda possibilidade de lançar ordens
       // waits for possible trading time 
       if (WaittoAct()<0)
          {return(-1);}

       //Só agora podemos iniciar o cálculo necessários
       //only now we can do the necessary calculations
       RefreshRates();

       //Calcula os preços de compra e venda
       //calculates the buy and sell price
       Buy=NormalizeDouble(MarketInfo(Pair,MODE_ASK)+Pips*Points,Digits_);
       Sell=NormalizeDouble(MarketInfo(Pair,MODE_BID)-Pips*Points,Digits_);

       //Calcula o ponto de lucro
       //calculates the prodit point
       if (TP==0) { BuyProfit=0; SellProfit=0; }
       else { Pips=MathMax(TP,STOPLEVEL);
              BuyProfit=NormalizeDouble(Buy+Pips*Points,Digits_);
              SellProfit=NormalizeDouble(Sell-Pips*Points,Digits_);
            }
       if (SL==0) { BuyLoss=0; SellLoss=0; }
       else { Pips=MathMax(SL,STOPLEVEL);
              BuyLoss=NormalizeDouble(Buy-Pips*Points,Digits_);
              SellLoss=NormalizeDouble(Sell+Pips*Points,Digits_);
            }

       //Envia as ordens
       //send the orders 
       if (try==99)
         {Print("Orders: Pair=",Pair," Lots=",Lots," Pips=",Pips," TP=",TP," SL=",SL," Buy=",Buy," Sell=",Sell," Spread=",(Buy-Sell)/Points-2*Pips);}
       if (BuyTicket<1)
          { BuyTicket=OrderSend(Pair,OP_BUYSTOP,Lots,Buy,2,BuyLoss,BuyProfit,"Straddle JB",MagicNumber,0,CLR_NONE);}
       BuyTicket=TreatOrderError(BuyTicket,"Straddle Buy",Buy,BuyProfit,BuyLoss,Lots,100-try);

       if (SellTicket<1)
          { SellTicket=OrderSend(Pair,OP_SELLSTOP,Lots,Sell,2,SellLoss,SellProfit,"Straddle JB",MagicNumber,0,CLR_NONE);}
       SellTicket=TreatOrderError(SellTicket,"Straddle Sell",Sell,SellProfit,SellLoss,Lots,100-try);
      }
    if (try<99)
      {Print("Orders: Pair=",Pair," Lots=",Lots," Pips=",Pips," TP=",TP," SL=",SL," Buy=",Buy," Sell=",Sell," Spread=",(Buy-Sell)/Points-2*Pips);}
    Comment("Straddle done!");
    return(0);
}

void StraddleReverse(string Pair="",double Lots=0,int Pips=0,int TP=0,int SL=0)
{
    int Digits_,try,BuyTicket,SellTicket;
    double Points,Buy,Sell,BuyProfit,SellProfit,BuyLoss,SellLoss;

    Print("StraddleReverse(Pair=",Pair," Lots=",Lots," Pips=",Pips," TP=",TP," SL=",SL,")");

    //se não definir explicitamente o par, seleciona o par corrente
    //if not explicit the pair select the current pair
    if (Pair=="") {Pair=Symbol();}

    // determina o SL e TP mínimos dependendo da corretora
    // detect the minimal SL and TP acording to the broaker
    int STOPLEVEL=MarketInfo(Pair,MODE_STOPLEVEL);

    //Calcula o valor em pips do nível do straddle entre o mínimo da corretora e o solicitado
    //calculates the distance of the price for the straddle, Digits and Points
    Pips=MathMax(Pips,STOPLEVEL);
    Digits_=MarketInfo(Pair,MODE_DIGITS);
    Points=MarketInfo(Pair,MODE_POINT);

    //Calcula a quantidade correta de lotes
    //calculates the lots quantity
    Lots=MathMin(MarketInfo(Pair,MODE_MAXLOT),Lots);
    Lots=MathMax(MarketInfo(Pair,MODE_MINLOT),Lots);

    // Tenta lançar as ordens 10 vezes
    // Try 100 times to lunch the orders.
    try=100;BuyTicket=0;SellTicket=0;
    while ((try>0) && ((SellTicket<1) || (BuyTicket<1)))  //&& ((SellTicket<1) || (BuyTicket<1))
      {try--;

       // Aguarda possibilidade de lançar ordens
       // waits for possible trading time 
       if (WaittoAct()<0)
          {return(-1);}

       //Só agora podemos iniciar o cálculo necessários
       //only now we can do the necessary calculations
       RefreshRates();

       //Calcula os preços de compra e venda
       //calculates the buy and sell price
       Buy=NormalizeDouble(MarketInfo(Pair,MODE_ASK)-Pips*Points,Digits_);
       Sell=NormalizeDouble(MarketInfo(Pair,MODE_BID)+Pips*Points,Digits_);

       //Calcula o ponto de lucro
       //calculates the prodit point
       if (TP==0) { BuyProfit=0; SellProfit=0; }
       else { Pips=MathMax(TP,STOPLEVEL);
              BuyProfit=NormalizeDouble(Buy+Pips*Points,Digits_);
              SellProfit=NormalizeDouble(Sell-Pips*Points,Digits_);
            }
       if (SL==0) { BuyLoss=0; SellLoss=0; }
       else { Pips=MathMax(SL,STOPLEVEL);
              BuyLoss=NormalizeDouble(Buy-Pips*Points,Digits_);
              SellLoss=NormalizeDouble(Sell+Pips*Points,Digits_);
            }

       //Envia as ordens
       //send the orders 
       if (try==99)
         {Print("Orders: Pair=",Pair," Lots=",Lots," Pips=",Pips," TP=",TP," SL=",SL," Buy=",Buy," Sell=",Sell," Spread=",(Buy-Sell)/Points-2*Pips);}
       if (BuyTicket<1)
          { BuyTicket=OrderSend(Pair,OP_BUYLIMIT,Lots,Buy,2,BuyLoss,BuyProfit,"StraddleReverse JB",MagicNumber,0,CLR_NONE);}
       BuyTicket=TreatOrderError(BuyTicket,"StraddleReverse Buy",Buy,BuyProfit,BuyLoss,Lots,100-try);

       if (SellTicket<1)
          { SellTicket=OrderSend(Pair,OP_SELLLIMIT,Lots,Sell,2,SellLoss,SellProfit,"StraddleReverse JB",MagicNumber,0,CLR_NONE);}
       SellTicket=TreatOrderError(SellTicket,"StraddleReverse Sell",Sell,SellProfit,SellLoss,Lots,100-try);
      }
    if (try<99)
      {Print("Orders: Pair=",Pair," Lots=",Lots," Pips=",Pips," TP=",TP," SL=",SL," Buy=",Buy," Sell=",Sell," Spread=",(Buy-Sell)/Points-2*Pips);}
    Comment("StraddleReverse done!");
    return(0);
}

int TreatOrderError(int Ticket=0,string Routine="",double Price=0,double TP=0,double SL=0,double Lots=0,int try=1)
{
   if (Ticket>0) {return(Ticket);}
   int Error=GetLastError();
   string ErrorString;
   int ErrorReturn;
   switch (Error)
   {
 		case 0:   ErrorString="no error";ErrorReturn=Ticket;break;
		case 1:   ErrorString="no error";ErrorReturn=Ticket;break;
		case 2:   ErrorString="common error";ErrorReturn=-1;break;
		case 3:   ErrorString="invalid trade parameters";ErrorReturn=-1;break;
		case 4:   ErrorString="trade server is busy";ErrorReturn=-1;break;
		case 5:   ErrorString="old version of the client terminal";ErrorReturn=1;break;
		case 6:   ErrorString="no connection with trade server";ErrorReturn=-1;break;
		case 7:   ErrorString="not enough rights";ErrorReturn=1;break;
		case 8:   ErrorString="too frequent requests";ErrorReturn=-1;break;
		case 9:   ErrorString="malfunctional trade operation";ErrorReturn=-1;break;
		case 64:  ErrorString="account disabled";ErrorReturn=1;break;
		case 65:  ErrorString="invalid account";ErrorReturn=1;break;
		case 128: ErrorString="trade timeout";ErrorReturn=-1;break;
		case 129: ErrorString="invalid price";ErrorReturn=-1;break;
		case 130: ErrorString="invalid stops";ErrorReturn=-1;break;
		case 131: ErrorString="invalid trade volume";ErrorReturn=1;break;
		case 132: ErrorString="market is closed";ErrorReturn=1;break;
		case 133: ErrorString="trade is disabled";ErrorReturn=1;break;
		case 134: ErrorString="not enough money";ErrorReturn=1;break;
		case 135: ErrorString="price changed";ErrorReturn=-1;break;
		case 136: ErrorString="off quotes";ErrorReturn=-1;break;
		case 137: ErrorString="broker is busy";ErrorReturn=-1;break;
		case 138: ErrorString="requote";ErrorReturn=-1;break;
		case 139: ErrorString="order is locked";ErrorReturn=1;
		case 140: ErrorString="long positions only allowed";ErrorReturn=1;break;
		case 141: ErrorString="too many requests";ErrorReturn=1;break;
		case 145: ErrorString="modification denied because order too close to market";ErrorReturn=-1;break;
		case 146: ErrorString="trade context is busy";ErrorReturn=-1;break;
      default:  ErrorString="common error";ErrorReturn=-1;
   }
   Print(Routine," - Error#",Error," Price:",Price," TP:",TP," SL:",SL," Lots:",Lots," Try# ",try);
   return(ErrorReturn);
}

int WaittoAct()
{  // Aguarda possibilidade de lançar ordens
   // waits for trading possible
   int try=100;
   int Trade=IsTradePossible();
   while ((Trade<0) && (try>0))
      { try--; Trade=IsTradePossible();}
   Comment("Ready to act!");
   return(Trade);
}

int IsTradePossible()
{
    //Verificações básicas
    //basic verifications
    if (!IsConnected())
    { Comment("error: not connected, Internet or broker problens");
        Sleep(1000);return(-1);
    }
    if (IsStopped()) 
    { Comment("error: Stop demand");
        Sleep(10000);return(-1);
    }
    if (!IsExpertEnabled()) 
    { Comment("error: Experts are disable");
       Sleep(5000);return(-1);
    }
    if (!IsTradeAllowed()) 
    { Comment("error: Broker are having problems to process the orders ");
       Sleep(500);return(1);
    }
    if (IsTradeContextBusy()) 
    { Comment("error: Some Expert are blocking this one");
       Sleep(100);return(1);
    }
    Comment("Trade is possible!");
    return(0);
}

int init()
  {
   MagicNumber=CurTime();
   Print("Straddle_JB set its Magic Number to ",MagicNumber);
   start();
   return(0);
  }

int deinit()
  { int try;
    for(int J = OrdersTotal()-1; J >= 0; J--)
    {OrderSelect(J, SELECT_BY_POS, MODE_TRADES);
     if (((OrderType()==OP_BUYLIMIT) ||(OrderType()==OP_BUYSTOP) ||(OrderType()==OP_SELLLIMIT) ||(OrderType()==OP_SELLSTOP)) && (OrderMagicNumber()==MagicNumber))
       try=100;
       while ((!OrderDelete(OrderTicket())) && (try>0))
       {try--;}
    }
   Print("Orders send by Straddle_JB removed! Magic Number=",MagicNumber);
   Comment("Straddle ended");
   Start=false;
   return(0);
  }
int start()
  {
      if (LocalTime()<StartTime)
        {
         Comment("Waiting to start at ",TimeToStr(StartTime,TIME_SECONDS)," (",TimeToStr(LocalTime(),TIME_SECONDS),")");
         Sleep(1000);return(0);
        }

      if (LocalTime()<EndTime)
        {
         if (!Start)
               {
                  Start=true;
                  Straddle();
               }
            Comment("Waiting to stop at ",TimeToStr(EndTime,TIME_SECONDS)," (",TimeToStr(LocalTime(),TIME_SECONDS),")");Sleep(1000);
            return(0);
        }
      Start=false;
      deinit();      
      
// You can use any combination of the parameters here....
// Straddle ( Pair, Lots, Pips, TakeProfit, StopLoss )
// Exemples:
// Straddle ("GBPUSD"); //Straddle a minimal distance from the price for GBPUSD
// Straddle ("",10); //Straddle 10 points from the current price for the current pair
// Straddle ("",0,10); //Straddle minimal points from the price with 10 points TP for the current pair
// Straddle ("EURUSD",10,20,30); //Straddle 10 points from the price with 20 point SL, 30 points TP for EURUSD

   return(0);
  }


