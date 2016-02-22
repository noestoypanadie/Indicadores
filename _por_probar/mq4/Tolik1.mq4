//+------------------------------------------------------------------+
//|                                                        Tolik.mq4 |
//|                    Crazy Alex © 2006, Crazy Alex  Software Corp. |
//|                                          http://www.CrazyAlex.ru |
//+------------------------------------------------------------------+
#property copyright "Crazy Alex © 2006, Crazy Alex  Software Corp."
#property link      "http://www.CrazyAlex.ru"


//---- input parameters
extern double TakeProfit = 50;
extern double Lots = 0.1;
extern double StopLoss = 50;
extern double TralingStop = 35;
extern double FirstStop = 24;

extern double ten_sen = 9;
extern double kij_sen = 26;
extern double sen_span_b = 52;


extern string mail_users =" ";

extern double FreeMargin = 500;
extern double MathLots = 300;



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
  
int cnt, ticket, total,TotalOpenOrders,Commentary;
int napr;
 
  
//----
double tenkan_sen    = iIchimoku(NULL, 0, ten_sen, kij_sen, sen_span_b, MODE_TENKANSEN, 0);
double Kijun_sen     = iIchimoku(NULL, 0, ten_sen, kij_sen, sen_span_b, MODE_KIJUNSEN, 0);
double Senkou_Span_A = iIchimoku(NULL, 0, ten_sen, kij_sen, sen_span_b, MODE_SENKOUSPANA, 0);
double Senkou_Span_B = iIchimoku(NULL, 0, ten_sen, kij_sen, sen_span_b, MODE_SENKOUSPANB, 0);
double Chinkou_Span  = iIchimoku(NULL, 0, ten_sen, kij_sen, sen_span_b, MODE_CHINKOUSPAN, kij_sen);
//***********************************************************************
double tenkan_sen_1    = iIchimoku(NULL, 0, ten_sen, kij_sen, sen_span_b, MODE_TENKANSEN, 1);
double Kijun_sen_1     = iIchimoku(NULL, 0, ten_sen, kij_sen, sen_span_b, MODE_KIJUNSEN, 1);
double Senkou_Span_A_1 = iIchimoku(NULL, 0, ten_sen, kij_sen, sen_span_b, MODE_SENKOUSPANA, 1);
double Senkou_Span_B_1 = iIchimoku(NULL, 0, ten_sen, kij_sen, sen_span_b, MODE_SENKOUSPANB, 1);
double Chinkou_Span_1  = iIchimoku(NULL, 0, ten_sen, kij_sen, sen_span_b, MODE_CHINKOUSPAN, kij_sen+1);


double Adx_Main = iADX(NULL,0,14,PRICE_HIGH,MODE_MAIN,0);
double Adx_PlusDi = iADX(NULL,0,14,PRICE_HIGH,MODE_PLUSDI,0);
double Adx_MinusDi = iADX(NULL,0,14,PRICE_HIGH,MODE_MINUSDI,0);

double open   =  iOpen(NULL,0,0);
double close  =  iClose(NULL,0,0);
double higt   =  iHigh(NULL,0,0);
double low    =  iLow(NULL,0,0);

//Comment("Chinkou_Span ",Chinkou_Span,"\n","tenkan_sen ",tenkan_sen_1,"\n","Kijun_sen ",Kijun_sen_1,"\n","Adx_PlusDi ",Adx_PlusDi,"\n","Adx_MinusDi ",Adx_MinusDi);

   // считаем колво открытых ордеров    

total=OrdersTotal();
TotalOpenOrders = 0;
for(cnt=0;cnt<total;cnt++)
{
   if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES) == true) 
      {
      if (OrderSymbol()==Symbol())
         {
         if (OrderStopLoss()!=0)
         
         if (OrderType( ) == OP_BUY)
              { 
              //Comment("Стоит Бай");
              //Comment(OrderTakeProfit(),"|",Bid,"|", Bid-OrderStopLoss()," ",TralingStop*Point);
                if (Bid-OrderStopLoss()>TralingStop*Point)
                {
                         OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TralingStop*Point,Bid+TakeProfit*Point,0,CLR_NONE);
                 return(0);
                 }
                 }
         if (OrderType( ) == OP_SELL)
                 {
             
            // Comment(OrderTakeProfit(),"|",Ask,"|", Ask-OrderTakeProfit());

            if (OrderStopLoss()-Ask>TralingStop*Point) 
                    {
                           OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TralingStop*Point,Ask-TakeProfit*Point,0,CLR_NONE);
                     return(0);
                     //Comment("Изменить");
                    //  Comment("Стоит Селл");
                       }
                   }       
                   
         if (OrderStopLoss()==0)

            {
           if (OrderType( ) == OP_BUY)
           {
           if (Bid-OrderOpenPrice()>FirstStop*Point)
               {
                OrderModify(OrderTicket(),OrderOpenPrice(),Bid-StopLoss*Point,Bid+TakeProfit*Point,0,CLR_NONE);
               return(0);
            
                }  
           }
           if (OrderType( ) == OP_SELL)
           {
           if (OrderOpenPrice()-Ask>FirstStop*Point)
               {
                OrderModify(OrderTicket(),OrderOpenPrice(),Ask+StopLoss*Point,Ask-TakeProfit*Point,0,CLR_NONE);
                return(0);
               }
           }

            
            
            
            }
                   
         }//КонецЕсли этот символ
     }//КонецЕсли выбран
    
}//КонецЦикла


total=OrdersTotal();
TotalOpenOrders = 0;
for(cnt=0;cnt<total;cnt++)
{
   if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES) == true) 
      {
      if (OrderSymbol()==Symbol())
         {
         TotalOpenOrders = TotalOpenOrders+1;
         }
       }
}         



  total=OrdersTotal();
   for(cnt=0;cnt<total;cnt++)
      {
      if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES) == true) 
         {
         if (OrderSymbol()==Symbol())
               {
                  if (OrderType()==OP_BUY&&higt>Senkou_Span_B&&Ask<Senkou_Span_B&&tenkan_sen<Kijun_sen) OrderClose(OrderTicket(),OrderLots(),Bid,3,CLR_NONE);
                  if (OrderType()==OP_SELL&&low<Senkou_Span_B&&Bid>Senkou_Span_B&&tenkan_sen>Kijun_sen) OrderClose(OrderTicket(),OrderLots(),Ask,3,CLR_NONE);

               }
          }
      }         




if (TotalOpenOrders < 1)
{

  if (AccountEquity()< FreeMargin)
{
Lots = 0.1;
}
else  Lots = (MathRound( AccountEquity()/MathLots)/ 10);

   
    if (higt>Senkou_Span_B&&Ask<Senkou_Span_B&&tenkan_sen<Kijun_sen)//(Chinkou_Span>tenkan_sen&&Chinkou_Span>Kijun_sen&&Chinkou_Span>Senkou_Span_B&&Chinkou_Span>Senkou_Span_A&&Adx_PlusDi>Adx_MinusDi)    //&&iOpen(NULL,0,0)>tenkan_sen&&Bid<tenkan_sen)//<Adx_MinusDi&&tenkan_sen_1!=Kijun_sen_1)//Условия открытия ордера на продажу
    {
    
      
      OrderSend(Symbol(), OP_SELL,Lots,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,NULL,0,0,CLR_NONE);
      
      
    }
    
    if (low<Senkou_Span_B&&Bid>Senkou_Span_B&&tenkan_sen>Kijun_sen)//(Chinkou_Span<tenkan_sen&&Chinkou_Span<Kijun_sen&&Chinkou_Span<Senkou_Span_B&&Chinkou_Span<Senkou_Span_A&&Adx_PlusDi<Adx_MinusDi)//Условия открытия ордера на покупку
    {
        
      OrderSend(Symbol(), OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,NULL,0,0,CLR_NONE);
      
      
    }
}






   
//----
   return(0);
  }
//+------------------------------------------------------------------+