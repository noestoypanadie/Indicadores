//+------------------------------------------------------------------+
//|                                              Mouteki EA v0.4.mq4 |
//|                                    Copyright 2006, Hua Ai (aha)  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2006, Hua Ai (aha)"
#property link      ""

// Ver 0.4 Added parameters to control the mark hours the EA is allowed
//         to enter a trade.
//

// Ver 0.3 Fixed a minor bug causing problems on finding right point
//         for trend lines.
//
// Ver 0.2
// Modifications:
// 1. On a trend reversal, when the PP calculated based on the highs 
//    after the first point is smaller (consolidating) than that based 
//    on the highs between the first point and the 2nd point, use 
//    latter PP for calculating ST and TP.
// 2. When both TL are broken, only signal this special situation, not
//    to close any trades. When price break the Top TL again from that 
//    situation, close all the short trades and let the long trades
//    run. When price break the bottom TL again from that situation,
//    close all the long trades and let the short trades run.

// Ver 0.1
// Modifications:
// 1. Allow EA to enter a trade even 3 bars after TL breaks. This is
//    because sometimes we got whipsaw back below TL and then breaks
//    again, or sometimes, the break is not detectation by only 
//    checking the recent two bars.

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
//   1) Enter long when price open higher than the top trend line. The
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
//   1) Enter short when price open lower than the bottom trend line. 
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
// 1. When profit is greater than ProfitToMoveSL pips, move the SL to +PositiveSL.
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
//********** Variable EA **********//
//extern bool    AlertsOn=true;
extern bool    AlertsOn=False;
extern bool    MultiPositions=false;
extern int     ProfitToMoveSL=40;
extern int     PositiveSL=10;
extern int     SL_Offset=0;
extern int     TP_Offset=0;

int         spread;
bool        TD=False;/*Default is false. True setting draws up and down arrows instead of dots on TD Points creating more clutter.*/ 
int         BackSteps=0;/*Used to be extern int now just int. Leave at 0*/
int         ShowingSteps=1;/*Used to be extern int now just int.  Leave at 1*/
bool        FractalAsTD=false;/*Used to be extern bool now just bool.  Leave at false, otherwise Trend Lines based on Fractal Points not TD Points*/
//-- Trend Line Break Up
double      TrendLineBreakUp=-1;//Line added.
double      TrendLineBreakUpPrev=-1;//Line added.
double      TrendLineBreakUpPrev1=-1;//Line added.
bool        TrendLineBreakUpFlag=False;//Line added.
//-- Trend Line Break Down
double      TrendLineBreakDown=-1;//Line added.
double      TrendLineBreakDownPrev=-1;//Line added.
double      TrendLineBreakDownPrev1=-1;//Line added.
bool        TrendLineBreakDownFlag=False;//Line added.
//-- Trend Line Break Both
bool        BothTLBroken=false;

//---- buffers
double highs[100000];
double lows[100000];

//********** Variables Indic **********//
extern bool      Comments=true;/*Optional Comments.  Default is false. Orginal variable called "Commen"*/
extern bool      TrendLine=True;/*Default is true to draw current TD Lines*/
extern int       TrendLineStyle=STYLE_SOLID;/*STYLE>_SOLID=0,DASH=1,_DOT=2,_DASHDOT=3,_DASHDDOTDOT=4. Line of code added from original.*/
extern int       TrendLineWidth=1;/*Thinnest or allow dots and dashes = 0 or 1, Thinner=2, Medium=3,Thicker=4,Thickest=5.  Line of code added from original.*/
extern color     UpperTrendLineColour=LimeGreen;/*Line of code added from original.*/
extern color     LowerTrendLineColour=Red;/*Line of code added from original.*/
extern bool      ProjectionLines=True;/*Default is True.  These are the TD Price Projections. Original variable called "Take Prof"*/
extern int       ProjectionLinesStyle=STYLE_DOT;/*STYLE>_SOLID=0,DASH=1,_DOT=2,_DASHDOT=3,_DASHDDOTDOT=4. Line of code added from original.*/
extern int       ProjectionLinesWidth=1;/*Thinnest or allow dots and dashes = 0 or 1, Thinner=2, Medium=3,Thicker=4,Thickest=5.  Line of code added from original.*/
extern color     UpperProjectionLineColour=LimeGreen;/*Line of code added from original.*/
extern color     LowerProjectionLineColour=Red;/*Line of code added from original.*/
extern bool      HorizontLine=true;/*Default is false.  It seems the Horizontal Lines are were the code predicts price may cross TD line.*/

//********** Variables communes à l'EA et à l'Indic **********//
int      i, ii, iii, j=0;
int      H1, H2, L1, L2;
double   k,St, pp, tp, sl;
double   kH,HC1,HC2,HC3;
double   kL,LC1,LC2,LC3;
int      cnt, pos, total, ticket;
string   Comm="";

//********** Variables pour l'optimisation des lots **********//
extern double  Lots              = 0.1;
extern double  MaximumRisk       = 0.02;
extern double  DecreaseFactor    = 3;

//********** Variables pour le controle de la prise de trade **********//
int OpenTradesBuy, OpenTradesSell;
int      LongTradeTicket, ShortTradeTicket=0;
//bool     LongTradeTaken, ShortTradeTaken=False;
//+------------------------------------------------------------------+
//| Fonction d'initialisation de l'expert                            |
//+------------------------------------------------------------------+
int init()
   {
//---- Expert Advisor
      spread = MarketInfo(Symbol(),MODE_SPREAD);
//---- Indicateur
      SetIndexStyle(0,DRAW_ARROW);
      SetIndexArrow(0,217);
      SetIndexBuffer(0,highs);
      SetIndexEmptyValue(0,0.0);
      SetIndexStyle(1,DRAW_ARROW);
      SetIndexArrow(1,218);
      SetIndexBuffer(1,lows);
      SetIndexEmptyValue(1,0.0);
      for (int i=1;i<=10;i++)
         {
            ObjectDelete("HHL_"+i);ObjectDelete("HL_"+i);
            ObjectDelete("HLL_"+i);ObjectDelete("LL_"+i);
            ObjectDelete("HC1_"+i);
            ObjectDelete("HC2_"+i);
            ObjectDelete("HC3_"+i);
            ObjectDelete("LC1_"+i);
            ObjectDelete("LC2_"+i);
            ObjectDelete("LC3_"+i);
         }
      Comment(""); 
//----   
      return(0);
   }
//+------------------------------------------------------------------+
//| Fonction de desinitialisation de l'expert                        |
//+------------------------------------------------------------------+
int deinit()
   {
//---- Indicateur
      for (int i=1;i<=10;i++)
         {
            ObjectDelete("HHL_"+i);ObjectDelete("HL_"+i);
            ObjectDelete("HLL_"+i);ObjectDelete("LL_"+i);
            ObjectDelete("HC1_"+i);
            ObjectDelete("HC2_"+i);
            ObjectDelete("HC3_"+i);
            ObjectDelete("LC1_"+i);
            ObjectDelete("LC2_"+i);
            ObjectDelete("LC3_"+i);
         }
      Comment("");
//----
      return(0);
   }
//--------------------------------------------------------------------

//+------------------------------------------------------------------+
//| Calculs preliminaires de l'expert                                |
//+------------------------------------------------------------------+
//********** Calcul de la taille optimale du lot **********//
double LotsOptimized()
   {
      double lot=Lots;
      int    orders=HistoryTotal();     // Historique des ordres
      int    losses=0;                  // Nombre de trade perdants consécutif
/* Selection de la taille du lot */
      lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000,1);
/* Calcul du nombre de perte consecutive */
      if(DecreaseFactor>0)
         {
            for(int i=orders-1;i>=0;i--)
               {
                  if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==False) 
                     { 
                        Print("Erreur dans l historique!"); 
                        break; 
                     }
                  if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) 
                     continue;
         //----
                  if(OrderProfit()>0) 
                     break;
                  if(OrderProfit()<0) 
                     losses++;
               }
            if(losses>1) 
               lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
         }
/* Retour de la taille du lot */
      if(lot<0.1) 
         lot=0.1;
      return(lot);
   }

//********** Fonctions communes Expert et Indicateur **********//   
//---- Recherche des Hauts et Bas du graph courant ----//
int SetTDPoint(int B)
   {
      int shift;
      if (FractalAsTD==false)
         {
            for (shift=B;shift>2;shift--)
               {       
/* Si le Haut de la bougie de gauche et egale au Haut de la bougie courante, le Haut de la bougie courante est un Haut valide */
                  if (High[shift+2]<High[shift] && High[shift+1]<High[shift] && 
                  High[shift-1]<High[shift]  && High[shift-2]<High[shift])
                     {
                        highs[shift]=High[shift];
                     }
/*                  if(shift<100 && highs[shift]!=0) 
                     {
                        Print("shift=", shift, " highs[shift]=", highs[shift]);
                     }
                  else 
                     highs[shift]=0; */
/* Si le Bas de la bougie de gauche et egale au Bas de la bougie courante, le Bas de la bougie courante est un Bas valide */
                  if (Low[shift+2]>Low[shift] && Low[shift+1]>Low[shift] && 
                  Low[shift-1]>Low[shift]  && Low[shift-2]>Low[shift])
                     {
                        lows[shift]=Low[shift];
                     }
/*                  else 
                     lows[shift]=0; */
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
                     {
                        highs[shift]=High[shift];
                     }
                  else 
                     highs[shift]=0;    
                  if (Low[shift+1]>=Low[shift] && Low[shift-1]>Low[shift] && 
                  Low[shift+2]>=Low[shift] && Low[shift-2]>Low[shift])
                     {
                        lows[shift]=Low[shift];
                     }
                  else 
                     lows[shift]=0;    
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

//-- Choix des sommets pour tracer la TrendLine --//
/* Sommet Haut 1 */
int GetHighTD(int P)
   {
      int i=0,j=0;
      while (j<P)
         {
            i++;
            while(highs[i]==0)
               {
                  i++;
                  if(i>Bars-2)
                     return(-1);
               }
            j++;
         }   
      return (i);         
   }
/* Sommet Haut 2 */
int GetNextHighTD(int P)
   { 
      int i=P+1;
      while(highs[i]<=High[P])
         {
            i++;
            if(i>Bars-2)
               return(-1);
         }
      return (i);
   }
//--------------------------------------------------------------------
/* Sommet Bas 1 */
int GetLowTD(int P)
   {
      int i=0,j=0;
      while (j<P)
         {
            i++;
            while(lows[i]==0)
               {
                  i++;
                  if(i>Bars-2)
                     return(-1);
               }
            j++;
         }   
      return (i); 
   }
/* Sommet Bas 2 */
int GetNextLowTD(int P)
   {
      int i=P+1;
      while(lows[i]>=Low[P] || lows[i]==0)
         {
            i++;
            if(i>Bars-2)
               return(-1);
         }
      return (i);
   }
//--------------------------------------------------------------------

//********** Fonctions de dessin des Trend Lines **********//
//-- Trend Line du Haut
int TrendLineHighTD(int H1,int H2,int Step,int Col)/*Draw Upper Trend Line*/
   {
      ObjectSet("HL_"+Step,OBJPROP_TIME1,Time[H2]);ObjectSet("HL_"+Step,OBJPROP_TIME2,Time[H1]);
      ObjectSet("HL_"+Step,OBJPROP_PRICE1,High[H2]);ObjectSet("HL_"+Step,OBJPROP_PRICE2,High[H1]);
      ObjectSet("HL_"+Step,OBJPROP_COLOR,UpperTrendLineColour);/*TEMP Original OBJPROP_COLOR,Col*/
      if (Step==1)
         ObjectSet("HL_"+Step,OBJPROP_WIDTH,TrendLineWidth);/*Original OBJPROP_WIDTH,2*/
      else 
         ObjectSet("HL_"+Step,OBJPROP_WIDTH,1);
      return(0);
   }   
//-- Trend Line du Bas
int TrendLineLowTD(int L1,int L2,int Step,int Col)/*Draw Lower Trend Line*/
   {
      ObjectSet("LL_"+Step,OBJPROP_TIME1,Time[L2]);ObjectSet("LL_"+Step,OBJPROP_TIME2,Time[L1]);
      ObjectSet("LL_"+Step,OBJPROP_PRICE1,Low[L2]);ObjectSet("LL_"+Step,OBJPROP_PRICE2,Low[L1]);
      ObjectSet("LL_"+Step,OBJPROP_COLOR,LowerTrendLineColour);/*TEMP Original OBJPROP_COLOR,Col*/
      if (Step==1)
         ObjectSet("LL_"+Step,OBJPROP_WIDTH,TrendLineWidth);/*Original OBJPROP_WIDTH,2*/
      else 
         ObjectSet("LL_"+Step,OBJPROP_WIDTH,1);      
      return(0);
   }
//--------------------------------------------------------------------

// ********** Fonction de dessin des HorizontalLine **********//
//-- Horizontal Line du Haut
int HorizontLineHighTD(int H1,int H2,int Step,double St,int Col)
   {
      ObjectSet("HHL_"+Step,OBJPROP_PRICE1,High[H2]-(High[H2]-High[H1])/(H2-H1)*H2);//HORIZONTAL HIGH LINE HEIGHT CALCULATION
      ObjectSet("HHL_"+Step,OBJPROP_STYLE,St);
      ObjectSet("HHL_"+Step,OBJPROP_COLOR,Col);
      ObjectSet("HHL_"+Step,OBJPROP_BACK,True);//Line added
      return(0); 
   }   
//-- Horizontal Line du Bas
int HorizontLineLowTD(int L1,int L2,int Step,double St,int Col)
   {
      ObjectSet("HLL_"+Step,OBJPROP_PRICE1,Low[L2]+(Low[L1]-Low[L2])/(L2-L1)*L2);//HORIZONTAL LOW LINE HEIGHT CALCULATION
      ObjectSet("HLL_"+Step,OBJPROP_STYLE,St);
      ObjectSet("HLL_"+Step,OBJPROP_COLOR,Col);
      ObjectSet("HLL_"+Step,OBJPROP_BACK,True);//Line added
      return(0); 
   }
//--------------------------------------------------------------------

//********** Fonction de dessin des TakeProfit **********//
//-- TakeProfit Line du Haut
string TakeProfitHighTD(int H1,int H2,int Step,int Col)/*Draw Buy TD Price Projection(s)*/
   {
      kH=(High[H2]-High[H1])/(H2-H1);
      while (NormalizeDouble(Point,j)==0)
         {
            j++; 
            k=0;
            for(i=H1;i>0;i--)if(Close[i]>High[H2]-kH*(H2-i))
            {
               k=High[H2]-kH*(H2-i);
               break;
            }
            if (k>0)
               { 
                  Comm=Comm+"UTD_Line ("+DoubleToStr(High[H2]-kH*H2,j)+") broken at "+DoubleToStr(k,j)+", uptargets:\n";
                  ii=Lowest(NULL,0,MODE_LOW,H2-i,i);    
                  HC1=High[H2]-kH*(H2-ii)-Low[ii];
                  HC2=High[H2]-kH*(H2-ii)-Close[ii];
                  ii=Lowest(NULL,0,MODE_CLOSE,H2-i,i);
                  HC3=High[H2]-kH*(H2-ii)-Close[ii];
                  St=TrendLineStyle;/*Original STYLE_SOLID*/ 
               } 
            else
               {
                  k=High[H2]-kH*H2;
                  Comm=Comm+"UTD_Line ("+DoubleToStr(k,j)+"), probable break-up targets:\n";  
                  ii=Lowest(NULL,0,MODE_LOW,H2,0);    
                  HC1=High[H2]-kH*(H2-ii)-Low[ii];
                  HC2=High[H2]-kH*(H2-ii)-Close[ii];
                  ii=Lowest(NULL,0,MODE_CLOSE,H2,0);
                  HC3=High[H2]-kH*(H2-ii)-Close[ii];
                  St=TrendLineStyle;/*Original STYLE_DASHDOT*/ 
               }
            ObjectSet("HL_"+Step,OBJPROP_STYLE,St);  
            Comm=Comm+"T1="+DoubleToStr(HC1+k,j)+" ("+DoubleToStr(HC1/Point,0)+"pts.)\n";//changed "pts.)" to "pts.)\n"
            ObjectSet("HC1_"+Step,OBJPROP_TIME1,Time[H1]);ObjectSet("HC1_"+Step,OBJPROP_TIME2,Time[0]);
            ObjectSet("HC1_"+Step,OBJPROP_PRICE1,HC1+k);ObjectSet("HC1_"+Step,OBJPROP_PRICE2,HC1+k);
            ObjectSet("HC1_"+Step,OBJPROP_COLOR,Col);ObjectSet("HC1_"+Step,OBJPROP_STYLE,St);      
            if (Step==1)
               {
                  ObjectSet("HC1_"+Step,OBJPROP_WIDTH,ProjectionLinesWidth);/*Original OBJPROP_WIDTH,2*/
                  ObjectSet("HC1_"+Step,OBJPROP_STYLE,ProjectionLinesStyle);/*This Line of code added from original. TD Upper Projection Line Style*/
               } 
            else
               {
                  ObjectSet("HC1_"+Step,OBJPROP_WIDTH,2);
               }
            return(Comm);
      } 
   }
//-- TakeProfit Line du Bas
string TakeProfitLowTD(int L1,int L2,int Step,int Col)/*Draw Sell TD Price Projection(s)*/
   {
      kL=(Low[L1]-Low[L2])/(L2-L1);
      while (NormalizeDouble(Point,j)==0)
         {
            j++; 
            k=0;
            for(i=L1;i>0;i--)if(Close[i]<Low[L2]+kL*(L2-i))
               {
                  k=Low[L2]+kL*(L2-i);
                  break;
               }
            if (k>0)
               {
                  Comm=Comm+"LTD_Line ("+DoubleToStr(Low[L2]+kL*L2,j)+") broken at "+DoubleToStr(k,j)+", downtargets:\n";
                  ii=Highest(NULL,0,MODE_HIGH,L2-i,i);    
                  LC1=High[ii]-(Low[L2]+kL*(L2-ii));
                  LC2=Close[ii]-(Low[L2]+kL*(L2-ii));
                  i=Highest(NULL,0,MODE_CLOSE,L2-i,i);
                  LC3=Close[ii]-(Low[L2]+kL*(L2-ii));
                  St=TrendLineStyle;/*Original STYLE_SOLID*/ 
               } 
            else
               {
                  k=Low[L2]+kL*L2;
                  Comm=Comm+"LTD_Line ("+DoubleToStr(k,j)+"), probable downbreak targets:\n";        
                  ii=Highest(NULL,0,MODE_HIGH,L2,0);    
                  LC1=High[ii]-(Low[L2]+kL*(L2-ii));
                  LC2=Close[ii]-(Low[L2]+kL*(L2-ii));
                  ii=Highest(NULL,0,MODE_CLOSE,L2,0);
                  LC3=Close[ii]-(Low[L2]+kL*(L2-ii));
                  St=TrendLineStyle;/*Original STYLE_DASHDOT*/ 
               }
            ObjectSet("LL_"+Step,OBJPROP_STYLE,St);   
            Comm=Comm+"T1="+DoubleToStr(k-LC1,j)+" ("+DoubleToStr(LC1/Point,0)+"pts.)\n";//changed "pts.)" to "pts.)\n"
            ObjectSet("LC1_"+Step,OBJPROP_TIME1,Time[L1]);ObjectSet("LC1_"+Step,OBJPROP_TIME2,Time[0]);
            ObjectSet("LC1_"+Step,OBJPROP_PRICE1,k-LC1);ObjectSet("LC1_"+Step,OBJPROP_PRICE2,k-LC1);
            ObjectSet("LC1_"+Step,OBJPROP_COLOR,Col);ObjectSet("LC1_"+Step,OBJPROP_STYLE,St);      
            if (Step==1)
               {
                  ObjectSet("LC1_"+Step,OBJPROP_WIDTH,ProjectionLinesWidth);/*Original OBJPROP_WIDTH,2*/
                  ObjectSet("LC1_"+Step,OBJPROP_STYLE,ProjectionLinesStyle);/*This Line of code added from original. TD Lower Projection Line Style*/
               } 
            else
               {
                  ObjectSet("LC1_"+Step,OBJPROP_WIDTH,2);
               }
            return(Comm);
      }
   }
//--------------------------------------------------------------------

string TDMain(int Step)
   {
      string Comm="---   step "+Step+"   --------------------\n";   
      int i,j; 
      while (NormalizeDouble(Point,j)==0)
      {
         j++;
         double Style;
         double Col[20];
         Col[0]=UpperProjectionLineColour/*Original Col[0]=Red, Colour for Current Upper TD Projection*/;Col[2]=Magenta;Col[4]=Chocolate;Col[6]=Goldenrod;Col[8]=SlateBlue;
         Col[1]=LowerProjectionLineColour/*Original Col[1]=Blue, Colour for Current Lower TD Projection*/;Col[3]=FireBrick;Col[5]=Green;Col[7]=MediumOrchid;Col[9]=CornflowerBlue;
         Col[10]=Red;
         Col[12]=Magenta;
         Col[14]=Chocolate;
         Col[16]=Goldenrod;
         Col[18]=SlateBlue;
         Col[11]=Blue;
         Col[13]=FireBrick;
         Col[15]=Green;
         Col[17]=MediumOrchid;
         Col[19]=CornflowerBlue;
//-- Initialisation des Variable H et L         
         Step=Step+BackSteps;  
         H1=GetHighTD(Step);
         H2=GetNextHighTD(H1);
         L1=GetLowTD(Step);
         L2=GetNextLowTD(L1);
//-- Définition de TrendLineBreak         
         TrendLineBreakUp=High[H2]-(High[H2]-High[H1])/(H2-H1)*H2;//added line
         TrendLineBreakDown=Low[L2]+(Low[L1]-Low[L2])/(L2-L1)*L2;//added line
         if (H1<0)
            Comm=Comm+"UTD no TD up-point \n";
         else 
            if (H2<0)
               Comm=Comm+"UTD no TD point-upper then last one ("+DoubleToStr(High[H1],j)+")\n";
            else 
               Comm=Comm+"UTD "+DoubleToStr(High[H2],j)+"  "+DoubleToStr(High[H1],j)+"\n"; 
            if (L1<0)
               Comm=Comm+"LTD no TD down-point \n";
            else 
               if (L2<0)
                  Comm=Comm+"LTD no TD point-lower then last one ("+DoubleToStr(Low[L1],j)+")\n";   
               else 
                  Comm=Comm+"LTD  "+DoubleToStr(Low[L2],j)+"  "+DoubleToStr(Low[L1],j)+"\n";
//-----------------------------------------------------------------------------------
         if (Step==1)
            Style=STYLE_SOLID;
         else 
            Style=STYLE_DOT;
         if (H1>0 && H2>0)
            {
               if (TrendLine==1)
                  {
                     ObjectCreate("HL_"+Step,OBJ_TREND,0,0,0,0,0);
                     TrendLineHighTD(H1,H2,Step,Col[Step*2-2]);
                  } 
               else 
                     ObjectDelete("HL_"+Step);
               if (HorizontLine==1 && Step==1)
                  {
                     ObjectCreate("HHL_"+Step,OBJ_HLINE,0,0,0,0,0);
                     ObjectSet("HHL_"+Step,OBJPROP_BACK,True);//Line added
//-- Appel de la fonction
                     HorizontLineHighTD(H1,H2,Step,Style,Col[Step*2-2]);
                  } 
               else 
                     ObjectDelete("HHL_"+Step);
               if (ProjectionLines==1)
                  {
                     ObjectCreate("HC1_"+Step,OBJ_TREND,0,0,0,0,0);
                     ObjectCreate("HC2_"+Step,OBJ_TREND,0,0,0,0,0);
                     ObjectCreate("HC3_"+Step,OBJ_TREND,0,0,0,0,0);
//-- Appel de la fonction
                     Comm=Comm+TakeProfitHighTD(H1,H2,Step,Col[Step*2-2]);
                  }
               else
                  {
                     ObjectDelete("HC1_"+Step);
                     ObjectDelete("HC2_"+Step);
                     ObjectDelete("HC3_"+Step);   
                  }  
            }
//-----------------------------------------------------------------------------------   
         if (L1>0 && L2>0)
            {   
               if (TrendLine==1)
                  {
                     ObjectCreate("LL_"+Step,OBJ_TREND,0,0,0,0,0);
                     TrendLineLowTD(L1,L2,Step,Col[Step*2-1]);
                  }    
               else 
                     ObjectDelete("LL_"+Step);
               if (HorizontLine==1 && Step==1)
                  {
                     ObjectCreate("HLL_"+Step,OBJ_HLINE,0,0,0,0,0);
                     ObjectSet("HLL_"+Step,OBJPROP_BACK,True);//Line added
//-- Appel de la fonction
                     HorizontLineLowTD(L1,L2,Step,Style,Col[Step*2-1]);
                  } 
               else 
                     ObjectDelete("HLL_"+Step);
               if (ProjectionLines==1)
                  {
                     ObjectCreate("LC1_"+Step,OBJ_TREND,0,0,0,0,0);
                     ObjectCreate("LC2_"+Step,OBJ_TREND,0,0,0,0,0);
                     ObjectCreate("LC3_"+Step,OBJ_TREND,0,0,0,0,0);
//-- Appel de la fonction
                     Comm=Comm+TakeProfitLowTD(L1,L2,Step,Col[Step*2-1]);
                  }
               else
                  {
                     ObjectDelete("LC1_"+Step);
                     ObjectDelete("LC2_"+Step);
                     ObjectDelete("LC3_"+Step);       
                  }        
            }
//--------------------------------------------------------------------
         if(AlertsOn)//added this Alerts section
            {
               if(Close[0]>TrendLineBreakUp && TrendLineBreakUpFlag==False)
                  {
                     //Print("Upper TrendLine Break ",Symbol()," ",Period()," ",Bid);
                     Alert("UTL Break>",TrendLineBreakUp," on ",Symbol()," ",Period()," @ ",Bid); 
                     TrendLineBreakUpFlag=True;
                  }   
               if(Close[0]<TrendLineBreakDown && TrendLineBreakDownFlag==False)
                  {
                     //Print("Lower Trendline Break ",Symbol()," ",Period()," ",Bid);
                     Alert("LTL Break<",TrendLineBreakDown," on ",Symbol()," ",Period()," @ ",Bid); 
                     TrendLineBreakDownFlag=True;
                  }
//--------------------------------------------------------------------    
            }
         }          
      return(Comm);       
   }

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
   {
//********** Indicateur Mouteki **********//
      string Comm="";       
      SetTDPoint(Bars-1);
      if (TD==1)
         {
            SetIndexArrow(0,217);
            SetIndexArrow(1,218);
         }
      else
         {
            SetIndexArrow(0,160);
            SetIndexArrow(1,160);
         }   
      if (ShowingSteps>10)
         {
            Comment("ShowingSteps readings 0 - 10");  
            return(0);
         } 
      for (int i=1;i<=ShowingSteps;i++)
         {
            Comm=Comm+TDMain(i);
            Comm=Comm+"------------------------------------\nShowingSteps="+ShowingSteps+"\nBackSteps="+BackSteps;    
            if (FractalAsTD==true)
               {
                  Comm=Comm+"\nFractals";
               }
            else 
               {
                  Comm=Comm+"\nTD point";
               }
            if (Comments==1)
               {                
                  Comment(Comm);
               }
            else 
               {
                  Comment("");
               }
         }

//********** Expert Advisor Mouteki **********//
// The first 10 seconds of every 4 hours
      if (MathMod(Hour(),4)==0 && Minute()==0 && Seconds()<10)
         {
// Condition pour modifier le TrailingStop
// Whenever order profit reaches ProfitToMoveSL pips, move SL to +PositiveSL
            total=OrdersTotal();
            for(cnt=0;cnt<total;cnt++)
               {
                  if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)==true)
                     {
                        if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())
                           {
                              if(OrderType()==OP_BUY && 
                              Bid-OrderOpenPrice()>=ProfitToMoveSL*Point &&
                              OrderOpenPrice()-OrderStopLoss()>=0)
                                 {
                                    OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+PositiveSL*Point,OrderTakeProfit(),0);
                                    continue;
                                 }
                              if(OrderType()==OP_SELL &&
                              OrderOpenPrice()-Ask>=ProfitToMoveSL*Point &&
                              OrderOpenPrice()-OrderStopLoss()<=0)
                                 {
                                    OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-PositiveSL*Point,OrderTakeProfit(),0);
                                    continue;
                                 }
                           }
                     }   
                  else
                     Print("OrderSelect returned the error of ",GetLastError());
               }
                                                                                          
//--Ou sont les Trend Lines?
            SetTDPoint(Bars-1);
            H1=GetHighTD(1);
            H2=GetNextHighTD(H1);
            L1=GetLowTD(1);
            L2=GetNextLowTD(L1);
            kH=(High[H2]-High[H1])/(H2-H1);
            kL=(Low[L1]-Low[L2])/(L2-L1);
            TrendLineBreakUp=High[H2]-kH*H2;
            TrendLineBreakUpPrev=High[H2]-kH*(H2-1);
            TrendLineBreakUpPrev1=High[H2]-kH*(H2-2);
            TrendLineBreakDown=Low[L2]+kL*L2;
            TrendLineBreakDownPrev=Low[L2]+kL*(L2-1);
            TrendLineBreakDownPrev1=Low[L2]+kL*(L2-2);
                                                                                                   
//Top trend line and bottom trend line both broken? Wait!
            if(Open[0]>TrendLineBreakUp && Open[0]<TrendLineBreakDown)
            // && H2<50 && L2<50)
               {
                  BothTLBroken=true;
                  ArrayInitialize(highs, 0.0);
                  ArrayInitialize(lows, 0.0);
                  return(0);
               }
                                                                              
//Top trend line broken?
            /*if(Open[0]>TrendLineBreakUp && Open[0]>TrendLineBreakDown &&
            (Open[1]<TrendLineBreakUpPrev || Open[2]<TrendLineBreakUpPrev) &&
            H2<50 && L2<50)
            if(Open[0]>TrendLineBreakUp &&
            (Open[1]<TrendLineBreakUpPrev || Open[2]<TrendLineBreakUpPrev))*/
            if(
                        ( Open[0]>TrendLineBreakUp && Open[0]>TrendLineBreakDown && 
            (Open[1]<TrendLineBreakUpPrev||Open[2]<TrendLineBreakUpPrev1||
            Open[3]<TrendLineBreakUpPrev1) ) 
            || 
            (
            BothTLBroken==true && 
            Open[0]>TrendLineBreakUp && Open[0]>TrendLineBreakDown &&
            ( Open[1]<TrendLineBreakDownPrev||Open[2]<TrendLineBreakDownPrev1||
            Open[3]<TrendLineBreakDownPrev1)))//<-- ADDED 2
            /*if((//TrendLineBreakUpFlag==False && 
            Close[0]>TrendLineBreakUp && Close[0]>TrendLineBreakDown && (
            Close[1]<TrendLineBreakUpPrev||Close[2]<TrendLineBreakUpPrev1||
            Close[3]<TrendLineBreakUpPrev1)
            ) || (
            BothTLBroken==true && 
            Close[0]>TrendLineBreakUp && Close[0]>TrendLineBreakDown && (
            Close[1]<TrendLineBreakDownPrev||Close[2]<TrendLineBreakDownPrev1||
            Close[3]<TrendLineBreakDownPrev1)
            ))*/
               {
                  BothTLBroken=false;
                  //TrendLineBreakUpFlag=True;
                  if(AlertsOn) 
                     //Print("Upper TrendLine Break ",Symbol()," ",Period()," ",Bid);
                     Alert("UTL Break>",TrendLineBreakUp," on ",Symbol()," ",Period()," @ ",Ask); 
// Calculate profit projection
                  while (NormalizeDouble(Point,j)==0)
                     {
                        j++; 
                        k=0;
                        for(i=H1;i>0;i--)if(Close[i]>High[H2]-kH*(H2-i))
                           {
                              k=High[H2]-kH*(H2-i);
                              break;
                           }
                        if (k>0)
                           { 
                              ii=Lowest(NULL,0,MODE_LOW,H2-i,i);    
                              HC1=High[H2]-kH*(H2-ii)-Low[ii];
                              HC2=High[H2]-kH*(H2-ii)-Close[ii];
                              ii=Lowest(NULL,0,MODE_CLOSE,H2-i,i);
                              HC3=High[H2]-kH*(H2-ii)-Close[ii];
                           } 
                        else
                           {
                              k=High[H2]-kH*H2;
                              ii=Lowest(NULL,0,MODE_LOW,H2,0);    
                              HC1=High[H2]-kH*(H2-ii)-Low[ii];
                              HC2=High[H2]-kH*(H2-ii)-Close[ii];
                              ii=Lowest(NULL,0,MODE_CLOSE,H2,0);
                              HC3=High[H2]-kH*(H2-ii)-Close[ii];
                           }
                     }                  
                  pp=MathMax(HC1, HC2);
// Calculate TP and SL
                  tp=pp-spread*Point+Open[0]+TP_Offset*Point;
                  if (pp>90*Point) 
                     sl=Open[0]-spread*Point-MathRound(10000*pp*0.33)/10000-SL_Offset*Point;
                  else
                     sl=Open[0]-spread*Point-MathRound(10000*pp*0.5)/10000-SL_Offset*Point;
                                                                            
// Short exists? Close it. Long exists? Change it.
                  total=OrdersTotal();
                  pos=0;
                  for(cnt=0;cnt<total;cnt++)
                     {
                        if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)==true)
                           {
/*                                                         
// Close the shorts                                               
                              if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
                                 {
                                    OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet);
                                    continue;
                                 }
*/
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
                  //if (pos==0||MultiPositions)
                        //Print("Ready to open a trade");
                        
                       
                        PosCounterBuy();
                        
                  if (/*LongTradeTaken==False && */ OpenTradesBuy==0)
                     {
                        ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,sl,tp,"Mouteki",00011,0,Green);
                        if(ticket>0)
                           {
                              if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
                              Print("Long order opened : ",OrderOpenPrice());
                              LongTradeTicket=ticket;
                              //LongTradeTaken=True;
                              TrendLineBreakUpFlag=False;
                           }
                        else 
                           Print("Error opening Long order : ",GetLastError());
                     }
                  else
                     Print("Ordre déjà ouvert, ticket n° : ",ShortTradeTicket);
               }
                                                                              
//Bottom trend line broken?                                                                                 
            /*if(Open[0]<TrendLineBreakDown && Open[0]<TrendLineBreakUp &&
            (Open[1]>TrendLineBreakDownPrev || Open[2]>TrendLineBreakDownPrev) &&
            H2<50 && L2<50)
            if(Open[0]<TrendLineBreakDown &&
            (Open[1]>TrendLineBreakDownPrev || Open[2]>TrendLineBreakDownPrev)) */
            if(
            (Open[0]<TrendLineBreakDown && Open[0]<TrendLineBreakUp&&
            ( Open[1]>TrendLineBreakDownPrev||Open[2]>TrendLineBreakDownPrev1||
            Open[3]>TrendLineBreakDownPrev1)
            ) || 
            
            (
            BothTLBroken==true && 
            Open[0]<TrendLineBreakUp && Open[0]<TrendLineBreakDown&&(
            Open[1]>TrendLineBreakUpPrev||Open[2]>TrendLineBreakUpPrev1||
            Open[3]>TrendLineBreakUpPrev1)
            ))//<---ADDED 1
            /*if((//TrendLineBreakDownFlag==False && 
            Close[0]<TrendLineBreakDown && Close[0]<TrendLineBreakUp&&(
            Close[1]>TrendLineBreakDownPrev||Close[2]>TrendLineBreakDownPrev1||
            Close[3]>TrendLineBreakDownPrev1)
            ) || (
            BothTLBroken==true && 
            Close[0]<TrendLineBreakUp && Close[0]<TrendLineBreakDown&&(
            Close[1]>TrendLineBreakUpPrev||Close[2]>TrendLineBreakUpPrev1||
            Close[3]>TrendLineBreakUpPrev1)
            ))*/
               {
                  BothTLBroken=false;
                  TrendLineBreakDownFlag=True;
                  if(AlertsOn)
                     Alert("LTL Break<",TrendLineBreakDown," on ",Symbol()," ",Period()," @ ",Bid); 
                     //Print("Lower Trendline Break ",Symbol()," ",Period()," ",Bid);
// Calculate profit projection                           
                  while (NormalizeDouble(Point,j)==0)
                     {
                        j++; 
                        k=0;
                        for(i=L1;i>0;i--)
                           if(Close[i]<Low[L2]+kL*(L2-i))
                              {
                                 k=Low[L2]+kL*(L2-i);
                                 break;   
                              }
                           if (k>0)
                              {
                                 ii=Highest(NULL,0,MODE_HIGH,L2-i,i);    
                                 LC1=High[ii]-(Low[L2]+kL*(L2-ii));
                                 LC2=Close[ii]-(Low[L2]+kL*(L2-ii));
                                 i=Highest(NULL,0,MODE_CLOSE,L2-i,i);
                                 LC3=Close[ii]-(Low[L2]+kL*(L2-ii));
                              } 
                           else
                              {
                                 k=Low[L2]+kL*L2;
                                 ii=Highest(NULL,0,MODE_HIGH,L2,0);    
                                 LC1=High[ii]-(Low[L2]+kL*(L2-ii));
                                 LC2=Close[ii]-(Low[L2]+kL*(L2-ii));
                                 ii=Highest(NULL,0,MODE_CLOSE,L2,0);
                                 LC3=Close[ii]-(Low[L2]+kL*(L2-ii));
                              }
                     }
                  pp=MathMax(LC1, LC2);
// Calculate TP and SL                                      
                  tp=Open[0]-pp+spread*Point-TP_Offset*Point;
                  if (pp>90*Point) 
                     sl=Open[0]+spread*Point+MathRound(10000*pp*0.33)/10000+SL_Offset*Point;
                  else
                     sl=Open[0]+spread*Point+MathRound(10000*pp*0.5)/10000+SL_Offset*Point;         

// Long exists? Close it. Short exists? Change it.
                  total=OrdersTotal();
                  pos=0;
                  for(cnt=0;cnt<total;cnt++)
                     {
                        if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)==true)
                           {
/*                                                 
// Close the longs                                       
                              if(OrderType()==OP_BUY && OrderSymbol()==Symbol())
                                 {
                                    OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet);
                                    continue;
                                 }
*/                                                               
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
               //if (pos==0||MultiPositions)
               PosCounterSell();
               if (/*ShortTradeTaken==False*/OpenTradesSell==0)
                  {
                     ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,sl,tp,"Mouteki",00021,0,Red);
                     if(ticket>0)
                        {
                           if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
                              Print("Short order opened : ",OrderOpenPrice());
                              ShortTradeTicket=ticket;
                              //ShortTradeTaken=True;
                              TrendLineBreakDownFlag=False;
                        }
                     else 
                        Print("Error opening Short order : ",GetLastError()); 
                  }
               else
                  Print("Ordre déjà ouvert, ticket n° : ",ShortTradeTicket);
               }
         }
//----
            ArrayInitialize(highs, 0.0);
            ArrayInitialize(lows, 0.0);
//         }
//----
      return(0);
   }
/*)*/ //<----TOOK THIS ONE OUT//+------------------------------------------------------------------+
void PosCounterBuy() 
{ OpenTradesBuy=0;
for ( cnt=OrdersTotal( )-1; cnt>=0; cnt--)
{ OrderSelect( cnt, SELECT_BY_POS, MODE_TRADES) ; 
if (OrderSymbol( )==Symbol( ) && OrderType()==OP_BUY )
OpenTradesBuy++ ;
}
}

void PosCounterSell() 
{ OpenTradesSell=0;
for ( cnt=OrdersTotal( )-1; cnt>=0; cnt--)
{ OrderSelect( cnt, SELECT_BY_POS, MODE_TRADES) ; 
if (OrderSymbol( )==Symbol( ) && OrderType()==OP_SELL)
OpenTradesSell++ ;
}
}