

Hi all.  Neurex is switching to MQ4 in a couple months, and thus my 
current system is soon to be obsolete.  Can someone please convert 
my code?  I promise it is very simple - I just have no idea how to 
do MQ4.  I have posted my code below.  Thanks a ton!


/*[[
        Name := Trading
        Author := Copyright © 2005
        Lots := 0.10
        Stop Loss := 25
        Take Profit := 100
        Trailing Stop := 15
]]*/
/////////////////////////////////////////////////////
// Defines
/////////////////////////////////////////////////////
defines: Slippage(3), mm(1),risk(50);
vars:           
                        
                        sl(0),tp(0),maxSimOpen(0),
                        mode(0),
                        buffer(0),
                        lastHigh(0),
                        target(0),
                        entryTS(0),
                        lastLow(0),
                        cnt(0),
                        first(0),
                        lotMM(0),
                        tHour(0);
cnt=1;
/////////////////////////////////////////////////
//  CUSTOM INDICATORS
/////////////////////////////////////////////////
If      Bars<100 or TakeProfit<10 then Exit;
If      IsIndirect(Symbol)=TRUE then Exit;



/////////////////////////////////////////////////
//  Main Script Conditions
/////////////////////////////////////////////////


//      PYRAMIDING - LINEAR
//
//      Money management risk exposure compounding
    
if      mm<>0 then 
        {
        lotMM=Ceil(Balance*risk/10000)/10;
        if      lotMM < 0.1 then {
                lotMM = lots;
                };
        If      lotMM > 1 then {
                lotMM = Ceil(lotMM);
                };
        If      lotMM > 100 then {
                lotMM = 100;
                };
        } else {
        lotMM=Lots;
        };


//      Adding simultaneously opened position


if      mm = 1 then {
        If      balance < 1000000 then maxSimOpen=1;


        If      balance > 1000000 then {        
                maxSimOpen=(Balance*risk/10000)/1000;
                } else { 
                maxSimOpen=1;
                }
        };


if      mm = 2 then {
        if      balance < 1000000 then maxSimOpen=1;
        
        if      balance > 1000000 then {        
                maxSimOpen=(Balance*risk/10000)/1000;
        if      maxSimOpen > 20 then maxSimOpen=20;
                } else { 
                maxSimOpen=1;
                };
        };



/////////////////////////////////////////////////
//  Comment on the chart
/////////////////////////////////////////////////



/////////////////////////////////////////////////
//  Long/Short Entry and Re-entry Trades
/////////////////////////////////////////////////


If      TotalTrades<maxSimOpen Then
  {// нет ни одного открытого ордера
   // на всякий случай проверим, если у нас свободные деньги на 
счету?
   // значение 1000 взято для примера, обычно можно открыть 1 лот
     // денег нет - выходим


   // проверим, не слишком ли часто пытаемся открыться?
   // если последний раз торговали менее чем 5 минут(5*60=300 сек)
   // назад, то выходи
   // проверяем на возможность встать в длинную позицию (BUY)
   If ask > close[1] + 5*Point and curtime-LastTradeTime > 43200
   then
     {
      SetOrder(OP_BUY,Lotmm,ask,slippage,ask-
stoploss*point,ask+takeprofit*point,Cyan); // исполняем
      Exit; // выходим, так как все равно после совершения торговой 
операции
            // наступил 10-ти секундный таймаут на совершение 
торговых операций
     };
   // проверяем на возможность встать в короткую позицию (SELL)
   If bid < close[1] - 5*Point and curtime-LastTradeTime > 43200
      then
     {
      SetOrder(OP_SELL,Lotmm,bid,slippage,bid+stoploss*point,bid-
takeprofit*point,Fuchsia); // исполняем
      Exit; // выходим
     };
   // здесь мы завершили проверку на возможность открытия новых 
позиций.
   // новые позиции открыты не были и просто выходим по Exit, так как
   // все равно анализировать нечего
   Exit;
  };


for cnt=1 to TotalTrades
  {
   mode=OrderValue(cnt,VAL_TYPE);
   If mode=OP_BUY then   // if the already opened position were BUY
     {
      // lets check if EMA(16) has crossed EMA(60) downwards?
      If iac(1) <-5  then
        {
         // try to close the position at current Bid price 
         CloseOrder(OrderValue(cnt,VAL_TICKET),OrderValue
(cnt,VAL_LOTS),Bid,Slippage,RED);
         Exit;
        };
      // Here we check the trailing stop at open position.
      // Trailing stop ( Stop Loss) of the BUY position is being
      // kept at level 20 points below the market.


      // If the profit (current Bid-OpenPrice) more than 
TrailingStop (20) pips
      If (Bid-OrderValue(cnt,VAL_OPENPRICE))>(TrailingStop*Point) 
then
        {
         // we have won already not less than 'TrailingStop' pips!
         If OrderValue(cnt,VAL_STOPLOSS)<(Bid-TrailingStop*Point) 
then
           {
            // move the trailing stop (Stop Loss) to the 
level 'TrailingStop' from the market
            ModifyOrder(OrderValue(cnt,VAL_TICKET),OrderValue
(cnt,VAL_OPENPRICE),
                        Bid-Point*TrailingStop,OrderValue
(cnt,VAL_TAKEPROFIT),Red);
            Exit;
           };
        };
     };
   If mode=OP_SELL then   // if the already opened position were SELL
     {
      // check if EMA(16) has crossed already EMA(60) upwards?
      If iac(1) >5  then
        {
         // try to close the position at current Ask price
         CloseOrder(OrderValue(cnt,VAL_TICKET),OrderValue
(cnt,VAL_LOTS),Ask,Slippage,RED);
         Exit;
        };
      // Here we check the trailing stop at open position.
      // Trailing stop ( Stop Loss) of the BUY position is being
      // kept at level 20 points below the market.


      // If the profit (current Bid-OpenPrice) more than 
TrailingStop (20) pips
      If (OrderValue(cnt,VAL_OPENPRICE)-Ask)>(TrailingStop*Point) 
then
        {
         // we have won already not less than 'TrailingStop' pips!
         If OrderValue(cnt,VAL_STOPLOSS)>(Ask+TrailingStop*Point) or
            OrderValue(cnt,VAL_STOPLOSS)=0 then
           {
            // move the trailing stop (Stop Loss) to the 
level 'TrailingStop' from the market
            ModifyOrder(OrderValue(cnt,VAL_TICKET),OrderValue
(cnt,VAL_OPENPRICE),
                        Ask+Point*TrailingStop,OrderValue
(cnt,VAL_TAKEPROFIT),Red);
            Exit;
           };
        };
     };};
  






