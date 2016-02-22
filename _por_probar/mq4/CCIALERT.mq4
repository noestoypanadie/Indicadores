//+------------------------------------------------------------------+
//|                                                    CCI ALERT.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2004, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

//---- input parameters
extern int       periodCCI=14;
extern int       HFEhigh=220;
extern int       HFElow=-220;
double CCI1,CCI2;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int  start()
  {
CCI1=iCCI(NULL,0,periodCCI,PRICE_CLOSE,0);
CCI2=iCCI(NULL,0,periodCCI,PRICE_CLOSE,1);
Comment("                                                                                      CCI(",periodCCI,") = ",CCI1,"\n",
        "                                                                   Hook From Extreme HIGH=",HFEhigh,"\n",
        "                                                                   Hook From Extreme LOW=",HFElow);
  
   if(CCI2 > HFEhigh && CCI1 < HFEhigh)
         
      {
      Alert("CCI <",HFEhigh,"...Hook From Extreme HIGH  ",Symbol());
         
      }   
      if(CCI2 < HFElow && CCI1 > HFElow )
         
      {
      Alert("CCI >",HFElow,"...Hook From Extreme LOW  ",Symbol());
         
      }   


 }
   return(0);
 