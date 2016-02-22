//+------------------------------------------------------------------+
//|                                                        ADX-1.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------
//|                                                          ADX.mq4 
//|                                    Bheurekso - MojoFX conversion 
//|                                                fx.studiomojo.com 
//+------------------------------------------------------------------

#property copyright "Bheurekso - MojoFX conversion"
#property link      "fx.studiomojo.com"

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color2 Red
#property indicator_color1 Blue
#property indicator_color3 White
#property indicator_color4 Yellow

extern int DXperiod = 14;
extern bool displayADXR = false;
extern int Populasi = 0;

int prevbars,LoopAnjing;
bool Pertama = true;
double 
Tutup,TutupTadi,Atas,AtasTadi,Bawah,BawahTadi,TRtadi,TR,TRbaku,BedaAt
as,BedaBawah;
double 
PDMI,MDMI,PDItadi,PDIbaku,MDItadi,MDIbaku,PDI,MDI,DX,ADXtadi,ADX,ADXR
;
//---- buffers
double L1[];
double L2[];
double L3[];
double L4[];

//+------------------------------------------------------------------
+
//| Custom indicator initialization function                         
|
//+------------------------------------------------------------------
+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_LINE,0,1);
   SetIndexBuffer(0,L1);
   SetIndexStyle(1,DRAW_LINE,0,1);
   SetIndexBuffer(1,L2);
   SetIndexStyle(2,DRAW_LINE,0,2);
   SetIndexBuffer(2,L3);
   SetIndexStyle(3,DRAW_LINE,0,2);
   SetIndexBuffer(3,L4);
//----
   return(0);
  }
//+------------------------------------------------------------------
+
//| Custor indicator deinitialization function                       
|
//+------------------------------------------------------------------
+
int deinit()
  {
//---- 
   
//----
   return(0);
  }
//+------------------------------------------------------------------
+
//| Custom indicator iteration function                              
|
//+------------------------------------------------------------------
+
int start()
  {
   int    counted_bars=IndicatorCounted();
//---- 
   
   for (int shift=Bars-2*DXperiod; shift > 0; shift--) {

Tutup=Close[shift];
TutupTadi=Close[shift+1];
Atas=High[shift];
AtasTadi=High[shift+1];
Bawah=Low[shift];
BawahTadi=Low[shift+1];

TRtadi=TR;
TRbaku=MathMax(MathAbs(Atas-Bawah), MathMax(MathAbs(Atas-
TutupTadi),MathAbs(TutupTadi-Bawah)));
TR= TRbaku+TRtadi*(DXperiod-1)/DXperiod;
BedaAtas=Atas-AtasTadi;
BedaBawah=BawahTadi-Bawah;
if ((BedaAtas < 0 && BedaBawah < 0) || 
(BedaAtas==BedaBawah)) {PDMI=0;MDMI=0;}
if (BedaAtas > BedaBawah) {PDMI=BedaAtas;MDMI=0;}
if (BedaAtas < BedaBawah) {PDMI=0;MDMI = BedaBawah;}
PDItadi=PDIbaku;
MDItadi=MDIbaku;
PDIbaku= PDMI+PDItadi*(DXperiod-1)/DXperiod;
MDIbaku= MDMI+MDItadi*(DXperiod-1)/DXperiod;
PDI=100*PDIbaku/TR;
MDI=100*MDIbaku/TR;
DX=100*MathAbs(PDI-MDI)/(PDI+MDI);
ADXtadi=ADX;
ADX=(DX+(DXperiod-1)*ADXtadi)/DXperiod;
   ADXR=(ADX+L1[shift+Period()])/2;

L1[shift] = PDI;
L2[shift] = MDI;
L3[shift] = ADX;

if (displayADXR) { L4[shift] = ADXR; }  

}
//----
   return(0);
  }
//+------------------------------------------------------------------

