//+------------------------------------------------------------------+
//|                                      Universal Trailing Stop.mq4 |
//|                                                     Joao Barbosa |
//|                                        obarbosa2001@yahoo.com.br |
//+------------------------------------------------------------------+
#property copyright "João Barbosa"
#property link      "obarbosa2001@yahoo.com.br"

extern int TrailingStop = 20; // Valor do Trailing Stop
       int Tentativas = 10; // número de tentativas para executar a ordem
       int B=0; // Contagem de acionamentos = +- quantidade de pips garantidos
       // isso indica o quanto esse EA rendeu em pips em cada seçao para quem usa

int init()
  {Print("Garante Lucro Universal iniciado (",TimeToStr(CurTime(),TIME_DATE)," - ",TimeToStr(CurTime(),TIME_SECONDS),") ");
   start();return(0);}
int deinit()
  {Print("Garante Lucro Universal finalizado (",TimeToStr(CurTime(),TIME_DATE)," - ",TimeToStr(CurTime(),TIME_SECONDS),") ");return(0);}
int start()
  {Comment("Universal Trailing Stop(",TimeToStr(CurTime(),TIME_DATE)," - ",TimeToStr(CurTime(),TIME_SECONDS),") ");
   for(int J = OrdersTotal()-1; J >= 0; J--)
    {OrderSelect(J, SELECT_BY_POS, MODE_TRADES);
     double OrderPoint=MarketInfo(OrderSymbol(),MODE_POINT);
     double SLMin=MarketInfo(OrderSymbol(),MODE_STOPLEVEL);
     int TS=TrailingStop;
     int Mudou=Tentativas;
     if (TrailingStop<SLMin) TS=SLMin; 
     if ( (TrailingStop>0) && (OrderProfit()>0.0) && 
          (MathAbs(OrderStopLoss()-OrderClosePrice())/OrderPoint>TS) )
             { if (OrderType()==OP_SELL)
                { Print("Modificando ordem ",OrderSymbol()," SL: ", OrderClosePrice()+TS*OrderPoint);
                  while (Mudou>0)
                    { Mudou=Mudou-1;
                      if (OrderModify(OrderTicket(),OrderOpenPrice(),OrderClosePrice()+TS*OrderPoint,OrderTakeProfit(),0,Red)==0) Mudou=0;
                      else Sleep(1000);
                    }
                  B=B+1;}
               else if (OrderType()==OP_BUY)
                { Print("Modificando ordem ",OrderSymbol()," SL: ", OrderClosePrice()-TS*OrderPoint);
                  while (Mudou>0)
                    { Mudou=Mudou-1;
                      if (OrderModify(OrderTicket(),OrderOpenPrice(),OrderClosePrice()-TS*OrderPoint,OrderTakeProfit(),0,Red)==0) Mudou=0;
                      else Sleep(1000);
                    }
                  B=B+1;}
             }
    }
   return(0);
  }

