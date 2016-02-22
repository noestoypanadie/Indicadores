#property  copyright "ANG3110@latchess.com"
//----------------at_DItpm3-------------------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 SkyBlue
#property indicator_color2 Silver
//----------------------------------
extern double hr=4;
extern int s=20;
extern int Days=11;

//----------------------------------
double ci[],bi[],at[],a0[];
int pt,cb;
//================================================
int init(){
   IndicatorBuffers(4);
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(0,at);
   SetIndexBuffer(1,a0);
   IndicatorShortName("ANG");
   SetIndexBuffer(2,ci);
   SetIndexBuffer(3,bi);
pt=hr*60/Period();
cb=MathFloor(Days*1440/Period()/pt)*pt;   
   return(0);}
//================================================
int start() {
int cbi,aa,bb,cc;
//----------------------------
cbi=Bars-IndicatorCounted()-2;
if (cbi>=0) {
//------------------------
//for (i=cb; i>=0; i--)
for (int m=cb; m>=s; m--) {
for (int i=0; i<=cb; i=i+pt) {
if (m==0) {
ci[i+pt]=(Open[i]+Open[i+pt]+Open[i+2*pt])/3; 
ci[0]=Open[0]; ci[cb+2*pt]=Open[cb+2*pt]; }
if (m>0 && m<s) {
bi[i+pt]=(ci[i]+ci[i+pt]+ci[i+2*pt])/3; 
bi[0]=(ci[0]+ci[pt])/2;  
bi[cb+2*pt]=ci[cb+2*pt];
if (i==cb) ArrayCopy(ci,bi,0,0,cb+2*pt);}
if (m==s) { aa=i; bb=i+pt; cc=i+2*pt;
for (int n=i; n<=cc; n++)  {
ci[n]=ci[aa]*((n-bb)*(n-cc))/((aa-bb)*(aa-cc))
+ci[bb]*((n-aa)*(n-cc))/((bb-aa)*(bb-cc))
+ci[cc]*((n-aa)*(n-bb))/((cc-aa)*(cc-bb));}
}}}
for (i=cb; i>=0; i--) {
at[i]=ci[i]-ci[i+pt]; 
a0[i]=0.00000001;}
}
//-----------------------
return(0);
  }
//+------------------------------------------------------------------+