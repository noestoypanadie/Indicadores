//+------------------------------------------------------------------+
//|                                            Straddler Handler.mq4 |
//|                              Author := pip_seeker copyright 2005 |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
// Code Begin
//--------------------------------------------
/*[[
 Name := Straddler Handler
 Author := pip_seeker copyright 2005
 Notes := This does not place orders. All it does is delete the other side of the straddle when one side enters
 Lots := 0
 Stop Loss := 0
 Take Profit := 0
 Trailing Stop := 0
]]*/
Vars: OpenBuyOrders(0),OpenTrade(0),OpenSellOrders(0),cnt(0);
/***********************************************************
************************** Notes ***************************
        Manually place your straddle Buylimit, Selllimit
        Or BuyStop, SellStop and then place this script
        on your chart for this to handle the trades from
        this point. This script will close the opposing
        Order when the other order is triggered.
        
        Further, you could add a trailing stop to this
        script.
        This script does not place any orders you have to
        enter them manually. 
*///////////////////////////////////////////////////////////

If CurTime - LastTradeTime < 10 then exit; 
OpenBuyOrders=0;
For cnt = 1 to TotalTrades
Begin
  If OrderValue(cnt,VAL_SYMBOL)=Symbol And 
  OrderValue(cnt,VAL_TYPE)==OP_BUYSTOP OR 
  OrderValue(cnt,VAL_TYPE)==OP_BUYLIMIT Then 
  {
  OpenBuyOrders=OpenBuyOrders+1;
  };
  End;
  
OpenSellOrders=0;
For cnt = 1 to TotalTrades
Begin
  If OrderValue(cnt,VAL_SYMBOL)==Symbol And
  OrderValue(cnt,VAL_TYPE)==OP_SELLSTOP OR
  OrderValue(cnt,VAL_TYPE)==OP_SELLLIMIT Then
  {
  OpenSellOrders=OpenSellOrders+1;
  };
  End;
  
OpenTrade=0;
For cnt = 1 to TotalTrades
Begin
   If OrderValue(cnt,VAL_SYMBOL)==Symbol And
   OrderValue(cnt,VAL_TYPE)==OP_BUY OR 
   OrderValue(cnt,Val_type)==OP_SELL Then
   {
   OpenTrade=OpenTrade+1;
   };
   End; 
For cnt = 1 to TotalTrades 
Begin
  
     If (OpenTrade==1 and OpenSellOrders==1) OR (OpenTrade==1 and OpenBuyOrders==1) OR
        (OpenTrade==0 and OpenSellOrders==1 and OpenBuyOrders==0) OR
        (OpenTrade==0 and OpenSellOrders==0 and OpenBuyOrders==1) Then 
        {
        DeleteOrder(OrderValue(cnt,VAL_TICKET),Silver);
        Exit;
        };
     
End;
Exit; 
//---------------------------------------------
// Code end