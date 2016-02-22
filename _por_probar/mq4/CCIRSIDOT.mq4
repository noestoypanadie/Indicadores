/*

*********************************************************************
          
                 RSI with Trend Catcher signal
                      
                              
                          by Matsu
              based on codes from various sources
                  
*********************************************************************

*/


#property indicator_separate_window
#property indicator_buffers 6
#property indicator_color1 LightBlue
#property indicator_color2 LightBlue
#property indicator_color3 LightBlue
#property indicator_color4 Red
#property indicator_width4 2

#property indicator_color5 LimeGreen
#property indicator_width5 2
#property indicator_color6 Red
#property indicator_width6 2



#property indicator_level1 100
#property indicator_level3 -100
//#property indicator_level3 40


extern int       CCIPeriod=14;
extern int       RSIPeriod=14;

extern int       BullLevel=100;
extern int       BearLevel=-100;
extern bool      AlertOn = true;
double rsi,rsib4;
double cci,ccib4;

double CCI[];
double DnCCI[];
double UpCCI[];
double NoCCI[];
double RSIdotup[];
double RSIdotdn[];





int init() 
{

   IndicatorBuffers(6);
   
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,CCI);
   
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,DnCCI);
   
   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(2,UpCCI);
   
   SetIndexStyle(3,DRAW_LINE);
   SetIndexBuffer(3,NoCCI);
   
      SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2);
      SetIndexArrow(4,159);
      SetIndexBuffer(4,RSIdotup);
      
       SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,2);
      SetIndexArrow(5,159);
      SetIndexBuffer(5,RSIdotdn);
   
      
   IndicatorShortName("CCI with RSI Crossing zero dot CCI Period=("+CCIPeriod+")");
   
   return(0);
   
}



int start() 
{

   int counted_bars=IndicatorCounted();
   int shift,limit,ob,os;
   bool dn = false;
   double BuyNow, BuyPrevious, SellNow, SellPrevious;
   static datetime prevtime = 0;
   
      
   if (counted_bars<0) return(-1);
   if (counted_bars>0) counted_bars--;
 //  limit=Bars-31;
  // if(counted_bars>=31) limit=Bars-counted_bars-1;

   for (shift=500;shift>=0;shift--)   
   {
             rsi=iRSI(NULL,0,RSIPeriod,0,shift);  
             rsib4=iRSI(NULL,0,RSIPeriod,0,shift+1);     
             cci=iCCI(Symbol(),Period(),CCIPeriod,PRICE_TYPICAL,shift);  // no Im not dumb I had to do it this way
             ccib4=iCCI(Symbol(),Period(),CCIPeriod,PRICE_TYPICAL,shift+1);
             CCI[shift]=iCCI(Symbol(),Period(),CCIPeriod,PRICE_TYPICAL,shift);
      
   //  Alert (RSI[shift+1]);
      
    
     if (rsib4<50 && rsi>50)
      {
        RSIdotup[shift]=0;
        }
         if (rsib4>50 && rsi<50)
      {
        RSIdotdn[shift]=0;
        }
      
      // ========= three-tone RSI
      
     // if (dn==true)
     // {
       //  if (CCI[shift]> BullLevel) 
       //  {
        //    DnCCI[shift]=EMPTY_VALUE;
         //   NoCCI[shift]=EMPTY_VALUE;
         //   UpCCI[shift]=CCI[shift];

   //  }

    
    //     if (CCI[shift]<BearLevel) 
    //     {
     //       DnCCI[shift]=CCI[shift];
     //       NoCCI[shift]=EMPTY_VALUE;
      //      UpCCI[shift]=EMPTY_VALUE;
      //   }
              
      }
      
 //  }      
         

   // ======= Alert =========

   if(AlertOn)
   {
      if(prevtime == Time[0]) 
      {
         return(0);
      }
      prevtime = Time[0];
      
      if (cci<100 && ccib4> 100) Alert(Symbol()," ",Period(),"m ","CCI above 100");
      if (cci>100 && ccib4< 100) Alert(Symbol()," ",Period(),"m ","CCI below 100");

  
   }

    
    

   // ======= Alert Ends =========


   
   return(0);
   
}



