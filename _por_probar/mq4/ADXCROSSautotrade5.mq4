//+------------------------------------------------------------------+
//|                                             ADXcross EXPERT      |
//|                                                     Perky_z      |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Perky_z@yahoo.com                                    "
#property link      "http://groups.yahoo.com/group/MetaTrader_Experts_and_Indicators/"
//+--------------------------------------------------------------------------------------------------+
//|  Alerts in hand with ADXcrosses Indicator they dont need to be run together                       |
//+--------------------------------------------------------------------------------------------------+
// Alerts on cross of + and - DI lines
// I use it on 15 min charts
// though looks good on any time frame
// use other indicators to confirm this trigger tho

//---- input parameters


extern double    Lots=0.1;
extern int       ADXperiod=14;
extern int       Stoploss=40;
extern int       TakeProfit=999;
extern double    TrailingStop = 15;
extern int       Slip=5;



//----
double b4plusdi,b4minusdi,nowplusdi,nowminusdi,Opentrades,cnt,total;


//---- indicators




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//| Setting internal variables for quick access to data              |
//+------------------------------------------------------------------+
int start()
  {
  
   Opentrades=0;
   for (cnt=0;cnt<OrdersTotal();cnt++) 
   {
      if ( OrderSelect (cnt, SELECT_BY_POS) == false )  continue;
      if ( OrderSymbol()==Symbol()) Opentrades=Opentrades+1;
   }

   if (Opentrades!=0)  //and iATR(5,2)<StopLoss*Point 
   
     {
      total=OrdersTotal();
     
      for(cnt=0;cnt<total;cnt++)
        {
         if ( OrderSelect (cnt, SELECT_BY_POS) == false )  continue;
         if ( OrderSymbol() != Symbol())  continue;
         if((OrderType() == OP_BUY || OrderType() == OP_BUYSTOP) && (OrderSymbol()==Symbol()))
             {
                //TradesInThisSymbol++;
                if(TrailingStop>0) 
                  {                
                   if(Bid-OrderOpenPrice()>Point*TrailingStop)
                     {
                      if(OrderStopLoss()<Bid-Point*TrailingStop)
                        {
                         OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Aqua);
                         return(0);
                        }
                     }
                  }
             }
         if((OrderType() == OP_SELL || OrderType() == OP_SELLSTOP) && (OrderSymbol()==Symbol()))
             {
                //TradesInThisSymbol++;
                if(TrailingStop>0)  
                  {                
                   if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                     {
                      if(OrderStopLoss()==0.0 || 
                         OrderStopLoss()>(Ask+Point*TrailingStop))
                        {
                         OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Aqua);
                         return(0);
                        }
                     }
                  }
             }
        }
   }
   
   if (Opentrades==0)  //and iATR(5,2)<StopLoss*Point 
   
     {
  
   
  
         b4plusdi=iADX(NULL,0,ADXperiod,PRICE_CLOSE,MODE_PLUSDI,1);
         nowplusdi=iADX(NULL,0,ADXperiod,PRICE_CLOSE,MODE_PLUSDI,0);
   
         b4minusdi=iADX(NULL,0,ADXperiod,PRICE_CLOSE,MODE_MINUSDI,1);
         nowminusdi=iADX(NULL,0,ADXperiod,PRICE_CLOSE,MODE_MINUSDI,0);
   
      //Comment (nowplusdi);
      //+------------------------------------------------------------------+
      //| Money Management mm=0(lots) mm=-1(Mini) mm=1(full compounding)   |
      //+------------------------------------------------------------------+   
   
   
      //----

      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
   
   
         if(b4plusdi>b4minusdi &&
               nowplusdi<nowminusdi && iADX(NULL,0,ADXperiod,PRICE_CLOSE,MODE_MAIN,0)>21 &&  iADX(NULL,0,ADXperiod,PRICE_CLOSE,MODE_MAIN,0)>iADX(NULL,0,ADXperiod,PRICE_CLOSE,MODE_MAIN,1) && iATR(Symbol(),0,4,0)>iATR(Symbol(),0,4,1)) 
               //iOsMA(Symbol(),0,5,8,3,PRICE_CLOSE,0)>0)
               //nowplusdi<nowminusdi && iATR(Symbol(),0,14,0)>0.0006)
            {
            //Alert(Symbol()," ",Period()," ADX SELLING");
            OrderSend(Symbol(),OP_SELL,Lots,Bid,Slip,Bid+Stoploss*Point,Bid-TakeProfit*Point,"ADX",0,0,Red);
            }   
            if(b4plusdi<b4minusdi &&
               nowplusdi>nowminusdi && iADX(NULL,0,ADXperiod,PRICE_CLOSE,MODE_MAIN,0)>21 &&  iADX(NULL,0,ADXperiod,PRICE_CLOSE,MODE_MAIN,0)>iADX(NULL,0,ADXperiod,PRICE_CLOSE,MODE_MAIN,1) && iATR(Symbol(),0,4,0)>iATR(Symbol(),0,4,1))
               //&& iOsMA(Symbol(),0,5,8,3,PRICE_CLOSE,0)<0)
               //nowplusdi>nowminusdi && iATR(Symbol(),0,14,0)>0.0006)
             {
               //Alert(Symbol()," ",Period()," ADX BUYING");
               OrderSend(Symbol(),OP_BUY,Lots,Ask,Slip,Ask-Stoploss*Point,Ask+TakeProfit*Point,"ADX",0,0,White);
              }
        
     
            }
      }
   return(0);
  // }
   
  
 


