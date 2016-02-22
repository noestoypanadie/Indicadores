//+------------------------------------------------------------------+
//|                                              TrendScalper_TR.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Testing"
#property link      "http://www.metaquotes.net/"

//---- input parameters
extern int       MA1period=10;
extern int       MA1mode=1;
extern int       MA2period=20;
extern int       MA2mode=1;
extern int       MA3period=50;
extern int       MA3mode=1;
extern int       MA4period=200;
extern int       MA4mode=1;
extern int       CloseMA_A=2;
extern int       CloseMA_B=3;
extern double    LotsIfNoMM=0.1;
extern int       Stoploss=0;
extern int       TakeProfit=0;
extern int       Slip=5;
extern int       MM_Mode=0;
extern int       MM_Risk=40;

double Opentrades,orders,first,mode,Ilo,sym,b;
double b4signal,Signal,Triggerline,b4Triggerline,Nowsignal,NowTriggerline,sl,LastOpByExpert,LastBarChecked;
int cnt,cnt2,OpenPosition,notouchbar; 
bool test;
double MA1,MA2,MA3,MA4,CloseMA1,CloseMA2;

#define Long 1
#define Short 2

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
//return(0);
   
   if ( ! IsTesting() ) Comment(" Trailingstop    ",  b, "\n","      Tick no. ", iVolume(NULL,0,0),"\n"," Lots    ",Ilo);


   /**********************************Money and Risk Management***************************************
   Changing the value of mm will give you several money management options
   mm = 0 : Single 1 lot orders.
   mm = -1 : Fractional lots/ balance X the risk factor.(use for Mini accts)
   mm = 1 : Full lots/ balance X the risk factor up to 100 lot orders.(use for Regular accounts)
   ***************************************************************************************************
   RISK FACTOR:
   risk can be anything from 1 up. 
   Factor of 5 adds a lot for every $20,000.00 added to the balance. 
   Factor of 10 adds a lot with every $10.000.00 added to the balance.
   The higher the risk,  the easier it is to blow your margin..
   **************************************************************************************************/

   if (MM_Mode < 0)  {
   Ilo = MathCeil(AccountBalance()*MM_Risk/10000)/10;
     if (Ilo > 100) {  
     Ilo = 100;  
     }
   } else {
   Ilo = LotsIfNoMM;
   }
   if (MM_Mode > 0)  
    {
   Ilo = MathCeil(AccountBalance()*MM_Risk/10000)/10;
    if (Ilo > 1)  
    {
    Ilo = MathCeil(Ilo);
    }
    if (Ilo < 1)  
    {
    Ilo = 1;
    }
    if (Ilo > 100)  
    {  
     Ilo = 100;  
     }
   }
 	      

//     if (notouchbar == Time[0]) 
//         return(0);


     if (LastBarChecked == Time[0]) 
     //if (1 == 2) //just so this part is never true for now
         return(0); 
      else 
  	      {
  	      LastBarChecked = Time[0]; 

         MA1=iMA(NULL,0,MA1period,0,MA1mode,PRICE_CLOSE,1);
         MA2=iMA(NULL,0,MA2period,0,MA2mode,PRICE_CLOSE,1);
         MA3=iMA(NULL,0,MA3period,0,MA3mode,PRICE_CLOSE,1);
         MA4=iMA(NULL,0,MA4period,0,MA4mode,PRICE_CLOSE,1);
           	     
         switch (CloseMA_A)
            {
            case 1:
               CloseMA1=MA1;
               break;
            case 2:
               CloseMA1=MA2;
               break;
            case 3:
               CloseMA1=MA3;
               break;
            case 4:
               CloseMA1=MA4;
               break;
            default:
               Alert("CloseMA_A must be in range 1-4");
               break;
            }
            
         switch (CloseMA_B)
            {
            case 1:
               CloseMA2=MA1;
               break;
            case 2:
               CloseMA2=MA2;
               break;
            case 3:
               CloseMA2=MA3;
               break;
            case 4:
               CloseMA2=MA4;
               break;
            default:
               Alert("CloseMA_B must be in range 1-4");
               break;
            }
            
            
                       	      
         Opentrades=0;
         for (cnt=0;cnt<OrdersTotal();cnt++) 
            {
            if ( OrderSelect (cnt, SELECT_BY_POS) == false )  continue;
            if ( OrderSymbol()==Symbol()) 
               {
               Opentrades=Opentrades+1;
               if(OrderType()==OP_BUY) 
                  {
                  OpenPosition = Long; 

                  if (IsTesting()) 
                     {
                        //LastLogTime=iTime(NULL,PERIOD_H1,1);
                        if (OrderTakeProfit()==OrderOpenPrice()+Point*10000)
                           OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderOpenPrice()+Point*10001,0,Cyan);
                          else
                           OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),OrderOpenPrice()+Point*10000,0,Cyan);
                     }

                  }
                 else 
                  {
                  OpenPosition = Short; 

                  if (IsTesting()) 
                     {
                        //LastLogTime=iTime(NULL,PERIOD_H1,1);
                        if (OrderTakeProfit()==0)
                           OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),Point*1,0,Cyan);
                          else
                           OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),0,0,Cyan);
                     }

                  }
                  
               }
            }

  	      
  	      
         //----------------------------------------Order Control-------------------------------------------
 
         if (Opentrades != 0)  
   
            {


            if (OpenPosition == Long)
               {
               if (CloseMA1<CloseMA2)
                  {
                  OrderClose(OrderTicket(),OrderLots(),Bid,Slip,Red);
                  //Alert("DanMA close long ",Symbol());
                  //notouchbar=Time[0];
                  return(0);
                  }
               }
            
            if (OpenPosition == Short)
               {
               if (CloseMA1>CloseMA2)
                  {
                  OrderClose(OrderTicket(),OrderLots(),Ask,Slip,Red);
                  //Alert("DanMA close short ",Symbol());
                  //notouchbar=Time[0];
                  return(0);
                  }
               }
            

            }

  	      
  	      
         //----------------------------------------New signals-------------------------------------------
         
         
         if (Opentrades == 0)  
   
           {
           if (MA1>MA2 && MA2 > MA3 && MA3>MA4)
                  {
                  OrderSend(Symbol(),OP_BUY,Ilo,Ask,Slip,0,0,"",0,0,White);
                  return(0);
                  }
           
           if (MA1<MA2 && MA2 < MA3 && MA3<MA4)
                  {
                     OrderSend(Symbol(),OP_SELL,Ilo,Bid,Slip,0,0,"",0,0,Red);
                     //notouchbar=Time[0];
                     return(0);
                  }
           
           
           
           
           }
           
  	      
  	      
  	      
      } //Ends if (LastBarChecked == Time[0])

   return(0);
  }


