//+------------------------------------------------------------------+

//| Center of Gravity.mq4

//|

//+------------------------------------------------------------------+

#property copyright "Copyright 2002, Finware.ru Ltd."

#property link "http://www.finware.ru/"


#property indicator_separate_window

#property indicator_buffers 2

#property indicator_color1 Blue

#property indicator_color2 Red


//Inputs : Per(10);

//Variable : shift(0),StartBar(600);

//Variable : value1(0), sum(0),sum1(0), cnt(0);


extern int Per=10;

extern int CountBars=300;

//---- buffers

double val1[];

double val2[];


//+------------------------------------------------------------------+

//| Custom indicator initialization function |

//+------------------------------------------------------------------+

int init()

{

string short_name;

//---- indicator line

IndicatorBuffers(2);

SetIndexStyle(0,DRAW_LINE);

SetIndexBuffer(0,val1);

SetIndexStyle(1,DRAW_LINE);

SetIndexBuffer(1,val2);

//----

return(0);

}

//+------------------------------------------------------------------+

//| Center of Gravity |

//+------------------------------------------------------------------+

int start()

{

if (CountBars>=Bars) CountBars=Bars;

SetIndexDrawBegin(0,Bars-CountBars+Per+1);

SetIndexDrawBegin(1,Bars-CountBars+Per+1);

int i,cnt,counted_bars=IndicatorCounted();

double value1,sum,sum1;

//----

if(Bars<=38) return(0);

//---- initial zero

if(counted_bars<Per)

{

for(i=1;i<=0;i++) val1[CountBars-i]=0.0;

for(i=1;i<=0;i++) val2[CountBars-i]=0.0;

}

//----

i=CountBars-Per-1;

// if(counted_bars>=39) i=Bars-counted_bars-1;

while(i>=0)

{


sum = 0.0;

for (cnt=0; cnt<=Per-1; cnt++)

{

sum = sum + (High[i+cnt]+Low[i+cnt])/2;

}


sum1=0.0;

for (cnt=0; cnt<=Per-1; cnt++)

{

sum1=sum1+((High[i+cnt]+Low[i+cnt])*(cnt+1)/2);

}


value1=sum/sum1;

//SetIndexValue(i,value1);

//SetIndexValue2(i-1,value1);


val1[i]=value1;

if (i>0) val2[i-1]=value1;


i--;

}

return(0);

} //+------------------------------------------------------------------+

