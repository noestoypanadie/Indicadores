//+------------------------------------------------------------------+
//|                                                        Sidus.mq4 |
//|                                  Copyright © 2006, GwadaTradeBoy |
//|                                            racooni_1975@yahoo.fr |
//|                                                                  |
//+------------------------------------------------------------------+
//| * Conditions d'entrée :                                          |
//| Le signal réel de la prise de position est quand les deux bords  |
//| du  tunnel rouge se croisent!!                                   |
//|                                                                  |
//|   - Buy : WMA5 passe au-dessus de WMA8 vers le haut, et ils      |
//|           passent au-dessus du tunnel rouge (EMA18 et EMA28)     |
//|   - Sell : WMA5 plonge sous WMA8, et ils plongent sous le tunnel |
//|            rouge (EMA18 et EMA28)                                |
//|                                                                  |
//| * Conditions de sortie :                                         |
//| Fermez toujours votre position quand les bords du tunnel rouge   |
//| se croisent ou quand ils deviennent si étroits qu'ils se         |
//| confondent!                                                      |
//|                                                                  |
//|   - Buy : WMA5 plonge sous WMA8, et le prix a atteint un sommet  |
//|   - Sell : WMA5 passe au-dessus de WMA8, et le prix a atteint un |
//|            bas                                                   |
//|                                                                  |
//| * Recomandations :                                               |
//| Quand lors d'un trade WMA5 et WMA8 croisent le tunnel rouge      |
//| Prête l'attention! Tant que les bords du tunnel rouge ne se      |
//| croisent pas, il n'y a aucun problème, mais souvent c'est un     |
//| signe que ça arrive!                                             |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, GwadaTradeBoy"
#property link      "racooni_1975@yahoo.fr"

//----Section #property
#property indicator_buffers 6
#property indicator_color1 Red
#property indicator_color2 Red
#property indicator_color3 Aqua
#property indicator_color4 Yellow
#property indicator_color5 Green
#property indicator_color6 Red

//---- Indicateurs
double         EMA18, EMA28, WMA5, WMA8, tuncross;
double         EMA18Current, EMA18Previous, EMA28Current, EMA28Previous;
double         WMA5Current, WMA5Previous, WMA8Current, WMA8Previous;
extern double  digit=0;
int            nShift,limit,i,j;
//---- buffers
double ExtMapBuffer1[];    //EMA18
double ExtMapBuffer2[];    //EMA28
double ExtMapBuffer3[];    //WMA5
double ExtMapBuffer4[];    //WMA8
double ExtMapBuffer5[];    //Fleche Haut
double ExtMapBuffer6[];    //Fleche Bas

//---- Money Management
extern double  Lots              = 0.1;
extern double  MaximumRisk       = 0.02;
extern double  DecreaseFactor    = 3;

//---- Prise de position
extern int     MagicEA           = 221206;
extern string  NameEA            = "Sidus.mq4";
extern double  StopLoss          = 15;
extern int     Slippage          = 3;
extern color   clOpenBuy         = Blue;
extern color   clCloseBuy        = Aqua;
extern color   clOpenSell        = Red;
extern color   clCloseSell       = Violet;
extern color   clModiBuy         = Blue;
extern color   clModiSell        = Red;
extern double  TrailingStop      = 15;
int            spread;
double         ldStop;
bool           isBuying = false, isSelling = false, isBuyClosing = false, isSellClosing = false;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
   {
//---- indicators
//---- Styles et couleur des Lignes
      SetIndexStyle(0,DRAW_LINE);
      SetIndexBuffer(0,ExtMapBuffer1);
      SetIndexStyle(1,DRAW_LINE);
      SetIndexBuffer(1,ExtMapBuffer2);
      SetIndexStyle(2,DRAW_LINE);
      SetIndexBuffer(2,ExtMapBuffer3);
      SetIndexStyle(3,DRAW_LINE);
      SetIndexBuffer(3,ExtMapBuffer4);
      SetIndexStyle(3,DRAW_LINE);
//---- Styles et couleur des Fleches      
      SetIndexStyle(4, DRAW_ARROW, 0, 2);    // Fleche vers le haut
      SetIndexArrow(4, 233);
      SetIndexBuffer(4, ExtMapBuffer5);
      SetIndexStyle(5, DRAW_ARROW, 0, 2);    // Fleche vers le bas
      SetIndexArrow(5, 234);
      SetIndexBuffer(5, ExtMapBuffer6);
//----       
      switch(Period())
         {
            case     1: nShift = 1;   break;
            case     5: nShift = 3;   break;
            case    15: nShift = 5;   break;
            case    30: nShift = 10;  break;
            case    60: nShift = 15;  break;
            case   240: nShift = 20;  break;
            case  1440: nShift = 80;  break;
            case 10080: nShift = 100; break;
            case 43200: nShift = 200; break;
         }
//---- Expert Advisor
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
//+------------------------------------------------------------------+

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
   
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
   {
//---- Trailing Stop                        
//---- Calculs des positions ouvertes
      int total = OrdersTotal();
//----
      for(int i = 0; i < total; i++) 
         {
            OrderSelect(i, SELECT_BY_POS, MODE_TRADES); 
//---- Tri par paire et par Numero d'EA
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicEA) 
               {
                  int prevticket = OrderTicket();
//---- Buy                                        
                  if(OrderType() == OP_BUY)
                     {
                        TrailingPositionsBuy(TrailingStop);
                     }
//---- Sell                                        
                  if(OrderType() == OP_SELL)
                     {
                        TrailingPositionsSell(TrailingStop);
                     }
                  
                  
                  return(0);           
               }
         }
//----
      int    counted_bars=IndicatorCounted();
//----
      if(counted_bars<0) 
         return(-1);
      if(counted_bars>0) 
         counted_bars--;
      limit=Bars-counted_bars;
   
      for(i=0; i<limit; i++)
         {
            EMA18Current=iMA(NULL,0,18,0,MODE_EMA,PRICE_CLOSE,i);
            EMA18Previous=iMA(NULL,0,18,0,MODE_EMA,PRICE_CLOSE,i+1);
            ExtMapBuffer1[i]=EMA18Current;
            EMA28Current=iMA(NULL,0,28,0,MODE_EMA,PRICE_CLOSE,i);
            EMA28Previous=iMA(NULL,0,28,0,MODE_EMA,PRICE_CLOSE,i+1);
            ExtMapBuffer2[i]=EMA28Current;
            WMA5Current=iMA(NULL,0,5,0,MODE_LWMA,PRICE_CLOSE,i);
            WMA5Previous=iMA(NULL,0,5,0,MODE_LWMA,PRICE_CLOSE,i+1);
            ExtMapBuffer3[i]=WMA5Current;
            WMA8Current=iMA(NULL,0,8,0,MODE_LWMA,PRICE_CLOSE,i);
            WMA8Previous=iMA(NULL,0,8,0,MODE_LWMA,PRICE_CLOSE,i+1);
            ExtMapBuffer4[i]=WMA8Current;
//---- Dessin des fleches et entré en trade
//---- Buy
            if((WMA5Current > WMA8Current+  digit*Point )&&(WMA5Previous<=WMA8Previous))  // Croisement WMA5 et WMA8, Lot = 10% de LotsOptimized()
               {
                  ExtMapBuffer5[i] = Low[i] - nShift*Point;
                  OrderSend(Symbol(),OP_BUY,(LotsOptimized()*0.1),Ask,Slippage,15,0,NameEA,MagicEA,0,clOpenBuy);
               }
            if((WMA8Current > EMA28Current+ digit*Point) && ( WMA8Previous <= EMA28Current))  // Croisement WMA8  up bord supérieur du tunnel
               {
                  ExtMapBuffer5[i] = Low[i] - nShift*Point;
                  OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,Slippage,15,0,NameEA,MagicEA,0,clOpenBuy);
               }

//---- Sell
            //if((WMA8Current > WMA5Current+ digit*Point) && (WMA8Previous <= WMA5Previous))
            if((WMA8Current > WMA5Current+  digit*Point )&&(WMA8Previous<=WMA5Previous))  // Croisement WMA5 et WMA8, Lot = 10% de LotsOptimized()
               {
                  ExtMapBuffer6[i] = High[i] + nShift*Point;
                  OrderSend(Symbol(),OP_SELL,(LotsOptimized()*0.1),Bid,Slippage,15,0,NameEA,MagicEA,0,clOpenSell);            
               }
            if((EMA28Current > WMA8Current+ digit*Point) && ( WMA8Previous >= EMA28Current))  // Croisement WMA8  down bord inférieur du tunnel
               {
                  ExtMapBuffer6[i] = High[i] + nShift*Point;
                  //ldStop = Open[0]+spread*Point+StopLoss*Point; 
                  OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,Slippage,15,0,NameEA,MagicEA,0,clOpenSell);
               }

         }               
//----
      return(0);
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Section des void                                                 |
//+------------------------------------------------------------------+

void TrailingPositionsBuy(int TrailingStop) 
   { 
      for (int i=0; i<OrdersTotal(); i++) 
         { 
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
               { 
                  if (OrderSymbol()==Symbol() && OrderMagicNumber() == MagicEA) 
                     { 
                        if (OrderType()==OP_BUY) 
                           { 
                              if (Bid-OrderOpenPrice()>TrailingStop) 
                                 { 
                                    if (OrderStopLoss()<Bid-TrailingStop) 
                                       {
                                          ModifyStopLoss(Bid-TrailingStop); 
                                       }
                                 } 
                           } 
                     } 
               } 
         } 
   } 

void TrailingPositionsSell(int TrailingStop) 
   { 
      for (int i=0; i<OrdersTotal(); i++) 
         { 
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
               { 
                  if (OrderSymbol()==Symbol() && OrderMagicNumber() == MagicEA) 
                     { 
                        if (OrderType()==OP_SELL) 
                           { 
                              if (OrderOpenPrice()-Ask>TrailingStop) 
                                 { 
                                    if (OrderStopLoss()>Ask+TrailingStop 
                                    || OrderStopLoss()==0)  
                                       {
                                          ModifyStopLoss(Ask+TrailingStop); 
                                       }
                                 } 
                           } 
                     } 
               } 
         } 
   } 

void ModifyStopLoss(double ldStopLoss) 
   { 
      bool fm;
      fm = OrderModify(OrderTicket(),OrderOpenPrice(),ldStopLoss,OrderTakeProfit(),0,CLR_NONE); 
   } 
/*
void CloseBuyPositions()
   { 
      for (int i=0; i<OrdersTotal(); i++) 
         { 
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
               { 
                  if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) 
                     { 
                        if (OrderType()==OP_BUY) 
                           OrderClose(OrderTicket(),Lots,Bid,Slippage);
                     } 
               } 
         } 
   } 

void CloseSellPositions()
   { 
      for (int i=0; i<OrdersTotal(); i++) 
         { 
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
               { 
                  if (OrderSymbol()==Symbol() && OrderMagicNumber() == magicEA) 
                     { 
                        if (OrderType()==OP_SELL) 
                           OrderClose(OrderTicket(),Lots,Ask,Slippage);
                     } 
               } 
         } 
    }
*/