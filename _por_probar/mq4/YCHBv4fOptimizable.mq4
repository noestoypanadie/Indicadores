//+------------------------------------------------------------------+
//|                                           YCHBv4fOptimizable.mq4 |
//|                   Copyright © 2006, David W Honeywell 11/01/2006 |
//|             DavidHoneywell800@msn.com  transport.david@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, David W Honeywell 11/01/2006"
#property link      "DavidHoneywell800@msn.com  transport.david@gmail.com"

#include <stdlib.mqh>
#include <stderror.mqh> 

/* Terms = "Use At Your Own Risk , Author Is Not Responsible For Losses , Profits Or Mental Anguish" .*/
extern int    IAcceptTerms         =    1; // Default=0

extern double Lots                 = 0.50;
extern int    ShowComments         =    1; // 1 = Yes  ,  0 = No .

int    Magic_Num            =   13;

//- Set User Values ------------------------------------------------------------------------------------------------------

/* Adjust These Values To Your Liking Below These Explainations .
--------------------------------------------------------------------------------------------------------------------------
FrstSessHour          The Chart Hour You Want The Orders To Be Set And/Or Modified
SecondSessHour        The Chart Hour You Want The Orders To Be Set And/Or Modified
--------------------------------------------------------------------------------------------------------------------------
MaxProfit             TakeProfit Amount (pips)
MaxLoss               StopLoss Amount (pips)
--------------------------------------------------------------------------------------------------------------------------
PeriodsLookback       Chart Periods back to monitor HH/LL
--------------------------------------------------------------------------------------------------------------------------
CnclPndngIfActvTrd    Set this to 1 if you want pending order cancelled after 1 pending becomes active
--------------------------------------------------------------------------------------------------------------------------
DeleteOrderAfterMnts  Set this to 1 if you want the orders deleted using DltAftr_Mnts
                      Set to 0 if you do Not want to delete orders after (n) minutes (DltAftr_Mnts)
DltAftr_Mnts          Delete Pending Orders After This Many Minutes
--------------------------------------------------------------------------------------------------------------------------
AdjustToBreakeven     Set this to 1 if you want to adjust stop to breakeven after (n) pips profit
                      Set to 0 if you do Not want to adjust stop to breakeven after (n) pips profit
Adj2B.E.Aftr_Pips     Adjust StopLoss to breakeven after this many pips profit
AdjustToB.E.Plus      Adjust StopLoss to this many pips in profit
--------------------------------------------------------------------------------------------------------------------------
DynamicProfit         Set this to 1 if you want to use the ATR as a TakeProfit
ProfitAtrPrds         ATR Periods to use for the Atr TakeProfit (DynamicProfit)
FactorProf            Multiple of the ATR reading to calculate the final TakeProfit (DynamicProfit) amount
--------------------------------------------------------------------------------------------------------------------------
AtrTrailing           Set this to 1 if you want to use the ATR TrailingStop
                      Set to 0 if you do not want to use the ATR TrailingStop
                      When Set to 0 , the TrailingStop will Default to a standard TrailingStop
AtrPeriods            Atr Periods to calculate the ATR TrailingStop
TrailAt_TimesATR      Multiple of the ATR reading to calculate the final TrailingStop amount
--------------------------------------------------------------------------------------------------------------------------
                      If AtrTrailing is 0 , this TrailingStop amount Will Be Used
StandardTrailAmt      Set this as you would for a standard TrailingStop
--------------------------------------------------------------------------------------------------------------------------
*/

extern int    FrstSessHour         =    1,
              SecondSessHour       =   15,
              
              MaxProfit            =  130,
              MaxLoss              =  100,
              
              PeriodsLookback      =   11,
              
              CnclPndngIfActvTrd   =    0,
              
              DeleteOrderAfterMnts =    0,
              DltAftr_Mnts         =    0,
              
              AdjustToBreakeven    =    0,
              Adj2B.E.Aftr_Pips    =    0,
              AdjustToB.E.Plus     =    0,
              
              DynamicProfit        =    0,
              ProfitAtrPrds        =    0;
extern double FactorProf           =  0.0;

extern int    AtrTrailing          =    1,
              AtrPeriods           =   4;
extern double TrailAt_TimesATR     =  3.0;

extern int    StandardTrailAmt     =   40;

double spread,buystop,sellstop,pips,stops,allow,byok,slok,deleteall,
       aa,ab,ac,ad,ae,af,ag,ah,ai,aj,ak,al,am,ao,ap,aq,ar,as,au,av,
       ba,bb,bc,bd,be,bf,bg,bh,bi,bj,bk,bl,bm,bo,bp,bq,br,bs,bu,bv,
       ca,cb,cc,cd,ce,cf,cg,ch,ci,cj,ck,cl,cm,co,cp,cq,cr,cs,cu,cv,
       da,db,dc,dd,de,df,dg,dh,di,dj,dk,dl,dm,do,dp,dq,dr,ds,du,dv,
       ea,eb,ec,ed,ee,ef,eg,eh,ei,ej,ek,el,em,eo,ep,eq,er,es,eu,ev,
       fa,fb,fc,fd,fe,ff,fg,fh,fi,fj,fk,fl,fm,fo,fp,fq,fr,fs,fu,fv,
       ga,gb,gc,gd,ge,gf,gg,gh,gi,gj,gk,gl,gm,go,gp,gq,gr,gs,gu,gv,
       ha,hb,hc,hd,he,hf,hg,hh,hi,hj,hk,hl,hm,ho,hp,hq,hr,hs,hu,hv,
       ja,jb,jc,jd,je,jf,jg,jh,ji,jj,jk,jl,jm,jo,jp,jq,jr,js,ju,jv,
       ka,kb,kc,kd,ke,kf,kg,kh,ki,kj,kk,kl,km,ko,kp,kq,kr,ks,ku,kv,
       hidiff,lowdiff,rdhidiff,rdlwdiff;

int LastBuystopTicket,LastSellstopTicket;

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
//----

if (IAcceptTerms == 0) return(0);
if (IAcceptTerms != 0)
{

//- Comment Check and prevent this expert from removing comments applied by other experts or indicators ------------------

double CheckComments, first = true;

if (CheckComments != (Time[0] + ShowComments)) { first = true; CheckComments = Time[0] + ShowComments; }
if (first == true && ShowComments == 0) { Comment(""); CheckComments = Time[0] + ShowComments; first = false; }
if (first == true && ShowComments == 1) { CheckComments = Time[0] + ShowComments; first = false; }

//- Check for open trades and pending orders per symbol ------------------------------------------------------------------

int cnt, LastBuyTicket = 0, LastSellTicket = 0, buyorderticket = 0, sellorderticket = 0;
double  opentrades = 0, bought = 0, sold = 0, buyorder = 0, sellorder = 0;
int ATimeToKill = 1;

for(cnt = 0; cnt < OrdersTotal(); cnt++)
 {
   OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
  if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Num)
   { opentrades++;
   }
  if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Num && OrderType()==OP_BUY)
   { bought++; LastBuyTicket = OrderTicket();
   }
  if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Num && OrderType()==OP_SELL)
   { sold++; LastSellTicket = OrderTicket();
   }
  if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Num && OrderType()==OP_BUYSTOP)
   { buyorder++; byok = 10; buyorderticket = OrderTicket();
   }
  if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic_Num && OrderType()==OP_SELLSTOP)
   { sellorder++; slok = 10; sellorderticket = OrderTicket();
   }
 }

//- Reset allow , deleteall ----------------------------------------------------------------------------------------------

if ( allow != Time[0] && (Hour() == FrstSessHour || Hour() == SecondSessHour) )
 {
   deleteall =      10;
   byok      =     -10;
   slok      =     -10;
   allow     = Time[0];
 }

//- Reset deleteall , byok , slok ----------------------------------------------------------------------------------------

if ( buyorder == 0 && sellorder == 0 )
 {
   deleteall = -10;
 }

//- Set Variable Values --------------------------------------------------------------------------------------------------

aa=MathAbs(High[101]-High[100]);ab=MathAbs(High[100]-High[99]);ac=MathAbs(High[99]-High[98]);ad=MathAbs(High[98]-High[97]);ae=MathAbs(High[97]-High[96]);
af=MathAbs(High[96]-High[95]);ag=MathAbs(High[95]-High[94]);ah=MathAbs(High[94]-High[93]);ai=MathAbs(High[93]-High[92]);aj=MathAbs(High[92]-High[91]);
ak=MathAbs(High[91]-High[90]);al=MathAbs(High[90]-High[89]);am=MathAbs(High[89]-High[88]);ao=MathAbs(High[88]-High[87]);ap=MathAbs(High[87]-High[86]);
aq=MathAbs(High[86]-High[85]);ar=MathAbs(High[85]-High[84]);as=MathAbs(High[84]-High[83]);au=MathAbs(High[83]-High[82]);av=MathAbs(High[82]-High[81]);

ba=MathAbs(High[81]-High[80]);bb=MathAbs(High[80]-High[79]);bc=MathAbs(High[79]-High[78]);bd=MathAbs(High[78]-High[77]);be=MathAbs(High[77]-High[76]);
bf=MathAbs(High[76]-High[75]);bg=MathAbs(High[75]-High[74]);bh=MathAbs(High[74]-High[73]);bi=MathAbs(High[73]-High[72]);bj=MathAbs(High[72]-High[71]);
bk=MathAbs(High[71]-High[70]);bl=MathAbs(High[70]-High[69]);bm=MathAbs(High[69]-High[68]);bo=MathAbs(High[68]-High[67]);bp=MathAbs(High[67]-High[66]);
bq=MathAbs(High[66]-High[65]);br=MathAbs(High[65]-High[64]);bs=MathAbs(High[64]-High[63]);bu=MathAbs(High[63]-High[62]);bv=MathAbs(High[62]-High[61]);

ca=MathAbs(High[61]-High[60]);cb=MathAbs(High[60]-High[59]);cc=MathAbs(High[59]-High[58]);cd=MathAbs(High[58]-High[57]);ce=MathAbs(High[57]-High[56]);
cf=MathAbs(High[56]-High[55]);cg=MathAbs(High[55]-High[54]);ch=MathAbs(High[54]-High[53]);ci=MathAbs(High[53]-High[52]);cj=MathAbs(High[52]-High[51]);
ck=MathAbs(High[51]-High[50]);cl=MathAbs(High[50]-High[49]);cm=MathAbs(High[49]-High[48]);co=MathAbs(High[48]-High[47]);cp=MathAbs(High[47]-High[46]);
cq=MathAbs(High[46]-High[45]);cr=MathAbs(High[45]-High[44]);cs=MathAbs(High[44]-High[43]);cu=MathAbs(High[43]-High[42]);cv=MathAbs(High[42]-High[41]);

da=MathAbs(High[41]-High[40]);db=MathAbs(High[40]-High[39]);dc=MathAbs(High[39]-High[38]);dd=MathAbs(High[38]-High[37]);de=MathAbs(High[37]-High[36]);
df=MathAbs(High[36]-High[35]);dg=MathAbs(High[35]-High[34]);dh=MathAbs(High[34]-High[33]);di=MathAbs(High[33]-High[32]);dj=MathAbs(High[32]-High[31]);
dk=MathAbs(High[31]-High[30]);dl=MathAbs(High[30]-High[29]);dm=MathAbs(High[29]-High[28]);do=MathAbs(High[28]-High[27]);dp=MathAbs(High[27]-High[26]);
dq=MathAbs(High[26]-High[25]);dr=MathAbs(High[25]-High[24]);ds=MathAbs(High[24]-High[23]);du=MathAbs(High[23]-High[22]);dv=MathAbs(High[22]-High[21]);

ea=MathAbs(High[21]-High[20]);eb=MathAbs(High[20]-High[19]);ec=MathAbs(High[19]-High[18]);ed=MathAbs(High[18]-High[17]);ee=MathAbs(High[17]-High[16]);
ef=MathAbs(High[16]-High[15]);eg=MathAbs(High[15]-High[14]);eh=MathAbs(High[14]-High[13]);ei=MathAbs(High[13]-High[12]);ej=MathAbs(High[12]-High[11]);
ek=MathAbs(High[11]-High[10]);el=MathAbs(High[10]-High[9]);em=MathAbs(High[9]-High[8]);eo=MathAbs(High[8]-High[7]);ep=MathAbs(High[7]-High[6]);
eq=MathAbs(High[6]-High[5]);er=MathAbs(High[5]-High[4]);es=MathAbs(High[4]-High[3]);eu=MathAbs(High[3]-High[2]);ev=MathAbs(High[2]-High[1]);

fa=MathAbs(Low[101]-Low[100]);fb=MathAbs(Low[100]-Low[99]);fc=MathAbs(Low[99]-Low[98]);fd=MathAbs(Low[98]-Low[97]);fe=MathAbs(Low[97]-Low[96]);
ff=MathAbs(Low[96]-Low[95]);fg=MathAbs(Low[95]-Low[94]);fh=MathAbs(Low[94]-Low[93]);fi=MathAbs(Low[93]-Low[92]);fj=MathAbs(Low[92]-Low[91]);
fk=MathAbs(Low[91]-Low[90]);fl=MathAbs(Low[90]-Low[89]);fm=MathAbs(Low[89]-Low[88]);fo=MathAbs(Low[88]-Low[87]);fp=MathAbs(Low[87]-Low[86]);
fq=MathAbs(Low[86]-Low[85]);fr=MathAbs(Low[85]-Low[84]);fs=MathAbs(Low[84]-Low[83]);fu=MathAbs(Low[83]-Low[82]);fv=MathAbs(Low[82]-Low[81]);

ga=MathAbs(Low[81]-Low[80]);gb=MathAbs(Low[80]-Low[79]);gc=MathAbs(Low[79]-Low[78]);gd=MathAbs(Low[78]-Low[77]);ge=MathAbs(Low[77]-Low[76]);
gf=MathAbs(Low[76]-Low[75]);gg=MathAbs(Low[75]-Low[74]);gh=MathAbs(Low[74]-Low[73]);gi=MathAbs(Low[73]-Low[72]);gj=MathAbs(Low[72]-Low[71]);
gk=MathAbs(Low[71]-Low[70]);gl=MathAbs(Low[70]-Low[69]);gm=MathAbs(Low[69]-Low[68]);go=MathAbs(Low[68]-Low[67]);gp=MathAbs(Low[67]-Low[66]);
gq=MathAbs(Low[66]-Low[65]);gr=MathAbs(Low[65]-Low[64]);gs=MathAbs(Low[64]-Low[63]);gu=MathAbs(Low[63]-Low[62]);gv=MathAbs(Low[62]-Low[61]);

ha=MathAbs(Low[61]-Low[60]);hb=MathAbs(Low[60]-Low[59]);hc=MathAbs(Low[59]-Low[58]);hd=MathAbs(Low[58]-Low[57]);he=MathAbs(Low[57]-Low[56]);
hf=MathAbs(Low[56]-Low[55]);hg=MathAbs(Low[55]-Low[54]);hh=MathAbs(Low[54]-Low[53]);hi=MathAbs(Low[53]-Low[52]);hj=MathAbs(Low[52]-Low[51]);
hk=MathAbs(Low[51]-Low[50]);hl=MathAbs(Low[50]-Low[49]);hm=MathAbs(Low[49]-Low[48]);ho=MathAbs(Low[48]-Low[47]);hp=MathAbs(Low[47]-Low[46]);
hq=MathAbs(Low[46]-Low[45]);hr=MathAbs(Low[45]-Low[44]);hs=MathAbs(Low[44]-Low[43]);hu=MathAbs(Low[43]-Low[42]);hv=MathAbs(Low[42]-Low[41]);

ja=MathAbs(Low[41]-Low[40]);jb=MathAbs(Low[40]-Low[39]);jc=MathAbs(Low[39]-Low[38]);jd=MathAbs(Low[38]-Low[37]);je=MathAbs(Low[37]-Low[36]);
jf=MathAbs(Low[36]-Low[35]);jg=MathAbs(Low[35]-Low[34]);jh=MathAbs(Low[34]-Low[33]);ji=MathAbs(Low[33]-Low[32]);jj=MathAbs(Low[32]-Low[31]);
jk=MathAbs(Low[31]-Low[30]);jl=MathAbs(Low[30]-Low[29]);jm=MathAbs(Low[29]-Low[28]);jo=MathAbs(Low[28]-Low[27]);jp=MathAbs(Low[27]-Low[26]);
jq=MathAbs(Low[26]-Low[25]);jr=MathAbs(Low[25]-Low[24]);js=MathAbs(Low[24]-Low[23]);ju=MathAbs(Low[23]-Low[22]);jv=MathAbs(Low[22]-Low[21]);

ka=MathAbs(Low[21]-Low[20]);kb=MathAbs(Low[20]-Low[19]);kc=MathAbs(Low[19]-Low[18]);kd=MathAbs(Low[18]-Low[17]);ke=MathAbs(Low[17]-Low[16]);
kf=MathAbs(Low[16]-Low[15]);kg=MathAbs(Low[15]-Low[14]);kh=MathAbs(Low[14]-Low[13]);ki=MathAbs(Low[13]-Low[12]);kj=MathAbs(Low[12]-Low[11]);
kk=MathAbs(Low[11]-Low[10]);kl=MathAbs(Low[10]-Low[9]);km=MathAbs(Low[9]-Low[8]);ko=MathAbs(Low[8]-Low[7]);kp=MathAbs(Low[7]-Low[6]);
kq=MathAbs(Low[6]-Low[5]);kr=MathAbs(Low[5]-Low[4]);ks=MathAbs(Low[4]-Low[3]);ku=MathAbs(Low[3]-Low[2]);kv=MathAbs(Low[2]-Low[1]);

//----------------------------------

hidiff=(aa+ab+ac+ad+ae+af+ag+ah+ai+aj+ak+al+am+ao+ap+aq+ar+as+au+av+
ba+bb+bc+bd+be+bf+bg+bh+bi+bj+bk+bl+bm+bo+bp+bq+br+bs+bu+bv+
ca+cb+cc+cd+ce+cf+cg+ch+ci+cj+ck+cl+cm+co+cp+cq+cr+cs+cu+cv+
da+db+dc+dd+de+df+dg+dh+di+dj+dk+dl+dm+do+dp+dq+dr+ds+du+dv+
ea+eb+ec+ed+ee+ef+eg+eh+ei+ej+ek+el+em+eo+ep+eq+er+es+eu+ev)/100;

lowdiff=(fa+fb+fc+fd+fe+ff+fg+fh+fi+fj+fk+fl+fm+fo+fp+fq+fr+fs+fu+fv+
ga+gb+gc+gd+ge+gf+gg+gh+gi+gj+gk+gl+gm+go+gp+gr+gs+gu+gv+
ha+hb+hc+hd+he+hf+hg+hh+hi+hj+hk+hl+hm+ho+hp+hr+hs+hu+hv+
ja+jb+jc+jd+je+jf+jg+jh+ji+jj+jk+jl+jm+jo+jp+jq+jr+js+ju+jv+
ka+kb+kc+kd+ke+kf+kg+kh+ki+kj+kk+kl+km+ko+kp+kq+kr+ks+ku+kv)/100;

rdhidiff = (MathRound(hidiff/Point))*Point;

rdlwdiff = (MathRound(lowdiff/Point))*Point;

spread   = (MathRound((Ask-Bid)/Point))*Point;

buystop  = (((MathRound((High[Highest(Symbol(),0,MODE_HIGH,PeriodsLookback,1)])/Point))*Point)+(rdhidiff))+spread+spread;
sellstop = (((MathRound((Low[Lowest(Symbol(),0,MODE_LOW,PeriodsLookback,1)])/Point))*Point)-(rdlwdiff))-spread;

pips     = (MathRound((iATR(Symbol(),0,ProfitAtrPrds,0)*FactorProf)/Point))*Point;
stops    = (MathRound((iATR(Symbol(),0,AtrPeriods,0)*TrailAt_TimesATR)/Point))*Point;

//- Place Comments on Chart Window ---------------------------------------------------------------------------------------

if (ShowComments != 0 &&
    (Minute()==0 || Minute()==2 || Minute()==4 || Minute()==6 || Minute()==8 ||
     Minute()==10 || Minute()==12 || Minute()==14 || Minute()==16 || Minute()==18 ||
     Minute()==20 || Minute()==22 || Minute()==24 || Minute()==26 || Minute()==28 ||
     Minute()==30 || Minute()==32 || Minute()==34 || Minute()==36 || Minute()==38 ||
     Minute()==40 || Minute()==42 || Minute()==44 || Minute()==46 || Minute()==48 ||
     Minute()==50 || Minute()==52 || Minute()==54 || Minute()==56 || Minute()==58) )
 { Comment("\n","  Chart Hour:  =  ",Hour()," ,  FrstSessHour:  =  ",FrstSessHour," ,  SecondSessHour:  =  ",SecondSessHour,
           "\n",
           "\n","  deleteall:  =  ",deleteall," ,  byok:  =  ",byok," ,  slok:  =  ",slok,
           "\n","  Symbol:  =  ",Symbol()," ,  MaxProfit:  =  ",MaxProfit," ,  MaxLoss:  =  ",MaxLoss,
           "\n","  Open Buys:  =  ",bought," ,  Open Sells:  =  ",sold,
           "\n","  Buy Stops:  =  ",buyorder," ,  Sell Stops:  =  ",sellorder,
           "\n","  All Positions:  =  ",opentrades,
           "\n",
           "\n","  PeriodsLookback:  =  ",PeriodsLookback,
           "\n","  Spread:  =  ",spread,
           "\n","  rdhidiff:  =  ",rdhidiff," ,  rdlwdiff:  =  ",rdlwdiff,
           "\n",
           "\n","  BuyStop ( Highest High of PeriodsLookback + Spread + rdhidiff + Spread) :  =  ",buystop,
           "\n","  SellStop  ( Lowest Low  of PeriodsLookback  - Spread  - rdlwdiff ) :  =  ",sellstop);
 }
if (ShowComments != 0 &&
    (Minute()==1 || Minute()==3 || Minute()==5 || Minute()==7 || Minute()==9 ||
     Minute()==11 || Minute()==13 || Minute()==15 || Minute()==17 || Minute()==19 ||
     Minute()==21 || Minute()==23 || Minute()==25 || Minute()==27 || Minute()==29 ||
     Minute()==31 || Minute()==33 || Minute()==35 || Minute()==37 || Minute()==39 ||
     Minute()==41 || Minute()==43 || Minute()==45 || Minute()==47 || Minute()==49 ||
     Minute()==51 || Minute()==53 || Minute()==55 || Minute()==57 || Minute()==59) )
 { Comment("\n","  CnclPndngIfActvTrd:  =  ",CnclPndngIfActvTrd,
           "\n",
           "\n","  DeleteOrderAfterMnts:  =  ",DeleteOrderAfterMnts,"  DltAftr_Mnts:  =  ",DltAftr_Mnts,
           "\n",
           "\n","  AdjustToBreakeven:  =  ",AdjustToBreakeven," ,  Adj2B.E.Aftr_Pips:  =  ",Adj2B.E.Aftr_Pips," ,  AdjustToB.E.Plus:  =  ",AdjustToB.E.Plus,
           "\n",
           "\n","  DynamicProfit:  =  ",DynamicProfit,
           "\n","  ProfitAtrPrds:  =  ",ProfitAtrPrds," ,  FactorProf:  =  ",FactorProf,
           "\n","  ATR Profit Amount:  =  ",pips,
           "\n",
           "\n","  AtrTrailing:  =  ",AtrTrailing,
           "\n","  AtrPeriods:  =  ",AtrPeriods," ,  TrailAt_TimesATR:  =  ",TrailAt_TimesATR,
           "\n","  Atr TrailingStop Amount:  =  ",stops,
           "\n",
           "\n","  StandardTrailAmt:  =  ",StandardTrailAmt);
 }

//- Delete Previous Pending Orders ---------------------------------------------------------------------------------------

if (deleteall > 0)
 {
  for(cnt = 0; cnt < OrdersTotal(); cnt++)
   {
     OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if ( Hour() == FrstSessHour || Hour() == SecondSessHour )
     {
      if ( OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Num && ( OrderType()==OP_SELLSTOP || OrderType()==OP_BUYSTOP ) )
       {
         byok = -10;
         slok = -10;
         OrderDelete(OrderTicket());
         Print("Deleted Order For New Session Trade  ",Symbol());
         return(0);
       }
     }
   }
 }

//- If pending order becomes active Set Flag to delete opposing stop order -----------------------------------------------

if (CnclPndngIfActvTrd==0) { ATimeToKill = 0; LastBuystopTicket = 0; LastSellstopTicket = 0; }

if (CnclPndngIfActvTrd != 0 && buyorder > 0 && sellorder > 0)
 { ATimeToKill = 1; byok = 10; slok = 10;
  for(cnt = 0; cnt < OrdersTotal(); cnt++)
   {
     OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if (OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Num)
     {
      if ( OrderType()==OP_BUYSTOP )  LastBuystopTicket = OrderTicket();
      if ( OrderType()==OP_SELLSTOP ) LastSellstopTicket = OrderTicket();
     }
   }
 }

//- If CnclPndngIfActvTrd==1 and active LastBuystopTicket and LastSellstopTicket , Delete Opposing Stop Order ------------

if (ATimeToKill != 0)
 {
  for(cnt = 0; cnt < OrdersTotal(); cnt++)
   {
     OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if (OrderSymbol()==Symbol() && OrderType()==OP_BUYSTOP && OrderMagicNumber()==Magic_Num)
     {
      if (LastSellstopTicket != sellorderticket && LastBuystopTicket == buyorderticket)
       {
         OrderDelete(LastBuystopTicket);
         ATimeToKill = 1;
         byok = 10;
         Print("Deleted Due To Active Sell Order  ",Symbol());
         return(0);
       }
     }
    if (OrderSymbol()==Symbol() && OrderType()==OP_SELLSTOP && OrderMagicNumber()==Magic_Num)
     {
      if (LastSellstopTicket == sellorderticket && LastBuystopTicket != buyorderticket)
       {
         OrderDelete(LastSellstopTicket);
         ATimeToKill = 1;
         slok = 10;
         Print("Deleted Due To Active Buy Order  ",Symbol());
         return(0);
       }
     }
   }
 }

//- Delete Pending Orders when DltAftr_Mnts has elapsed ------------------------------------------------------------------

if (DeleteOrderAfterMnts != 0)
 {
  for(cnt = 0; cnt < OrdersTotal(); cnt++)
   {
     OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if (OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Num)
     {
      if (OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP)
       {
        if (CurTime()-OrderOpenTime()>(DltAftr_Mnts*60) )
         {
           OrderDelete(OrderTicket());
           byok = 10; slok = 10;
           Print("Delete after minutes  ",Symbol());
           return(0);
         }
       }
     }
   }
 }

//- Set BuyStop and SellStop ---------------------------------------------------------------------------------------------

int ticket = -1;

if ( Hour() == FrstSessHour || Hour() == SecondSessHour )
 {
  if ( buyorder == 0 && byok <= 0 && deleteall < 0 )
   {
     ticket = OrderSend(Symbol(),OP_BUYSTOP,Lots,buystop,0,buystop-MaxLoss*Point,buystop+MaxProfit*Point,"YCHBv4f",Magic_Num,0,Lime);
     Print("New Session BuyStop  ",Symbol());
    if(ticket<0)
     {
       Print("OrderSend failed with error #",GetLastError());
     }
    return(0);
   }
  if ( sellorder == 0 && slok <= 0 && deleteall < 0 )
   {
     ticket = OrderSend(Symbol(),OP_SELLSTOP,Lots,sellstop,0,sellstop+MaxLoss*Point,sellstop-MaxProfit*Point,"YCHBv4f",Magic_Num,0,Red);
     Print("New Session SellStop  ",Symbol());
    if(ticket<0)
     {
       Print("OrderSend failed with error #",GetLastError());
     }
    return(0);
   }
 }

//- Adjust StopLoss to breakeven if in profit more than Adj2B.E.Aftr_Pips ------------------------------------------------

if (AdjustToBreakeven != 0)
 {
  for(cnt = 0; cnt < OrdersTotal(); cnt++)
   {
     OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if (OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Num && OrderType()==OP_BUY)
     {
      if ( OrderStopLoss() < OrderOpenPrice()-1*Point && OrderClosePrice()-OrderOpenPrice() > Adj2B.E.Aftr_Pips*Point )
       {
         OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+AdjustToB.E.Plus*Point,OrderTakeProfit(),0,Magenta);
         Print("Adjusted To Breakeven  ",Symbol());
         return(0);
       }
     }
    if (OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Num && OrderType()==OP_SELL)
     {
      if ( OrderStopLoss() > OrderOpenPrice()+1*Point && OrderOpenPrice()-OrderClosePrice() > Adj2B.E.Aftr_Pips*Point )
       {
         OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-AdjustToB.E.Plus*Point,OrderTakeProfit(),0,Magenta);
         Print("Adjusted To Breakeven  ",Symbol());
         return(0);
       }
     }
   }
 }

//- ATR TP ---------------------------------------------------------------------------------------------------------------

if (DynamicProfit != 0)
 {
  for(cnt = 0; cnt < OrdersTotal(); cnt++)
   {
     OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if (OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Num && OrderType()==OP_BUY)
     {
      if (OrderClosePrice()-OrderOpenPrice() > pips)
       {
         OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,Brown);
         Print("Close At ATR TakeProfit  ",Symbol());
         return(0);
       }
     }
    if (OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Num && OrderType()==OP_SELL)
     {
      if (OrderOpenPrice()-OrderClosePrice() > pips)
       {
         OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,Brown);
         Print("Close At ATR TakeProfit  ",Symbol());
         return(0);
       }
     }
   }
 }

//- ATR TrailingStop -----------------------------------------------------------------------------------------------------

if (AtrTrailing != 0)
 {
  for(cnt = 0; cnt < OrdersTotal(); cnt++)
   {
     OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if (OrderSymbol()==Symbol() && (AtrTrailing==1) && OrderMagicNumber()==Magic_Num && OrderType()==OP_BUY)
     {
      if ( OrderClosePrice()-OrderOpenPrice() > stops &&
           ( OrderClosePrice()-stops > OrderStopLoss() ||
             OrderStopLoss()==0) )
       {
         OrderModify(OrderTicket(),OrderOpenPrice(),(OrderClosePrice()-stops),OrderTakeProfit(),0,White);
         Print("Adjusted ATR TrailingStop  ",Symbol());
         return(0);
       }
     }
    if (OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Num && OrderType()==OP_SELL)
     {
      if ( OrderOpenPrice()-OrderClosePrice() > stops &&
           ( OrderClosePrice()+stops < OrderStopLoss() ||
             OrderStopLoss()==0) )
       {
         OrderModify(OrderTicket(),OrderOpenPrice(),(OrderClosePrice()+stops),OrderTakeProfit(),0,DodgerBlue);
         Print("Adjusted ATR TrailingStop  ",Symbol());
         return(0);
       }
     }
   }
 }

//- Standard TrailingStop ------------------------------------------------------------------------------------------------

if (StandardTrailAmt != 0 && AtrTrailing == 0)
 {
  for(cnt = 0; cnt < OrdersTotal(); cnt++)
   {
     OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
    if (OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Num && OrderType()==OP_BUY)
     {
      if ( OrderClosePrice()-OrderOpenPrice() > StandardTrailAmt*Point &&
           ( OrderClosePrice()-StandardTrailAmt*Point > OrderStopLoss() ||
             OrderStopLoss()==0) )
       {
         OrderModify(OrderTicket(),OrderOpenPrice(),(OrderClosePrice()-StandardTrailAmt*Point),OrderTakeProfit(),0,White);
         Print("Moved Standard TrailingStop  ",Symbol());
         return(0);
       }
     }
    if (OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Num && OrderType()==OP_SELL)
     {
      if ( OrderOpenPrice()-OrderClosePrice() > StandardTrailAmt*Point &&
           ( OrderClosePrice()+StandardTrailAmt*Point < OrderStopLoss() ||
             OrderStopLoss()==0) )
       { 
         OrderModify(OrderTicket(),OrderOpenPrice(),(OrderClosePrice()+StandardTrailAmt*Point),OrderTakeProfit(),0,DodgerBlue);
         Print("Moved Standard TrailingStop  ",Symbol());
         return(0);
       }
     }
   }
 }

//- End ------------------------------------------------------------------------------------------------------------------
}
return(0);
}