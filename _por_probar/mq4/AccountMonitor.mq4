//+------------------------------------------------------------------+
//|                                               AccountMonitor.mq4 |
//|                                                       Kirk Sloan |
//|                                                   ksfx@kc.rr.com |
//+------------------------------------------------------------------+
#property copyright "Kirk Sloan"
#property link      "ksfx@kc.rr.com"

//---- input parameters
extern bool      Run=true;
double Balance;
double Equity;
string Message;

datetime Bartime;
int Bartick=0;
bool Tradeallowed=true;
string Orders;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
if(Bartime!=Time[0]){
   Bartime=Time[0]; 
   Tradeallowed=true;
   }  


   if(Tradeallowed && Run == true) {
   Tradeallowed = false;
   Orders="";
   Message = "";
   OrderInfo();
   Message = StringConcatenate (TimeToStr(CurTime(),TIME_MINUTES),": Balance= ",AccountBalance()," - Equity= ",AccountEquity()," - Open orders: ",Orders) ;
   SendMail("Account Update", Message);
   }
//----
   return(0);
  }
//+------------------------------------------------------------------+

int OrderInfo(){
   int atotal =OrdersTotal();
   int acnt;
   for(acnt=0;acnt<atotal;acnt++){
     OrderSelect(acnt, SELECT_BY_POS, MODE_TRADES);
     if (OrderType()==OP_BUY)  
       Orders = StringConcatenate (Orders,"BUY ",OrderSymbol(),": Profit= ",OrderProfit()," | ");
     if (OrderType()==OP_SELL)  
       Orders = StringConcatenate (Orders,"SELL ",OrderSymbol(),": Profit= ",OrderProfit()," | ");
   }
}