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

double b4plusdi,b4minusdi,nowplusdi,nowminusdi;


//----


//---- indicators




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//| Setting internal variables for quick access to data              |
//+------------------------------------------------------------------+
int start()
  {
  
   
  
   b4plusdi=iADX(NULL,0,14,PRICE_CLOSE,MODE_PLUSDI,1);
   nowplusdi=iADX(NULL,0,14,PRICE_CLOSE,MODE_PLUSDI,0);
   
   b4minusdi=iADX(NULL,0,14,PRICE_CLOSE,MODE_MINUSDI,1);
   nowminusdi=iADX(NULL,0,14,PRICE_CLOSE,MODE_MINUSDI,0);
   
//Comment (nowplusdi);
//+------------------------------------------------------------------+
//| Money Management mm=0(lots) mm=-1(Mini) mm=1(full compounding)   |
//+------------------------------------------------------------------+   
   
   
//----

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   
   
   if(b4plusdi>b4minusdi &&
         nowplusdi<nowminusdi)
      {
      Alert(Symbol()," ",Period()," ADX SELLING");
         
      }   
      if(b4plusdi<b4minusdi &&
         nowplusdi>nowminusdi)
       {
         Alert(Symbol()," ",Period()," ADX BUYING");
         
        }
        
     
      }
   return(0);
  // }
   
  
 


