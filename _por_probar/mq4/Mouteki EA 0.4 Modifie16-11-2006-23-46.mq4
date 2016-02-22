//+------------------------------------------------------------------+
//|                                       Mouteki EA 0.4 Modifié.mq4 |
//|                                  Copyright © 2006, GwadaTradeBoy |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, GwadaTradeBoy"
#property link      "http://www.metaquotes.net"


//-- Variables pour l'EA Mouteki --//
//#define MAGICMA  20050610
extern string nameEA       = "Mouteki";

extern bool    AlertsOn=True;
extern bool    MultiPositions=False;
extern int     ProfitToMoveSL=40;
extern int     PositiveSL=10;
extern int     SL_Offset=0;
extern int     TP_Offset=0;
//extern double  LotsPerTrade=1;
//extern bool    LondonOpen=True;
//extern bool    NewYorkOpen=True;
//extern bool    TokyoOpen=True;

int         spread;
bool        TD=False;/*Default is False. True setting draws up and down arrows instead of dots on TD Points creating more clutter.*/ 
int         BackSteps=0;/*Used to be extern int now just int. Leave at 0*/
int         ShowingSteps=1;/*Used to be extern int now just int.  Leave at 1*/
bool        FractalAsTD=False;/*Used to be extern bool now just bool.  Leave at False, otherwise Trend Lines based on Fractal Points not TD Points*/
 
double      TrendLineBreakUp=-1;//Line added.
double      TrendLineBreakUpPrev=-1;//Line added.
double      TrendLineBreakUpPrev1=-1;//Line added.
bool        TrendLineBreakUpFlag=False;//Line added.
double      TrendLineBreakDown=-1;//Line added.
double      TrendLineBreakDownPrev=-1;//Line added.
double      TrendLineBreakDownPrev1=-1;//Line added.
bool        TrendLineBreakDownFlag=False;//Line added.
bool        BothTLBroken=False;

//---- buffers
double highs[100000];
double lows[100000];

//-- Variables pour l'indic Mouteki --//
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
string Comm="";
//-- Variables pour l'optimisation des lots --//
extern double  Lots              = 0.1;
extern double  MaximumRisk       = 0.02;
extern double  DecreaseFactor    = 3;

//-- Variable pour l'optimisation de l'EA --//
bool isBuying = false;
bool isSelling = false;
bool isClosing = false;

//-- Variables pour le Signal 2 Stolastic --//

//+------------------------------------------------------------------+
//| Fonction d'initialisation de l'expert                            |
//+------------------------------------------------------------------+
int init()
   {
//-- Lecture du spread
      spread = MarketInfo(Symbol(),MODE_SPREAD);
//-- Initialisation indicateur Mouteki
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
//-- Desinitialisation indicateur Mouteki
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
//| Calculs preliminaires de l'expert                                |
//+------------------------------------------------------------------+

//--- Calcul de la taille optimale du lot ---//
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
                  if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==False) { Print("Erreur dans l historique!"); break; }
                  if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL) continue;
         //----
                  if(OrderProfit()>0) break;
                  if(OrderProfit()<0) losses++;
               }
            if(losses>1) lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
         }
/* Retour de la taille du lot */
      if(lot<0.1) lot=0.1;
      return(lot);
   }

//--- Calcul préliminaire à l'utilisation de Mouteki ---//  
/* Recherche des Hauts et des Bas dans le graph */
int SetTDPoint(int B)
   {
      int shift;
      if (FractalAsTD==False)
         {
            for (shift=B;shift>2;shift--)
               {       
        
/* Si le Haut de la barre de gauche et egale au Haut de la barre courante, le Haut de la barre courante est un Haut valide */
                  if (High[shift+2]<=High[shift] && High[shift+1]<=High[shift] && 
                  High[shift-1]<High[shift]  && High[shift-2]<High[shift])
                     highs[shift]=High[shift];
                  //if(shift<100 && highs[shift]!=0) Print("shift=", shift, " highs[shift]=", highs[shift]);
            
                  //else highs[shift]=0;
        
/* Si le Bas de la barre de gauche et egale au Bas de la barre courante, le Bas de la barre courante est un Bas valide */
                  if (Low[shift+2]>=Low[shift] && Low[shift+1]>=Low[shift] && 
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
                  else 
                     highs[shift]=0;    
                  if (Low[shift+1]>=Low[shift] && Low[shift-1]>Low[shift] && 
                  Low[shift+2]>=Low[shift] && Low[shift-2]>Low[shift])
                     lows[shift]=Low[shift];
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
                  i++;if(i>Bars-2)return(-1);
               }
            j++;
         }   
      return (i);         
   }
/* Sommet Haut 2 */
int GetNextHighTD(int P)
   { 
      int i=P+1;
      while(lows[i]<=High[P])
         {
            i++;if(i>Bars-2)return(-1);
         }
      return (i);
   }
/* Sommet Bas 1 */
int GetLowTD(int P)
   {
      int i=0,j=0;
      while (j<P)
         {
            i++;
            while(lows[i]==0)
               {
                  i++;if(i>Bars-2)return(-1);
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
            i++;if(i>Bars-2)return(-1);
         }
      return (i);
   }
//-- Dessin des Trend Lines 
//-- Trend Line du Haut
int TrendLineHighTD(int H1,int H2,int Step,int Col)
   {
      ObjectSet("HL_"+Step,OBJPROP_TIME1,Time[H2]);
      ObjectSet("HL_"+Step,OBJPROP_TIME2,Time[H1]);
      ObjectSet("HL_"+Step,OBJPROP_PRICE1,High[H2]);
      ObjectSet("HL_"+Step,OBJPROP_PRICE2,High[H1]);
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
      ObjectSet("LL_"+Step,OBJPROP_TIME1,Time[L2]);
      ObjectSet("LL_"+Step,OBJPROP_TIME2,Time[L1]);
      ObjectSet("LL_"+Step,OBJPROP_PRICE1,Low[L2]);
      ObjectSet("LL_"+Step,OBJPROP_PRICE2,Low[L1]);
      ObjectSet("LL_"+Step,OBJPROP_COLOR,LowerTrendLineColour);/*TEMP Original OBJPROP_COLOR,Col*/
      if (Step==1)
         ObjectSet("LL_"+Step,OBJPROP_WIDTH,TrendLineWidth);/*Original OBJPROP_WIDTH,2*/
      else 
         ObjectSet("LL_"+Step,OBJPROP_WIDTH,1);      
      return(0);
   }

//-- Dessin des Projections de Prix
//-- Projection Long
string TakeProfitHighTD(int H1,int H2,int Step,int Col)/*Draw Buy TD Price Projection(s)*/
   {
      int i,ii,j=0;
      string Comm="";
      double kH,HC1,HC2,HC3,k,St;
      kH=(High[H2]-High[H1])/(H2-H1);
      while (NormalizeDouble(Point,j)==0)j++; 
         k=0;
         for(i=H1;i>0;i--)
            if(Close[i]>High[H2]-kH*(H2-i)){k=High[H2]-kH*(H2-i);
               break;}
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
//-- Projection Short
string TakeProfitLowTD(int L1,int L2,int Step,int Col)/*Draw Sell TD Price Projection(s)*/
   {
      int i,ii,j=0;
      string Comm="";
      double kL,LC1,LC2,LC3,k,St;
      kL=(Low[L1]-Low[L2])/(L2-L1);
      while (NormalizeDouble(Point,j)==0)j++; 
         k=0;
         for(i=L1;i>0;i--)
            if(Close[i]<Low[L2]+kL*(L2-i))
               {k=Low[L2]+kL*(L2-i);
               break;}
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

string TDMain(int Step)
   {
      int H1,H2,L1,L2;
//      string Comm="---   step "+Step+"   --------------------\n";   
      int i,j; while (NormalizeDouble(Point,j)==0)j++;
      double Style;
      double Col[20];Col[0]=UpperProjectionLineColour/*Original Col[0]=Red, Colour for Current Upper TD Projection*/;Col[2]=Magenta;Col[4]=Chocolate;Col[6]=Goldenrod;Col[8]=SlateBlue;
                Col[1]=LowerProjectionLineColour/*Original Col[1]=Blue, Colour for Current Lower TD Projection*/;Col[3]=FireBrick;Col[5]=Green;Col[7]=MediumOrchid;Col[9]=CornflowerBlue;
                Col[10]=Red;Col[12]=Magenta;Col[14]=Chocolate;Col[16]=Goldenrod;Col[18]=SlateBlue;
                Col[11]=Blue;Col[13]=FireBrick;Col[15]=Green;Col[17]=MediumOrchid;Col[19]=CornflowerBlue;
      Step=Step+BackSteps;  
      H1=GetHighTD(Step);
      H2=GetNextHighTD(H1);
      L1=GetLowTD(Step);
      L2=GetNextLowTD(L1);
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
               } 
            else 
               ObjectDelete("HHL_"+Step);
            if (ProjectionLines==1)
               {
                  ObjectCreate("HC1_"+Step,OBJ_TREND,0,0,0,0,0);
                  ObjectCreate("HC2_"+Step,OBJ_TREND,0,0,0,0,0);
                  ObjectCreate("HC3_"+Step,OBJ_TREND,0,0,0,0,0);
                  //Comm=Comm+TakeProfitHighTD(H1,H2,Step,Col[Step*2-2]);
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
               } 
            else 
               ObjectDelete("HLL_"+Step);
            if (ProjectionLines==1)
               {
                  ObjectCreate("LC1_"+Step,OBJ_TREND,0,0,0,0,0);
                  ObjectCreate("LC2_"+Step,OBJ_TREND,0,0,0,0,0);
                  ObjectCreate("LC3_"+Step,OBJ_TREND,0,0,0,0,0);
                  //Comm=Comm+TakeProfitLowTD(L1,L2,Step,Col[Step*2-1]);
               }
            else
               {
                  ObjectDelete("LC1_"+Step);
                  ObjectDelete("LC2_"+Step);
                  ObjectDelete("LC3_"+Step);       
               }        
         }
   }

//** Fonction en test **
bool IsNewBar()
   {
      static datetime lastbar = 0;
      datetime curbar = Time[0];
      if(lastbar!= curbar)
         {
            lastbar=curbar;
            return (true);
         }
      else
         {
            return(false) ;
         }
   } 

//+------------------------------------------------------------------+
//| fonction de demarrage de l'expert                                |
//+------------------------------------------------------------------+
int start()
   {
//==============Indicateur Mouteki==============================
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
               Comm=Comm+"\nFractals";
            else 
               Comm=Comm+"\nTD point";
            if (Comments==1)
               Comment(Comm);
            else 
               Comment("");
         }
//==============EA Mouteki==============================
   int      cnt, H1, H2, L1, L2, ii, iii, pos, total, ticket;
   double   kH, kL, k, pp, tp, sl;
   
//--- Calcul du lancement du Trailing Stop ---//
// il faudrait amméliorer le trailing stop pour qu'il suive le mouvement de PositiveSL
//--Calcul
      total=OrdersTotal();
      for(cnt=0;cnt<total;cnt++)
         {
            if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)==True)
               {
                  if(OrderType()<=OP_SELL && OrderSymbol()==Symbol())
                     {
                        if(OrderType()==OP_BUY && Bid-OrderOpenPrice()>=ProfitToMoveSL*Point &&          
                        OrderOpenPrice()-OrderStopLoss()>=0)
                           {
                              OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+PositiveSL*Point,OrderTakeProfit(),0);
                              continue;
                           }
                        if(OrderType()==OP_SELL && OrderOpenPrice()-Ask>=ProfitToMoveSL*Point &&
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
      
      
//--- Les Trend Line ---//
//-- Où sont-elles?
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
      
//=====================SIGNAL1=======================
//-- Cassure des 2 Trend Line? Wait!
      if(Open[0]>TrendLineBreakUp && Open[0]<TrendLineBreakDown)
        // && H2<50 && L2<50)
         {
            BothTLBroken=True;
            ArrayInitialize(highs, 0.0);
            ArrayInitialize(lows, 0.0);
            return(0);
         }
//-- Cassure de la Trend Line du Haut ?
      //if(Open[0]<TrendLineBreakUp)
      if(Close[0]>TrendLineBreakUp && Open[0]<TrendLineBreakUp && TrendLineBreakUpFlag==False)
         {
            BothTLBroken=False;
            TrendLineBreakUpFlag=True;
            //Print("Upper TrendLine Break ",Symbol()," ",Period()," ",Bid);
            if(AlertsOn) 
               Alert("UTL Break>",TrendLineBreakUp," on ",Symbol()," ",Period()," @ ",Ask); 
         }
//-- Long à la cassure de la trend line ??
      if (pos==0||MultiPositions && Close[0]>TrendLineBreakUp)
         {
            Print("Ready to open a long trade");
//-- Ordre d'achat
            ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,sl,tp,"Mouteki",00011,0,Green);
            if(ticket>0)
               {
                  if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) 
                     {
                        Print("Long order opened : ",OrderOpenPrice());
//--Ordre passé réinitialisation des variables
                        ArrayInitialize(highs, 0.0);
                        ArrayInitialize(lows, 0.0);
                        TrendLineBreakUp = False;
                        isBuying = False;
                     }
                  else Print("Error opening Long order : ",GetLastError()); 
               }
         }
//-- Cassure de la Trend Line du Bas ? 
      //if(Open[0]<TrendLineBreakDown)
      if(Close[0]<TrendLineBreakDown && TrendLineBreakDownFlag==False)
         {
            
            BothTLBroken=False;
            TrendLineBreakDownFlag=True;
            //Print("Lower Trendline Break ",Symbol()," ",Period()," ",Bid);
            if(AlertsOn)
               Alert("LTL Break<",TrendLineBreakDown," on ",Symbol()," ",Period()," @ ",Bid); 
         }
//=====================SIGNAL2=======================

//==============Prise de Décision==============================
//--- Opération Horaire ---//
// Les 10 premières seconde de chaque bougie de 4H
   //if (MathMod(Hour(),4)==0 && Minute()==0 && Seconds()<10)
   if (IsNewBar())
      {
         //if (TrendLineBreakUpFlag == True && Open[0]>TrendLineBreakUp)
         if (TrendLineBreakUpFlag == True && Open[0]>TrendLineBreakUp && Close[-1]>TrendLineBreakUp)
            {
               isBuying = True;
            }
         //if (TrendLineBreakDownFlag == True && Open[0]<TrendLineBreakDown)
         if (TrendLineBreakDownFlag == True && Close[0]<TrendLineBreakDown)
            {
               isSelling = True;
            }
      }

//=====================Prise de position=======================
//-- Conditions d'achat 
          if(isBuying && !isSelling && !isClosing) 
            {  
//-- Calcul de la Projection de Prix 
/*
               int i,ii,j=0;
               double kH,HC1,HC2,HC3,k,St;
               kH=(High[H2]-High[H1])/(H2-H1);
               while (NormalizeDouble(Point,j)==0)j++; 
                  k=0;
                  for(i=H1;i>0;i--)
                     if(Close[i]>High[H2]-kH*(H2-i))
                        {k=High[H2]-kH*(H2-i);
                        break;}
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
*/   
// Il y a une couille à vérifier parce que jamais atteinte
               ii=Lowest(NULL,0,MODE_LOW,H2-1,1);
               iii=Lowest(NULL,0,MODE_LOW,H2-H1,H1);
               pp=MathMax(High[H2]-kH*(H2-ii)-Low[ii], High[H2]-kH*(H2-iii)-Low[iii]);
//-- Calcul du StopLoss et du Take Profit               
               tp=pp-spread*Point+Open[0]+TP_Offset*Point;
               if (pp>90*Point) 
                  sl=Open[0]-spread*Point-MathRound(10000*pp*0.33)/10000-SL_Offset*Point;
               else
                  sl=Open[0]-spread*Point-MathRound(10000*pp*0.5)/10000-SL_Offset*Point;
/*Ca pue les pieds la, il faudra dépatouiller tout ça */         
// Short exists? Close it. Long exists? Change it.
               total=OrdersTotal();
               pos=0;
               for(cnt=0;cnt<total;cnt++)
                  {
                     if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)==True)
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
               Print("pos=", pos, " MultiPositions=", MultiPositions);
// Long à la cassure de la Trend Line Haut
               if (pos==0||MultiPositions)
                  {
                     Print("Ready to open a long trade");
//-- Ordre d'achat
                     ticket=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,sl,tp,"Mouteki",00011,0,Green);
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
// Fin de la prise de position, réinitialisation des variables pour un autre tour
                              ArrayInitialize(highs, 0.0);
                              ArrayInitialize(lows, 0.0);
                              TrendLineBreakUp = False;
                              isBuying = False;
                        }
                     else Print("Error opening Long order : ",GetLastError()); 
                  }
//         }
      }
      
//-- Conditions de vente
         if(isSelling && !isBuying && !isClosing) 
            {  
//-- Calcul de la Projection de Prix 
//Revoir à partir de calcul de prix du haut
// Il y a une couille target jamais atteind
               ii=Highest(NULL,0,MODE_HIGH,L2-1,1);    
               iii=Highest(NULL,0,MODE_HIGH,L2-L1,L1);    
               pp=MathMax(High[ii]-(Low[L2]+kL*(L2-ii)), High[iii]-(Low[L2]+kL*(L2-iii)));
//-- Calcul du StopLoss et du Take Profit
               tp=Open[0]-pp+spread*Point-TP_Offset*Point;
               if (pp>90*Point) 
                  sl=Open[0]+spread*Point+MathRound(10000*pp*0.33)/10000+SL_Offset*Point;
               else
                  sl=Open[0]+spread*Point+MathRound(10000*pp*0.5)/10000+SL_Offset*Point;
/* ca re-pue des pieds */         
// Long exists? Close it. Short exists? Change it.
               total=OrdersTotal();
               pos=0;
               for(cnt=0;cnt<total;cnt++)
                  {
                     if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES)==True)
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

// Short à la cassure de la Trend Line Bas
            if (pos==0||MultiPositions)
               {
                  Print("Ready to open a short trade");
//-- Ordre de vente
                  ticket=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,sl,tp,"Mouteki",00021,0,Red);
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
// Fin de la prise de position, réinitialisation des variables pour un autre tour
                        ArrayInitialize(highs, 0.0);
                        ArrayInitialize(lows, 0.0);
                        TrendLineBreakDown = False;
                        isSelling = False;
                     }
                  else Print("Error opening Long order : ",GetLastError()); 
               }
         }

//-- Conditions de cloture
//         if(isClosing && !isSelling && !isBuying) 
//            {  


//            }

//      ArrayInitialize(highs, 0.0);
//      ArrayInitialize(lows, 0.0);
//         }
//      }

//----
   return(0);
   }
//+------------------------------------------------------------------+