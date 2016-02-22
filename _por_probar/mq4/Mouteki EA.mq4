//+------------------------------------------------------------------+
//|                                                   Mouteki EA.mq4 |
//|                                    Copyright ?2006, Hua Ai (aha) |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright ?2006, Hua Ai (aha)"
#property link      ""

// Determine trend lines:
// 1. Each time determine two trend lines: top trend line and bottom 
//    trend line.
// 2. Each trend line is determined by two points. Top trend line has
//    to be slopped downward from left to right. Bottom trend line 
//    has to be slopped upward from left to right.
// 3. The 1st point for the top trend line is the most recent high.
//    The 2nd point is the most recent high that is higher than the
//    1st point.
// 4. The 1st point for the bottom trend line is the most recent low.
//    The 2nd point is the most recent low that is lower than the
//    1st point.
// 5. A bar is qualified as a high when it's high is the highest among 
//    the 5 bars centered at this bar. A bar is qualified as a low when
//    it's low is the lowest among the 5 bars centered at this bar.

// Entry Conditions:
//
// 1. Enter long trade
//   1) Enter long when price close higher than the top trend line. The
//      entry price is the first open price above the top trend line.
//   2) Profit projection is determined by calculating the distance 
//      between the lowest low from the current bar to the 2nd point 
//      of the top trend line, and the trend line.
//   3) TP is calculated by adding the profit projection to the first
//      open price above the top trend line.
//   4) SL is calulated based on profit projection:
//     i.  When profit projection is less than 90 pips, set SL to half 
//         of the profit projection to create a 2:1 win/loss ratio.
//     ii. When profit project is greater than 90 pips, set SL to 33% 
//         of the profit projection to create a 3:1 win/loss ratio.
//
// 2. Enter short trade
//   1) Enter short when price close lower than the bottom trend line. 
//      The entry price is the first open price below the bottom trend
//      line.
//   2) Profit projection is determined by calculating the distance 
//      between the highest high from the current bar to the 2nd point 
//      of the bottom trend line, and the trend line.
//   3) TP is calculated by adding the profit projection to the first
//      open price below the bottom trend line.
//   4) SL is calulated based on profit projection:
//     i.  When profit projection is less than 90 pips, set SL to half 
//         of the profit projection to create a 2:1 win/loss ratio.
//     ii. When profit project is greater than 90 pips, set SL to 33% 
//         of the profit projection to create a 3:1 win/loss ratio.
//
// Condition to modify a trade:
// 
// 1. When profit is greater than 40 pips, move the SL to +10.
// 2. When a new trade setup is formed in the same direction of an 
//    existing trade:
//   1) Adjusting TP if the new TP is farther than the existing one.
//   2) Adjusting SL if the new SL is closer than the existing one.
//   3) May add a position based on the new setup if there is only 
//      one trade exists.
//
// Conditions to close a trade:
//
// 1. TP is hit.
// 2. SL is hit.
// 3. A new trade setup is formed in a reversed direction of the 
//    existing trade.
//
// Timing:
//
// 1. The first 10 seconds of every 4 hours:
//   1) Check entry conditions.
//   2) Check new setups -- may open new position and/or close old 
//      positions.
//   3) Condition to modify SL. (This items was checked every tick but
//      was proved not good, it tends to cut profits a lot. So now this
//      is checked every 4 hours as well)
// 

extern bool    AlertsOn=true;
extern bool    MultiPositions=false;
extern double  LotsPerTrade=1;

int         spread;
bool        TD=False;/*Default is false. True setting draws up and down arrows instead of dots on TD Points creating more clutter.*/ 
int         BackSteps=0;/*Used to be extern int now just int. Leave at 0*/
int         ShowingSteps=1;/*Used to be extern int now just int.  Leave at 1*/
bool        FractalAsTD=false;/*Used to be extern bool now just bool.  Leave at false, otherwise Trend Lines based on Fractal Points not TD Points*/
 
double      TrendLineBreakUp=-1;//Line added.
double      TrendLineBreakUpPrev=-1;//Line added.
bool        TrendLineBreakUpFlag=False;//Line added.
double      TrendLineBreakDown=-1;//Line added.
double      TrendLineBreakDownPrev=-1;//Line added.
bool        TrendLineBreakDownFlag=False;//Line added.

//---- buffers
double highs[100000];
double lows[100000];

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   spread = MarketInfo(Symbol(),MODE_SPREAD);
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
//--------------------------------------------------------------------
// Find the highs and lows in the current chart. 
int SetTDPoint(int B)
{
 int shift;
 if (FractalAsTD==false)
   {
    //Print("B = ",B);
    //Print("Bars = ",Bars);
    //Print("IndicatorCounted() = ",IndicatorCounted());
    //It seems B is the same as IndicatorCounted()function 
    for (shift=B;shift>2;shift--)
       {       
        
        // If the bar highs at the left are equal to current bar high, 
        // the current bar high is still a valid high.
        if (High[shift+2]<High[shift] && High[shift+1]<High[shift] && 
            High[shift-1]<High[shift]  && High[shift-2]<High[shift])
           highs[shift]=High[shift];
            
        //else highs[shift]=0;
        
        // If the bar lows at the left are equal to current bar low, 
        // the current bar low is still a valid low.
        if (Low[shift+2]>Low[shift] && Low[shift+1]>Low[shift] && 
            Low[shift-1]>Low[shift]  && Low[shift-2]>Low[shift])
           lows[shift]=Low[shift];
        
        //else lows[shift]=0;    
       }  
    highs[0]=0;
    lows[0]=0;
    highs[1]=0;
    lows[1]=0;
   }
 else
   {
    for (shift=B;shift>3;shift--)
       {
        if (High[shift+1]<=High[shift] && High[shift-1]<High[shift] &&
            High[shift+2]<=High[shift] && High[shift-2]<High[shift])
             highs[shift]=High[shift];
        else highs[shift]=0;    
        if (Low[shift+1]>=Low[shift] && Low[shift-1]>Low[shift] && 
            Low[shift+2]>=Low[shift] && Low[shift-2]>Low[shift])
            lows[shift]=Low[shift];
        else lows[shift]=0;    
       }  
    highs[0]=0;
    lows[0]=0;
    highs[1]=0;
    lows[1]=0;
    highs[2]=0;
    lows[2]=0;    
   }  
 return(0);
}

//--------------------------------------------------------------------
int GetHighTD(int P)
{
 int i=0,j=0;
 while (j<P)
   {
    i++;
    while(highs[i]==0)
      {i++;if(i>Bars-2)return(-1);}
    j++;
   }   
 return (i);         
}
//--------------------------------------------------------------------
int GetNextHighTD(int P)
{ 
 int i=P+1;
 while(highs[i]<=High[P]){i++;if(i>Bars-2)return(-1);}
 return (i);
}
//--------------------------------------------------------------------
int GetLowTD(int P)
{
 int i=0,j=0;
 while (j<P)
   {
    i++;
    while(lows[i]==0)
      {i++;if(i>Bars-2)return(-1);}
    j++;
   }   
 return (i); 
}
//--------------------------------------------------------------------
int GetNextLowTD(int P)
{
 int i=P+1;
 while(lows[i]>=Low[P] || lows[i]==0){i++;if(i>Bars-2)return(-1);}
 return (i);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   int      cnt, H1, H2, L1, L2, ii, pos, total, ticket;
   double   kH, kL, k, pp, tp, sl;
   
   //--------------------------------------------------------
   // The first 10 seconds of every 4 hours
   if (MathMod(Hour(),4)==0 && Minute()==0 && Seconds()<10)
   {
      //--------------------------------------------------------
      // Condition to modify ST
      // Whenever order profit reaches 40 pips, move SL to +10
      total=OrdersTotal();
      for(cnt=0;cnt<total;cnt++)
      {
         if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)==true)
         {
            if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())
            {
               if(OrderType()==OP_BUY && 
                  Bid-OrderOpenPrice()>=40*Point &&
                  OrderOpenPrice()-OrderStopLoss()>=0)
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+10*Point,OrderTakeProfit(),0);
                  continue;
               }
               if(OrderType()==OP_SELL &&
                  OrderOpenPrice()-Ask>=40*Point &&
                  OrderOpenPrice()-OrderStopLoss()<=0)
               {
                  OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-10*Point,OrderTakeProfit(),0);
                  continue;
               }
            }
         }
         else
            Print("OrderSelect returned the error of ",GetLastError());
      }
      
      
      // Where is the trend line?
      SetTDPoint(Bars-1);
      H1=GetHighTD(1);
      H2=GetNextHighTD(H1);
      L1=GetLowTD(1);
      L2=GetNextLowTD(L1);
      kH=(High[H2]-High[H1])/(H2-H1);
      kL=(Low[L1]-Low[L2])/(L2-L1);
      TrendLineBreakUp=High[H2]-kH*H2;
      TrendLineBreakUpPrev=High[H2]-kH*(H2-1);
      TrendLineBreakDown=Low[L2]+kL*L2;
      TrendLineBreakDownPrev=Low[L2]+kL*(L2-1);
      
      //Top trend line and bottom trend line both broken? Wait!
      if(Open[0]>TrendLineBreakUp && Open[0]<TrendLineBreakDown)
        // && H2<50 && L2<50)
      {
         total=OrdersTotal();
         for(cnt=0;cnt<total;cnt++)
         {
            if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)==true)
            {
               if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
               {
                  OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet);
                  continue;
               }
               
               if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
               {
                  OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet);
                  continue;
               }
            }
            else
               Print("OrderSelect returned the error of ",GetLastError());
         }
         ArrayInitialize(highs, 0.0);
         ArrayInitialize(lows, 0.0);
         return(0);
      }
      //Top trend line broken?
      /*if(Open[0]>TrendLineBreakUp && Open[0]>TrendLineBreakDown &&
         (Open[1]<TrendLineBreakUpPrev || Open[2]<TrendLineBreakUpPrev) &&
         H2<50 && L2<50)*/
      //if(Open[0]>TrendLineBreakUp &&
      //   (Open[1]<TrendLineBreakUpPrev || Open[2]<TrendLineBreakUpPrev))
      if(Open[0]>TrendLineBreakUp && Open[0]>TrendLineBreakDown &&
         (Open[1]<TrendLineBreakUpPrev || Open[2]<TrendLineBreakUpPrev))
      {
         //Print("Upper TrendLine Break ",Symbol()," ",Period()," ",Bid);
         if(AlertsOn) 
            Alert("UTL Break>",TrendLineBreakUp," on ",Symbol()," ",Period()," @ ",Ask); 
         //TrendLineBreakUpFlag=True;
         
         // Calculate profit projection, stop loss, take profit
         ii=Lowest(NULL,0,MODE_LOW,H2-1,1);    
         pp=High[H2]-kH*(H2-ii)-Low[ii];
         // Calculate TP and SL
         tp=pp-spread*Point+Open[0];
         if (pp>90*Point) 
            sl=Open[0]-spread*Point-MathRound(10000*pp*0.33)/10000;
         else
            sl=Open[0]-spread*Point-MathRound(10000*pp*0.5)/10000;
         
         // Short exists? Close it. Long exists? Change it.
         total=OrdersTotal();
         pos=0;
         for(cnt=0;cnt<total;cnt++)
         {
            if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)==true)
            {
               // Close the shorts
               if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
               {
                  OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet);
                  continue;
               }
               
               // Modify the longs
               if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
               {
                  pos++;
                  OrderModify(OrderTicket(),OrderOpenPrice(),sl,tp,0);
                  continue;
               }
            }
            else
               Print("OrderSelect returned the error of ",GetLastError());
         }
         
         // Long at the break of top trend line
         if (pos==0||MultiPositions)
         {
            ticket=OrderSend(Symbol(),OP_BUY,LotsPerTrade,Ask,3,sl,tp,"Mouteki",00011,0,Green);
            if(ticket>0)
            {
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
                  Print("Long order opened : ",OrderOpenPrice());
/*             
               Print("H1=", H1, " High[H1]=", High[H1]);
               Print("H2=", H2, " High[H2]=", High[H2]);
               Print("L1=", L1, " Low[L1]=", Low[L1]);
               Print("L2=", L2, " Low[L2]=", Low[L2]);
               Print("TrendLineBreakUp=", TrendLineBreakUp);
               Print("TrendLineBreakDown=", TrendLineBreakDown);
               Print("Open[0]=", Open[0], " Open[1]=", Open[1]);
*/
            }
            else Print("Error opening Long order : ",GetLastError()); 
         }
      }
      
      //Bottom trend line broken?
      /*if(Open[0]<TrendLineBreakDown && Open[0]<TrendLineBreakUp &&
         (Open[1]>TrendLineBreakDownPrev || Open[2]>TrendLineBreakDownPrev) &&
         H2<50 && L2<50)*/
      //if(Open[0]<TrendLineBreakDown &&
      //   (Open[1]>TrendLineBreakDownPrev || Open[2]>TrendLineBreakDownPrev))
      if(Open[0]<TrendLineBreakDown && Open[0]<TrendLineBreakUp &&
         (Open[1]>TrendLineBreakDownPrev || Open[2]>TrendLineBreakDownPrev))
      {
         //Print("Lower Trendline Break ",Symbol()," ",Period()," ",Bid);
         if(AlertsOn)
            Alert("LTL Break<",TrendLineBreakDown," on ",Symbol()," ",Period()," @ ",Bid); 
         //TrendLineBreakDownFlag=True;

         // Calculate profit projection, stop loss, take profit
         ii=Highest(NULL,0,MODE_HIGH,L2-1,1);    
         pp=High[ii]-(Low[L2]+kL*(L2-ii));
         // Calculate TP and SL
         tp=Open[0]-pp+spread*Point;
         if (pp>90*Point) 
            sl=Open[0]+spread*Point+MathRound(10000*pp*0.33)/10000;
         else
            sl=Open[0]+spread*Point+MathRound(10000*pp*0.5)/10000;
         
         // Long exists? Close it. Short exists? Change it.
         total=OrdersTotal();
         pos=0;
         for(cnt=0;cnt<total;cnt++)
         {
            if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)==true)
            {
               // Close the longs
               if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
               {
                  OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet);
                  continue;
               }
               
               // Modify the shorts
               if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
               {
                  pos++;
                  OrderModify(OrderTicket(),OrderOpenPrice(),sl,tp,0);
                  continue;
               }
            }
            else
               Print("OrderSelect returned the error of ",GetLastError());
         }
         
         // Short at the break of the bottom trend line
         if (pos==0||MultiPositions)
         {
            ticket=OrderSend(Symbol(),OP_SELL,LotsPerTrade,Bid,3,sl,tp,"Mouteki",00021,0,Red);
            if(ticket>0)
            {
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
                  Print("Short order opened : ",OrderOpenPrice());
/*                  
               Print("H1=", H1, " High[H1]=", High[H1]);
               Print("H2=", H2, " High[H2]=", High[H2]);
               Print("L1=", L1, " Low[L1]=", Low[L1]);
               Print("L2=", L2, " Low[L2]=", Low[L2]);
               Print("TrendLineBreakUp=", TrendLineBreakUp);
               Print("TrendLineBreakDown=", TrendLineBreakDown);
               Print("Open[0]=", Open[0], " Open[1]=", Open[1]);
*/
            }
            else Print("Error opening Long order : ",GetLastError()); 
         }
      }
      ArrayInitialize(highs, 0.0);
      ArrayInitialize(lows, 0.0);
   }
   
//----
   return(0);
  }
//+------------------------------------------------------------------+