//+------------------------------------------------------------------+
//|                                            Ind-TD-DeMark-3-1.mq4 |
//|                            Copyright © 2005, Kara Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Kara Software Corp."
#property link      ""
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Red
#property indicator_color2 Blue
//---- input parameters
extern int       BackSteps=0;
extern int       ShowingSteps=1;
extern bool      FractalAsTD=false;
extern bool      Commen=true;
extern bool      TD=true;
extern bool      TrendLine=true;
extern bool      HorizontLine=true;
extern bool      TakeProf=true;
//---- buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
//====================================================================
int init()
  {
   SetIndexStyle(0,DRAW_ARROW);
   SetIndexArrow(0,217);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexEmptyValue(0,0.0);
   SetIndexStyle(1,DRAW_ARROW);
   SetIndexArrow(1,218);
   SetIndexBuffer(1,ExtMapBuffer2);
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
   return(0);
  }
int deinit()
  {
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
   return(0);
  }
//--------------------------------------------------------------------
int SetTDPoint(int B)
{
 int shift;
 if (FractalAsTD==false)
   {
    for (shift=B;shift>1;shift--)
       {
        if (High[shift+1]<High[shift] && High[shift-1]<High[shift] && Close[shift+2]<High[shift])
             ExtMapBuffer1[shift]=High[shift];
        else ExtMapBuffer1[shift]=0;    
        if (Low[shift+1]>Low[shift] && Low[shift-1]>Low[shift] && Close[shift+2]>Low[shift])
            ExtMapBuffer2[shift]=Low[shift];
        else ExtMapBuffer2[shift]=0;    
       }  
    ExtMapBuffer1[0]=0;
    ExtMapBuffer2[0]=0;
    ExtMapBuffer1[1]=0;
    ExtMapBuffer2[1]=0;
   }
 else
   {
    for (shift=B;shift>3;shift--)
       {
        if (High[shift+1]<=High[shift] && High[shift-1]<High[shift] && High[shift+2]<=High[shift] && High[shift-2]<High[shift])
             ExtMapBuffer1[shift]=High[shift];
        else ExtMapBuffer1[shift]=0;    
        if (Low[shift+1]>=Low[shift] && Low[shift-1]>Low[shift] && Low[shift+2]>=Low[shift] && Low[shift-2]>Low[shift])
            ExtMapBuffer2[shift]=Low[shift];
        else ExtMapBuffer2[shift]=0;    
       }  
    ExtMapBuffer1[0]=0;
    ExtMapBuffer2[0]=0;
    ExtMapBuffer1[1]=0;
    ExtMapBuffer2[1]=0;
    ExtMapBuffer1[2]=0;
    ExtMapBuffer2[2]=0;    
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
    while(ExtMapBuffer1[i]==0)
      {i++;if(i>Bars-2)return(-1);}
    j++;
   }   
 return (i);         
}
//--------------------------------------------------------------------
int GetNextHighTD(int P)
{ 
 int i=P+1;
 while(ExtMapBuffer1[i]<=High[P]){i++;if(i>Bars-2)return(-1);}
 return (i);
}
//--------------------------------------------------------------------
int GetLowTD(int P)
{
 int i=0,j=0;
 while (j<P)
   {
    i++;
    while(ExtMapBuffer2[i]==0)
      {i++;if(i>Bars-2)return(-1);}
    j++;
   }   
 return (i); 
}
//--------------------------------------------------------------------
int GetNextLowTD(int P)
{
 int i=P+1;
 while(ExtMapBuffer2[i]>=Low[P] || ExtMapBuffer2[i]==0){i++;if(i>Bars-2)return(-1);}
 return (i);
}
//--------------------------------------------------------------------
int TrendLineHighTD(int H1,int H2,int Step,int Col)
{
 ObjectSet("HL_"+Step,OBJPROP_TIME1,Time[H2]);ObjectSet("HL_"+Step,OBJPROP_TIME2,Time[H1]);
 ObjectSet("HL_"+Step,OBJPROP_PRICE1,High[H2]);ObjectSet("HL_"+Step,OBJPROP_PRICE2,High[H1]);
 ObjectSet("HL_"+Step,OBJPROP_COLOR,Col);
 if (Step==1)ObjectSet("HL_"+Step,OBJPROP_WIDTH,2);
 else ObjectSet("HL_"+Step,OBJPROP_WIDTH,1);
 return(0);
}   
//--------------------------------------------------------------------
int TrendLineLowTD(int L1,int L2,int Step,int Col)
{
 ObjectSet("LL_"+Step,OBJPROP_TIME1,Time[L2]);ObjectSet("LL_"+Step,OBJPROP_TIME2,Time[L1]);
 ObjectSet("LL_"+Step,OBJPROP_PRICE1,Low[L2]);ObjectSet("LL_"+Step,OBJPROP_PRICE2,Low[L1]);
 ObjectSet("LL_"+Step,OBJPROP_COLOR,Col);
 if (Step==1)ObjectSet("LL_"+Step,OBJPROP_WIDTH,2);
 else ObjectSet("LL_"+Step,OBJPROP_WIDTH,1);      
 return(0);
}
//--------------------------------------------------------------------
int HorizontLineHighTD(int H1,int H2,int Step,double St,int Col)
{
 ObjectSet("HHL_"+Step,OBJPROP_PRICE1,High[H2]-(High[H2]-High[H1])/(H2-H1)*H2);
 ObjectSet("HHL_"+Step,OBJPROP_STYLE,St);
 ObjectSet("HHL_"+Step,OBJPROP_COLOR,Col);
 return(0); 
}   
//--------------------------------------------------------------------
int HorizontLineLowTD(int L1,int L2,int Step,double St,int Col)
{
 ObjectSet("HLL_"+Step,OBJPROP_PRICE1,Low[L2]+(Low[L1]-Low[L2])/(L2-L1)*L2);
 ObjectSet("HLL_"+Step,OBJPROP_STYLE,St);
 ObjectSet("HLL_"+Step,OBJPROP_COLOR,Col);
 return(0); 
}
//--------------------------------------------------------------------
string TakeProfitHighTD(int H1,int H2,int Step,int Col)
{
 int i,ii,j=0;
 string Comm="";
 double kH,HC1,HC2,HC3,k,St;
 kH=(High[H2]-High[H1])/(H2-H1);
 while (NormalizeDouble(Point,j)==0)j++; 
 k=0;
 for(i=H1;i>0;i--)if(Close[i]>High[H2]-kH*(H2-i)){k=High[H2]-kH*(H2-i);break;}
 if (k>0)
   { 
    Comm=Comm+"UTD_Line ("+DoubleToStr(High[H2]-kH*H2,j)+") hit the point "+DoubleToStr(k,j)+", target above:\n";
    ii=Lowest(NULL,0,MODE_LOW,H2-i,i);    
    HC1=High[H2]-kH*(H2-ii)-Low[ii];
    HC2=High[H2]-kH*(H2-ii)-Close[ii];
    ii=Lowest(NULL,0,MODE_CLOSE,H2-i,i);
    HC3=High[H2]-kH*(H2-ii)-Close[ii];
    St=STYLE_SOLID;
   } 
 else
   {
    k=High[H2]-kH*H2;
    Comm=Comm+"UTD_Line ("+DoubleToStr(k,j)+"), estimated targets above if hit:\n";  
    ii=Lowest(NULL,0,MODE_LOW,H2,0);    
    HC1=High[H2]-kH*(H2-ii)-Low[ii];
    HC2=High[H2]-kH*(H2-ii)-Close[ii];
    ii=Lowest(NULL,0,MODE_CLOSE,H2,0);
    HC3=High[H2]-kH*(H2-ii)-Close[ii];
    St=STYLE_DASHDOT;  
   }
 ObjectSet("HL_"+Step,OBJPROP_STYLE,St);  
 Comm=Comm+"Target1="+DoubleToStr(HC1+k,j)+" ("+DoubleToStr(HC1/Point,0)+"p.)";
 Comm=Comm+" Target2="+DoubleToStr(HC2+k,j)+" ("+DoubleToStr(HC2/Point,0)+"p.)";
 Comm=Comm+" Target3="+DoubleToStr(HC3+k,j)+" ("+DoubleToStr(HC3/Point,0)+"p.)\n";  
 ObjectSet("HC1_"+Step,OBJPROP_TIME1,Time[H1]);ObjectSet("HC1_"+Step,OBJPROP_TIME2,Time[0]);
 ObjectSet("HC1_"+Step,OBJPROP_PRICE1,HC1+k);ObjectSet("HC1_"+Step,OBJPROP_PRICE2,HC1+k);
 ObjectSet("HC1_"+Step,OBJPROP_COLOR,Col);ObjectSet("HC1_"+Step,OBJPROP_STYLE,St);      
 ObjectSet("HC2_"+Step,OBJPROP_TIME1,Time[H1]);ObjectSet("HC2_"+Step,OBJPROP_TIME2,Time[0]);
 ObjectSet("HC2_"+Step,OBJPROP_PRICE1,HC2+k);ObjectSet("HC2_"+Step,OBJPROP_PRICE2,HC2+k);
 ObjectSet("HC2_"+Step,OBJPROP_COLOR,Col);ObjectSet("HC2_"+Step,OBJPROP_STYLE,St);
 ObjectSet("HC3_"+Step,OBJPROP_TIME1,Time[H1]);ObjectSet("HC3_"+Step,OBJPROP_TIME2,Time[0]);
 ObjectSet("HC3_"+Step,OBJPROP_PRICE1,HC3+k);ObjectSet("HC3_"+Step,OBJPROP_PRICE2,HC3+k);
 ObjectSet("HC3_"+Step,OBJPROP_COLOR,Col);ObjectSet("HC3_"+Step,OBJPROP_STYLE,St);   
 if (Step==1)
   {
    ObjectSet("HC1_"+Step,OBJPROP_WIDTH,2);
    ObjectSet("HC2_"+Step,OBJPROP_WIDTH,2);
    ObjectSet("HC3_"+Step,OBJPROP_WIDTH,2);
   } 
 else
   {
    ObjectSet("HC1_"+Step,OBJPROP_WIDTH,1);
    ObjectSet("HC2_"+Step,OBJPROP_WIDTH,1);
    ObjectSet("HC3_"+Step,OBJPROP_WIDTH,1);
   }
 return(Comm); 
}
//--------------------------------------------------------------------
string TakeProfitLowTD(int L1,int L2,int Step,int Col)
{
 int i,ii,j=0;
 string Comm="";
 double kL,LC1,LC2,LC3,k,St;
 kL=(Low[L1]-Low[L2])/(L2-L1);
 while (NormalizeDouble(Point,j)==0)j++; 
 k=0;
 for(i=L1;i>0;i--)if(Close[i]<Low[L2]+kL*(L2-i)){k=Low[L2]+kL*(L2-i);break;}
 if (k>0)
   {
    Comm=Comm+"LTD_Line ("+DoubleToStr(Low[L2]+kL*L2,j)+") hit the point "+DoubleToStr(k,j)+", targets below:\n";
    ii=Highest(NULL,0,MODE_HIGH,L2-i,i);    
    LC1=High[ii]-(Low[L2]+kL*(L2-ii));
    LC2=Close[ii]-(Low[L2]+kL*(L2-ii));
    i=Highest(NULL,0,MODE_CLOSE,L2-i,i);
    LC3=Close[ii]-(Low[L2]+kL*(L2-ii));
    St=STYLE_SOLID;
   } 
 else
   {
    k=Low[L2]+kL*L2;
    Comm=Comm+"LTD_Line ("+DoubleToStr(k,j)+"), estimated targets below if hit:\n";        
    ii=Highest(NULL,0,MODE_HIGH,L2,0);    
    LC1=High[ii]-(Low[L2]+kL*(L2-ii));
    LC2=Close[ii]-(Low[L2]+kL*(L2-ii));
    ii=Highest(NULL,0,MODE_CLOSE,L2,0);
    LC3=Close[ii]-(Low[L2]+kL*(L2-ii));
    St=STYLE_DASHDOT;
   }
 ObjectSet("LL_"+Step,OBJPROP_STYLE,St);   
 Comm=Comm+"Target1="+DoubleToStr(k-LC1,j)+" ("+DoubleToStr(LC1/Point,0)+"p.)";
 Comm=Comm+" Target2="+DoubleToStr(k-LC2,j)+" ("+DoubleToStr(LC2/Point,0)+"p.)";
 Comm=Comm+" Target3="+DoubleToStr(k-LC3,j)+" ("+DoubleToStr(LC3/Point,0)+"p.)\n";
 ObjectSet("LC1_"+Step,OBJPROP_TIME1,Time[L1]);ObjectSet("LC1_"+Step,OBJPROP_TIME2,Time[0]);
 ObjectSet("LC1_"+Step,OBJPROP_PRICE1,k-LC1);ObjectSet("LC1_"+Step,OBJPROP_PRICE2,k-LC1);
 ObjectSet("LC1_"+Step,OBJPROP_COLOR,Col);ObjectSet("LC1_"+Step,OBJPROP_STYLE,St);      
 ObjectSet("LC2_"+Step,OBJPROP_TIME1,Time[L1]);ObjectSet("LC2_"+Step,OBJPROP_TIME2,Time[0]);
 ObjectSet("LC2_"+Step,OBJPROP_PRICE1,k-LC2);ObjectSet("LC2_"+Step,OBJPROP_PRICE2,k-LC2);
 ObjectSet("LC2_"+Step,OBJPROP_COLOR,Col);ObjectSet("LC2_"+Step,OBJPROP_STYLE,St);
 ObjectSet("LC3_"+Step,OBJPROP_TIME1,Time[L1]);ObjectSet("LC3_"+Step,OBJPROP_TIME2,Time[0]);
 ObjectSet("LC3_"+Step,OBJPROP_PRICE1,k-LC3);ObjectSet("LC3_"+Step,OBJPROP_PRICE2,k-LC3);
 ObjectSet("LC3_"+Step,OBJPROP_COLOR,Col);ObjectSet("LC3_"+Step,OBJPROP_STYLE,St);   
 if (Step==1)
   {
    ObjectSet("LC1_"+Step,OBJPROP_WIDTH,2);
    ObjectSet("LC2_"+Step,OBJPROP_WIDTH,2);
    ObjectSet("LC3_"+Step,OBJPROP_WIDTH,2);
   } 
 else
   {
    ObjectSet("LC1_"+Step,OBJPROP_WIDTH,1);
    ObjectSet("LC2_"+Step,OBJPROP_WIDTH,1);
    ObjectSet("LC3_"+Step,OBJPROP_WIDTH,1);
   }
 return(Comm);
}
//--------------------------------------------------------------------
string TDMain(int Step)
{
 int H1,H2,L1,L2;
 string Comm="---   STEP "+Step+"   --------------------\n";   
 int i,j; while (NormalizeDouble(Point,j)==0)j++;
 double Style;
 double Col[20];Col[0]=Red;Col[2]=Magenta;Col[4]=Chocolate;Col[6]=Goldenrod;Col[8]=SlateBlue;
                Col[1]=Blue;Col[3]=DeepSkyBlue;Col[5]=Green;Col[7]=MediumOrchid;Col[9]=CornflowerBlue;
                Col[10]=Red;Col[12]=Magenta;Col[14]=Chocolate;Col[16]=Goldenrod;Col[18]=SlateBlue;
                Col[11]=Blue;Col[13]=DeepSkyBlue;Col[15]=Green;Col[17]=MediumOrchid;Col[19]=CornflowerBlue;
   Step=Step+BackSteps;  
   H1=GetHighTD(Step);
   H2=GetNextHighTD(H1);
   L1=GetLowTD(Step);
   L2=GetNextLowTD(L1);
   if (H1<0)Comm=Comm+"UTD on the chart: no above TD point \n";
   else 
     if (H2<0)Comm=Comm+"UTD on the chart: no TD point above the last one ("+DoubleToStr(High[H1],j)+")\n";
     else Comm=Comm+"UTD "+DoubleToStr(High[H2],j)+"  "+DoubleToStr(High[H1],j)+"\n"; 
   if (L1<0)Comm=Comm+"LTD on the chart: no below TD point \n";
   else 
     if (L2<0)Comm=Comm+"LTD on the chart: no TD point below the last one ("+DoubleToStr(Low[L1],j)+")\n";   
     else Comm=Comm+"LTD  "+DoubleToStr(Low[L2],j)+"  "+DoubleToStr(Low[L1],j)+"\n";
   //-----------------------------------------------------------------------------------
   if (Step==1)Style=STYLE_SOLID;
   else Style=STYLE_DOT;
   if (H1>0 && H2>0)
     {
      if (TrendLine==1)
        {
         ObjectCreate("HL_"+Step,OBJ_TREND,0,0,0,0,0);
         TrendLineHighTD(H1,H2,Step,Col[Step*2-2]);
        } 
      else ObjectDelete("HL_"+Step);
      if (HorizontLine==1 && Step==1)
        {
         ObjectCreate("HHL_"+Step,OBJ_HLINE,0,0,0,0,0);
         HorizontLineHighTD(H1,H2,Step,Style,Col[Step*2-2]);
        } 
      else ObjectDelete("HHL_"+Step);
      if (TakeProf==1)
        {
         ObjectCreate("HC1_"+Step,OBJ_TREND,0,0,0,0,0);
         ObjectCreate("HC2_"+Step,OBJ_TREND,0,0,0,0,0);
         ObjectCreate("HC3_"+Step,OBJ_TREND,0,0,0,0,0);
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
      else ObjectDelete("LL_"+Step);
      if (HorizontLine==1 && Step==1)
        {
         ObjectCreate("HLL_"+Step,OBJ_HLINE,0,0,0,0,0);
         HorizontLineLowTD(L1,L2,Step,Style,Col[Step*2-1]);
        } 
      else ObjectDelete("HLL_"+Step);
      if (TakeProf==1)
        {
         ObjectCreate("LC1_"+Step,OBJ_TREND,0,0,0,0,0);
         ObjectCreate("LC2_"+Step,OBJ_TREND,0,0,0,0,0);
         ObjectCreate("LC3_"+Step,OBJ_TREND,0,0,0,0,0);
         Comm=Comm+TakeProfitLowTD(L1,L2,Step,Col[Step*2-1]);
        }
      else
        {
         ObjectDelete("LC1_"+Step);
         ObjectDelete("LC2_"+Step);
         ObjectDelete("LC3_"+Step);       
        }
     }
 return(Comm);       
}
//--------------------------------------------------------------------
int start()
{
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
     Comment("ShowingSteps value 0 - 10");  
     return(0);
    } 
   for (int i=1;i<=ShowingSteps;i++)Comm=Comm+TDMain(i);
   Comm=Comm+"------------------------------------\nShowingSteps="+ShowingSteps+"\nBackSteps="+BackSteps;    
   if (FractalAsTD==true)Comm=Comm+"\nFractals";
   else Comm=Comm+"\nTD point";
   if (Commen==1)Comment(Comm);
   else Comment("");
   return(0);
  }
//+------------------------------------------------------------------+



