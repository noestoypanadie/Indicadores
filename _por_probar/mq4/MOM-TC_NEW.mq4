/*

//+------------------------------------------------------------------+
//|                         Momentum with Alert Cross and signal.mq4 |
//|                                                                  |
//|   Original: RSI with Trend Catcher signal by Matsu               |  
//|   Modified: Momentum with cross signal by Linuxser for Forex-TSD |
//+------------------------------------------------------------------+

*/


#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 LimeGreen
#property indicator_color2 LimeGreen
#property indicator_color3 Orange
#property indicator_color4 Orange

#property indicator_level1 100
#property indicator_levelstyle STYLE_DOT
#property indicator_levelcolor Red


extern int       MOMPeriod=14;

extern bool      AlertOn = true;

double MOM[];
double Buy[];
double Sell[];
double DnMOM[];
double Levela[];

int Level=100.00;
int init() 
{

   IndicatorBuffers(4);
   
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,MOM);
   
   SetIndexStyle(1,DRAW_ARROW,STYLE_SOLID);
   SetIndexArrow(1,159);
   SetIndexBuffer(1,Buy);
   
   SetIndexStyle(2,DRAW_ARROW,STYLE_SOLID);
   SetIndexArrow(2,159);
   SetIndexBuffer(2,Sell);
   
   SetIndexStyle(3,DRAW_LINE);
   SetIndexBuffer(3,DnMOM);
   
   IndicatorShortName("Momentum("+MOMPeriod+")");
   IndicatorDigits(2);
   
   return(0);
   
}



int start() 
{

   int counted_bars=IndicatorCounted();
   int shift,limit,ob,os;   
   bool TrendUp, TrendDn;
   bool dn = false;
   double BuyNow, BuyPrevious, SellNow, SellPrevious;
   static datetime prevtime = 0;
         
   if (counted_bars<0) return(-1);
   if (counted_bars>0) counted_bars--;
   limit=Bars-31;
   if(counted_bars>=31) limit=Bars-counted_bars-1;

   for (shift=limit;shift>=0;shift--)   
   {
            
      MOM[shift]=iMomentum(NULL,0,MOMPeriod,PRICE_CLOSE,shift);
      ob = Level;
      os = Level;
      
      
      TrendUp=false;
      TrendDn=false;
      

      if(MOM[shift]>Level) TrendUp=true;
      if(MOM[shift]<Level) TrendDn=true;
      
      if (dn==true)
      {
         if (MOM[shift]>Level) 
         {
            dn=false;
            DnMOM[shift]=EMPTY_VALUE;
         }
         else
         {
            dn=true;
            DnMOM[shift]=MOM[shift];
         }

      }
      else
      {
         if (MOM[shift]<Level) 
         {
            dn=true;
            DnMOM[shift]=MOM[shift];
         }
         else
         {
            dn=false;
            DnMOM[shift]=EMPTY_VALUE;
         }
           
      }
      
      


      if(TrendUp==true) 
      {
         Buy[shift]=ob;
         Sell[shift]=EMPTY_VALUE;
      } 
      else 
      if(TrendDn==true) 
      {
         Buy[shift]=EMPTY_VALUE;
         Sell[shift]=os;
      } 
      else
      {
         Buy[shift]=EMPTY_VALUE;
         Sell[shift]=EMPTY_VALUE;
      }
      
    }      
         

//       ======= Alert =========

   if(AlertOn)
   {
      if(prevtime == Time[0]) 
      {
         return(0);
      }
      prevtime = Time[0];
   
      BuyNow = Buy[0];
      BuyPrevious = Buy[1];
      SellNow = Sell[0];
      SellPrevious = Sell[1];
   
      if((BuyNow ==ob) && (BuyPrevious ==EMPTY_VALUE) )
      {
         Alert(Symbol(), " M", Period(), " Momentum Cross UP Alert");
      }
      else   
      if((SellNow ==os) && (SellPrevious ==EMPTY_VALUE) )
      {
         Alert(Symbol(), " M", Period(), " Momentum Cross Down Alert");
      }
         
      IndicatorShortName("Momentum("+MOMPeriod+") (Alert on)");

   }

//       ======= Alert End =========


   
   return(0);
   
}



