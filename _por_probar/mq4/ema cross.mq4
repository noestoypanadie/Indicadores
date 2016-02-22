//---- input parameters
extern int FastEMA=5;
extern int SlowEMA=6;
double EMA1,EMA2,EMA3,EMA4;
//+------------------------------------------------------------------+
//| expert initialization function |
//+------------------------------------------------------------------+
int start()
{


    EMA1=iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,0);
    EMA2=iMA(NULL,0,6,0,MODE_EMA,PRICE_CLOSE,0);
    EMA3=iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,1);
    EMA4=iMA(NULL,0,6,0,MODE_EMA,PRICE_CLOSE,1);

    if (EMA1 > EMA2 && EMA3 < EMA4)
    {
    Alert("",Symbol());

    }
    if (EMA2 > EMA1 && EMA4 < EMA3)
    {
    Alert("",Symbol());

    }

	//----
   return(0);
  }
//+------------------------------------------------------------------+


