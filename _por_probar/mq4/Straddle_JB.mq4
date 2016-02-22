//+------------------------------------------------------------------+
//|                                                     Straddle.mq4 |
//|                                   Copyright © 2006, Joao Barbosa |
//|                                        obarbosa2001@yahoo.com.br |
//+------------------------------------------------------------------+
#property copyright "Joao Barbosa"
#property link      "obarbosa2001@yahoo.com.br"


void Straddle(string Pair="",double Lots=0,int Pips=0,int TP=0,int SL=0)
{
    int Digits_,try,BuyTicket,SellTicket;
    double Points,Buy,Sell,BuyProfit,SellProfit,BuyLoss,SellLoss;

    Print("Parameters: Pair=",Pair," Lots=",Lots," Pips=",Pips," TP=",TP," SL=",SL);
    // Aguarda possibilidade de lançar ordens
    // waits for possible trading time 
    if (WaittoAct()<0)
       {return(-1);}

    //Só agora podemos iniciar o cálculo necessários
    //only now we can do the necessary calculations
    RefreshRates();
    // se não definir explicitamente o par, seleciona o par corrente
    // if not explicit the pair select the current pair
    if (Pair=="") {Pair=Symbol();}

    // determina o SL e TP mínimos dependendo da corretora
    // detect the minimal SL and TP acording to the broaker
    int STOPLEVEL=MarketInfo(Pair,MODE_STOPLEVEL);

    // Calcula o valor em pips do nível do straddle entre o mínimo da corretora e o solicitado
    // calculates the distance of the price for the straddle
    Pips=MathMax(Pips,STOPLEVEL);

    // Calcula os preços de compra e venda
    // calculates the buy and sell price
    Digits_ = MarketInfo(Pair,MODE_DIGITS);
    Points=MarketInfo(Pair,MODE_POINT);
    Buy=NormalizeDouble(MarketInfo(Pair,MODE_ASK)+Pips*Points,Digits_);
    Sell=NormalizeDouble(MarketInfo(Pair,MODE_BID)-Pips*Points,Digits_);

    // Calcula o ponto de lucro
    // calculates the prodit point
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
    // verifica a quantidade correta de lotes
    // verify the lots quantity
    Lots=MathMin(MarketInfo(Pair,MODE_MAXLOT),Lots);
    Lots=MathMax(MarketInfo(Pair,MODE_MINLOT),Lots);

    Print("Orders: Pair=",Pair," Lots=",Lots," Pips=",Pips," TP=",TP," SL=",SL," Buy=",Buy," Sell=",Sell," Spread=",(Buy-Sell)/Points-2*Pips);
    // Tenta lançar as ordens 10 vezes
    // Try 100 times to lunch the orders.
    try=100;BuyTicket=0;SellTicket=0;
    while ((try>0) && ((SellTicket<1) || (BuyTicket<1)))  //&& ((SellTicket<1) || (BuyTicket<1))
      {try--;

       // Aguarda possibilidade de lançar ordens
       // waits for trading possible
       WaittoAct();
       if (BuyTicket<1)
          { BuyTicket=OrderSend(Pair,OP_BUYSTOP,Lots,Buy,2,BuyLoss,BuyProfit,"",0,0,CLR_NONE);}

       // Aguarda possibilidade de lançar ordens
       // waits for trading possible
       WaittoAct();
       if (SellTicket<1)
          { SellTicket=OrderSend(Pair,OP_SELLSTOP,Lots,Sell,2,SellLoss,SellProfit,"",0,0,CLR_NONE);}
      }
    return(0);
}




//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   
Straddle();

// You can use any combination of the parameters here....
// Straddle ( Pair, Lots, Pips, TakeProfit, StopLoss )
// Exemples:
// Straddle ("GBPUSD"); //Straddle a minimal distance from the price for GBPUSD
// Straddle ("",10); //Straddle 10 points from the current price for the current pair
// Straddle ("",0,10); //Straddle minimal points from the price with 10 points TP for the current pair
// Straddle ("EURUSD",10,20,30); //Straddle 10 points from the price with 20 point SL, 30 points TP for EURUSD


//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
    for(int J = OrdersTotal()-1; J >= 0; J--)
    {OrderSelect(J, SELECT_BY_POS, MODE_TRADES);
     if ((OrderType()==OP_BUYLIMIT) ||(OrderType()==OP_BUYSTOP) ||(OrderType()==OP_SELLLIMIT) ||(OrderType()==OP_SELLSTOP))
       while (! OrderDelete(OrderTicket()))
       {}
    }
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+


int WaittoAct()
{  // Aguarda possibilidade de lançar ordens
   // waits for trading possible
   int try=100;
   int Trade=TradeIsPossible();
   while ((Trade<0) && (try>0))
      { try--; Trade=TradeIsPossible();}
   return(Trade);
}

int TradeIsPossible()
{
    //Verificações básicas
    //basic verifications
    if (!IsConnected())
    { Print("error: not connected, Internet or broker problens");
        Sleep(1000);return(-1);
    }
    if (IsStopped()) 
    { Print("error: Stop demand");
        Sleep(10000);return(-1);
    }
    if (!IsExpertEnabled()) 
    { Print("error: Experts are disable");
       Sleep(5000);return(-1);
    }
    if (!IsTradeAllowed()) 
    { Print("error: Broker are having problems to process the orders ");
       Sleep(500);return(1);
    }
    if (IsTradeContextBusy()) 
    { Print("error: Some Expert are blocking this one");
       Sleep(100);return(1);
    }
    return(0);
}


